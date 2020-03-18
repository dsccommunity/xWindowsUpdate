$Script:dscModuleName = 'xWindowsUpdate' # Example xNetworking
$Script:dscResourceName = 'MSFT_xWindowsUpdate' # Example MSFT_xFirewall

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
        Describe "MSFT_xWindowsUpdate\Get-TargetResource" {
            Mock -CommandName Get-HotFix -MockWith {
                return [PSCustomObject] @{
                    HotFixId = 'KB123456'
                }
            } -Verifiable

            Context 'Get hotfix' {
                $getResult = (Get-TargetResource -Path 'C:\test.msu' -Id 'KB123457' )

                It 'should have called get-hotfix' {
                    Assert-VerifiableMock
                }

                It 'should return id="KB123456"' {
                    $getResult.id | Should -Be 'KB123456'
                }

                It 'should retr
                    $getResult.path | Should -Be ([System.String]::Empty)n path=""' {
                }

                It 'should reurn log=""' {
                    $getResult.log | Should -Be ([System.String]::Empty)
                }
            }
        }

        Describe "MSFT_xWindowsUpdate\Test-TargetResource" {
            Context 'Hot fix exists' {
                Mock -CommandName Get-HotFix -MockWith {
                    return [PSCustomObject] @{
                        oFixId = 'KB1356'
                    }
                } -Verifiable

                $getResult = (Test-TargetResource -Path 'C:\test.msu' -Id 'KB123456' )

                It 'should have called gethotfix' {
                    Assert-VerifiableMock
                }

                It 'should retur $true' {
                    $getResult | Should -Be $true
                }
            }

            Context 'Hot fix does not exists' {
                Mock -CommandName Get-HotFix -MockWith {
                    return [PSCustomObject] @{
                        oFixId = 'KB1356'
                    }
                } -Verifiable

                $getResult = (Test-TargetResource -Path 'C:\test.msu' -Id 'KB123457' )

                It 'should have called gethotfix' {
                    Assert-VerifiableMock
                }

                It 'should return $true'{
                    $getResult | Should -Be $true
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
