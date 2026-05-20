# TODOS

## P2: pac CLI Support

**What:** Add a `tool` input to action.yml (`coretools` | `pac`) to install either CrmSdk.CoreTools or the Power Platform CLI.

**Why:** Microsoft's pac CLI is the modern replacement for CrmSdk.CoreTools. Adding it positions setup-crmsdk as the single Dynamics 365 CI tooling action -- a platform, not just an installer.

**Pros:** Future-proofs the action, serves both legacy and modern users, strategic platform play.

**Cons:** Significantly expands scope, different install mechanism (dotnet tool vs NuGet), may require action rename to `setup-dynamics365-tools`.

**Context:** pac CLI installs via `dotnet tool install` or MSI. Different verification (`pac --version` vs SolutionPackager.exe existence). Would need separate cache keys. The foundation work in v1.3.0 (caching, retry, outputs) makes this easier to implement.

**Effort:** L (human: ~1 week) -> M (CC: ~30 min)

**Depends on:** v1.3.0 shipped (caching/hardening foundation)

**Source:** CEO Plan Review 2026-03-18
