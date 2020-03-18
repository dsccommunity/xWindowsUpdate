function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]

    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [string]$IsSingleInstance, 
        
        [Nullable[datetime]]$StartTime,

        [Nullable[datetime]]$EndTime
    )
    
    $rebootRequired = Get-WuaSystemInfo

    return @{
        IsSingleInstance = $IsSingleInstance
        StartTime = $StartTime
        EndTime = $EndTime
        RebootRequired = $rebootRequired.RebootRequired
    }
}

function Set-TargetResource
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [string]$IsSingleInstance, 

        [Nullable[datetime]]$StartTime,

        [Nullable[datetime]]$EndTime
    )

    if(Assert-MaintenanceWindow -StartTime $StartTime -EndTime $EndTime)
    {
        Write-Verbose "Computer within maintenance window. StartTime: $StartTime EndTime: $EndTime"
        $global:DSCMachineStatus = 1
    }
    else
    {
        Write-Verbose "Computer is not in defined maintenance window. StartTime: $StartTime EndTime: $EndTime"
    }
}

function Test-TargetResource
{
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [string]$IsSingleInstance,
                
        [Nullable[datetime]]$StartTime,

        [Nullable[datetime]]$EndTime
    )

    $rebootRequired = $(Get-WuaSystemInfo).RebootRequired  

    return !$rebootRequired
}

function Assert-MaintenanceWindow
{
    param
    (
        [Nullable[datetime]]$StartTime,

        [Nullable[datetime]]$EndTime
    )

    $currentDate = Get-Date
    Write-Verbose "Current date: $currentDate"

    $inMaintenanceWindow = $false
    #if no window defined, will always return $true to ignore the maintenance window logic
    if(-not $StartTime -and -not $EndTime)
    {
        $inMaintenanceWindow = $true
    }
    elseif($StartTime -and $EndTime)
    {
        if($currentDate -gt $StartTime -and $currentDate -lt $EndTime)
        {
            $inMaintenanceWindow = $true   
        }
    }
    elseif($StartTime)
    {
        if($currentDate -gt $StartTime)
        {
            $inMaintenanceWindow = $true
        }
    }
    elseif($EndTime)
    {
        if($currentDate -lt $EndTime)
        {
            $inMaintenanceWindow = $true
        }
    }

    return $inMaintenanceWindow
}

function Get-WuaSystemInfo
{
    return (New-Object -ComObject 'Microsoft.Update.SystemInfo')
}

Export-ModuleMember -Function *-TargetResource
