$script:dscModuleName = 'xWindowsUpdate'
$script:dscResourceName = 'MSFT_xWindowsUpdateAgent'

function Invoke-TestSetup
{
    try
    {
        Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

try
{
    InModuleScope $script:dscResourceName {
        #region Pester Test Initialization
        $script:mockedSearchResultWithUpdate = [PSCustomObject] @{
            Updates = @{
                Count = 1
                Title = 'Mocked Update'
            }
        }

        $script:mockedSearchResultWithoutUpdate = [PSCustomObject] @{
            Updates = @{
                Count = 0
            }
        }

        $script:mockedSearchResultWithoutUpdatesProperty = [PSCustomObject] @{
        }

        $script:mockedWuaDisableNotificationLevel = 'Disabled'
        $script:mockedWuaOtherNotificationLevel = 'Notify before download'
        $script:mockedWuaSystemInfoNoReboot = @{
            RebootRequired = $false
        }

        $script:mockedWuaSystemInfoReboot = @{
            RebootRequired = $true
        }

        $script:mockedWindowsUpdateServiceManager = [PSCustomObject]  @{
            Services = @(
                [PSCustomObject] @{
                    ServiceId          = '9482f4b4-e343-43b6-b170-9a65bc822c77'
                    IsDefaultAUService = $true
                    IsManaged          = $false
                }
            )
        }

        $script:mockedMicrosoftUpdateServiceManager = [PSCustomObject]  @{
            Services = @(
                [PSCustomObject] @{
                    ServiceId          = '7971f918-a847-4430-9279-4a52d1efe18d'
                    IsDefaultAUService = $true
                    IsManaged          = $false
                }
                [PSCustomObject] @{
                    ServiceId          = '9482f4b4-e343-43b6-b170-9a65bc822c77'
                    IsDefaultAUService = $false
                    IsManaged          = $false
                }
            )
        }

        $testCategories = @('Security', 'Important')

        #endregion


        #region Function Get-TargetResource
        Describe 'MSFT_xWindowsUpdateAgent\Get-TargetResource' {
            Mock -CommandName Get-WuaServiceManager -MockWith { return $script:mockedWindowsUpdateServiceManager }
            Mock -CommandName New-Object -ParameterFilter { $ComObject -ne $null }

            Context 'MU service' {
                Mock -CommandName  Get-WuaSearcher -MockWith {
                    return $null
                } -Verifiable

                Mock -CommandName  Get-WuaAuNotificationLevel -MockWith {
                    return $script:mockedWuaDisableNotificationLevel
                } -Verifiable

                Mock -CommandName Get-WuaSystemInfo -MockWith {
                    return $script:mockedWuaSystemInfoNoReboot
                } -Verifiable

                Mock -CommandName Get-WuaServiceManager -MockWith { return $script:mockedMicrosoftUpdateServiceManager }

                $getResult = (Get-TargetResource -IsSingleInstance 'yes' -UpdateNow $true -Category $testCategories -Notifications Disabled -Source WindowsUpdate )

                It 'Should not have called the New-Object mock' {
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0
                }

                It 'Should return Category=$testCategories' {
                    $getResult.Category | Should -Be $testCategories
                }

                It 'Should return IsSingleInstance = Yes' {
                    $getResult.IsSingleInstance | Should -Be 'Yes'
                }

                It "should return AutomaticUpdatesNotificationSetting = ${script:mockedWuaDisableNotificationLevel}" {
                    $getResult.AutomaticUpdatesNotificationSetting | Should -Be $script:mockedWuaDisableNotificationLevel
                }

                It 'Should return 0 update not installed ' {
                    $getResult.TotalUpdatesNotInstalled | Should -Be 0
                }

                It 'Should return reboot requied $false' {
                    $getResult.RebootRequired | Should -Be $false
                }

                It 'Should return Notifications=Disabled' {
                    $getResult.Notifications | Should -Be 'Disabled'
                }

                It 'Should return UpdateNome=$true' {
                    $getResult.UpdateNow | Should -Be $true
                }
                It 'Should return Source=MU' {
                    $getResult.Source | Should -Be "MicrosoftUpdate"
                }

                It 'Should have called the mock' {
                    Assert-VerifiableMock
                }
            }

            Context 'null search result and disabled notification' {
                Mock -CommandName  Get-WuaSearcher -MockWith {
                    return $null
                } -Verifiable

                Mock -CommandName  Get-WuaAuNotificationLevel -MockWith {
                    return $script:mockedWuaDisableNotificationLevel
                } -Verifiable

                Mock -CommandName Get-WuaSystemInfo -MockWith {
                    return $script:mockedWuaSystemInfoNoReboot
                } -Verifiable

                $getResult = (Get-TargetResource -IsSingleInstance 'yes' -UpdateNow $true -Category $testCategories -Notifications Disabled  -Source WindowsUpdate )

                It 'Should not have called the New-Object mock' {
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0
                }

                It 'Should return Category=$testCategories' {
                    $getResult.Category | Should -Be $testCategories
                }

                It 'Should return IsSingleInstance = Yes' {
                    $getResult.IsSingleInstance | Should -Be 'Yes'
                }

                It "should return AutomaticUpdatesNotificationSetting = ${script:mockedWuaDisableNotificationLevel}" {
                    $getResult.AutomaticUpdatesNotificationSetting | Should -Be $script:mockedWuaDisableNotificationLevel
                }

                It 'Should return 0 update not installed ' {
                    $getResult.TotalUpdatesNotInstalled | Should -Be 0
                }

                It 'Should return reboot requied $false' {
                    $getResult.RebootRequired | Should -Be $false
                }

                It 'Should return Notifications=Disabled' {
                    $getResult.Notifications | Should -Be 'Disabled'
                }

                It 'Should return UpdateNome=$true' {
                    $getResult.UpdateNow | Should -Be $true
                }

                It 'Should return Source=WU' {
                    $getResult.Source | Should -Be "WindowsUpdate"
                }

                It 'Should have called the mock' {
                    Assert-VerifiableMock
                }
            }

            Context 'no updates property and disabled notification' {
                Mock -CommandName  Get-WuaSearcher -MockWith {
                    return $script:mockedSearchResultWithoutUpdatesProperty
                } -Verifiable

                Mock -CommandName  Get-WuaAuNotificationLevel -MockWith {
                    return $script:mockedWuaDisableNotificationLevel
                } -Verifiable

                Mock -CommandName Get-WuaSystemInfo -MockWith {
                    return $script:mockedWuaSystemInfoNoReboot
                } -Verifiable

                $getResult = (Get-TargetResource -IsSingleInstance 'yes' -UpdateNow $true -Category $testCategories -Notifications Disabled -Source WindowsUpdate )

                It 'Should not have called the New-Object mock' {
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0
                }

                It 'Should return Category=$testCategories' {
                    $getResult.Category | Should -Be $testCategories
                }

                It 'Should return IsSingleInstance = Yes' {
                    $getResult.IsSingleInstance | Should -Be 'Yes'
                }

                It "should return AutomaticUpdatesNotificationSetting = ${script:mockedWuaDisableNotificationLevel}" {
                    $getResult.AutomaticUpdatesNotificationSetting | Should -Be $script:mockedWuaDisableNotificationLevel
                }

                It 'Should return 0 update not installed ' {
                    $getResult.TotalUpdatesNotInstalled | Should -Be 0
                }

                It 'Should return reboot requied $false' {
                    $getResult.RebootRequired | Should -Be $false
                }

                It 'Should return UpdateNow=$true' {
                    $getResult.UpdateNow | Should -Be $true
                }

                It 'Should return Notifications=Disabled' {
                    $getResult.Notifications | Should -Be 'Disabled'
                }

                It 'Should have called the mock' {
                    Assert-VerifiableMock
                }
            }

            Context 'no updates and disabled notification' {
                Mock -CommandName  Get-WuaSearcher -MockWith {
                    return $script:mockedSearchResultWithoutUpdate
                } -Verifiable

                Mock -CommandName  Get-WuaAuNotificationLevel -MockWith {
                    return $script:mockedWuaDisableNotificationLevel
                } -Verifiable

                Mock -CommandName Get-WuaSystemInfo -MockWith {
                    return $script:mockedWuaSystemInfoNoReboot
                } -Verifiable

                $getResult = (Get-TargetResource -IsSingleInstance 'yes' -UpdateNow $true -Category $testCategories -Notifications Disabled -Source WindowsUpdate )

                It 'Should not have called the New-Object mock' {
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0
                }

                It 'Should return Category=$testCategories' {
                    $getResult.Category | Should -Be $testCategories
                }

                It 'Should return IsSingleInstance = Yes' {
                    $getResult.IsSingleInstance | Should -Be 'Yes'
                }

                It "should return AutomaticUpdatesNotificationSetting = ${script:mockedWuaDisableNotificationLevel}" {
                    $getResult.AutomaticUpdatesNotificationSetting | Should -Be $script:mockedWuaDisableNotificationLevel
                }

                It 'Should return 0 update not installed ' {
                    $getResult.TotalUpdatesNotInstalled | Should -Be 0
                }

                It 'Should return reboot requied $false' {
                    $getResult.RebootRequired | Should -Be $false
                }

                It 'Should return UpdateNow=$true' {
                    $getResult.UpdateNow | Should -Be $true
                }

                It 'Should return Notifications=Disabled' {
                    $getResult.Notifications | Should -Be 'Disabled'
                }

                It 'Should have called the mock' {
                    Assert-VerifiableMock
                }
            }

            Context 'no updates , disabled notification, and reboot required' {
                Mock -CommandName  Get-WuaSearcher -MockWith {
                    return $script:mockedSearchResultWithoutUpdate
                } -Verifiable

                Mock -CommandName  Get-WuaAuNotificationLevel -MockWith {
                    return $script:mockedWuaDisableNotificationLevel
                } -Verifiable

                Mock -CommandName Get-WuaSystemInfo -MockWith {
                    return $script:mockedWuaSystemInfoReboot
                } -Verifiable

                $getResult = (Get-TargetResource -IsSingleInstance 'yes' -UpdateNow $true -Category $testCategories -Notifications Disabled -Source WindowsUpdate )

                It 'Should not have called the New-Object mock' {
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0
                }

                It 'Should return Category=$testCategories' {
                    $getResult.Category | Should -Be $testCategories
                }

                It 'Should return Notifications=Disabled' {
                    $getResult.Notifications | Should -Be 'Disabled'
                }

                It 'Should return UpdateNow=$false' {
                    $getResult.UpdateNow | Should -Be $false
                }

                It 'Should return IsSingleInstance = Yes' {
                    $getResult.IsSingleInstance | Should -Be 'Yes'
                }

                It "should return AutomaticUpdatesNotificationSetting = ${script:mockedWuaDisableNotificationLevel}" {
                    $getResult.AutomaticUpdatesNotificationSetting | Should -Be $script:mockedWuaDisableNotificationLevel
                }

                It 'Should return 0 update not installed ' {
                    $getResult.TotalUpdatesNotInstalled | Should -Be 0
                }

                It 'Should return reboot requied $true' {
                    $getResult.RebootRequired | Should -Be $true
                }

                It 'Should have called the mock' {
                    Assert-VerifiableMock
                }
            }

            Context 'updates and disable notification' {
                Mock -CommandName  Get-WuaSearcher -MockWith {
                    return $script:mockedSearchResultWithUpdate
                } -Verifiable

                Mock -CommandName  Get-WuaAuNotificationLevel -MockWith {
                    return $script:mockedWuaDisableNotificationLevel
                } -Verifiable

                Mock -CommandName Get-WuaSystemInfo -MockWith {
                    return $script:mockedWuaSystemInfoNoReboot
                } -Verifiable

                $getResult = (Get-TargetResource -IsSingleInstance 'yes' -UpdateNow $true -Category $testCategories  -Source WindowsUpdate)

                It 'Should not have called the New-Object mock' {
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0
                }

                It 'Should return Category=$testCategories' {
                    $getResult.Category | Should -Be $testCategories
                }

                It 'Should return Notifications=Disabled' {
                    $getResult.Notifications | Should -Be 'Disabled'
                }

                It 'Should return UpdateNow=$false' {
                    $getResult.UpdateNow | Should -Be $false
                }

                It 'Should return IsSingleInstance = Yes' {
                    $getResult.IsSingleInstance | Should -Be 'Yes'
                }

                It "should return AutomaticUpdatesNotificationSetting = $script:mockedWuaDisableNotificationLevel" {
                    $getResult.AutomaticUpdatesNotificationSetting | Should -Be $script:mockedWuaDisableNotificationLevel
                }

                It 'Should return 1 update not installed ' {
                    $getResult.TotalUpdatesNotInstalled | Should -Be 1
                }

                It 'Should return reboot requied $false' {
                    $getResult.RebootRequired | Should -Be $false
                }

                It 'Should have called the mock' {
                    Assert-VerifiableMock
                }
            }

            Context 'updates and other notification' {
                Mock -CommandName  Get-WuaSearcher -MockWith {
                    return $script:mockedSearchResultWithUpdate
                } -Verifiable

                Mock -CommandName  Get-WuaAuNotificationLevel -MockWith {
                    return $script:mockedWuaOtherNotificationLevel
                } -Verifiable

                Mock -CommandName Get-WuaSystemInfo -MockWith {
                    return $script:mockedWuaSystemInfoNoReboot
                } -Verifiable

                $getResult = (Get-TargetResource -IsSingleInstance 'yes' -UpdateNow $true -Category $testCategories  -Source WindowsUpdate)

                It 'Should not have called the New-Object mock' {
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0
                }

                It 'Should return Category=$testCategories' {
                    $getResult.Category | Should -Be $testCategories
                }

                It 'Should return Notifications=Notify before Download' {
                    $getResult.Notifications | Should -Be 'Notify before Download'
                }

                It 'Should return UpdateNow=$false' {
                    $getResult.UpdateNow | Should -Be $false
                }

                It 'Should return IsSingleInstance = Yes' {
                    $getResult.IsSingleInstance | Should -Be 'Yes'
                }

                It "should return AutomaticUpdatesNotificationSetting = $script:mockedWuaOtherNotificationLevel" {
                    $getResult.AutomaticUpdatesNotificationSetting | Should -Be $script:mockedWuaOtherNotificationLevel
                }

                It 'Should return 1 update not installed ' {
                    $getResult.TotalUpdatesNotInstalled | Should -Be 1
                }

                It 'Should return reboot requied $false' {
                    $getResult.RebootRequired | Should -Be $false
                }

                It 'Should have called the mock' {
                    Assert-VerifiableMock
                }
            }
        }
        #endregion

        #region Function Test-TargetResource
        Describe 'MSFT_xWindowsUpdateAgent\Test-TargetResource' {
            Mock -CommandName Get-WuaServiceManager -MockWith { return $script:mockedWindowsUpdateServiceManager }
            Mock -CommandName New-object -ParameterFilter { $ComObject -ne $null }

            Context 'Ensure UpToDate with no updates and disabled notification and wu service' {
                Mock -CommandName  Get-WuaSearcher -MockWith {
                    return $script:mockedSearchResultWithoutUpdate
                } -Verifiable

                Mock -CommandName  Get-WuaAuNotificationLevel -MockWith {
                    return $script:mockedWuaDisableNotificationLevel
                } -Verifiable

                Mock -CommandName Get-WuaSystemInfo -MockWith {
                    return $script:mockedWuaSystemInfoNoReboot
                } -Verifiable

                It 'Should return $true' {
                    (Test-TargetResource -IsSingleInstance 'yes' -UpdateNow $true -Category $testCategories -Source MicrosoftUpdate  -verbose) | Should -Be $false
                }

                It 'Should not have called the New-Object mock' {
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0
                }

                It 'Should have called the mock' {
                    Assert-VerifiableMock
                }
            }

            Context 'Ensure UpToDate with no updates and disabled notification and mu service' {
                Mock -CommandName  Get-WuaSearcher -MockWith {
                    return $script:mockedSearchResultWithoutUpdate
                } -Verifiable

                Mock -CommandName  Get-WuaAuNotificationLevel -MockWith {
                    return $script:mockedWuaDisableNotificationLevel
                } -Verifiable

                Mock -CommandName Get-WuaSystemInfo -MockWith {
                    return $script:mockedWuaSystemInfoNoReboot
                } -Verifiable

                Mock -CommandName Get-WuaServiceManager -MockWith { return $script:mockedMicrosoftUpdateServiceManager }

                It 'Should return $true' {
                    (Test-TargetResource -IsSingleInstance 'yes' -UpdateNow $true -Category $testCategories -Source MicrosoftUpdate  -verbose) | Should -Be $true
                }

                It 'Should not have called the New-Object mock' {
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0
                }

                It 'Should have called the mock' {
                    Assert-VerifiableMock
                }
            }

            Context 'Ensure UpToDate with no updates and disabled notification' {
                Mock -CommandName  Get-WuaSearcher -MockWith {
                    return $script:mockedSearchResultWithoutUpdate
                } -Verifiable

                Mock -CommandName  Get-WuaAuNotificationLevel -MockWith {
                    return $script:mockedWuaDisableNotificationLevel
                } -Verifiable

                Mock -CommandName Get-WuaSystemInfo -MockWith {
                    return $script:mockedWuaSystemInfoNoReboot
                } -Verifiable

                It 'Should return $true' {
                    (Test-TargetResource -IsSingleInstance 'yes' -UpdateNow $true -Category $testCategories  -verbose  -Source WindowsUpdate) | Should -Be $true
                }

                It 'Should not have called the New-Object mock' {
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0
                }

                It 'Should have called the mock' {
                    Assert-VerifiableMock
                }
            }

            Context 'Ensure UpToDate with no updates, disabled notification and reboot required' {
                Mock -CommandName  Get-WuaSearcher -MockWith {
                    return $script:mockedSearchResultWithoutUpdate
                } -Verifiable

                Mock -CommandName  Get-WuaAuNotificationLevel -MockWith {
                    return $script:mockedWuaDisableNotificationLevel
                } -Verifiable

                Mock -CommandName Get-WuaSystemInfo -MockWith {
                    return $script:mockedWuaSystemInfoReboot
                } -Verifiable

                It 'Should return $false' {
                    (Test-TargetResource  -IsSingleInstance 'yes' -UpdateNow $true -Category $testCategories -verbose  -Source WindowsUpdate) | Should -Be $false
                }

                It 'Should not have called the New-Object mock' {
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0
                }

                It 'Should have called the mock' {
                    Assert-VerifiableMock
                }
            }

            Context 'Ensure UpToDate with updates and disabled notification' {
                Mock -CommandName  Get-WuaSearcher -MockWith {
                    return $script:mockedSearchResultWithUpdate
                } -Verifiable

                Mock -CommandName  Get-WuaAuNotificationLevel -MockWith {
                    return $script:mockedWuaDisableNotificationLevel
                } -Verifiable

                Mock -CommandName Get-WuaSystemInfo -MockWith {
                    return $script:mockedWuaSystemInfoNoReboot
                } -Verifiable

                It 'Should return $false' {
                    (Test-TargetResource -IsSingleInstance 'yes' -UpdateNow $true -Category $testCategories -verbose  -Source WindowsUpdate) | Should -Be $false
                }

                It 'Should not have called the New-Object mock' {
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0
                }

                It 'Should have called the mock' {
                    Assert-VerifiableMock
                }
            }

            Context 'Ensure Disable with updates and disable notification' {
                Mock -CommandName  Get-WuaSearcher -MockWith {
                    return $script:mockedSearchResultWithUpdate
                }

                Mock -CommandName  Get-WuaAuNotificationLevel -MockWith {
                    return $script:mockedWuaDisableNotificationLevel
                } -Verifiable

                Mock -CommandName Get-WuaSystemInfo -MockWith {
                    return $script:mockedWuaSystemInfoNoReboot
                }

                It 'Should return $true' {
                    (Test-TargetResource  -IsSingleInstance 'yes' -UpdateNow $false -Notifications Disabled -verbose  -Source WindowsUpdate) | Should -Be $true
                }

                It 'Should not have called the New-Object mock' {
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0
                }

                It 'Should not have called the Get-WuaSystemInfo mock' {
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName Get-WuaSystemInfo -Times 0
                }

                It 'Should not have called the get-wuasearcher mock' {
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName Get-WuaSearcher -Times 0
                }

                It 'Should have called the mock' {
                    Assert-VerifiableMock
                }
            }

            Context 'Ensure Disable with updates and other notification' {
                Mock -CommandName  Get-WuaSearcher -MockWith {
                    return $script:mockedSearchResultWithUpdate
                }

                Mock -CommandName  Get-WuaAuNotificationLevel -MockWith {
                    return $script:mockedWuaOtherNotificationLevel
                } -Verifiable

                Mock -CommandName Get-WuaSystemInfo -MockWith {
                    return $script:mockedWuaSystemInfoNoReboot
                }

                It 'Should return $false' {
                    (Test-TargetResource -IsSingleInstance 'yes' -UpdateNow $false -Notifications Disabled -verbose  -Source WindowsUpdate) | Should -Be $false
                }

                It 'Should not have called the New-Object mock' {
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0
                }

                It 'Should not have called the Get-WuaSystemInfo mock' {
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName Get-WuaSystemInfo -Times 0
                }

                It 'Should not have called the get-wuasearcher mock' {
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName Get-WuaSearcher -Times 0
                }

                It 'Should have called the mock' {
                    Assert-VerifiableMock
                }
            }

            Context 'Ensure UpToDate with updates and other notification' {
                Mock -CommandName  Get-WuaSearcher -MockWith {
                    return $script:mockedSearchResultWithUpdate
                } -Verifiable

                Mock -CommandName  Get-WuaAuNotificationLevel -MockWith {
                    return $script:mockedWuaOtherNotificationLevel
                } -Verifiable

                Mock -CommandName Get-WuaSystemInfo -MockWith {
                    return $script:mockedWuaSystemInfoNoReboot
                } -Verifiable

                It 'Should return $true' {
                    (Test-TargetResource -IsSingleInstance 'yes' -UpdateNow $true -verbose -Category $testCategories -Source WindowsUpdate) | Should -Be $false
                }

                It 'Should not have called the New-Object mock' {
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0
                }

                It 'Should have called the mock' {
                    Assert-VerifiableMock
                }
            }

            Context 'Ensure UpdateNow = $false with updates and other notification' {
                Mock -CommandName  Get-WuaSearcher -MockWith {
                    return $script:mockedSearchResultWithUpdate
                }

                Mock -CommandName  Get-WuaAuNotificationLevel -MockWith {
                    return $script:mockedWuaOtherNotificationLevel
                } -Verifiable

                Mock -CommandName Get-WuaSystemInfo -MockWith {
                    return $script:mockedWuaSystemInfoNoReboot
                }

                It 'Should return $true' {
                    (Test-TargetResource -IsSingleInstance 'yes' -UpdateNow $false -verbose -Category $testCategories -Source WindowsUpdate) | Should -Be $true
                }

                It 'Should not have called the New-Object mock' {
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0
                }

                It 'Should not have called the Get-WuaSystemInfo mock' {
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName Get-WuaSystemInfo -Times 0
                }

                It 'Should not have called the get-wuasearcher mock' {
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName Get-WuaSearcher -Times 0
                }

                It 'Should have called the mock' {
                    Assert-VerifiableMock
                }
            }
        }
        #endregion

        #region Function Set-TargetResource
        Describe 'MSFT_xWindowsUpdateAgent\Set-TargetResource' {
            Mock -CommandName Get-WuaServiceManager -MockWith { return $script:mockedWindowsUpdateServiceManager }
            Mock -CommandName New-object -ParameterFilter { $ComObject -ne $null }

            Context 'Ensure UpToDate with null search results, disabled notification, and reboot required' {
                BeforeAll {
                    $global:DSCMachineStatus = $null
                }

                AfterAll {
                    $global:DSCMachineStatus = $null
                }

                Mock -CommandName  Get-WuaSearcher -MockWith {
                    return $null
                } -Verifiable

                Mock -CommandName  Get-WuaAuNotificationLevel -MockWith {
                    return $script:mockedWuaDisableNotificationLevel
                } -Verifiable

                Mock -CommandName Get-WuaRebootRequired -MockWith {
                    return $true
                } -Verifiable

                Mock -CommandName Invoke-WuaDownloadUpdates
                Mock -CommandName Invoke-WuaInstallUpdates
                Mock -CommandName Set-WuaAuNotificationLevel

                It 'Should not Throw' {
                    try
                    {
                        Set-TargetResource -IsSingleInstance 'yes' -UpdateNow $true -verbose -Category $testCategories  -Source WindowsUpdate | Should -Be $null
                    }
                    catch
                    {
                        $_ | Should -Be $null
                    }
                }

                It 'Should not have called the New-Object mock' {
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0 -ParameterFilter { $ComObject -ne $null }
                }

                It 'Should not have changed wua' {
                    Assert-MockCalled -CommandName Invoke-WuaDownloadUpdates -Times 0
                    Assert-MockCalled -CommandName Invoke-WuaInstallUpdates -Times 0
                    Assert-MockCalled -CommandName Set-WuaAuNotificationLevel -Times 0
                }

                It 'Should have triggered a reboot' {
                    $global:DSCMachineStatus | Should -Be 1
                }

                It 'Should have called the mock' {
                    Assert-VerifiableMock
                }
            }

            Context 'Ensure UpToDate with no updates, mu and disabled notification' {
                BeforeAll {
                    $global:DSCMachineStatus = $null
                }

                AfterAll {
                    $global:DSCMachineStatus = $null
                }

                Mock -CommandName  Get-WuaSearcher -MockWith {
                    return $script:mockedSearchResultWithoutUpdate
                } -Verifiable

                Mock -CommandName  Get-WuaAuNotificationLevel -MockWith {
                    return $script:mockedWuaDisableNotificationLevel
                } -Verifiable

                Mock -CommandName Get-WuaSystemInfo -MockWith {
                    return $script:mockedWuaSystemInfoNoReboot
                } -Verifiable

                Mock -CommandName Add-WuaService -Verifiable
                Mock -CommandName Remove-WuaService
                Mock -CommandName Invoke-WuaDownloadUpdates
                Mock -CommandName Invoke-WuaInstallUpdates
                Mock -CommandName Set-WuaAuNotificationLevel

                It 'Should not Throw' {
                    { Set-TargetResource -IsSingleInstance 'yes'  -UpdateNow $true -verbose -Category $testCategories -Source MicrosoftUpdate } | Should -Not -Throw
                }

                It 'Should not have called the New-Object mock' {
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0
                }

                It 'Should not have changed wua' {
                    Assert-MockCalled -CommandName Invoke-WuaDownloadUpdates -Times 0
                    Assert-MockCalled -CommandName Invoke-WuaInstallUpdates -Times 0
                    Assert-MockCalled -CommandName Set-WuaAuNotificationLevel -Times 0
                }

                It 'Should not have triggered a reboot' {
                    $global:DSCMachineStatus | Should -Be $null
                }

                It 'Should have called the mock' {
                    Assert-VerifiableMock
                }
            }

            Context 'Ensure UpToDate with no updates, mu and disabled notification' {
                BeforeAll {
                    $global:DSCMachineStatus = $null
                }

                AfterAll {
                    $global:DSCMachineStatus = $null
                }

                Mock -CommandName  Get-WuaSearcher -MockWith {
                    return $script:mockedSearchResultWithoutUpdate
                } -Verifiable

                Mock -CommandName  Get-WuaAuNotificationLevel -MockWith {
                    return $script:mockedWuaDisableNotificationLevel
                } -Verifiable

                Mock -CommandName Get-WuaSystemInfo -MockWith {
                    return $script:mockedWuaSystemInfoNoReboot
                } -Verifiable

                Mock -CommandName Add-WuaService
                Mock -CommandName Remove-WuaService
                Mock -CommandName Invoke-WuaDownloadUpdates
                Mock -CommandName Invoke-WuaInstallUpdates
                Mock -CommandName Set-WuaAuNotificationLevel

                It 'Should not Throw' {
                    { Set-TargetResource -IsSingleInstance 'yes'  -UpdateNow $true -verbose -Category $testCategories -Source WindowsUpdate } | Should -Not -Throw
                }

                It 'Should not have called the New-Object mock' {
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0
                }

                It 'Should not have changed wua' {
                    Assert-MockCalled -CommandName Invoke-WuaDownloadUpdates -Times 0
                    Assert-MockCalled -CommandName Invoke-WuaInstallUpdates -Times 0
                    Assert-MockCalled -CommandName Set-WuaAuNotificationLevel -Times 0
                    Assert-MockCalled -CommandName Add-WuaService  -Times 0
                    Assert-MockCalled -CommandName Remove-WuaService  -Times 0
                }

                It 'Should not have triggered a reboot' {
                    $global:DSCMachineStatus | Should -Be $null
                }

                It 'Should have called the mock' {
                    Assert-VerifiableMock
                }
            }

            Context 'Ensure UpToDate with no updates, mu and disabled notification' {
                BeforeAll {
                    $global:DSCMachineStatus = $null
                }

                AfterAll {
                    $global:DSCMachineStatus = $null
                }

                Mock -CommandName  Get-WuaSearcher -MockWith {
                    return $script:mockedSearchResultWithoutUpdate
                } -Verifiable

                Mock -CommandName  Get-WuaAuNotificationLevel -MockWith {
                    return $script:mockedWuaDisableNotificationLevel
                } -Verifiable

                Mock -CommandName Get-WuaSystemInfo -MockWith {
                    return $script:mockedWuaSystemInfoNoReboot
                } -Verifiable

                Mock -CommandName Get-WuaServiceManager -MockWith {
                    return $script:mockedMicrosoftUpdateServiceManager
                } -Verifiable

                Mock -CommandName Add-WuaService
                Mock -CommandName Remove-WuaService -Verifiable
                Mock -CommandName Invoke-WuaDownloadUpdates
                Mock -CommandName Invoke-WuaInstallUpdates
                Mock -CommandName Set-WuaAuNotificationLevel

                It 'Should not Throw' {
                    { Set-TargetResource -IsSingleInstance 'yes'  -UpdateNow $true -verbose -Category $testCategories -Source WindowsUpdate } | Should -Not -Throw
                }

                It 'Should not have called the New-Object mock' {
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0
                }

                It 'Should not have changed wua' {
                    Assert-MockCalled -CommandName Invoke-WuaDownloadUpdates -Times 0
                    Assert-MockCalled -CommandName Invoke-WuaInstallUpdates -Times 0
                    Assert-MockCalled -CommandName Set-WuaAuNotificationLevel -Times 0
                    Assert-MockCalled -CommandName Add-WuaService  -Times 0
                }

                It 'Should not have triggered a reboot' {
                    $global:DSCMachineStatus | Should -Be $null
                }

                It 'Should have called the mock' {
                    Assert-VerifiableMock
                }
            }

            Context 'Ensure UpToDate with no updates and disabled notification' {
                BeforeAll {
                    $global:DSCMachineStatus = $null
                }

                AfterAll {
                    $global:DSCMachineStatus = $null
                }

                Mock -CommandName  Get-WuaSearcher -MockWith {
                    return $script:mockedSearchResultWithoutUpdate
                } -Verifiable

                Mock -CommandName  Get-WuaAuNotificationLevel -MockWith {
                    return $script:mockedWuaDisableNotificationLevel
                } -Verifiable

                Mock -CommandName Get-WuaSystemInfo -MockWith {
                    return $script:mockedWuaSystemInfoNoReboot
                } -Verifiable

                Mock -CommandName Invoke-WuaDownloadUpdates
                Mock -CommandName Invoke-WuaInstallUpdates
                Mock -CommandName Set-WuaAuNotificationLevel

                It 'Should not Throw' {
                    { Set-TargetResource -IsSingleInstance 'yes'  -UpdateNow $true -verbose -Category $testCategories  -Source WindowsUpdate } | Should -Not -Throw
                }

                It 'Should not have called the New-Object mock' {
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0
                }

                It 'Should not have changed wua' {
                    Assert-MockCalled -CommandName Invoke-WuaDownloadUpdates -Times 0
                    Assert-MockCalled -CommandName Invoke-WuaInstallUpdates -Times 0
                    Assert-MockCalled -CommandName Set-WuaAuNotificationLevel -Times 0
                }

                It 'Should not have triggered a reboot' {
                    $global:DSCMachineStatus | Should -Be $null
                }

                It 'Should have called the mock' {
                    Assert-VerifiableMock
                }
            }

            Context 'Ensure UpToDate with no updates, disabled notification and reboot required' {
                BeforeAll {
                    $global:DSCMachineStatus = $null
                }

                AfterAll {
                    $global:DSCMachineStatus = $null
                }

                Mock -CommandName  Get-WuaSearcher -MockWith {
                    return $script:mockedSearchResultWithoutUpdate
                } -Verifiable

                Mock -CommandName  Get-WuaAuNotificationLevel -MockWith {
                    return $script:mockedWuaDisableNotificationLevel
                } -Verifiable

                Mock -CommandName Get-WuaSystemInfo -MockWith {
                    return $script:mockedWuaSystemInfoReboot
                } -Verifiable

                Mock -CommandName Invoke-WuaDownloadUpdates
                Mock -CommandName Invoke-WuaInstallUpdates
                Mock -CommandName Set-WuaAuNotificationLevel

                It 'Should return $false' {
                    { Set-TargetResource -IsSingleInstance 'yes'  -UpdateNow $true -verbose -Category $testCategories  -Source WindowsUpdate } | Should -Not -Throw
                }

                It 'Should not have called the New-Object mock' {
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0
                }

                It 'Should not have changed wua' {
                    Assert-MockCalled -CommandName Invoke-WuaDownloadUpdates -Times 0
                    Assert-MockCalled -CommandName Invoke-WuaInstallUpdates -Times 0
                    Assert-MockCalled -CommandName Set-WuaAuNotificationLevel -Times 0
                }

                It 'Should have triggered a reboot' {
                    $global:DSCMachineStatus | Should -Be 1
                }

                It 'Should have called the mock' {
                    Assert-VerifiableMock
                }
            }

            Context 'Ensure UpToDate with updates and disabled notification' {
                BeforeAll {
                    $global:DSCMachineStatus = $null
                }

                AfterAll {
                    $global:DSCMachineStatus = $null
                }

                Mock -CommandName  Get-WuaSearcher -MockWith {
                    return $script:mockedSearchResultWithUpdate
                } -Verifiable

                Mock -CommandName  Get-WuaAuNotificationLevel -MockWith {
                    return $script:mockedWuaDisableNotificationLevel
                } -Verifiable

                Mock -CommandName Get-WuaSystemInfo -MockWith {
                    return $script:mockedWuaSystemInfoNoReboot
                } -Verifiable

                Mock -CommandName Invoke-WuaDownloadUpdates -Verifiable
                Mock -CommandName Invoke-WuaInstallUpdates -Verifiable
                Mock -CommandName Set-WuaAuNotificationLevel

                It 'Should return $false' {
                    { Set-TargetResource -IsSingleInstance 'yes'  -UpdateNow $true -verbose -Category $testCategories -Source WindowsUpdate } | Should -Not -Throw
                }

                It 'Should not have called the New-Object mock' {
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0
                }

                It 'Should not have changed wua notification' {
                    Assert-MockCalled -CommandName Set-WuaAuNotificationLevel -Times 0
                }

                It 'Should not have triggered a reboot' {
                    $global:DSCMachineStatus | Should -Be $null
                }

                It 'Should have called the mock' {
                    Assert-VerifiableMock
                }
            }

            Context 'Ensure UpToDate with updates and disabled notification with reboot after install' {
                BeforeAll {
                    $global:DSCMachineStatus = $null
                }

                AfterAll {
                    $global:DSCMachineStatus = $null
                }

                Mock -CommandName  Get-WuaSearcher -MockWith {
                    return $script:mockedSearchResultWithUpdate
                } -Verifiable

                Mock -CommandName  Get-WuaAuNotificationLevel -MockWith {
                    return $script:mockedWuaDisableNotificationLevel
                } -Verifiable

                Mock -CommandName Get-WuaSystemInfo -MockWith {
                    Set-StrictMode -Off
                    if (!$callCount)
                    {
                        $callCount = 1
                    }
                    else
                    {
                        $callCount++
                    }

                    if ($callCount -eq 1)
                    {
                        Write-Verbose -Message 'return no reboot' -Verbose
                        return $script:mockedWuaSystemInfoNoReboot
                    }
                    else
                    {
                        Write-Verbose -Message 'return reboot' -Verbose
                        return $script:mockedWuaSystemInfoReboot
                    }
                } -Verifiable

                Mock -CommandName Invoke-WuaDownloadUpdates -Verifiable
                Mock -CommandName Invoke-WuaInstallUpdates -Verifiable
                Mock -CommandName Set-WuaAuNotificationLevel

                It 'Should return $false' {
                    { Set-TargetResource -IsSingleInstance 'yes'  -UpdateNow $true -verbose -Category $testCategories -Source WindowsUpdate } | Should -Not -Throw
                }

                It 'Should not have called the New-Object mock' {
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0
                }

                It 'Should not have changed wua notification' {
                    Assert-MockCalled -CommandName Set-WuaAuNotificationLevel -Times 0
                }

                It 'Should not have triggered a reboot' {
                    $global:DSCMachineStatus | Should -Be $null
                }

                It 'Should have called the mock' {
                    Assert-VerifiableMock
                }
            }

            Context 'Ensure Disable with updates and disable notification' {
                BeforeAll {
                    $global:DSCMachineStatus = $null
                }

                AfterAll {
                    $global:DSCMachineStatus = $null
                }

                Mock -CommandName  Get-WuaSearcher -MockWith {
                    return $script:mockedSearchResultWithUpdate
                }

                Mock -CommandName  Get-WuaAuNotificationLevel -MockWith {
                    return $script:mockedWuaDisableNotificationLevel
                } -Verifiable

                Mock -CommandName Get-WuaSystemInfo -MockWith {
                    return $script:mockedWuaSystemInfoNoReboot
                }

                Mock -CommandName Invoke-WuaDownloadUpdates
                Mock -CommandName Invoke-WuaInstallUpdates
                Mock -CommandName Set-WuaAuNotificationLevel

                It 'Should not throw' {
                    { Set-TargetResource -IsSingleInstance 'yes' -notifications 'Disabled' -UpdateNow $false -Source WindowsUpdate } | Should -Not -Throw
                }

                It 'Should not have called the New-Object mock' {
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0
                }

                It 'Should not have called the Get-WuaSystemInfo mock' {
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName Get-WuaSystemInfo -Times 0
                }

                It 'Should not have called the get-wuasearcher mock' {
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName Get-WuaSearcher -Times 0
                }

                It 'Should not have changed wua' {
                    Assert-MockCalled -CommandName Invoke-WuaDownloadUpdates -Times 0
                    Assert-MockCalled -CommandName Invoke-WuaInstallUpdates -Times 0
                    Assert-MockCalled -CommandName Set-WuaAuNotificationLevel -Times 0
                }

                It 'Should not have triggered a reboot' {
                    $global:DSCMachineStatus | Should -Be $null
                }

                It 'Should have called the mock' {
                    Assert-VerifiableMock
                }
            }

            Context 'Ensure Disable with updates and other notification' {
                BeforeAll {
                    $global:DSCMachineStatus = $null
                }

                AfterAll {
                    $global:DSCMachineStatus = $null
                }

                Mock -CommandName  Get-WuaSearcher -MockWith {
                    return $script:mockedSearchResultWithUpdate
                }

                Mock -CommandName  Get-WuaAuNotificationLevel -MockWith {
                    return $script:mockedWuaOtherNotificationLevel
                } -Verifiable

                Mock -CommandName Get-WuaSystemInfo -MockWith {
                    return $script:mockedWuaSystemInfoNoReboot
                }

                Mock -CommandName Invoke-WuaDownloadUpdates
                Mock -CommandName Invoke-WuaInstallUpdates
                Mock -CommandName Set-WuaAuNotificationLevel

                It 'Should not throw' {
                    { Set-TargetResource -IsSingleInstance 'yes' -notifications 'Disabled'  -UpdateNow $false -Source WindowsUpdate } | Should -Not -Throw
                }

                It 'Should not have called the New-Object mock' {
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0
                }

                It 'Should not have called the Get-WuaSystemInfo mock' {
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName Get-WuaSystemInfo -Times 0
                }

                It 'Should not have called the get-wuasearcher mock' {
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName Get-WuaSearcher -Times 0
                }

                It 'Should have set the notification level' {
                    Assert-MockCalled -CommandName Set-WuaAuNotificationLevel -Times 1 -ParameterFilter { $NotificationLevel -eq 'Disabled' }
                }

                It 'Should not have changed wua' {
                    Assert-MockCalled -CommandName Invoke-WuaDownloadUpdates -Times 0
                    Assert-MockCalled -CommandName Invoke-WuaInstallUpdates -Times 0
                }

                It 'Should not have triggered a reboot' {
                    $global:DSCMachineStatus | Should -Be $null
                }

                It 'Should have called the mock' {
                    Assert-VerifiableMock
                }
            }

            Context 'Ensure UpToDate with updates and other notification' {
                BeforeAll {
                    $global:DSCMachineStatus = $null
                }

                AfterAll {
                    $global:DSCMachineStatus = $null
                }

                Mock -CommandName  Get-WuaSearcher -MockWith {
                    return $script:mockedSearchResultWithUpdate
                } -Verifiable

                Mock -CommandName  Get-WuaAuNotificationLevel -MockWith {
                    return $script:mockedWuaOtherNotificationLevel
                } -Verifiable

                Mock -CommandName Get-WuaSystemInfo -MockWith {
                    return $script:mockedWuaSystemInfoNoReboot
                } -Verifiable

                Mock -CommandName Invoke-WuaDownloadUpdates -Verifiable
                Mock -CommandName Invoke-WuaInstallUpdates -Verifiable
                Mock -CommandName Set-WuaAuNotificationLevel

                It 'Should not throw' {
                    { Set-TargetResource -IsSingleInstance 'yes'  -UpdateNow $true -verbose -Category $testCategories -Source WindowsUpdate } | Should -Not -Throw
                }

                It 'Should not have called the New-Object mock' {
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0
                }

                It 'Should not have changed wua notification' {
                    Assert-MockCalled -CommandName Set-WuaAuNotificationLevel -Times 0
                }

                It 'Should not have triggered a reboot' {
                    $global:DSCMachineStatus | Should -Be $null
                }

                It 'Should have called the mock' {
                    Assert-VerifiableMock
                }
            }
        }
        #endregion

        Describe 'MSFT_xWindowsUpdateAgent\Get-WuaWrapper' {
            It 'Should return value based passed parameter' {
                Get-WuaWrapper -tryBlock {
                    param
                    (
                        [Parameter()]
                        $a,

                        [Parameter()]
                        $b
                    )

                    return $a + $b
                } -ArgumentList @(1, 2) | Should -Be 3
            }

            It 'Should throw unexpected exception' {
                $exceptionMessage = 'foobar'

                {
                    Get-WuaWrapper -tryBlock {
                        throw $exceptionMessage
                    } -ArgumentList @(1, 2)
                } | Should -Throw $exceptionMessage
            }

            $handleErrors = @(
                @{
                    hresult = -2145124322
                    Name    = 'rebooting'
                },
                @{
                    hresult = -2145107921
                    Name    = 'CabProcessingSuceededWithError'
                }
            )

            foreach ($exception in $handleErrors)
            {
                $name = $exception.Name
                $hresult = $exception.hresult

                It "should handle $name exception and return null" {
                    $exceptionMessage = 'foobar'

                    Get-WuaWrapper -tryBlock {
                        $exception = New-Object -TypeName 'System.Runtime.InteropServices.COMException' -ArgumentList @('mocked com exception', $hresult)
                        throw $exception
                    } | Should -Be $null
                }

                It "should handle $name exception and return specified value" {
                    $exceptionReturnValue = 'foobar'

                    $wrapperParams = @{
                        "ExceptionReturnValue" = $exceptionReturnValue
                    }

                    Get-WuaWrapper -tryBlock {
                        $exception = New-Object -TypeName 'System.Runtime.InteropServices.COMException' -ArgumentList @('mocked com exception', $hresult)
                        throw $exception
                    } @wrapperParams | Should -Be $exceptionReturnValue
                }
            }

            $retryErrors = @(
                @{
                    hresult = -2145107924
                    Name    = 'HostNotFound'
                },
                @{
                    hresult = -2145107940
                    Name    = 'RequestTimeout'
                },
                @{
                    hresult = -2145107934
                    Name    = 'ServiceIsOverloaded'
                },
                @{
                    hresult = -2145107952
                    Name    = 'MaxRoundTripsExceeded'
                }
            )

            foreach ($exception in $retryErrors)
            {
                $name = $exception.Name
                $hresult = $exception.hresult

                It "should throw $name exception because does not resolve before retry count is exceeded" {
                    {
                        Get-WuaWrapper -tryBlock {
                            $exception = New-Object -TypeName 'System.Runtime.InteropServices.COMException' -ArgumentList @('mocked com exception', $hresult)

                            throw $exception
                        }
                    } | Should -Throw
                }

                It "should not throw $name exception because transisent error resolves before retry count is exceeded" {
                    $count = 0

                    {
                        Get-WuaWrapper -tryBlock {
                            $exception = New-Object -TypeName 'System.Runtime.InteropServices.COMException' -ArgumentList @('mocked com exception', $hresult)

                            if ($count++ -le 1)
                            {
                                throw $exception
                            }
                        }
                    } | Should -Not -Throw
                }
            }
        }

        Describe 'MSFT_xWindowsUpdateAgent\Get-WuaSearcher' {
            $testCases = @(
                @{
                    Category = @('Security', 'Optional', 'Important')
                }
                @{
                    Category = @('Security', 'Optional')
                }
                @{
                    Category = @('Security', 'Important')
                }
                @{
                    Category = @('Optional', 'Important')
                }
                @{
                    Category = @('Optional')
                }
                @{
                    Category = @('Important')
                }
                @{
                    Category = @()
                }
            )

            Context 'Verify wua call works' {
                It "Should get a searcher - Category: <Category>" -skip -TestCases $testCases {
                    param
                    (
                        [Parameter()]
                        [System.String[]]
                        $category
                    )

                    $searcher = (get-wuaSearcher -category $category -verbose)
                    $searcher | get-member
                    $searcher.GetType().FullName | Should -Be "System.__ComObject"
                }
            }

            Context 'verify call flow' {
                Mock -CommandName get-wuaWrapper -MockWith {
                    return "testResult"
                }

                It "should call get-wuasearchstring - Category: <Category>" -TestCases $testCases {
                    param
                    (
                        [Parameter()]
                        [System.String[]]
                        $category
                    )

                    $script:ImportantExpected = ($category -contains 'Important')
                    $script:SecurityExpected = ($category -contains 'Security')
                    $script:OptionalExpected = ($category -contains 'Optional')

                    Mock -CommandName get-WuaSearchString -MockWith { return 'mockedSearchString' } -ParameterFilter { $security -eq $script:SecurityExpected -and $optional -eq $script:OptionalExpected -and $Important -eq $script:ImportantExpected }

                    foreach ($categoryItem in $category)
                    {
                        Write-Verbose -Message $categoryItem -Verbose
                    }

                    get-wuaSearcher -category $category | Should -Be "testResult"

                    Assert-MockCalled -CommandName get-wuaSearchString -Times 1
                    Assert-MockCalled -CommandName get-wuaWrapper -Times 1 -ParameterFilter {
                        $ArgumentList -eq @('mockedSearchString')
                    }
                }
            }

        }

        Describe 'MSFT_xWindowsUpdateAgent\Get-WuaAuNotificationLevelInt' {
            $testCases = @(
                @{
                    notificationLevel    = 'Scheduled installation'
                    intNotificationLevel = 4
                }
                @{
                    notificationLevel    = 'Scheduledinstallation'
                    intNotificationLevel = 4
                }
                @{
                    notificationLevel    = 'Scheduled Installation'
                    intNotificationLevel = 4
                }
                @{
                    notificationLevel    = 'ScheduledInstallation'
                    intNotificationLevel = 4
                }
                @{
                    notificationLevel    = 'Disabled'
                    intNotificationLevel = 1
                }
                @{
                    notificationLevel    = 'disabled'
                    intNotificationLevel = 1
                }
            )

            It "Should return <intNotificationLevel> for <notificationLevel>" -TestCases $testCases {
                param
                (
                    [Parameter()]
                    $notificationLevel,

                    [Parameter()]
                    $intNotificationLevel
                )

                Get-WuaAuNotificationLevelInt -notificationLevel $notificationLevel | Should -Be $intNotificationLevel
            }
        }

        Describe 'MSFT_xWindowsUpdateAgent\Get-WuaServiceManager' {
            It "Should return an object with an AddService2 Method" {
                Get-WuaServiceManager | Get-Member -Name AddService2 -MemberType Method | should not be null
            }
        }

        Describe 'MSFT_xWindowsUpdateAgent\Add-WuaService' {
            Mock -CommandName Get-WuaServiceManager -MockWith {
                $wuaService = [PSCustomObject] @{ }
                $wuaService | Add-Member -MemberType ScriptMethod -value {
                    param
                    (
                        [Parameter()]
                        [System.String]
                        $string1,

                        [Parameter()]
                        [System.String]
                        $string2,

                        [Parameter()]
                        [System.String]
                        $string3
                    )

                    "$string1|$string2|$string3" | out-file testdrive:\addservice2.txt -force
                } -name AddService2

                return $wuaService
            } -Verifiable

            $testServiceId = 'fakeServiceId'

            It "should not throw" {
                { Add-WuaService -ServiceId $testServiceId } | Should -Not -Throw
            }

            It "should have called the mock" {
                Assert-VerifiableMock
            }

            It "should have created testdrive:\addservice2.txt" {
                'testdrive:\AddService2.txt' | Should -Exist
            }

            It "It should have called AddService2" {
                Get-Content testdrive:\AddService2.txt | Should -Be "$testServiceId|7|"
            }
        }

        Describe 'MSFT_xWindowsUpdateAgent\Get-WuaSearchString' {
            $testCases = @(
                @{
                    security  = $false
                    optional  = $false
                    important = $false
                    result    = "CategoryIds contains '0FA1201D-4330-4FA8-8AE9-B877473B6441' and IsHidden=0 and IsInstalled=0"
                }
                @{
                    security  = $true
                    optional  = $false
                    important = $false
                    result    = "CategoryIds contains '0FA1201D-4330-4FA8-8AE9-B877473B6441' and IsHidden=0 and IsInstalled=0"
                }
                @{
                    security  = $true
                    optional  = $true
                    important = $false
                    result    = "(IsAssigned=0 and IsHidden=0 and IsInstalled=0) or (CategoryIds contains '0FA1201D-4330-4FA8-8AE9-B877473B6441' and IsHidden=0 and IsInstalled=0)"
                }
                @{
                    security  = $true
                    optional  = $true
                    important = $true
                    result    = "IsHidden=0 and IsInstalled=0"
                }
                @{
                    security  = $false
                    optional  = $true
                    important = $false
                    result    = "IsAssigned=0 and IsHidden=0 and IsInstalled=0"
                }
                @{
                    security  = $false
                    optional  = $true
                    important = $true
                    result    = "IsHidden=0 and IsInstalled=0"
                }
                @{
                    security  = $false
                    optional  = $false
                    important = $true
                    result    = "IsAssigned=1 and IsHidden=0 and IsInstalled=0"
                }
            )

            $testServiceId = 'fakeServiceId'

            It "Calling with -security:<security> -optional:<optional> -important:<important> should result in expected query" -TestCases $testCases {
                param
                (
                    [Parameter()]
                    $security,

                    [Parameter()]
                    $optional,

                    [Parameter()]
                    $important,

                    [Parameter()]
                    $result
                )

                Get-WuaSearchString -security:$security -optional:$optional -important:$important | Should -Be $result
            }
        }

        Describe 'MSFT_xWindowsUpdateAgent\Get-WuaAuNotificationLevel' {
            $testCases = @(
                @{
                    NotificationLevel = 0
                    Result            = 'Not Configured'
                }
                @{
                    NotificationLevel = 1
                    Result            = 'Disabled'
                }
                @{
                    NotificationLevel = 2
                    Result            = 'Notify before download'
                }
                @{
                    NotificationLevel = 3
                    Result            = 'Notify before installation'
                }
                @{
                    NotificationLevel = 4
                    Result            = 'Scheduled installation'
                }
            )

            Mock -CommandName Get-WuaAuSettings -MockWith {
                $wuaService = [PSCustomObject] @{ }
                $wuaService | Add-Member -MemberType ScriptProperty -value {
                    return [System.Int32] (Get-Content testdrive:\NotificationLevel.txt)
                } -name NotificationLevel

                return $wuaService
            }

            It "Should return <result> when notification level is <NotificationLevel>" -TestCases $testCases {
                param
                (
                    [Parameter()]
                    [System.Int32]
                    $NotificationLevel,

                    [Parameter()]
                    $result
                )

                $NotificationLevel | Out-File testdrive:\NotificationLevel.txt -Force

                Get-WuaAuNotificationLevel | Should -Be $result
            }
        }

        Describe 'MSFT_xWindowsUpdateAgent\Test-TargetResourceProperties' {
            Mock -CommandName Write-Warning -Verifiable
            Mock -CommandName Write-Verbose

            It 'Calls write-warning when no categories are passed' {
                $PropertiesToTest = @{
                    IsSingleInstance = 'Yes'
                    Notifications    = 'Disabled'
                    Source           = 'WindowsUpdate'
                    Category         = @()
                    UpdateNow        = $True
                }

                Test-TargetResourceProperties @PropertiesToTest

                Assert-MockCalled -CommandName Write-Warning -Times 1 -Exactly -Scope It
            }

            It 'Calls write-warning when Important updates are requested but not Security updates' {
                $PropertiesToTest = @{
                    IsSingleInstance = 'Yes'
                    Notifications    = 'Disabled'
                    Source           = 'WindowsUpdate'
                    Category         = 'Important'
                }

                Test-TargetResourceProperties @PropertiesToTest

                Assert-MockCalled -CommandName Write-Warning -Times 1 -Exactly -Scope It
            }

            It 'Calls write-warning when Optional updates are requested but not Security updates' {
                $PropertiesToTest = @{
                    IsSingleInstance = 'Yes'
                    Notifications    = 'Disabled'
                    Source           = 'WindowsUpdate'
                    Category         = 'Optional'
                    UpdateNow        = $True
                }

                Test-TargetResourceProperties @PropertiesToTest

                Assert-MockCalled -CommandName Write-Verbose -Times 1 -Exactly -Scope It
            }

            It 'Throws an exception when passed WSUS as a source' {
                $PropertiesToTest = @{
                    IsSingleInstance = 'Yes'
                    Category         = 'Security'
                    Notifications    = 'Disabled'
                    Source           = 'WSUS'
                }

                { Test-TargetResourceProperties @PropertiesToTest } | Should -Throw
            }
        }

        Describe 'MSFT_xWindowsUpdateAgent\Get-WuaAuNotificationLevelInt' {
            It 'Gets int for notification level of Not Configured' {
                Get-WuaAuNotificationLevelInt -notificationLevel 'Not Configured' | Should -Be 0
            }

            It 'Gets int for notification level of Disabled' {
                Get-WuaAuNotificationLevelInt -notificationLevel 'Disabled' | Should -Be 1
            }

            It 'Gets int for notification level of Notify before download' {
                Get-WuaAuNotificationLevelInt -notificationLevel 'Notify before download' | Should -Be 2
            }

            It 'Gets int for notification level of Notify before installation' {
                Get-WuaAuNotificationLevelInt -notificationLevel 'Notify before installation' | Should -Be 3
            }

            It 'Gets int for notification level of Scheduled Installation' {
                Get-WuaAuNotificationLevelInt -notificationLevel 'Scheduled Installation' | Should -Be 4
            }

            It 'Gets int for notification level of ScheduledInstallation' {
                Get-WuaAuNotificationLevelInt -notificationLevel 'ScheduledInstallation' | Should -Be 4
            }

            It 'Gets int for notification level when nothing is provided' {
                { Get-WuaAuNotificationLevelInt } | Should -Throw
            }
        }
    }
    #endregion
}
finally
{
    Invoke-TestCleanup
}
