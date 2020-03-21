<#PSScriptInfo

.VERSION 1.0.0

.GUID d6aaf032-3561-4ee8-ad04-1ac361f3809c

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
        This example shows how to set the Windows Update Agent to use the Windows
        Update service and sets the notifications to scheduled install. Does not
        install updates during the configuration.
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
