# setup-crmsdk

[![CI](https://github.com/marcus-hooper/setup-crmsdk/actions/workflows/ci.yml/badge.svg)](https://github.com/marcus-hooper/setup-crmsdk/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/marcus-hooper/setup-crmsdk/graph/badge.svg)](https://codecov.io/gh/marcus-hooper/setup-crmsdk)
[![GitHub release](https://img.shields.io/github/v/release/marcus-hooper/setup-crmsdk)](https://github.com/marcus-hooper/setup-crmsdk/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PowerShell 5.1+](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://docs.microsoft.com/en-us/powershell/)
[![CodeQL](https://github.com/marcus-hooper/setup-crmsdk/actions/workflows/codeql.yml/badge.svg)](https://github.com/marcus-hooper/setup-crmsdk/actions/workflows/codeql.yml)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/marcus-hooper/setup-crmsdk/badge)](https://scorecard.dev/viewer/?uri=github.com/marcus-hooper/setup-crmsdk)
[![Security](https://github.com/marcus-hooper/setup-crmsdk/actions/workflows/security.yml/badge.svg)](https://github.com/marcus-hooper/setup-crmsdk/actions/workflows/security.yml)

A GitHub Action that installs Microsoft.CrmSdk.CoreTools and sets the `CRM_SDK_PATH` environment variable for use in CI/CD workflows.

## Features

- Installs the latest Microsoft.CrmSdk.CoreTools package
- Sets `CRM_SDK_PATH` environment variable for subsequent workflow steps
- Skips installation if SDK is already installed
- Automatic cleanup of temporary files

## Quick Start

```yaml
- name: Setup CRM SDK
  uses: marcus-hooper/setup-crmsdk@v1
```

## Usage

### Basic Usage

```yaml
- name: Setup CRM SDK
  id: crmsdk
  uses: marcus-hooper/setup-crmsdk@v1

- name: Run SolutionPackager
  run: |
    $solutionPackager = Join-Path $env:CRM_SDK_PATH "coretools\SolutionPackager.exe"
    & $solutionPackager /action:Extract /zipfile:solution.zip /folder:solution
  shell: powershell
```

### Using Outputs

```yaml
- name: Setup CRM SDK
  id: crmsdk
  uses: marcus-hooper/setup-crmsdk@v1

- name: Display SDK path
  run: echo "SDK installed at ${{ steps.crmsdk.outputs.sdk-path }}"
```

### Complete Workflow Example

Here's a complete workflow that extracts a Dynamics 365 solution:

```yaml
name: Extract Solution

on:
  push:
    branches: [main]

jobs:
  extract:
    name: Extract Solution
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v6

      - name: Setup CRM SDK
        id: crmsdk
        uses: marcus-hooper/setup-crmsdk@v1

      - name: Extract solution
        run: |
          $solutionPackager = Join-Path $env:CRM_SDK_PATH "coretools\SolutionPackager.exe"
          & $solutionPackager /action:Extract /zipfile:MySolution.zip /folder:./solution /packagetype:Both
        shell: powershell

      - name: Upload extracted solution
        uses: actions/upload-artifact@v6
        with:
          name: solution
          path: ./solution
```

## Outputs

| Output | Description |
|--------|-------------|
| `sdk-path` | Path to the installed CRM SDK directory |

## Environment Variables

This action sets the following environment variable:

| Variable | Description |
|----------|-------------|
| `CRM_SDK_PATH` | Path to the installed CRM SDK tools directory |

## What Gets Installed

The action installs the [Microsoft.CrmSdk.CoreTools](https://www.nuget.org/packages/Microsoft.CrmSdk.CoreTools) NuGet package. The tools are located in the `coretools` subdirectory under `CRM_SDK_PATH`:

- **SolutionPackager.exe** - Pack and unpack Dynamics 365 solution files
- **PackageDeployer.exe** - Deploy packages to Dynamics 365
- **CrmSvcUtil.exe** - Generate early-bound entity classes
- **PluginRegistration.exe** - Register plugins and custom workflow activities

Access tools using: `Join-Path $env:CRM_SDK_PATH "coretools\ToolName.exe"`

## Requirements

- Windows runner (`runs-on: windows-latest`)
- Internet access to download NuGet packages

## Limitations

- **Windows only** - Requires Windows runner; not compatible with Linux or macOS
- **Network required** - Downloads NuGet CLI and packages at runtime
- **Fixed install path** - Always installs to `$env:LOCALAPPDATA\Programs\`
- **No version pinning** - Always installs the latest Microsoft.CrmSdk.CoreTools

## How It Works

1. Checks if `CRM_SDK_PATH` is already set (skips installation if exists)
2. Creates installation directory at `$env:LOCALAPPDATA\Programs\`
3. Downloads NuGet CLI from `dist.nuget.org`
4. Installs `Microsoft.CrmSdk.CoreTools` package via NuGet
5. Locates `SolutionPackager.exe` and sets `CRM_SDK_PATH` to its directory
6. Exports the path to `GITHUB_ENV` for subsequent workflow steps
7. Cleans up the NuGet CLI

## Sample Output

When the action runs successfully, you'll see output similar to:

```
[INFO] Checking for existing CRM SDK installation...
[INFO] Downloading NuGet CLI...
[INFO] Installing Microsoft.CrmSdk.CoreTools...
[INFO] Package installed successfully
[INFO] Setting CRM_SDK_PATH to C:\Users\runneradmin\AppData\Local\Programs\Microsoft.CrmSdk.CoreTools.9.1.x\content\bin\coretools
[INFO] SDK installation complete
```

When the SDK is already installed:

```
[INFO] Checking for existing CRM SDK installation...
[INFO] CRM SDK is already installed at C:\Users\runneradmin\AppData\Local\Programs\Microsoft.CrmSdk.CoreTools.9.1.x\content\bin\coretools
[INFO] Skipping installation
```

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| `Unable to download NuGet` | Firewall or network restrictions | Ensure runner has access to `dist.nuget.org` |
| `Package not found` | NuGet.org unreachable | Check network connectivity and retry |
| `SolutionPackager.exe not found` | Package structure changed | Open an issue with the error details |
| Action completes but tools not available | `CRM_SDK_PATH` not in path | Use `$env:CRM_SDK_PATH` or the `sdk-path` output |
| Action skipped installation | SDK already installed | This is expected behavior; the action reuses existing installations |

### Debug Tips

1. **Check workflow logs** - Expand the "Setup CRM SDK" step for detailed output
2. **Verify environment variable** - Add a step to echo `$env:CRM_SDK_PATH`
3. **Check runner type** - This action only works on Windows runners
4. **Self-hosted runners** - Ensure write access to `$env:LOCALAPPDATA\Programs\`

## Development

### Requirements

- PowerShell 5.1+ (Windows)
- PSScriptAnalyzer (for linting)

### Local Testing

```powershell
# Run the script directly
.\scripts\Install-CrmSdk.ps1

# Check if environment variable was set
$env:CRM_SDK_PATH

# Verify SolutionPackager exists
Test-Path (Join-Path $env:CRM_SDK_PATH "coretools\SolutionPackager.exe")
```

### Linting

```powershell
# Install PSScriptAnalyzer if needed
Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser

# Run linter
Invoke-ScriptAnalyzer -Path ./scripts -Recurse -Settings PSGallery
```

### Formatting

```powershell
# Check formatting (CI runs this automatically)
Get-ChildItem -Path ./scripts -Include *.ps1,*.psm1 -Recurse | ForEach-Object {
    $original = Get-Content -Path $_.FullName -Raw
    $formatted = Invoke-Formatter -ScriptDefinition $original
    if ($original -ne $formatted) {
        Write-Host "Needs formatting: $($_.Name)"
    }
}

# Auto-format a file
$content = Get-Content -Path ./scripts/Install-CrmSdk.ps1 -Raw
Invoke-Formatter -ScriptDefinition $content | Set-Content -Path ./scripts/Install-CrmSdk.ps1
```

### Running Tests

```powershell
# Run Pester tests
Invoke-Pester -Path ./tests -Output Detailed
```

## Project Structure

```
setup-crmsdk/
├── action.yml                  # GitHub Action definition (composite action)
├── scripts/
│   ├── Install-CrmSdk.ps1      # Entry point script
│   └── Install-CrmSdk.psm1     # PowerShell module with testable functions
├── tests/                      # Pester unit tests
├── .github/
│   ├── ISSUE_TEMPLATE/         # Bug report and feature request forms
│   └── workflows/              # CI, CodeQL, security, release workflows
├── CHANGELOG.md                # Version history
├── CONTRIBUTING.md             # Contribution guidelines
└── SECURITY.md                 # Security policy
```

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

Quick start:

1. Check existing [issues](https://github.com/marcus-hooper/setup-crmsdk/issues) or open a new one
2. Fork the repository
3. Create a feature branch (`git checkout -b feature/my-feature`)
4. Make your changes and add tests if applicable
5. Ensure CI passes (lint, format, and test)
6. Submit a pull request

See the issue templates for [bug reports](.github/ISSUE_TEMPLATE/bug_report.yml) and [feature requests](.github/ISSUE_TEMPLATE/feature_request.yml).

## Related Projects

- [Microsoft.CrmSdk.CoreTools](https://www.nuget.org/packages/Microsoft.CrmSdk.CoreTools) - The NuGet package this action installs
- [Microsoft Power Platform CLI](https://learn.microsoft.com/en-us/power-platform/developer/cli/introduction) - Modern CLI alternative (pac CLI)
- [Power Platform Actions](https://github.com/microsoft/powerplatform-actions) - Official Microsoft GitHub Actions for Power Platform

## Security

See [SECURITY.md](SECURITY.md) for security policy and reporting vulnerabilities.

## License

MIT License - see [LICENSE](LICENSE) for details.
