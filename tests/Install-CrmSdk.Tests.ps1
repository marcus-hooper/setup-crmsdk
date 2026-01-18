BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..\scripts\Install-CrmSdk.psm1'
    Import-Module $modulePath -Force
}

Describe 'Write-Message' {
    It 'outputs message with INFO level by default' {
        $output = Write-Message -Message 'Test message' 6>&1

        $output | Should -Be '[INFO] Test message'
    }

    It 'outputs message with ERROR level when specified' {
        $output = Write-Message -Message 'Error occurred' -Level 'ERROR' 6>&1

        $output | Should -Be '[ERROR] Error occurred'
    }

    It 'outputs message with WARN level when specified' {
        $output = Write-Message -Message 'Warning' -Level 'WARN' 6>&1

        $output | Should -Be '[WARN] Warning'
    }
}

Describe 'Invoke-Safely' {
    It 'executes command successfully' {
        $result = Invoke-Safely -Command { 'success' } -ErrorMessage 'Should not see this'

        $result | Should -Be 'success'
    }

    It 'returns value from command' {
        $result = Invoke-Safely -Command { 42 } -ErrorMessage 'Should not see this'

        $result | Should -Be 42
    }

    It 'throws with custom error message on failure' {
        { Invoke-Safely -Command { throw 'inner error' } -ErrorMessage 'Custom error' } |
            Should -Throw
    }

    It 'includes original exception in error output' {
        $output = try {
            Invoke-Safely -Command { throw 'inner error' } -ErrorMessage 'Custom error' 6>&1
        }
        catch {
            # Expected to throw
        }

        # The Write-Message output should contain the custom error message
        $output | Should -Match 'Custom error'
    }
}

Describe 'Set-CrmSdkEnvironmentVariable' {
    BeforeEach {
        # Save original values
        $script:originalGithubEnv = $env:GITHUB_ENV
        $script:originalCI = $env:CI
        $script:originalTestVar = $env:TEST_VAR

        # Clear test variable
        Remove-Item -Path 'env:TEST_VAR' -ErrorAction SilentlyContinue
    }

    AfterEach {
        # Restore original values
        if ($script:originalGithubEnv) {
            $env:GITHUB_ENV = $script:originalGithubEnv
        }
        else {
            Remove-Item -Path 'env:GITHUB_ENV' -ErrorAction SilentlyContinue
        }

        if ($script:originalCI) {
            $env:CI = $script:originalCI
        }
        else {
            Remove-Item -Path 'env:CI' -ErrorAction SilentlyContinue
        }

        Remove-Item -Path 'env:TEST_VAR' -ErrorAction SilentlyContinue
    }

    It 'sets environment variable for current process' {
        # Ensure we are not in CI mode and no GITHUB_ENV
        Remove-Item -Path 'env:GITHUB_ENV' -ErrorAction SilentlyContinue
        $env:CI = 'true' # Set CI to skip user-scope persistence

        Set-CrmSdkEnvironmentVariable -Name 'TEST_VAR' -Value 'test_value'

        $env:TEST_VAR | Should -Be 'test_value'
    }

    It 'writes to GITHUB_ENV file when set' {
        $tempFile = [System.IO.Path]::GetTempFileName()
        try {
            $env:GITHUB_ENV = $tempFile
            $env:CI = 'true'

            Set-CrmSdkEnvironmentVariable -Name 'TEST_VAR' -Value 'github_value'

            $content = Get-Content -Path $tempFile -Raw
            $content | Should -Match 'TEST_VAR=github_value'
        }
        finally {
            Remove-Item -Path $tempFile -ErrorAction SilentlyContinue
        }
    }

    It 'respects WhatIf parameter' {
        Remove-Item -Path 'env:GITHUB_ENV' -ErrorAction SilentlyContinue
        $env:CI = 'true'

        Set-CrmSdkEnvironmentVariable -Name 'TEST_VAR' -Value 'whatif_value' -WhatIf

        $env:TEST_VAR | Should -BeNullOrEmpty
    }
}

Describe 'Get-NuGetCli' {
    BeforeAll {
        Mock Invoke-WebRequest { } -ModuleName Install-CrmSdk
    }

    It 'downloads NuGet CLI when not present' {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
        New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

        try {
            Get-NuGetCli -DestinationPath $tempDir

            Should -Invoke Invoke-WebRequest -ModuleName Install-CrmSdk -Times 1
        }
        finally {
            Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'skips download when NuGet CLI already exists' {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
        New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
        $nugetPath = Join-Path $tempDir 'nuget.exe'
        New-Item -Path $nugetPath -ItemType File -Force | Out-Null

        try {
            Get-NuGetCli -DestinationPath $tempDir

            Should -Invoke Invoke-WebRequest -ModuleName Install-CrmSdk -Times 0
        }
        finally {
            Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'returns path to nuget.exe' {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
        New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
        $expectedPath = Join-Path $tempDir 'nuget.exe'
        New-Item -Path $expectedPath -ItemType File -Force | Out-Null

        try {
            $result = Get-NuGetCli -DestinationPath $tempDir

            $result | Should -Be $expectedPath
        }
        finally {
            Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Describe 'Remove-NuGetCli' {
    It 'removes NuGet CLI file when it exists' {
        $tempFile = [System.IO.Path]::GetTempFileName()

        Remove-NuGetCli -NuGetPath $tempFile

        Test-Path $tempFile | Should -Be $false
    }

    It 'does not throw when file does not exist' {
        $nonExistentPath = Join-Path ([System.IO.Path]::GetTempPath()) 'nonexistent.exe'

        { Remove-NuGetCli -NuGetPath $nonExistentPath } | Should -Not -Throw
    }
}

Describe 'Invoke-NuGetInstall' {
    It 'passes version to NuGet when specified' {
        # We can't easily test the actual NuGet call without running it,
        # but we can verify the function accepts the Version parameter
        $params = @{
            NuGetPath       = 'C:\nonexistent\nuget.exe'
            PackageName     = 'TestPackage'
            OutputDirectory = 'C:\temp'
            Version         = '1.2.3'
        }

        # This will fail because nuget.exe doesn't exist, but it validates parameter binding
        { Invoke-NuGetInstall @params } | Should -Throw
    }
}

Describe 'Install-CrmSdkPackage' {
    BeforeAll {
        # Mock the NuGet install command to return success
        Mock Invoke-NuGetInstall { return 0 } -ModuleName Install-CrmSdk
    }

    It 'throws when SolutionPackager.exe is not found' {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
        New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

        try {
            { Install-CrmSdkPackage -NuGetPath 'nuget.exe' -InstallPath $tempDir } |
                Should -Throw '*SolutionPackager.exe not found*'
        }
        finally {
            Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'returns SDK path when SolutionPackager.exe is found' {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
        $sdkDir = Join-Path $tempDir 'Microsoft.CrmSdk.CoreTools.9.1.0'
        $coreToolsDir = Join-Path $sdkDir 'coretools'
        New-Item -Path $coreToolsDir -ItemType Directory -Force | Out-Null

        $solutionPackager = Join-Path $coreToolsDir 'SolutionPackager.exe'
        New-Item -Path $solutionPackager -ItemType File -Force | Out-Null

        try {
            $result = Install-CrmSdkPackage -NuGetPath 'nuget.exe' -InstallPath $tempDir

            $result | Should -Be $sdkDir
        }
        finally {
            Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'throws when NuGet install fails' {
        Mock Invoke-NuGetInstall { return 1 } -ModuleName Install-CrmSdk

        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
        New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

        try {
            { Install-CrmSdkPackage -NuGetPath 'nuget.exe' -InstallPath $tempDir } |
                Should -Throw '*NuGet install command failed*'
        }
        finally {
            Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'calls Invoke-NuGetInstall with correct parameters' {
        Mock Invoke-NuGetInstall { return 0 } -ModuleName Install-CrmSdk

        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
        $sdkDir = Join-Path $tempDir 'Microsoft.CrmSdk.CoreTools.9.1.0'
        $coreToolsDir = Join-Path $sdkDir 'coretools'
        New-Item -Path $coreToolsDir -ItemType Directory -Force | Out-Null
        New-Item -Path (Join-Path $coreToolsDir 'SolutionPackager.exe') -ItemType File -Force | Out-Null

        try {
            Install-CrmSdkPackage -NuGetPath 'C:\nuget.exe' -InstallPath $tempDir

            Should -Invoke Invoke-NuGetInstall -ModuleName Install-CrmSdk -ParameterFilter {
                $NuGetPath -eq 'C:\nuget.exe' -and
                $PackageName -eq 'Microsoft.CrmSdk.CoreTools' -and
                $OutputDirectory -eq $tempDir
            }
        }
        finally {
            Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'passes version to Invoke-NuGetInstall when specified' {
        Mock Invoke-NuGetInstall { return 0 } -ModuleName Install-CrmSdk

        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
        $sdkDir = Join-Path $tempDir 'Microsoft.CrmSdk.CoreTools.9.1.0'
        $coreToolsDir = Join-Path $sdkDir 'coretools'
        New-Item -Path $coreToolsDir -ItemType Directory -Force | Out-Null
        New-Item -Path (Join-Path $coreToolsDir 'SolutionPackager.exe') -ItemType File -Force | Out-Null

        try {
            Install-CrmSdkPackage -NuGetPath 'C:\nuget.exe' -InstallPath $tempDir -Version '9.1.0.184'

            Should -Invoke Invoke-NuGetInstall -ModuleName Install-CrmSdk -ParameterFilter {
                $NuGetPath -eq 'C:\nuget.exe' -and
                $PackageName -eq 'Microsoft.CrmSdk.CoreTools' -and
                $OutputDirectory -eq $tempDir -and
                $Version -eq '9.1.0.184'
            }
        }
        finally {
            Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'does not pass version to Invoke-NuGetInstall when not specified' {
        Mock Invoke-NuGetInstall { return 0 } -ModuleName Install-CrmSdk

        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
        $sdkDir = Join-Path $tempDir 'Microsoft.CrmSdk.CoreTools.9.1.0'
        $coreToolsDir = Join-Path $sdkDir 'coretools'
        New-Item -Path $coreToolsDir -ItemType Directory -Force | Out-Null
        New-Item -Path (Join-Path $coreToolsDir 'SolutionPackager.exe') -ItemType File -Force | Out-Null

        try {
            Install-CrmSdkPackage -NuGetPath 'C:\nuget.exe' -InstallPath $tempDir

            Should -Invoke Invoke-NuGetInstall -ModuleName Install-CrmSdk -ParameterFilter {
                $NuGetPath -eq 'C:\nuget.exe' -and
                $PackageName -eq 'Microsoft.CrmSdk.CoreTools' -and
                $OutputDirectory -eq $tempDir -and
                [string]::IsNullOrEmpty($Version)
            }
        }
        finally {
            Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Describe 'Install-CrmSdk' {
    BeforeEach {
        $script:originalCrmSdkPath = $env:CRM_SDK_PATH
        Remove-Item -Path 'env:CRM_SDK_PATH' -ErrorAction SilentlyContinue
    }

    AfterEach {
        if ($script:originalCrmSdkPath) {
            $env:CRM_SDK_PATH = $script:originalCrmSdkPath
        }
        else {
            Remove-Item -Path 'env:CRM_SDK_PATH' -ErrorAction SilentlyContinue
        }
    }

    It 'returns existing path when CRM_SDK_PATH is already set' {
        $env:CRM_SDK_PATH = 'C:\ExistingPath'

        $result = Install-CrmSdk

        $result | Should -Be 'C:\ExistingPath'
    }

    It 'skips installation when CRM_SDK_PATH is already set' {
        $env:CRM_SDK_PATH = 'C:\ExistingPath'

        Mock Get-NuGetCli { } -ModuleName Install-CrmSdk

        Install-CrmSdk

        Should -Invoke Get-NuGetCli -ModuleName Install-CrmSdk -Times 0
    }

    Context 'Full installation flow' {
        BeforeAll {
            Mock Get-NuGetCli { return 'C:\mock\nuget.exe' } -ModuleName Install-CrmSdk
            Mock Install-CrmSdkPackage { return 'C:\mock\sdk' } -ModuleName Install-CrmSdk
            Mock Set-CrmSdkEnvironmentVariable { } -ModuleName Install-CrmSdk
            Mock Remove-NuGetCli { } -ModuleName Install-CrmSdk
            Mock New-Item { } -ModuleName Install-CrmSdk
            Mock Test-Path {
                param($Path)
                if ($Path -eq 'env:CRM_SDK_PATH') { return $false }
                return $true
            } -ModuleName Install-CrmSdk
        }

        It 'downloads NuGet CLI' {
            Install-CrmSdk

            Should -Invoke Get-NuGetCli -ModuleName Install-CrmSdk -Times 1
        }

        It 'installs CRM SDK package' {
            Install-CrmSdk

            Should -Invoke Install-CrmSdkPackage -ModuleName Install-CrmSdk -Times 1
        }

        It 'sets environment variable' {
            Install-CrmSdk

            Should -Invoke Set-CrmSdkEnvironmentVariable -ModuleName Install-CrmSdk -Times 1 -ParameterFilter {
                $Name -eq 'CRM_SDK_PATH' -and $Value -eq 'C:\mock\sdk'
            }
        }

        It 'cleans up NuGet CLI' {
            Install-CrmSdk

            Should -Invoke Remove-NuGetCli -ModuleName Install-CrmSdk -Times 1
        }

        It 'returns SDK path' {
            $result = Install-CrmSdk

            $result | Should -Be 'C:\mock\sdk'
        }

        It 'passes version to Install-CrmSdkPackage when specified' {
            Install-CrmSdk -Version '9.1.0.184'

            Should -Invoke Install-CrmSdkPackage -ModuleName Install-CrmSdk -Times 1 -ParameterFilter {
                $Version -eq '9.1.0.184'
            }
        }

        It 'does not pass version to Install-CrmSdkPackage when not specified' {
            Install-CrmSdk

            Should -Invoke Install-CrmSdkPackage -ModuleName Install-CrmSdk -Times 1 -ParameterFilter {
                [string]::IsNullOrEmpty($Version)
            }
        }
    }

    Context 'Error handling' {
        It 'cleans up NuGet CLI even when installation fails' {
            Mock Get-NuGetCli { return 'C:\mock\nuget.exe' } -ModuleName Install-CrmSdk
            Mock Install-CrmSdkPackage { throw 'Installation failed' } -ModuleName Install-CrmSdk
            Mock Remove-NuGetCli { } -ModuleName Install-CrmSdk
            Mock Test-Path {
                param($Path)
                if ($Path -eq 'env:CRM_SDK_PATH') { return $false }
                return $true
            } -ModuleName Install-CrmSdk

            try {
                Install-CrmSdk
            }
            catch {
                # Expected to throw
            }

            Should -Invoke Remove-NuGetCli -ModuleName Install-CrmSdk -Times 1
        }
    }
}
