<#
    .EXAMPLE
        This configuration will install the hotfix from the .msu file given.
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
