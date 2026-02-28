---

title: Formalize ace-nav Protocol Source Discovery via Configuration Cascade
filename_suggestion: feat-nav-config-protocol-discovery
enhanced_at: 2026-01-22 21:45:52
location: backlog
llm_model: gflash
source: "taskflow:v.0.9.0"
---


# Formalize ace-nav Protocol Source Discovery via Configuration Cascade

## Problem
Protocol source definitions (e.g., for `wfi://` or `guide://`) are currently duplicated between the gem's distributed defaults (`ace-gem/.ace-defaults/nav/protocols/wfi-sources/*.yml`) and the project's active configuration (`.ace/nav/protocols/wfi-sources/*.yml`). This duplication violates the DRY principle and introduces ambiguity regarding the authoritative source, especially within the mono-repo development environment.

This pattern undermines the clarity of the Configuration Cascade (ADR-022), where `.ace-defaults/` should be the sole source of default definitions, and `.ace/` should only contain overrides or additions.

## Solution
Enhance the configuration loading mechanism within `ace-support-config` (used by `ace-nav`) to perform directory-level discovery for specific configuration sub-paths (like `nav/protocols/wfi-sources`). This ensures that all YAML files defining protocol sources are automatically aggregated from all cascade tiers (Gem Defaults, User, Project, CLI).

By implementing robust directory discovery, we can eliminate the need to copy the default protocol definition files from `ace-gem/.ace-defaults/` into the root `.ace/` directory. The definition provided by the installed gem's defaults will be automatically loaded and active.

## Implementation Approach
1. **Refactor `Ace::Support::Config` Organism:** Introduce a new method, perhaps `resolve_directory_namespace(namespace, subdirectory)`, which iterates through the four cascade tiers (Gem, User, Project, CLI) and collects all files matching the path pattern (e.g., `*/.ace-defaults/nav/protocols/wfi-sources/*.yml`).
2. **`ace-nav` Integration:** The `ace-nav` gem's protocol loading Molecule will utilize this new directory resolution method to build the complete list of available protocol sources.
3. **Cleanup:** Audit existing gems (like `ace-test` and `ace-docs`) to remove redundant protocol source definitions from the root `.ace/` directory, relying solely on the definitions in their respective `.ace-defaults/` folders.

## Considerations
- **Merge Strategy:** Since these are source definitions (not settings overrides), the files should be aggregated (concatenated or indexed by filename), not deep-merged like standard configuration settings.
- **Performance:** Directory scanning across multiple cascade paths must be optimized, potentially using caching mechanisms already present in `ace-support-core`.
- **CLI Interface Design:** This change is internal and should not affect the `ace-nav` CLI surface, maintaining Principle 3 (Same Tools, Same Experience).

## Benefits
- **Adherence to ADR-022:** Strictly enforces that `.ace-defaults/` is the source of truth for default definitions.
- **Reduced Duplication:** Eliminates redundant configuration files in the project root.
- **Simplified Gem Development:** New `ace-*` gems only need to define their protocol sources once in their `.ace-defaults/` directory to ensure they are discoverable by `ace-nav` upon installation.

---

## Original Idea

```
**Title**: ace-nav protocol configuration: .ace vs .ace-defaults duplication pattern

**Tags**: ace-nav,configuration,protocols,documentation

**Problem**: When gems register protocol sources (e.g., `guide://testing`), the configuration exists in both:
- `.ace/nav/protocols/*/gem-name.yml` (used in development/repo)
- `.ace-defaults/nav/protocols/*/gem-name.yml` (distributed with gem, used when installed)

This creates duplication and potential confusion about which source is authoritative.

**Current State**: We accept this duplication as intentional:
- `.ace/` = actual configuration used in this repo
- `.ace-defaults/` = distributed defaults/samples for the gem
- Both are needed for different scenarios

**Questions to Explore**:
1. Should ace-nav respect only one location?
2. If merged, which takes precedence?
3. Should protocol configs always be copied from .ace-defaults to .ace?
4. Or rename the concept to make this duality clearer?

**Context**: PR #173 (ace-test package creation) highlighted this pattern with protocol registration in both locations.
```
