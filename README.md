[![Build status](https://ci.appveyor.com/api/projects/status/t4bw4lnmxy1dg3ys/branch/master?svg=true)](https://ci.appveyor.com/project/PowerShell/xwindowsupdate/branch/master)

# xWindowsUpdate

The **xWindowsUpdate** module contains the **xWindowsUpdate** and **xMicrosoftUpdate** DSC resources.
**xWindowsUpdate** installs a Windows Update (or hotfix) from a given path. For more information on Windows Update and Hotfix, please refer to [this TechNet article](http://technet.microsoft.com/en-us/library/cc750077.aspx).
**xMicrosoftUpdate** enables or disables Microsoft Update.

## Contributing
Please check out common DSC Resources [contributing guidelines](https://github.com/PowerShell/DscResource.Kit/blob/master/CONTRIBUTING.md).


## Resources

### xWindowsUpdate

* **Path**: The path from where the hotfix should be installed
* **Log**: The name of the log where installation/uninstallation details are stored. 
If no log is used, a temporary log name is created by the resource. 
* **Id**: The hotfix ID of the Windows update that uniquely identifies the hotfix.
* **Ensure**: Ensures that the hotfix is **Present** or **Absent**. 

### xMicrosoftUpdate

* **Ensure**: Determines whether the Microsoft Update service should be enabled (ensure) or disabled (absent) in Windows Update.

## Versions

### Unreleased

* Fixed PSScriptAnalyzer error in examples 

### 2.3.0.0

* MSFT_xWindowsUpdate: Fixed an issue in the Get-TargetResource function, resulting in the Get-DscConfiguration cmdlet now working appropriately when the resource is applied.
* MSFT_xWindowsUpdate: Fixed an issue in the Set-TargetResource function that was causing the function to fail when the installation of a hotfix did not provide an exit code.

### 2.2.0.0

* Minor fixes

### 2.1.0.0

* Added xMicrosoftUpdate DSC resource which can be used to enable/disable Microsoft Update in the Windows Update Settings.

### 1.0.0.0

* Initial release with the following resource:
    - xHotfix
    
## Examples

### Install a hotfix present in the path C:/temp/Windows8.1-KB2908279-v2-x86.msu and the ID 2908279

This configuration will install the hotfix from the .msu file given. 
If the hotfix with the required hotfix ID is already present on the system, the installation is skipped.

```powershell
Configuration UpdateWindowsWithPath
{       
    Node ‘NodeName’
    { 
        xHotfix HotfixInstall
        {
            Ensure = "Present"
            Path = "c:/temp/Windows8.1-KB2908279-v2-x86.msu"
            Id = "KB2908279"
        } 
    } 
}
```

### Installs a hotfix from a given URI

This configuration will install the hotfix from a URI that is connected to a particular hotfix ID.

```powershell
Configuration UpdateWindowsWithURI
{
    Node ‘NodeName’
    { 
        xHotfix HotfixInstall
        {
            Ensure = "Present"
            URI = "http://hotfixv4.microsoft.com/Microsoft%20Office%20SharePoint%20Server%202007/sp2/officekb956056fullfilex64glb/12.0000.6327.5000/free/358323_intl_x64_zip.exe"
            Id = "KB2937982"
        } 
    } 
}
```
### Enable Microsoft Update

This configuration will enable the Microsoft Update Settings (checkbox) in the Windows Update settings

```powershell
Configuration MSUpdate
{
    Import-DscResource -Module cMicrosoftUpdate 
    cMicrosoftUpdate "EnableMSUpdate"
    {
        Ensure = "Present"
    }
}
```
