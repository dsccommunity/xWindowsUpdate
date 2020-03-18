<#PSScriptInfo

.VERSION 1.0.0

.GUID 6d0bc267-03dc-4478-b771-89215edd66fb

.AUTHOR DSC Community

.COMPANYNAME DSC Community

.COPYRIGHT DSC Community contributors. All rights reserved.

.TAGS DSCConfiguration

.LICENSEURI https://github.com/dsccommunity/xWindowsUpdate/blob/master/LICENSE

.PROJECTURI https://github.com/dsccommunity/xWindowsUpdate

.ICONURI https://dsccommunity.org/images/DSC_Logo_300p.png

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
First version.

.PRIVATEDATA 2016-Datacenter,2016-Datacenter-Server-Core

#>

#Requires -Module xWindowsUpdate

<#
    .DESCRIPTION
        This example shows how to set the Windows Update Agent to use Windows Update.
        Disables notification of future updates. Install all Security and Important
        updates from Windows Update during the configuration and consistency check.
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
