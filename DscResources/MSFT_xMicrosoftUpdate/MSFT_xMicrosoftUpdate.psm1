function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure
    )

    #Get the registered update services
    $UpdateServices = (New-Object -ComObject Microsoft.Update.ServiceManager).Services

    $returnValue = @{
                        Ensure = $Ensure
                    }

    #Check if the microsoft update service is registered
    if($UpdateServices | where {$_.ServiceID -eq '7971f918-a847-4430-9279-4a52d1efe18d'})
    {
        $returnValue.Ensure = 'Present'
    }
    Else
    {
        $returnValue.Ensure = 'Absent'
    }
    
    $returnValue
}


function Set-TargetResource
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure
    )


    Switch($Ensure)
    {
        'Present'
        {
            If($PSCmdlet.ShouldProcess("Enable Microsoft Update"))
            {
                Try
                {
                    Write-Verbose "Enable the Microsoft Update setting"
                    (New-Object -ComObject Microsoft.Update.ServiceManager).AddService2('7971f918-a847-4430-9279-4a52d1efe18d',7,"")
                    Restart-Service wuauserv -ErrorAction SilentlyContinue
                }
                Catch
                {
                    $ErrorMsg = $_.Exception.Message
                    Write-Verbose $ErrorMsg
                }
            }
        }
        'Absent'
        {
            If($PSCmdlet.ShouldProcess("$Drive","Disable Microsoft Update"))
            {
                Try
                {
                    Write-Verbose "Disable the Microsoft Update setting"
                    (New-Object -ComObject Microsoft.Update.ServiceManager).RemoveService('7971f918-a847-4430-9279-4a52d1efe18d')
                }
                Catch
                {
                    $ErrorMsg = $_.Exception.Message
                    Write-Verbose $ErrorMsg
                }
            }
        }
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure
    )

    #Output the result of Get-TargetResource function.
    $Get = Get-TargetResource -Ensure $Ensure

    If($Ensure -eq $Get.Ensure)
    {
        return $true
    }
    Else
    {
        return $false
    }
}


Export-ModuleMember -Function *-TargetResource
