# Change log for {RepositoryName}

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- xWindowsUpdate
  - Added automatic release with a new CI pipeline.
- xWindowsUpdateAgent
  - Added Retry logic to known transient errors ([issue #24](https://github.com/dsccommunity/xWindowsUpdate/issues/24)).

### Removed

- xWindowsUpdate
  - BREAKING CHANGE: Removed the deprecated resource `xMicrosoftUpdate`

## [2.8.0.0] - 2019-04-03

- xWindowsUpdateAgent: Fixed verbose statement returning incorrect variable
- Tests no longer fail on `Assert-VerifiableMocks`, these are now renamed
  to `Assert-VerifiableMock` (breaking change in Pester v4).
- README.md has been updated with correct description of the resources
  ([issue #58](https://github.com/dsccommunity/xWindowsUpdate/issues/58)).
- Updated appveyor.yml to use the correct parameters to call the test framework.
- Update appveyor.yml to use the default template.
- Added default template files .gitattributes, and .gitignore, and
  .vscode folder.

## [2.7.0.0] - 2017-07-12

- xWindowsUpdateAgent: Fix Get-TargetResource returning incorrect key

## [2.6.0.0] - 2017-03-08

- Converted appveyor.yml to install Pester from PSGallery instead of from
  Chocolatey.
- Fixed PSScriptAnalyzer issues.
- Fixed common test breaks (markdown style, and example style).
- Added CodeCov.io reporting
- Deprecated xMicrosoftUpdate as it's functionality is replaced by
  xWindowsUpdateAgent

## [2.5.0.0] - 2016-05-18

- Added xWindowsUpdateAgent

## [2.4.0.0] - 2016-03-30

- Fixed PSScriptAnalyzer error in examples

## [2.3.0.0] - 2016-02-02

- MSFT_xWindowsUpdate: Fixed an issue in the Get-TargetResource function,
  resulting in the Get-DscConfiguration cmdlet now working appropriately
  when the resource is applied.
- MSFT_xWindowsUpdate: Fixed an issue in the Set-TargetResource function
  that was causing the function to fail when the installation of a hotfix
  did not provide an exit code.

## [2.2.0.0] - 2015-09-11

- Minor fixes

## [2.1.0.0] - 2015-07-24

- Added xMicrosoftUpdate DSC resource which can be used to enable/disable
  Microsoft Update in the Windows Update Settings.

### [2.0.0.0] - 2015-04-23

- Initial release with the xHotfix resource
