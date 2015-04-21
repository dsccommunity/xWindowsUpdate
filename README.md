[![Build status](https://ci.appveyor.com/api/projects/status/t4bw4lnmxy1dg3ys/branch/master?svg=true)](https://ci.appveyor.com/project/PowerShell/xwindowsupdate/branch/master)

# xWindowsUpdate

The **xWindowsUpdate** module contains the **xHotfix** DSC resource that installs a Windows Update (or hotfix) from a given path. For more information on Windows Update and Hotfix, please refer to [this TechNet article](http://technet.microsoft.com/en-us/library/cc750077.aspx).

## Contributing
Please check out common DSC Resources [contributing guidelines](https://github.com/PowerShell/DscResource.Kit/blob/master/CONTRIBUTING.md).


## Resources

### xHotfix

* **Path**: The path from where the hotfix should be installed
* **URI**: The URI location where the hotfix is present. Only one of Path or URI can be specified.
* **Log**: The name of the log where installation/uninstallation details are stored. 
If no log is used, a temporary log name is created by the resource. 
* **Id**: The hotfix ID of the Windows update that uniquely identifies the hotfix.
* **Ensure**: Ensures that the hotfix is **Present** or **Absent**. 

## Versions

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
