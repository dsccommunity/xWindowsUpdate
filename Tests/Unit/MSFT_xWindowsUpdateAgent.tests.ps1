<#
.Synopsis
   Unit tests for xWindowsUpdateAgent
.DESCRIPTION
   Unit tests for  xWindowsUpdateAgent

.NOTES
   Code in HEADER and FOOTER regions are standard and may be moved into DSCResource.Tools in
   Future and therefore should not be altered if possible.
#>


$Global:DSCModuleName      = 'xWindowsUpdate' # Example xNetworking
$Global:DSCResourceName    = 'MSFT_xWindowsUpdateAgent' # Example MSFT_xFirewall

#region HEADER
[String] $moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))
if ( (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'))
}
else
{
    & git @('-C',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'),'pull')
}
Import-Module (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $Global:DSCModuleName `
    -DSCResourceName $Global:DSCResourceName `
    -TestType Unit 
#endregion

# TODO: Other Optional Init Code Goes Here...

# Begin Testing
try
{

    #region Pester Tests

    # The InModuleScope command allows you to perform white-box unit testing on the internal
    # (non-exported) code of a Script Module.
    InModuleScope $Global:DSCResourceName {

        #region Pester Test Initialization
        $Global:mockedSearchResultWithUpdate = [PSCustomObject] @{
            Updates = @{
                Count = 1
                Title = 'Mocked Update'
            }
        }

        $Global:mockedSearchResultWithoutUpdate = [PSCustomObject] @{
            Updates = @{
                Count = 0
            }
        }

        $Global:mockedSearchResultWithoutUpdatesProperty = [PSCustomObject] @{
        }
        
        $Global:mockedWuaDisableNotificationLevel = 'Disabled'
        $Global:mockedWuaOtherNotificationLevel = 'Notify before download'
        $Global:mockedWuaSystemInfoNoReboot = @{
            RebootRequired = $false
        }
        $Global:mockedWuaSystemInfoReboot = @{
            RebootRequired = $true
        }
        $Global:mockeWindowsUpdateServiceManager= [PSCustomObject]  @{
            Services = @(
                [PSCustomObject] @{
                    ServiceId = '9482f4b4-e343-43b6-b170-9a65bc822c77'
                    IsDefaultAUService = $true
                    IsManaged = $false
                }
            )
        }

        $Global:mockedMicrosoftUpdateServiceManager= [PSCustomObject]  @{
            Services = @(
                [PSCustomObject] @{
                    ServiceId = '7971f918-a847-4430-9279-4a52d1efe18d'
                    IsDefaultAUService = $true
                    IsManaged = $false
                }
                [PSCustomObject] @{
                    ServiceId = '9482f4b4-e343-43b6-b170-9a65bc822c77'
                    IsDefaultAUService = $false
                    IsManaged = $false
                }
            )
        }
        $testCategories = @('Security','Important')

        #endregion


        #region Function Get-TargetResource
        Describe "$($Global:DSCResourceName)\Get-TargetResource" {
            Mock Get-WuaServiceManager -MockWith { return $Global:mockeWindowsUpdateServiceManager}
            Mock New-object -MockWith {} -ParameterFilter {$ComObject -ne $null}
            Context 'MU service' {
                Mock  Get-WuaSearcher -MockWith {
                    return $null
                } -Verifiable
                
                Mock  Get-WuaAuNotificationLevel -MockWith {
                    return $Global:mockedWuaDisableNotificationLevel
                } -Verifiable                                    

                Mock Get-WuaSystemInfo -MockWith {
                    return $Global:mockedWuaSystemInfoNoReboot
                } -Verifiable
                
                Mock Get-WuaServiceManager -MockWith { return $Global:mockedMicrosoftUpdateServiceManager}
                    
                $getResult = (Get-TargetResource -IsSingleInstance 'yes' -UpdateNow $true -Category $testCategories -Notifications Disabled -Source WindowsUpdate )
                
                it 'should not have called the new-object mock'{
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0                    
                }
                it 'should return Category=$testCategories'{
                    $getResult.Category | should be $testCategories
                }

                it 'should return IsSingleInstance = Yes'{
                    $getResult.IsSingleInstance | should be 'Yes'
                }

                it "should return AutomaticUpdatesNotificationSetting = ${Global:mockedWuaDisableNotificationLevel}"{
                    $getResult.AutomaticUpdatesNotificationSetting | should be $Global:mockedWuaDisableNotificationLevel
                }

                it 'should return 0 update not installed '{
                    $getResult.TotalUpdatesNotInstalled | should be 0
                }

                it 'should return reboot requied $false' {
                    $getResult.RebootRequired | should be $false
                }

                it 'should return Notifications=Disabled'{
                    $getResult.Notifications | should be 'Disabled'
                }

                it 'should return UpdateNome=$true'{
                    $getResult.UpdateNow | should be $true
                }
                it 'should return Service=MU'{
                    $getResult.Service | should be "MicrosoftUpdate"
                }
                
                it 'should have called the mock' {
                    Assert-VerifiableMocks
                }
            }            
            Context 'null search result and disabled notification' {
                Mock  Get-WuaSearcher -MockWith {
                    return $null
                } -Verifiable
                
                Mock  Get-WuaAuNotificationLevel -MockWith {
                    return $Global:mockedWuaDisableNotificationLevel
                } -Verifiable                                    

                Mock Get-WuaSystemInfo -MockWith {
                    return $Global:mockedWuaSystemInfoNoReboot
                } -Verifiable
                    
                $getResult = (Get-TargetResource -IsSingleInstance 'yes' -UpdateNow $true -Category $testCategories -Notifications Disabled  -Source WindowsUpdate )
                
                it 'should not have called the new-object mock'{
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0                    
                }
                it 'should return Category=$testCategories'{
                    $getResult.Category | should be $testCategories
                }

                it 'should return IsSingleInstance = Yes'{
                    $getResult.IsSingleInstance | should be 'Yes'
                }

                it "should return AutomaticUpdatesNotificationSetting = ${Global:mockedWuaDisableNotificationLevel}"{
                    $getResult.AutomaticUpdatesNotificationSetting | should be $Global:mockedWuaDisableNotificationLevel
                }

                it 'should return 0 update not installed '{
                    $getResult.TotalUpdatesNotInstalled | should be 0
                }

                it 'should return reboot requied $false' {
                    $getResult.RebootRequired | should be $false
                }

                it 'should return Notifications=Disabled'{
                    $getResult.Notifications | should be 'Disabled'
                }

                it 'should return UpdateNome=$true'{
                    $getResult.UpdateNow | should be $true
                }
                it 'should return Service=WU'{
                    $getResult.Service | should be "WindowsUpdate"
                }
                
                it 'should have called the mock' {
                    Assert-VerifiableMocks
                }
            }            
            Context 'no updates property and disabled notification' {
                Mock  Get-WuaSearcher -MockWith {
                    return $Global:mockedSearchResultWithoutUpdatesProperty
                } -Verifiable
                
                Mock  Get-WuaAuNotificationLevel -MockWith {
                    return $Global:mockedWuaDisableNotificationLevel
                } -Verifiable                                    

                Mock Get-WuaSystemInfo -MockWith {
                    return $Global:mockedWuaSystemInfoNoReboot
                } -Verifiable
                    
                $getResult = (Get-TargetResource -IsSingleInstance 'yes' -UpdateNow $true -Category $testCategories -Notifications Disabled -Source WindowsUpdate )
                
                it 'should not have called the new-object mock'{
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0                    
                }

                it 'should return Category=$testCategories'{
                    $getResult.Category | should be $testCategories
                }

                it 'should return IsSingleInstance = Yes'{
                    $getResult.IsSingleInstance | should be 'Yes'
                }

                it "should return AutomaticUpdatesNotificationSetting = ${Global:mockedWuaDisableNotificationLevel}"{
                    $getResult.AutomaticUpdatesNotificationSetting | should be $Global:mockedWuaDisableNotificationLevel
                }

                it 'should return 0 update not installed '{
                    $getResult.TotalUpdatesNotInstalled | should be 0
                }

                it 'should return reboot requied $false' {
                    $getResult.RebootRequired | should be $false
                }

                it 'should return UpdateNow=$true'{
                    $getResult.UpdateNow | should be $true
                }

                it 'should return Notifications=Disabled'{
                    $getResult.Notifications | should be 'Disabled'
                }
                
                it 'should have called the mock' {
                    Assert-VerifiableMocks
                }
            }            
            Context 'no updates and disabled notification' {
                Mock  Get-WuaSearcher -MockWith {
                    return $Global:mockedSearchResultWithoutUpdate
                } -Verifiable
                
                Mock  Get-WuaAuNotificationLevel -MockWith {
                    return $Global:mockedWuaDisableNotificationLevel
                } -Verifiable                                    

                Mock Get-WuaSystemInfo -MockWith {
                    return $Global:mockedWuaSystemInfoNoReboot
                } -Verifiable
                    
                $getResult = (Get-TargetResource -IsSingleInstance 'yes' -UpdateNow $true -Category $testCategories -Notifications Disabled -Source WindowsUpdate )
                
                it 'should not have called the new-object mock'{
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0                    
                }
                
                it 'should return Category=$testCategories'{
                    $getResult.Category | should be $testCategories
                }

                it 'should return IsSingleInstance = Yes'{
                    $getResult.IsSingleInstance | should be 'Yes'
                }

                it "should return AutomaticUpdatesNotificationSetting = ${Global:mockedWuaDisableNotificationLevel}"{
                    $getResult.AutomaticUpdatesNotificationSetting | should be $Global:mockedWuaDisableNotificationLevel
                }

                it 'should return 0 update not installed '{
                    $getResult.TotalUpdatesNotInstalled | should be 0
                }

                it 'should return reboot requied $false' {
                    $getResult.RebootRequired | should be $false
                }

                it 'should return UpdateNow=$true'{
                    $getResult.UpdateNow | should be $true
                }

                it 'should return Notifications=Disabled'{
                    $getResult.Notifications | should be 'Disabled'
                }
                
                it 'should have called the mock' {
                    Assert-VerifiableMocks
                }
            }            
            Context 'no updates , disabled notification, and reboot required' {
                Mock  Get-WuaSearcher -MockWith {
                    return $Global:mockedSearchResultWithoutUpdate
                } -Verifiable
                
                Mock  Get-WuaAuNotificationLevel -MockWith {
                    return $Global:mockedWuaDisableNotificationLevel
                } -Verifiable                                    

                Mock Get-WuaSystemInfo -MockWith {
                    return $Global:mockedWuaSystemInfoReboot
                } -Verifiable
                    
                $getResult = (Get-TargetResource -IsSingleInstance 'yes' -UpdateNow $true -Category $testCategories -Notifications Disabled -Source WindowsUpdate )
                
                it 'should not have called the new-object mock'{
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0                    
                }
                
                it 'should return Category=$testCategories'{
                    $getResult.Category | should be $testCategories
                }

                it 'should return Notifications=Disabled'{
                    $getResult.Notifications | should be 'Disabled'
                }

                it 'should return UpdateNow=$false'{
                    $getResult.UpdateNow | should be $false
                }

                it 'should return IsSingleInstance = Yes'{
                    $getResult.IsSingleInstance | should be 'Yes'
                }

                it "should return AutomaticUpdatesNotificationSetting = ${Global:mockedWuaDisableNotificationLevel}"{
                    $getResult.AutomaticUpdatesNotificationSetting | should be $Global:mockedWuaDisableNotificationLevel
                }

                it 'should return 0 update not installed '{
                    $getResult.TotalUpdatesNotInstalled | should be 0
                }
                
                it 'should return reboot requied $true' {
                    $getResult.RebootRequired | should be $true
                }
                
                it 'should have called the mock' {
                    Assert-VerifiableMocks
                }
            }            
            Context 'updates and disable notification' {
                Mock  Get-WuaSearcher -MockWith {
                    return $Global:mockedSearchResultWithUpdate
                } -Verifiable
                
                Mock  Get-WuaAuNotificationLevel -MockWith {
                    return $Global:mockedWuaDisableNotificationLevel
                } -Verifiable
                    
                Mock Get-WuaSystemInfo -MockWith {
                    return $Global:mockedWuaSystemInfoNoReboot
                } -Verifiable

                $getResult = (Get-TargetResource -IsSingleInstance 'yes' -UpdateNow $true -Category $testCategories  -Source WindowsUpdate)
                
                it 'should not have called the new-object mock'{
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0                    
                }
                
                it 'should return Category=$testCategories'{
                    $getResult.Category | should be $testCategories
                }

                it 'should return Notifications=Disabled'{
                    $getResult.Notifications | should be 'Disabled'
                }

                it 'should return UpdateNow=$false'{
                    $getResult.UpdateNow | should be $false
                }

                it 'should return IsSingleInstance = Yes'{
                    $getResult.IsSingleInstance | should be 'Yes'
                }

                it "should return AutomaticUpdatesNotificationSetting = $Global:mockedWuaDisableNotificationLevel"{
                    $getResult.AutomaticUpdatesNotificationSetting | should be $Global:mockedWuaDisableNotificationLevel
                }

                it 'should return 1 update not installed '{
                    $getResult.TotalUpdatesNotInstalled | should be 1
                }
                
                it 'should return reboot requied $false' {
                    $getResult.RebootRequired | should be $false
                }

                it 'should have called the mock' {
                    Assert-VerifiableMocks
                }
            }            
            Context 'updates and other notification' {
                Mock  Get-WuaSearcher -MockWith {
                    return $Global:mockedSearchResultWithUpdate
                } -Verifiable
                
                Mock  Get-WuaAuNotificationLevel -MockWith {
                    return $Global:mockedWuaOtherNotificationLevel
                } -Verifiable
                    
                Mock Get-WuaSystemInfo -MockWith {
                    return $Global:mockedWuaSystemInfoNoReboot
                } -Verifiable

                $getResult = (Get-TargetResource -IsSingleInstance 'yes' -UpdateNow $true -Category $testCategories  -Source WindowsUpdate)
                
                it 'should not have called the new-object mock'{
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0                    
                }
                
                it 'should return Category=$testCategories'{
                    $getResult.Category | should be $testCategories
                }

                it 'should return Notifications=Notify before Download'{
                    $getResult.Notifications | should be 'Notify before Download'
                }

                it 'should return UpdateNow=$false'{
                    $getResult.UpdateNow | should be $false
                }

                it 'should return IsSingleInstance = Yes'{
                    $getResult.IsSingleInstance | should be 'Yes'
                }

                it "should return AutomaticUpdatesNotificationSetting = $Global:mockedWuaOtherNotificationLevel"{
                    $getResult.AutomaticUpdatesNotificationSetting | should be $Global:mockedWuaOtherNotificationLevel
                }

                it 'should return 1 update not installed '{
                    $getResult.TotalUpdatesNotInstalled | should be 1
                }
                
                it 'should return reboot requied $false' {
                    $getResult.RebootRequired | should be $false
                }

                it 'should have called the mock' {
                    Assert-VerifiableMocks
                }
            }            
        }
        #endregion


        #region Function Test-TargetResource
        Describe "$($Global:DSCResourceName)\Test-TargetResource" {
            Mock Get-WuaServiceManager -MockWith { return $Global:mockeWindowsUpdateServiceManager}
            Mock New-object -MockWith {} -ParameterFilter {$ComObject -ne $null}
            Context 'Ensure UpToDate with no updates and disabled notification and wu service' {
                Mock  Get-WuaSearcher -MockWith {
                    return $Global:mockedSearchResultWithoutUpdate
                } -Verifiable
                
                Mock  Get-WuaAuNotificationLevel -MockWith {
                    return $Global:mockedWuaDisableNotificationLevel
                } -Verifiable

                Mock Get-WuaSystemInfo -MockWith {
                    return $Global:mockedWuaSystemInfoNoReboot
                } -Verifiable

                it 'should return $true' {
                    (Test-TargetResource -IsSingleInstance 'yes' -UpdateNow $true -Category $testCategories -Source MicrosoftUpdate  -verbose) | should be $false    
                }
                    
                it 'should not have called the new-object mock'{
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0                    
                }
                                
                it 'should have called the mock' {
                    Assert-VerifiableMocks
                }
            }         
               
            Context 'Ensure UpToDate with no updates and disabled notification and mu service' {
                Mock  Get-WuaSearcher -MockWith {
                    return $Global:mockedSearchResultWithoutUpdate
                } -Verifiable
                
                Mock  Get-WuaAuNotificationLevel -MockWith {
                    return $Global:mockedWuaDisableNotificationLevel
                } -Verifiable

                Mock Get-WuaSystemInfo -MockWith {
                    return $Global:mockedWuaSystemInfoNoReboot
                } -Verifiable

                Mock Get-WuaServiceManager -MockWith { return $Global:mockedMicrosoftUpdateServiceManager}

                it 'should return $true' {
                    (Test-TargetResource -IsSingleInstance 'yes' -UpdateNow $true -Category $testCategories -Source MicrosoftUpdate  -verbose) | should be $true    
                }
                    
                it 'should not have called the new-object mock'{
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0                    
                }
                                
                it 'should have called the mock' {
                    Assert-VerifiableMocks
                }
            }              
            
            Context 'Ensure UpToDate with no updates and disabled notification' {
                Mock  Get-WuaSearcher -MockWith {
                    return $Global:mockedSearchResultWithoutUpdate
                } -Verifiable
                
                Mock  Get-WuaAuNotificationLevel -MockWith {
                    return $Global:mockedWuaDisableNotificationLevel
                } -Verifiable

                Mock Get-WuaSystemInfo -MockWith {
                    return $Global:mockedWuaSystemInfoNoReboot
                } -Verifiable

                it 'should return $true' {
                    (Test-TargetResource -IsSingleInstance 'yes' -UpdateNow $true -Category $testCategories  -verbose  -Source WindowsUpdate) | should be $true    
                }
                    
                it 'should not have called the new-object mock'{
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0                    
                }
                                
                it 'should have called the mock' {
                    Assert-VerifiableMocks
                }
            }            
            Context 'Ensure UpToDate with no updates, disabled notification and reboot requirde' {
                Mock  Get-WuaSearcher -MockWith {
                    return $Global:mockedSearchResultWithoutUpdate
                } -Verifiable
                
                Mock  Get-WuaAuNotificationLevel -MockWith {
                    return $Global:mockedWuaDisableNotificationLevel
                } -Verifiable

                Mock Get-WuaSystemInfo -MockWith {
                    return $Global:mockedWuaSystemInfoReboot
                } -Verifiable

                it 'should return $false' {
                    (Test-TargetResource  -IsSingleInstance 'yes' -UpdateNow $true -Category $testCategories -verbose  -Source WindowsUpdate) | should be $false    
                }
                    
                it 'should not have called the new-object mock'{
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0                    
                }
                                
                it 'should have called the mock' {
                    Assert-VerifiableMocks
                }
            }            
            Context 'Ensure UpToDate with updates and disabled notification' {
                Mock  Get-WuaSearcher -MockWith {
                    return $Global:mockedSearchResultWithUpdate
                } -Verifiable
                
                Mock  Get-WuaAuNotificationLevel -MockWith {
                    return $Global:mockedWuaDisableNotificationLevel
                } -Verifiable
                
                Mock Get-WuaSystemInfo -MockWith {
                    return $Global:mockedWuaSystemInfoNoReboot
                } -Verifiable
                    
                it 'should return $false' {
                    (Test-TargetResource -IsSingleInstance 'yes' -UpdateNow $true -Category $testCategories -verbose  -Source WindowsUpdate) | should be $false    
                }
                    
                it 'should not have called the new-object mock'{
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0                    
                }
                                
                it 'should have called the mock' {
                    Assert-VerifiableMocks
                }
            }            
            Context 'Ensure Disable with updates and disable notification' {
                Mock  Get-WuaSearcher -MockWith {
                    return $Global:mockedSearchResultWithUpdate
                } 
                
                Mock  Get-WuaAuNotificationLevel -MockWith {
                    return $Global:mockedWuaDisableNotificationLevel
                } -Verifiable
                
                Mock Get-WuaSystemInfo -MockWith {
                    return $Global:mockedWuaSystemInfoNoReboot
                } 
    
                it 'should return $true' {
                    (Test-TargetResource  -IsSingleInstance 'yes' -UpdateNow $false -Notifications Disabled -verbose  -Source WindowsUpdate) | should be $true    
                }
                    
                it 'should not have called the new-object mock'{
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0                    
                }
                
                it 'should not have called the Get-WuaSystemInfo mock'{
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName Get-WuaSystemInfo -Times 0                    
                }

                it 'should not have called the get-wuasearcher mock'{
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName Get-WuaSearcher -Times 0                    
                }
                                
                it 'should have called the mock' {
                    Assert-VerifiableMocks
                }
            }            
            Context 'Ensure Disable with updates and other notification' {
                Mock  Get-WuaSearcher -MockWith {
                    return $Global:mockedSearchResultWithUpdate
                } 
                
                Mock  Get-WuaAuNotificationLevel -MockWith {
                    return $Global:mockedWuaOtherNotificationLevel
                } -Verifiable
                    
                Mock Get-WuaSystemInfo -MockWith {
                    return $Global:mockedWuaSystemInfoNoReboot
                } 

                it 'should return $false' {
                    (Test-TargetResource -IsSingleInstance 'yes' -UpdateNow $false -Notifications Disabled -verbose  -Source WindowsUpdate) | should be $false    
                }
                    
                it 'should not have called the new-object mock'{
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0                    
                }

                it 'should not have called the Get-WuaSystemInfo mock'{
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName Get-WuaSystemInfo -Times 0                    
                }

                it 'should not have called the get-wuasearcher mock'{
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName Get-WuaSearcher -Times 0                    
                }
                                
                it 'should have called the mock' {
                    Assert-VerifiableMocks
                }
            }            

            Context 'Ensure UpToDate with updates and other notification' {
                Mock  Get-WuaSearcher -MockWith {
                    return $Global:mockedSearchResultWithUpdate
                } -Verifiable
                
                Mock  Get-WuaAuNotificationLevel -MockWith {
                    return $Global:mockedWuaOtherNotificationLevel
                } -Verifiable
                    
                Mock Get-WuaSystemInfo -MockWith {
                    return $Global:mockedWuaSystemInfoNoReboot
                } -Verifiable

                it 'should return $true' {
                    (Test-TargetResource -IsSingleInstance 'yes' -UpdateNow $true -verbose -Category $testCategories -Source WindowsUpdate) | should be $false    
                }
                    
                it 'should not have called the new-object mock'{
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0                    
                }
                                
                it 'should have called the mock' {
                    Assert-VerifiableMocks
                }
            }                             
            Context 'Ensure UpdateNow = $false with updates and other notification' {
                Mock  Get-WuaSearcher -MockWith {
                    return $Global:mockedSearchResultWithUpdate
                }
                
                Mock  Get-WuaAuNotificationLevel -MockWith {
                    return $Global:mockedWuaOtherNotificationLevel
                } -Verifiable
                    
                Mock Get-WuaSystemInfo -MockWith {
                    return $Global:mockedWuaSystemInfoNoReboot
                } 

                it 'should return $true' {
                    (Test-TargetResource -IsSingleInstance 'yes' -UpdateNow $false -verbose -Category $testCategories -Source WindowsUpdate) | should be $true    
                }
                    
                it 'should not have called the new-object mock'{
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0                    
                }

                it 'should not have called the Get-WuaSystemInfo mock'{
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName Get-WuaSystemInfo -Times 0                    
                }

                it 'should not have called the get-wuasearcher mock'{
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName Get-WuaSearcher -Times 0                    
                }
                                
                it 'should have called the mock' {
                    Assert-VerifiableMocks
                }
            }                             
        }
        #endregion


        #region Function Set-TargetResource
        Describe "$($Global:DSCResourceName)\Set-TargetResource" {
            Mock Get-WuaServiceManager -MockWith { return $Global:mockeWindowsUpdateServiceManager}
            Mock New-object -MockWith {} -ParameterFilter {$ComObject -ne $null}
            Context 'Ensure UpToDate with null search results, disabled notification, and reboot required' {
                BeforeAll {
                    $global:DSCMachineStatus = $null                
                }
                AfterAll {
                    $global:DSCMachineStatus = $null
                }

                Mock  Get-WuaSearcher -MockWith {
                    return $null
                } -Verifiable
                
                Mock  Get-WuaAuNotificationLevel -MockWith {
                    return $Global:mockedWuaDisableNotificationLevel
                } -Verifiable

                Mock Get-WuaRebootRequired -MockWith {
                    return $true
                } -Verifiable
                
                Mock Invoke-WuaDownloadUpdates -MockWith {} 
                Mock Invoke-WuaInstallUpdates -MockWith {} 
                Mock Set-WuaAuNotificationLevel -MockWith {}

                it 'should not Throw' {
                    try
                    {Set-TargetResource -IsSingleInstance 'yes' -UpdateNow $true -verbose -Category $testCategories  -Source WindowsUpdate | should be $null}
                    catch
                    {
                        $_ | should be $null
                    }    
                }
                    
                it 'should not have called the new-object mock'{
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0 -ParameterFilter {$ComObject -ne $null}                    
                }
                
                it 'should not have changed wua' {
                    Assert-MockCalled -CommandName Invoke-WuaDownloadUpdates -Times 0
                    Assert-MockCalled -CommandName Invoke-WuaInstallUpdates -Times 0
                    Assert-MockCalled -CommandName Set-WuaAuNotificationLevel -Times 0
                }

                it 'Should have triggered a reboot'{
                    $global:DSCMachineStatus | should be 1
                }
                                                
                it 'should have called the mock' {
                    Assert-VerifiableMocks
                }
            }            
            Context 'Ensure UpToDate with no updates, mu and disabled notification' {
                BeforeAll {
                    $global:DSCMachineStatus = $null                
                }
                AfterAll {
                    $global:DSCMachineStatus = $null
                }

                Mock  Get-WuaSearcher -MockWith {
                    return $Global:mockedSearchResultWithoutUpdate
                } -Verifiable
                
                Mock  Get-WuaAuNotificationLevel -MockWith {
                    return $Global:mockedWuaDisableNotificationLevel
                } -Verifiable

                Mock Get-WuaSystemInfo -MockWith {
                    return $Global:mockedWuaSystemInfoNoReboot
                } -Verifiable
                mock Add-WuaService -MockWith {} -Verifiable
                mock Remove-WuaService -MockWith {} 
                Mock Invoke-WuaDownloadUpdates -MockWith {} 
                Mock Invoke-WuaInstallUpdates -MockWith {} 
                Mock Set-WuaAuNotificationLevel -MockWith {}

                it 'should not Throw' {
                    {Set-TargetResource -IsSingleInstance 'yes'  -UpdateNow $true -verbose -Category $testCategories -Source MicrosoftUpdate} | should not throw    
                }
                    
                it 'should not have called the new-object mock'{
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0                    
                }
                
                it 'should not have changed wua' {
                    Assert-MockCalled -CommandName Invoke-WuaDownloadUpdates -Times 0
                    Assert-MockCalled -CommandName Invoke-WuaInstallUpdates -Times 0
                    Assert-MockCalled -CommandName Set-WuaAuNotificationLevel -Times 0
                }

                it 'Should not have triggered a reboot'{
                    $global:DSCMachineStatus | should be $null
                }
                                                
                it 'should have called the mock' {
                    Assert-VerifiableMocks
                }
            }        
            
            Context 'Ensure UpToDate with no updates, mu and disabled notification' {
                BeforeAll {
                    $global:DSCMachineStatus = $null                
                }
                AfterAll {
                    $global:DSCMachineStatus = $null
                }

                Mock  Get-WuaSearcher -MockWith {
                    return $Global:mockedSearchResultWithoutUpdate
                } -Verifiable
                
                Mock  Get-WuaAuNotificationLevel -MockWith {
                    return $Global:mockedWuaDisableNotificationLevel
                } -Verifiable

                Mock Get-WuaSystemInfo -MockWith {
                    return $Global:mockedWuaSystemInfoNoReboot
                } -Verifiable
                mock Add-WuaService -MockWith {} 
                mock Remove-WuaService -MockWith {} 
                Mock Invoke-WuaDownloadUpdates -MockWith {} 
                Mock Invoke-WuaInstallUpdates -MockWith {} 
                Mock Set-WuaAuNotificationLevel -MockWith {}

                it 'should not Throw' {
                    {Set-TargetResource -IsSingleInstance 'yes'  -UpdateNow $true -verbose -Category $testCategories -Source WindowsUpdate} | should not throw    
                }
                    
                it 'should not have called the new-object mock'{
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0                    
                }
                
                it 'should not have changed wua' {
                    Assert-MockCalled -CommandName Invoke-WuaDownloadUpdates -Times 0
                    Assert-MockCalled -CommandName Invoke-WuaInstallUpdates -Times 0
                    Assert-MockCalled -CommandName Set-WuaAuNotificationLevel -Times 0
                    Assert-MockCalled -CommandName Add-WuaService  -Times 0
                    Assert-MockCalled -CommandName Remove-WuaService  -Times 0
                }

                it 'Should not have triggered a reboot'{
                    $global:DSCMachineStatus | should be $null
                }
                                                
                it 'should have called the mock' {
                    Assert-VerifiableMocks
                }
            } 

            Context 'Ensure UpToDate with no updates, mu and disabled notification' {
                BeforeAll {
                    $global:DSCMachineStatus = $null                
                }
                AfterAll {
                    $global:DSCMachineStatus = $null
                }

                Mock  Get-WuaSearcher -MockWith {
                    return $Global:mockedSearchResultWithoutUpdate
                } -Verifiable
                
                Mock  Get-WuaAuNotificationLevel -MockWith {
                    return $Global:mockedWuaDisableNotificationLevel
                } -Verifiable

                Mock Get-WuaSystemInfo -MockWith {
                    return $Global:mockedWuaSystemInfoNoReboot
                } -Verifiable
                
                Mock Get-WuaServiceManager -MockWith { return $Global:mockedMicrosoftUpdateServiceManager} -Verifiable 
                mock Add-WuaService -MockWith {} 
                mock Remove-WuaService -MockWith {} -Verifiable
                Mock Invoke-WuaDownloadUpdates -MockWith {} 
                Mock Invoke-WuaInstallUpdates -MockWith {} 
                Mock Set-WuaAuNotificationLevel -MockWith {}

                it 'should not Throw' {
                    {Set-TargetResource -IsSingleInstance 'yes'  -UpdateNow $true -verbose -Category $testCategories -Source WindowsUpdate} | should not throw    
                }
                    
                it 'should not have called the new-object mock'{
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0                    
                }
                
                it 'should not have changed wua' {
                    Assert-MockCalled -CommandName Invoke-WuaDownloadUpdates -Times 0
                    Assert-MockCalled -CommandName Invoke-WuaInstallUpdates -Times 0
                    Assert-MockCalled -CommandName Set-WuaAuNotificationLevel -Times 0
                    Assert-MockCalled -CommandName Add-WuaService  -Times 0
                }

                it 'Should not have triggered a reboot'{
                    $global:DSCMachineStatus | should be $null
                }
                                                
                it 'should have called the mock' {
                    Assert-VerifiableMocks
                }
            } 
                        
            Context 'Ensure UpToDate with no updates and disabled notification' {
                BeforeAll {
                    $global:DSCMachineStatus = $null                
                }
                AfterAll {
                    $global:DSCMachineStatus = $null
                }

                Mock  Get-WuaSearcher -MockWith {
                    return $Global:mockedSearchResultWithoutUpdate
                } -Verifiable
                
                Mock  Get-WuaAuNotificationLevel -MockWith {
                    return $Global:mockedWuaDisableNotificationLevel
                } -Verifiable

                Mock Get-WuaSystemInfo -MockWith {
                    return $Global:mockedWuaSystemInfoNoReboot
                } -Verifiable
                
                Mock Invoke-WuaDownloadUpdates -MockWith {} 
                Mock Invoke-WuaInstallUpdates -MockWith {} 
                Mock Set-WuaAuNotificationLevel -MockWith {}

                it 'should not Throw' {
                    {Set-TargetResource -IsSingleInstance 'yes'  -UpdateNow $true -verbose -Category $testCategories  -Source WindowsUpdate} | should not throw    
                }
                    
                it 'should not have called the new-object mock'{
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0                    
                }
                
                it 'should not have changed wua' {
                    Assert-MockCalled -CommandName Invoke-WuaDownloadUpdates -Times 0
                    Assert-MockCalled -CommandName Invoke-WuaInstallUpdates -Times 0
                    Assert-MockCalled -CommandName Set-WuaAuNotificationLevel -Times 0
                }

                it 'Should not have triggered a reboot'{
                    $global:DSCMachineStatus | should be $null
                }
                                                
                it 'should have called the mock' {
                    Assert-VerifiableMocks
                }
            }            
            Context 'Ensure UpToDate with no updates, disabled notification and reboot required' {
                BeforeAll {
                    $global:DSCMachineStatus = $null                
                }
                AfterAll {
                    $global:DSCMachineStatus = $null
                }

                Mock  Get-WuaSearcher -MockWith {
                    return $Global:mockedSearchResultWithoutUpdate
                } -Verifiable
                
                Mock  Get-WuaAuNotificationLevel -MockWith {
                    return $Global:mockedWuaDisableNotificationLevel
                } -Verifiable

                Mock Get-WuaSystemInfo -MockWith {
                    return $Global:mockedWuaSystemInfoReboot
                } -Verifiable

                Mock Invoke-WuaDownloadUpdates -MockWith {} 
                Mock Invoke-WuaInstallUpdates -MockWith {} 
                Mock Set-WuaAuNotificationLevel -MockWith {}

                it 'should return $false' {
                    {Set-TargetResource -IsSingleInstance 'yes'  -UpdateNow $true -verbose -Category $testCategories  -Source WindowsUpdate} | should not throw    
                }
                    
                it 'should not have called the new-object mock'{
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0                    
                }
                                
                it 'should not have changed wua' {
                    Assert-MockCalled -CommandName Invoke-WuaDownloadUpdates -Times 0
                    Assert-MockCalled -CommandName Invoke-WuaInstallUpdates -Times 0
                    Assert-MockCalled -CommandName Set-WuaAuNotificationLevel -Times 0
                }

                it 'Should have triggered a reboot'{
                    $global:DSCMachineStatus | should be 1
                }
                                                
                it 'should have called the mock' {
                    Assert-VerifiableMocks
                }
            }            
            Context 'Ensure UpToDate with updates and disabled notification' {
                BeforeAll {
                    $global:DSCMachineStatus = $null                
                }
                AfterAll {
                    $global:DSCMachineStatus = $null
                }

                Mock  Get-WuaSearcher -MockWith {
                    return $Global:mockedSearchResultWithUpdate
                } -Verifiable
                
                Mock  Get-WuaAuNotificationLevel -MockWith {
                    return $Global:mockedWuaDisableNotificationLevel
                } -Verifiable
                
                Mock Get-WuaSystemInfo -MockWith {
                    return $Global:mockedWuaSystemInfoNoReboot
                } -Verifiable

                Mock Invoke-WuaDownloadUpdates -MockWith {} -Verifiable
                Mock Invoke-WuaInstallUpdates -MockWith {} -Verifiable
                Mock Set-WuaAuNotificationLevel -MockWith {}
                    
                it 'should return $false' {
                    {Set-TargetResource -IsSingleInstance 'yes'  -UpdateNow $true -verbose -Category $testCategories -Source WindowsUpdate} | should not throw    
                }
                    
                it 'should not have called the new-object mock'{
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0                    
                }

                                
                it 'should not have changed wua notification' {
                    Assert-MockCalled -CommandName Set-WuaAuNotificationLevel -Times 0
                }

                it 'Should not have triggered a reboot'{
                    $global:DSCMachineStatus | should be $null
                }
                                
                it 'should have called the mock' {
                    Assert-VerifiableMocks
                }
            }            
            Context 'Ensure UpToDate with updates and disabled notification with reboot after install' {
                BeforeAll {
                    $global:DSCMachineStatus = $null                
                }
                AfterAll {
                    $global:DSCMachineStatus = $null
                }

                Mock  Get-WuaSearcher -MockWith {
                    return $Global:mockedSearchResultWithUpdate
                } -Verifiable
                
                Mock  Get-WuaAuNotificationLevel -MockWith {
                    return $Global:mockedWuaDisableNotificationLevel
                } -Verifiable
                
                Mock Get-WuaSystemInfo -MockWith {
                    Set-StrictMode -Off
                    if(!$callCount)
                    {
                        $callCount = 1
                    }
                    else {
                        $callCount++
                    }
                    if($callCount -eq 1)
                    {
                        Write-Verbose -Message 'return no reboot' -Verbose
                        return $Global:mockedWuaSystemInfoNoReboot
                    }
                    else {
                        Write-Verbose -Message 'return reboot' -Verbose
                        return $Global:mockedWuaSystemInfoReboot
                    }
                } -Verifiable

                Mock Invoke-WuaDownloadUpdates -MockWith {} -Verifiable
                Mock Invoke-WuaInstallUpdates -MockWith {} -Verifiable
                Mock Set-WuaAuNotificationLevel -MockWith {}
                    
                it 'should return $false' {
                    {Set-TargetResource -IsSingleInstance 'yes'  -UpdateNow $true -verbose -Category $testCategories -Source WindowsUpdate} | should not throw    
                }
                    
                it 'should not have called the new-object mock'{
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0                    
                }
                                
                it 'should not have changed wua notification' {
                    Assert-MockCalled -CommandName Set-WuaAuNotificationLevel -Times 0
                }

                it 'Should not have triggered a reboot'{
                    $global:DSCMachineStatus | should be $null
                }
                                
                it 'should have called the mock' {
                    Assert-VerifiableMocks
                }
            }            
            Context 'Ensure Disable with updates and disable notification' {
                BeforeAll {
                    $global:DSCMachineStatus = $null                
                }
                AfterAll {
                    $global:DSCMachineStatus = $null
                }

                Mock  Get-WuaSearcher -MockWith {
                    return $Global:mockedSearchResultWithUpdate
                } 
                
                Mock  Get-WuaAuNotificationLevel -MockWith {
                    return $Global:mockedWuaDisableNotificationLevel
                } -Verifiable
                
                Mock Get-WuaSystemInfo -MockWith {
                    return $Global:mockedWuaSystemInfoNoReboot
                } 

                Mock Invoke-WuaDownloadUpdates -MockWith {} 
                Mock Invoke-WuaInstallUpdates -MockWith {} 
                Mock Set-WuaAuNotificationLevel -MockWith {}

    
                it 'should not throw' {
                    {Set-TargetResource -IsSingleInstance 'yes' -notifications 'Disabled' -UpdateNow $false -Source WindowsUpdate} | should not throw    
                }
                    
                it 'should not have called the new-object mock'{
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0                    
                }

                it 'should not have called the Get-WuaSystemInfo mock'{
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName Get-WuaSystemInfo -Times 0                    
                }

                it 'should not have called the get-wuasearcher mock'{
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName Get-WuaSearcher -Times 0                    
                }

                it 'should not have changed wua' {
                    Assert-MockCalled -CommandName Invoke-WuaDownloadUpdates -Times 0
                    Assert-MockCalled -CommandName Invoke-WuaInstallUpdates -Times 0
                    Assert-MockCalled -CommandName Set-WuaAuNotificationLevel -Times 0
                }

                it 'Should not have triggered a reboot'{
                    $global:DSCMachineStatus | should be $null
                }
                                
                it 'should have called the mock' {
                    Assert-VerifiableMocks
                }
            }            
           
            Context 'Ensure Disable with updates and other notification' {
                BeforeAll {
                    $global:DSCMachineStatus = $null                
                }
                AfterAll {
                    $global:DSCMachineStatus = $null
                }
                Mock  Get-WuaSearcher -MockWith {
                    return $Global:mockedSearchResultWithUpdate
                } 
                
                Mock  Get-WuaAuNotificationLevel -MockWith {
                    return $Global:mockedWuaOtherNotificationLevel
                } -Verifiable

                Mock Get-WuaSystemInfo -MockWith {
                    return $Global:mockedWuaSystemInfoNoReboot
                } 
                    
                Mock Invoke-WuaDownloadUpdates -MockWith {} 
                Mock Invoke-WuaInstallUpdates -MockWith {} 
                Mock Set-WuaAuNotificationLevel -MockWith {}

                it 'should not throw' {
                    {Set-TargetResource -IsSingleInstance 'yes' -notifications 'Disabled'  -UpdateNow $false -Source WindowsUpdate} | should not throw    
                }
                    
                it 'should not have called the new-object mock'{
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0                    
                }

                it 'should not have called the Get-WuaSystemInfo mock'{
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName Get-WuaSystemInfo -Times 0                    
                }

                it 'should not have called the get-wuasearcher mock'{
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName Get-WuaSearcher -Times 0                    
                }

                it 'should have set the notification level' {
                    Assert-MockCalled -CommandName Set-WuaAuNotificationLevel -Times 1 -ParameterFilter {$NotificationLevel -eq 'Disabled'}
                }                                
                
                it 'should not have changed wua' {
                    Assert-MockCalled -CommandName Invoke-WuaDownloadUpdates -Times 0
                    Assert-MockCalled -CommandName Invoke-WuaInstallUpdates -Times 0
                }

                it 'Should not have triggered a reboot'{
                    $global:DSCMachineStatus | should be $null
                }

                it 'should have called the mock' {
                    Assert-VerifiableMocks
                }
            }            

            Context 'Ensure UpToDate with updates and other notification' {
                BeforeAll {
                    $global:DSCMachineStatus = $null                
                }
                AfterAll {
                    $global:DSCMachineStatus = $null
                }
                Mock  Get-WuaSearcher -MockWith {
                    return $Global:mockedSearchResultWithUpdate
                } -Verifiable
                
                Mock  Get-WuaAuNotificationLevel -MockWith {
                    return $Global:mockedWuaOtherNotificationLevel
                } -Verifiable
                    
                Mock Get-WuaSystemInfo -MockWith {
                    return $Global:mockedWuaSystemInfoNoReboot
                } -Verifiable

                Mock Invoke-WuaDownloadUpdates -MockWith {} -Verifiable
                Mock Invoke-WuaInstallUpdates -MockWith {} -Verifiable
                Mock Set-WuaAuNotificationLevel -MockWith {}

                it 'should not throw' {
                    {Set-TargetResource -IsSingleInstance 'yes'  -UpdateNow $true -verbose -Category $testCategories -Source WindowsUpdate} | should not throw    
                }
                    
                it 'should not have called the new-object mock'{
                    # verify we mocked all WUA calls correctly
                    Assert-MockCalled -CommandName New-Object -Times 0                    
                }
                                
                it 'should not have changed wua notification' {
                    Assert-MockCalled -CommandName Set-WuaAuNotificationLevel -Times 0
                }

                it 'Should not have triggered a reboot'{
                    $global:DSCMachineStatus | should be $null
                }

                it 'should have called the mock' {
                    Assert-VerifiableMocks
                }
            }            
                        
        }
        #endregion
        
        Describe "$($Global:DSCResourceName)\Get-WuaWrapper" {
            it 'should return value based passed parameter' {
                Get-WuaWrapper -tryBlock {
                    param(
                        $a,
                        $b
                    )
                    return $a+$b
                } -argumentList @(1,2) | should be 3
            } 
            it 'should throw unexpected exception' {
                $exceptionMessage = 'foobar'
                {Get-WuaWrapper -tryBlock {
                    throw $exceptionMessage
                } -argumentList @(1,2)} | should throw $exceptionMessage
            }
            $exceptions = @(@{
                hresult = -2145124322
                Name = 'rebooting'
            },
            @{
                hresult = -2145107924
                Name = 'HostNotFound'
            },
            @{
                hresult = -2145107940
                Name = 'RequestTimeout'
            }            
            )
            foreach($exception in $exceptions)
            {
                $name = $exception.Name
                $hresult = $exception.hresult
                it "should handle $name exception and return null" {
                    $exceptionMessage = 'foobar'
                    Get-WuaWrapper -tryBlock {
                        $exception = new-object -TypeName 'System.Runtime.InteropServices.COMException' -ArgumentList @('mocked com exception',$hresult)
                        throw $exception
                    }  | should be $null
                }
                it "should handle $name exception and return specified value" {
                    $exceptionReturnValue = 'foobar'
                    $wrapperParams = @{
                        "ExceptionReturnValue" = $exceptionReturnValue
                    }
                    Get-WuaWrapper -tryBlock {
                        $exception = new-object -TypeName 'System.Runtime.InteropServices.COMException' -ArgumentList @('mocked com exception',$hresult)
                        throw $exception
                    } @wrapperParams  | should be $exceptionReturnValue
                }
            }
        }
        Describe "$($Global:DSCResourceName)\get-WuaSearcher" {
            
            $testCases =  @(
               @{ Category = @('Security','Optional','Important') }
               @{ Category = @('Security','Optional') }
               @{ Category = @('Security','Important') }
               @{ Category = @('Optional','Important') }
               @{ Category = @('Optional') }
               @{ Category = @('Important') }
               @{ Category = @() }
            ) 
            Context 'Verify wua call works' {
                it "Should get a searcher" -skip -TestCases $testCases {
                    param([string[]]$category)
                    $searcher = (get-wuaSearcher -category $category -verbose) 
                    $searcher | get-member 
                    $searcher.GetType().FullName | should be "System.__ComObject"
                }
            }
            Context 'verify call flow' {
                mock get-wuaWrapper -MockWith {return "testResult"} 
                it "should call get-wuasearchstring" -TestCases $testCases {
                    param([string[]]$category)
                    $global:ImportantExpected = ($category -contains 'Important')
                    $global:SecurityExpected = ($category -contains 'Security')
                    $global:OptionalExpected = ($category -contains 'Optional')
                    mock get-WuaSearchString -MockWith {return 'mockedSearchString'} -ParameterFilter {$security -eq $global:SecurityExpected -and $optional -eq $global:OptionalExpected -and $Important -eq $global:ImportantExpected }
                    foreach($categoryItem in $category)
                    {
                        Write-Verbose -Message $categoryItem -Verbose
                    }
                    get-wuaSearcher -category $category | should be "testResult"
                    #Assert-MockCalled -CommandName get-wuaSearchString -Times 1
                    Assert-MockCalled -CommandName get-wuaSearchString -Times 1 
                    Assert-MockCalled -CommandName get-wuaWrapper -Times 1 -ParameterFilter {$ArgumentList -eq @('mockedSearchString')}
                }
            }
            
        }

        # TODO: Pester Tests for any Helper Cmdlets

    }
    
    #endregion
    
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion

    # TODO: Other Optional Cleanup Code Goes Here...
}
