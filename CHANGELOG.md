# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- CHANGELOG.md for tracking version history
- Format check job in CI workflow
- Pester unit tests with code coverage
- Codecov integration for coverage reporting

### Changed
- Updated actions/checkout from v4 to v6
- Updated github/codeql-action from v3 to v4
- Updated ossf/scorecard-action from 2.4.0 to 2.4.3

### Fixed
- SolutionPackager.exe path in CI test to use coretools subdirectory

## [1.0.0] - 2024-01-01

### Added
- Initial release
- PowerShell script to install Microsoft.CrmSdk.CoreTools
- GitHub Action composite action definition
- Automatic `CRM_SDK_PATH` environment variable setup
- CI workflow with PSScriptAnalyzer linting
- Integration tests on Windows runner
