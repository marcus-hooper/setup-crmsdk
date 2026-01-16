# setup-crmsdk

[![CI](https://github.com/marcus-hooper/setup-crmsdk/actions/workflows/ci.yml/badge.svg)](https://github.com/marcus-hooper/setup-crmsdk/actions/workflows/ci.yml)
[![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/marcus-hooper/setup-crmsdk/badge)](https://securityscorecards.dev/viewer/?uri=github.com/marcus-hooper/setup-crmsdk)

A GitHub Action that installs Microsoft.CrmSdk.CoreTools and sets the `CRM_SDK_PATH` environment variable for use in CI/CD workflows.

## Features

- Installs the latest Microsoft.CrmSdk.CoreTools package
- Sets `CRM_SDK_PATH` environment variable for subsequent workflow steps
- Skips installation if SDK is already installed
- Automatic cleanup of temporary files

## Usage

```yaml
- name: Setup CRM SDK
  id: crmsdk
  uses: marcus-hooper/setup-crmsdk@main

- name: Run SolutionPackager
  run: |
    $solutionPackager = Join-Path $env:CRM_SDK_PATH "tools\SolutionPackager.exe"
    & $solutionPackager /action:Extract /zipfile:solution.zip /folder:solution
  shell: powershell
```

## Outputs

| Output | Description |
|--------|-------------|
| `sdk-path` | Path to the installed CRM SDK directory |

### Using Outputs

```yaml
- name: Setup CRM SDK
  id: crmsdk
  uses: marcus-hooper/setup-crmsdk@main

- name: Display SDK path
  run: echo "SDK installed at ${{ steps.crmsdk.outputs.sdk-path }}"
```

## Environment Variables

This action sets the following environment variable:

| Variable | Description |
|----------|-------------|
| `CRM_SDK_PATH` | Path to the installed CRM SDK tools directory |

## What Gets Installed

The action installs the [Microsoft.CrmSdk.CoreTools](https://www.nuget.org/packages/Microsoft.CrmSdk.CoreTools) NuGet package, which includes:

- **SolutionPackager.exe** - Pack and unpack Dynamics 365 solution files
- **PackageDeployer.exe** - Deploy packages to Dynamics 365
- **CrmSvcUtil.exe** - Generate early-bound entity classes
- **PluginRegistration.exe** - Register plugins and custom workflow activities

## Requirements

- Windows runner (`runs-on: windows-latest`)
- Internet access to download NuGet packages

## License

MIT License - see [LICENSE](LICENSE) for details.
