#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

<#
.SYNOPSIS
    Tests for PSNetDrive functionality.
.DESCRIPTION
    Comprehensive tests for PSNetDrive core functions and features.
.NOTES
    Version:        1.0
    Author:         elirancv
    Creation Date:  2025-04-05
#>

BeforeAll {
    # Import the scripts
    . (Join-Path $PSScriptRoot '../src/PSNetDrive.Core.ps1')
    . (Join-Path $PSScriptRoot '../src/PSNetDrive.ps1')
}

Describe 'PSNetDrive Core Functions' {
    Context 'Validation Functions' {
        It 'Test-DriveLetter validates drive letters correctly' {
            Test-DriveLetter 'A' | Should -BeTrue
            Test-DriveLetter 'Z' | Should -BeTrue
            Test-DriveLetter '1' | Should -BeFalse
            Test-DriveLetter 'AA' | Should -BeFalse
            Test-DriveLetter 'a' | Should -BeFalse  # Should be uppercase only
        }

        It 'Test-NetworkPathFormat validates UNC paths correctly' {
            Test-NetworkPathFormat '\\server\share' | Should -BeTrue
            Test-NetworkPathFormat 'C:\path' | Should -BeFalse
            Test-NetworkPathFormat '\\server\share\subfolder' | Should -BeFalse
            Test-NetworkPathFormat 'http://server/share' | Should -BeFalse
        }
    }

    Context 'Share Configuration' {
        BeforeAll {
            # Create test .env file with multiple configurations
            @'
TEST_SHARE1=T|\\server1\test1|Test Share 1|user1|pass1
TEST_SHARE2=S|\\server2\test2|Test Share 2|user2|pass2
'@ | Set-Content (Join-Path $PSScriptRoot '../.env') -Force
        }

        It 'Get-ShareConfiguration reads configuration correctly' {
            $config = Get-ShareConfiguration
            $config | Should -Not -BeNull
            $config.Count | Should -Be 2
            $config[0].Name | Should -Be 'T'
            $config[0].Path | Should -Be '\\server1\test1'
            $config[0].Description | Should -Be 'Test Share 1'
            $config[0].ShareName | Should -Be 'TEST_SHARE1'
            $config[1].Name | Should -Be 'S'
            $config[1].Path | Should -Be '\\server2\test2'
            $config[1].Description | Should -Be 'Test Share 2'
            $config[1].ShareName | Should -Be 'TEST_SHARE2'
        }

        AfterAll {
            # Cleanup test .env
            Remove-Item (Join-Path $PSScriptRoot '../.env') -Force -ErrorAction SilentlyContinue
        }
    }
}

Describe 'PSNetDrive CLI' {
    Context 'Command Validation' {
        BeforeAll {
            # Create test .env file
            @'
TEST_SHARE=T|\\server\test|Test Share|user|pass
'@ | Set-Content (Join-Path $PSScriptRoot '../.env') -Force
        }

        It 'Shows help when requested' {
            $output = & (Join-Path $PSScriptRoot '../src/PSNetDrive.ps1') Help 6>&1
            $output | Should -Not -BeNullOrEmpty
            $output -join "`n" | Should -Match 'PSNetDrive CLI'
        }

        It 'Validates invalid commands' {
            $output = & (Join-Path $PSScriptRoot '../src/PSNetDrive.ps1') InvalidCommand 2>&1
            $output | Should -Not -BeNullOrEmpty
            $output -join "`n" | Should -Match 'Invalid command'
        }

        AfterAll {
            # Cleanup test .env
            Remove-Item (Join-Path $PSScriptRoot '../.env') -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'Drive Operations' {
        BeforeAll {
            # Create test .env file
            @'
TEST_SHARE=T|\\server\test|Test Share|user|pass
'@ | Set-Content (Join-Path $PSScriptRoot '../.env') -Force

            # Mock network-related cmdlets
            Mock Test-NetConnection { return $true }
            Mock Get-CimInstance { 
                return @(
                    @{
                        LocalName = 'T:'
                        RemoteName = '\\server\test'
                        Status = 'OK'
                    }
                )
            }
        }

        It 'Lists network drives' {
            $output = & (Join-Path $PSScriptRoot '../src/PSNetDrive.ps1') List 6>&1
            $output | Should -Not -BeNullOrEmpty
            $output -join "`n" | Should -Match 'Currently Connected Network Drives'
        }

        It 'Shows drive status' {
            $output = & (Join-Path $PSScriptRoot '../src/PSNetDrive.ps1') Status 6>&1
            $output | Should -Not -BeNullOrEmpty
            $output -join "`n" | Should -Match 'Network Drive Connection Status'
        }

        AfterAll {
            # Cleanup test .env
            Remove-Item (Join-Path $PSScriptRoot '../.env') -Force -ErrorAction SilentlyContinue
        }
    }
} 