<#
    .EXAMPLE
        Sets the Windows Update Agent to use the Windows Update service and sets
        the notifications to scheduled install. Does not install updates during
        the configuration.
#>
Configuration xWindowsUpdateAgent_SetWuaScheduledFromWu_Config
{
    Import-DscResource -ModuleName 'xWindowsUpdate'

    xWindowsUpdateAgent 'ScheduleInstall'
    {
        IsSingleInstance = 'Yes'
        UpdateNow        = $false
        Source           = 'WindowsUpdate'
        Notifications    = 'ScheduledInstallation'
    }
}
