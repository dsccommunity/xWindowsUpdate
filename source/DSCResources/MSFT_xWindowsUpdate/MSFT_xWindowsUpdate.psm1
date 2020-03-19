$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'

Import-Module -Name $script:resourceHelperModulePath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

$script:cacheLocation = "$env:ProgramData\Microsoft\Windows\PowerShell\Configuration\BuiltinProvCache\MSFT_xWindowsUpdate"

# Get-TargetResource function
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Id
    )

    $uri, $kbId = Test-StandardArguments -Path $Path -Id $Id

    Write-Verbose $($script:localizedData.GettingHotfixMessage -f ${Id})

    $hotfix = Get-HotFix -Id "KB$kbId"

    $returnValue = @{
        Path = ''
        Id   = $hotfix.HotFixId
        Log  = ''
    }

    $returnValue

}

$Debug = $true
function Trace-Message
{
    param
    (
        [Parameter()]
        [System.String]
        $Message
    )

    if ($Debug)
    {
        Write-Verbose $Message
    }
}

function New-InvalidArgumentException
{
    param
    (
        [Parameter()]
        [System.String]
        $Message,

        [Parameter()]
        [System.String]
        $ParamName
    )

    $exception = new-object System.ArgumentException $Message, $ParamName
    $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $ParamName, 'InvalidArgument', $null

    throw $errorRecord
}

# The Set-TargetResource cmdlet
function Set-TargetResource
{
    # should be [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "DSCMachineStatus")], but it doesn't work
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "")]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Id,

        [Parameter()]
        [System.String]
        $Log,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credential
    )

    if (!$Log)
    {
        $Log = [IO.Path]::GetTempFileName()
        $Log += '.etl'

        Write-Verbose "$($script:localizedData.LogNotSpecified -f ${Log})"
    }

    $uri, $kbId = Test-StandardArguments -Path $Path -Id $Id

    if ($Ensure -eq 'Present')
    {
        $filePath = Test-WindowsUpdatePath -uri $uri -Credential $Credential
        Write-Verbose "$($script:localizedData.StartKeyWord) $($script:localizedData.ActionInstallUsingWsusa)"

        Start-Process -FilePath 'wusa.exe' -ArgumentList "`"$filepath`" /quiet /norestart /log:`"$Log`"" -Wait -NoNewWindow -ErrorAction SilentlyContinue
        $errorOccurred = Get-WinEvent -Path $Log -Oldest | Where-Object { $_.Id -eq 3 }
        if ($errorOccurred)
        {
            $errorMessage = $errorOccurred.Message
            throw "$($script:localizedData.ErrorOccurredOnHotfixInstall -f ${Log}, ${errorMessage})"
        }

        Write-Verbose "$($script:localizedData.EndKeyWord) $($script:localizedData.ActionInstallUsingWsusa)"
    }
    else
    {
        $argumentList = "/uninstall /KB:$kbId /quiet /norestart /log:`"$Log`""

        Write-Verbose "$($script:localizedData.StartKeyWord) $($script:localizedData.ActionUninstallUsingWsusa) Arguments: $ArgumentList"

        Start-Process -FilePath 'wusa.exe' -ArgumentList $argumentList  -Wait -NoNewWindow  -ErrorAction SilentlyContinue
        #Read the log and see if there was an error event
        $errorOccurred = Get-WinEvent -Path $Log -Oldest | Where-Object { $_.Id -eq 3 }
        if ($errorOccurred)
        {
            $errorMessage = $errorOccurred.Message
            throw "$($script:localizedData.ErrorOccurredOnHotfixUninstall -f ${Log}, ${errorMessage})"
        }

        Write-Verbose "$($script:localizedData.EndKeyWord) $($script:localizedData.ActionUninstallUsingWsusa)"
    }

    if (Test-Path -Path 'variable:\LASTEXITCODE')
    {
        if ($LASTEXITCODE -eq 3010)
        {
            # reboot machine if exitcode indicates reboot.
            $global:DSCMachineStatus = 1
        }
    }
}


# Function to test if Hotfix is installed.
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Id,

        [Parameter()]
        [System.String]
        $Log,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credential
    )

    Write-Verbose "$($script:localizedData.TestingEnsure -f ${Ensure})"
    $uri, $kbId = Test-StandardArguments -Path $Path -Id $Id

    # This is not the correct way to test to see if an update is applicable to a machine
    # but, WUSA does not currently expose a way to ask.
    $result = Get-HotFix -Id "KB$kbId" -ErrorAction SilentlyContinue
    $returnValue = [System.Boolean] $result

    if ($Ensure -eq 'Present')
    {
        return $returnValue
    }
    else
    {
        return !$returnValue
    }

}

function Test-StandardArguments
{
    param
    (
        [Parameter()]
        [System.String]
        $Path,

        [Parameter()]
        [System.String]
        $Id
    )

    Trace-Message ($script:localizedData.TestStandardArgumentsPathWasPath -f $Path)
    $uri = $null
    try
    {
        $uri = [uri] $Path
    }
    catch
    {
        New-InvalidArgumentException ($script:localizedData.InvalidPath -f $Path) 'Path'
    }

    if (-not @('file', 'http', 'https') -contains $uri.Scheme)
    {
        Trace-Message ($Localized.TheUriSchemeWasUriScheme -f $uri.Scheme)
        New-InvalidArgumentException ($script:localizedData.InvalidPath -f $Path) 'Path'
    }

    $pathExt = [System.IO.Path]::GetExtension($Path)
    Trace-Message ($script:localizedData.ThePathExtensionWasPathExt -f $pathExt)
    if (-not @('.msu') -contains $pathExt.ToLower())
    {
        New-InvalidArgumentException ($script:localizedData.InvalidBinaryType -f $Path) 'Path'
    }

    if (-not $Id)
    {
        New-InvalidArgumentException ($script:localizedData.NeedsMoreInfo -f $Path) 'Id'
    }
    else
    {
        if ($Id -match 'kb[0-9]+')
        {
            if ($Matches[0] -eq $id)
            {
                $kbId = $id.Substring(2)
            }
            else
            {
                New-InvalidArgumentException ($script:localizedData.InvalidIdFormat -f $Path) 'Id'
            }
        }
        elseif ($id -match '[0-9]+')
        {
            if ($Matches[0] -eq $id)
            {
                $kbId = $id
            }
            else
            {
                New-InvalidArgumentException ($script:localizedData.InvalidIdFormat -f $Path) 'Id'
            }
        }
    }

    return @($uri, $kbId)
}

function Test-WindowsUpdatePath
{
    <#
        .SYNOPSIS
        Validate path, if necessary, cache file and return the location to be accessed
    #>
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Uri]
        $uri,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credential
    )

    if ($uri.IsUnc)
    {
        $psdriveArgs = @{
            Name       = ([guid]::NewGuid())
            PSProvider = 'FileSystem'
            Root       = (Split-Path $uri.LocalPath)
        }

        if ($Credential)
        {
            #We need to optionally include these and then splat the hash otherwise
            #we pass a null for Credential which causes the cmdlet to pop a dialog up
            $psdriveArgs['Credential'] = $Credential
        }

        $psdrive = New-PSDrive @psdriveArgs
        $Path = Join-Path $psdrive.Root (Split-Path -Leaf $uri.LocalPath) #Necessary?
    }
    elseif (@('http', 'https') -contains $uri.Scheme)
    {
        $scheme = $uri.Scheme
        $outStream = $null
        $responseStream = $null

        try
        {
            Trace-Message ($script:localizedData.CreatingCacheLocation)

            if (-not (Test-Path -PathType Container $script:cacheLocation))
            {
                mkdir $script:cacheLocation | Out-Null
            }

            $destName = Join-Path $script:cacheLocation (Split-Path -Leaf $uri.LocalPath)

            Trace-Message ($script:localizedData.NeedToDownloadFileFromSchemeDestinationWillBeDestName -f $scheme, $destName)

            try
            {
                Trace-Message ($script:localizedData.CreatingTheDestinationCacheFile)
                $outStream = New-Object System.IO.FileStream $destName, 'Create'
            }
            catch
            {
                #Should never happen since we own the cache directory
                Throw-TerminatingError ($script:localizedData.CouldNotOpenDestFile -f $destName) $_
            }

            try
            {
                Trace-Message ($script:localizedData.CreatingTheSchemeStream -f $scheme)
                $request = [System.Net.WebRequest]::Create($uri)
                Trace-Message ($script:localizedData.SettingDefaultCredential)
                $request.Credentials = [System.Net.CredentialCache]::DefaultCredentials
                if ($scheme -eq 'http')
                {
                    Trace-Message ($script:localizedData.SettingAuthenticationLevel)
                    # default value is MutualAuthRequested, which applies to https scheme
                    $request.AuthenticationLevel = [System.Net.Security.AuthenticationLevel]::None
                }
                if ($scheme -eq 'https')
                {
                    Trace-Message ($script:localizedData.IgnoringBadCertificates)
                    $request.ServerCertificateValidationCallBack = { $true }
                }
                Trace-Message ($script:localizedData.GettingTheSchemeResponseStream -f $scheme)
                $responseStream = (([System.Net.HttpWebRequest] $request).GetResponse()).GetResponseStream()
            }
            catch
            {
                Trace-Message ($script:localizedData.ErrorOutString -f ($_ | Out-String))
                Throw-TerminatingError ($script:localizedData.CouldNotGetHttpStream -f $scheme, $Path) $_
            }

            try
            {
                Trace-Message ($script:localizedData.CopyingTheSchemeStreamBytesToTheDiskCache -f $scheme)
                $responseStream.CopyTo($outStream)
                $responseStream.Flush()
                $outStream.Flush()
            }
            catch
            {
                Trace-Message ($script:localizedData.ErrorOutString -f ($_ | Out-String))
                Throw-TerminatingError ($script:localizedData.ErrorCopyingDataToFile -f $Path, $destName) $_
            }
        }
        finally
        {
            if ($outStream)
            {
                $outStream.Close()
            }

            if ($responseStream)
            {
                $responseStream.Close()
            }
        }
        Trace-Message ($script:localizedData.RedirectingPackagePathToCacheFileLocation)
        $Path = $downloadedFileName = $destName
    }

    return $Path
}

Export-ModuleMember -Function *-TargetResource
