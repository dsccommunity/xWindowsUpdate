<#
    .EXAMPLE
        Set Windows Update Agent to use Windows Update. Disables notification of
        future updates. Install all Security and Important updates from Windows
        Update during the configuration and consistency check.
#>
Configuration xWindowsUpdateAgent_InstallUpdatesOnEachConsistencyCheck_Config
{
    Import-DscResource -ModuleName 'xWindowsUpdate'

    xWindowsUpdateAgent 'InstallSecurityAndImportant'
    {
        IsSingleInstance = 'Yes'
        UpdateNow        = $true
        Category         = @('Security','Important')
        Source           = 'WindowsUpdate'
        Notifications    = 'Disabled'
    }
}
