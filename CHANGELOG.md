# Changelog

All notable changes to setup-crmsdk are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Dependency review configuration file with license allow-list
- New issue labels: `type:test`, `priority:critical`, `status:needs-design`, `status:in-progress`, `area:powershell`, `area:action`, `area:ci`
- Security vulnerability reporting link in issue template config
- CODEOWNERS validation in validate workflow
- Checksum verification for action-validator binary download
- Notify-failure job in schedule workflow (auto-creates issues on failure)
- Test artifact upload in schedule workflow health checks
- Quick CI script in CONTRIBUTING.md
- Breaking change documentation in CONTRIBUTING.md

### Changed

- Consolidated lint and format-check into single `lint-and-format` job
- Updated action version comments for clarity (v6 → v6.0.1, v4 → v4.7.1)
- Simplified PowerShell file iteration in format check
- CI workflow now ignores issue template changes
- Expanded commit message prefixes in CONTRIBUTING.md (added `ci:`, `deps:`, `security:`, `perf:`)

### Security

- Enhanced harden-runner in security workflow (changed from audit to block mode)
- Added harden-runner to schedule workflow
- Checksum verification for downloaded binaries in validate workflow

## [1.1.0] - 2026-01-17

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

- NuGet exit code capture in Install-CrmSdk module (was capturing stdout instead of exit code)
- Code coverage configuration to include Install-CrmSdk.psm1 module
- Label sync action SHA reference (was invalid)
- SolutionPackager.exe path in CI test to use coretools subdirectory

### Security

- Codecov upload egress policy (added storage.googleapis.com)
- Release workflow egress policy (added api.github.com)

## [1.0.0] - 2024-01-01

### Added

- Initial release
- PowerShell script to install Microsoft.CrmSdk.CoreTools
- GitHub Action composite action definition
- Automatic `CRM_SDK_PATH` environment variable setup
- CI workflow with PSScriptAnalyzer linting
- Integration tests on Windows runner

---

<!--
## [X.Y.Z] - YYYY-MM-DD

### Added
- New features

### Changed
- Changes to existing functionality
- **BREAKING**: Description of breaking change

### Deprecated
- Features to be removed in future versions

### Removed
- Removed features

### Fixed
- Bug fixes

### Security
- Security improvements or vulnerability fixes
-->

[Unreleased]: https://github.com/marcus-hooper/setup-crmsdk/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/marcus-hooper/setup-crmsdk/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/marcus-hooper/setup-crmsdk/releases/tag/v1.0.0
