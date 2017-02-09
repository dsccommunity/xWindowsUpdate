<#
Sets the Windows Update Agent to use the Windows Update service 
(vs Microsoft Update or WSUS) and sets the notifications to 
scheduled install (no notifications, just automatically install 
the updates.)  Does not install updates during the configuration
#>

Configuration Example
{
    Import-DscResource -ModuleName xWindowsUpdate
    
    xWindowsUpdateAgent MuSecurityImportant
    {
        IsSingleInstance = 'Yes'
        UpdateNow        = $false
        Source           = 'WindowsUpdate'
        Notifications    = 'ScheduledInstallation'
    }
}
