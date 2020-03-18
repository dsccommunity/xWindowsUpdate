# xWindowsUpdate

[![Build Status](https://dev.azure.com/dsccommunity/xWindowsUpdate/_apis/build/status/dsccommunity.xWindowsUpdate?branchName=master)](https://dev.azure.com/dsccommunity/xWindowsUpdate/_build/latest?definitionId={definitionId}&branchName=master)
![Azure DevOps coverage (branch)](https://img.shields.io/azure-devops/coverage/dsccommunity/xWindowsUpdate/{definitionId}/master)
[![Azure DevOps tests](https://img.shields.io/azure-devops/tests/dsccommunity/xWindowsUpdate/{definitionId}/master)](https://dsccommunity.visualstudio.com/xWindowsUpdate/_test/analytics?definitionId={definitionId}&contextType=build)
[![PowerShell Gallery (with prereleases)](https://img.shields.io/powershellgallery/vpre/xWindowsUpdate?label=xWindowsUpdate%20Preview)](https://www.powershellgallery.com/packages/xWindowsUpdate/)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/xWindowsUpdate?label=xWindowsUpdate)](https://www.powershellgallery.com/packages/xWindowsUpdate/)

This module contains DSC resources for configuration of Microsoft Windows Update
and installing Windows updates.

## Code of Conduct

This project has adopted this [Code of Conduct](CODE_OF_CONDUCT.md).

## Releases

For each merge to the branch `master` a preview release will be
deployed to [PowerShell Gallery](https://www.powershellgallery.com/).
Periodically a release version tag will be pushed which will deploy a
full release to [PowerShell Gallery](https://www.powershellgallery.com/).

## Contributing

Please check out common DSC Community [contributing guidelines](https://dsccommunity.org/guidelines/contributing).

## Resources

### xHotfix

#### Parameters

- **`[String]` Path**: Specifies the path that contains the file for the
  hotfix installation.
- **`[String]` Log**: Specifies the location of the log that contains
  information from the install or uninstall. If not specified a temporary
  log name is created by the resource.
- **`[String]` Id**: Specifies the hotfix ID of the Windows update that
  uniquely identifies the hotfix.
- **`[String]` Ensure**: Specifies whether the hotfix should be installed
  or uninstalled. Default value is `'Present'`. { _Present_ | Absent }
- **`[PSCredential]` Credential**: Specifies the credential to use to
  authenticate to a UNC share if the path is on a UNC share.

#### Read-Only Properties from Get-TargetResource

None.

### xWindowsUpdateAgent

#### Parameters

- **`[String]` IsSingleInstance**: Specifies the resource is a single
  instance, the value must be 'Yes'.
- **`[Boolean]` UpdateNow**: Specifies if the resource should trigger an
  update during consistency check including initial configuration.
- **`[String[]]` Category**: Specifies one or more categories of updates
  that should be included. Defaults to `'Security'`. Please note that
  security is not mutually exclusive with Important and Optional, so
  selecting Important may install some security updates, etcetera.
  { _Security_ | Important | Optional }
- **`[String]` Notifications**: Specifies if the Windows update agent should
  notify about updates. { Disabled | ScheduledInstallation }
- **`[String]` Source**: Specifies which source service Windows update agent
  should use when searching for updates. Note that the option 'WSUS' is
  currently reserved for future use and not yet implemented.
  { MicrosoftUpdate | WindowsUpdate | WSUS }
- **`[SInt32]` RetryAttempts**: Specifies the number of retries when some
  known transient errors are raised during calls to Windows Update. Defaults
  to `3`. Known transient errors are 0x8024402c, 0x8024401c, 0x80244022,
  and 0x80244010.
- **`[SInt32]` RetryDelay**: Specifies the delay in seconds before each
  retry. Defaults to `0`.

#### Read-Only Properties from Get-TargetResource

- **`[String]` AutomaticUpdatesNotificationSetting**: Automatic Updates
  Notification Setting.
- **`[UInt32]` TotalUpdatesNotInstalled**: Count of updates not installed.
  Only returned if UpdateNow is specified.
- **`[Boolean]` RebootRequired**: Indicates if Wua Requires a reboot. Only
  returned if UpdateNow is specified.
