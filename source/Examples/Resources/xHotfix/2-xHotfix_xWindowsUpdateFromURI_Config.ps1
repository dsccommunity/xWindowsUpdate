<#PSScriptInfo

.VERSION 1.0.0

.GUID e3e23ff2-09dc-40f3-893a-e3ab840e516c

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
        This example shows how to install a particular windows update. However,
        the URI and ID properties can be changed as per the hotfix that you want
        to install
#>
Configuration xHotfix_xWindowsUpdateFromURI_Config
{
    Import-DscResource -ModuleName 'xWindowsUpdate'

    xHotfix 'KB956056'
    {
        Path   = 'http://hotfixv4.microsoft.com/Microsoft%20Office%20SharePoint%20Server%202007/sp2/officekb956056fullfilex64glb/12.0000.6327.5000/free/358323_intl_x64_zip.exe'
        Id     = 'KB956056'
        Ensure = 'Present'
    }

}
