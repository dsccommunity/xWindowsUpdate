<#PSScriptInfo

.VERSION 1.0.0

.GUID ba700959-e268-4710-8b65-0b02a7104b86

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
        This example shows how to install the hotfix from the .msu file given.
        If the hotfix with the required hotfix ID is already present on
        the system, the installation is skipped.
#>
Configuration xHotfix_xWindowsUpdateFromPath_Config
{
    Import-DscResource -ModuleName 'xWindowsUpdate'

    xHotfix 'KB2937982'
    {
        Path   = 'c:/temp/Windows8.1-KB2908279-v2-x86.msu'
        Id     = 'KB2937982'
        Ensure = 'Present'
    }
}
