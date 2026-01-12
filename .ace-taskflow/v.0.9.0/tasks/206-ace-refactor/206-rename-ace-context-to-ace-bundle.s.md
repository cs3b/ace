---
id: v.0.9.0+task.206
status: pending
priority: high
estimate: 8h
dependencies: []
---

# Rename ace-context to ace-bundle

## Behavioral Specification

### User Experience

- **Input**: Developers and agents use `ace-bundle` command (was `ace-context`) to load project context, presets, and workflows
- **Process**: All existing functionality works identically - preset loading, wfi:// protocol, chunked output, caching
- **Output**: Same output formats (stdout, cached files, chunked files) with updated paths (`.cache/ace-bundle/` instead of `.cache/ace-context/`)

### Expected Behavior

The rename should be transparent to users after migration:

1. **CLI Tool**: `ace-bundle` replaces `ace-context` with identical behavior
   - `ace-bundle project` loads project context
   - `ace-bundle wfi://workflow` resolves workflow protocols
   - `ace-bundle --list` shows available presets
   - All flags and options work identically

2. **Ruby API**: `Ace::Bundle` module replaces `Ace::Context`
   - `require 'ace/bundle'` instead of `require 'ace/context'`
   - All public interfaces unchanged
   - Dependent gems (ace-prompt, ace-review, ace-docs) updated

3. **Configuration**: `.ace/bundle/` replaces `.ace/context/`
   - Preset files in `.ace/bundle/presets/`
   - Config files follow same structure
   - `.ace-defaults/bundle/` for gem defaults

4. **Cache Directory**: `.cache/ace-bundle/` replaces `.cache/ace-context/`
   - Chunked output files use new directory
   - No migration of cached data needed (ephemeral)

### Interface Contract

```bash
# CLI Interface (unchanged behavior, new name)
ace-bundle [preset]              # Load preset (default: project)
ace-bundle wfi://workflow-name   # Load workflow via protocol
ace-bundle --list                # List available presets
ace-bundle --embed-source        # Include source document inline
ace-bundle --output stdio|cache  # Control output destination

# Ruby API (unchanged interface, new namespace)
require 'ace/bundle'

loader = Ace::Bundle::Organisms::ContextLoader.new
result = loader.load(preset: 'project')

# Configuration cascade (unchanged pattern, new paths)
# .ace-defaults/bundle/config.yml  (gem defaults)
# ~/.ace/bundle/config.yml         (user overrides)
# .ace/bundle/config.yml           (project overrides)
```

**Error Handling:**
- Invalid preset: Same error messages with new gem name reference
- Protocol resolution failure: Same behavior via ace-nav integration
- File not found: Same error handling

**Edge Cases:**
- Empty preset: Falls back to 'project' preset (unchanged)
- Large output: Chunking behavior unchanged (uses new cache path)
- wfi:// protocol: Works via ace-nav (unchanged integration)

### Success Criteria

- [ ] **CLI Parity**: `ace-bundle` command works identically to former `ace-context`
- [ ] **API Compatibility**: All public interfaces work with new `Ace::Bundle` namespace
- [ ] **Dependent Gems Updated**: ace-prompt, ace-review, ace-docs require `ace/bundle`
- [ ] **Documentation Updated**: README, CLAUDE.md, docs/*.md reference `ace-bundle`
- [ ] **Skills Updated**: All .claude/skills/ references updated
- [ ] **Tests Pass**: All ace-bundle tests pass (renamed from ace-context tests)
- [ ] **No Backward Compatibility**: Clean break - no aliases or deprecation warnings needed

### Validation Questions

- [x] **Naming Clarity**: "bundle" better describes aggregating multiple sources (files, commands, diffs, presets)
- [x] **Scope Confirmation**: No backward compatibility needed - single migration, no deprecation period
- [x] **Archive Exclusion**: No need to update archived tasks/docs in `.ace-taskflow/_archive/`

## Objective

Rename `ace-context` to `ace-bundle` to better reflect its purpose: bundling multiple content sources (files, commands, diffs, presets) into aggregated context. The current name "context" is generic; "bundle" describes the aggregation behavior more precisely.

## Scope of Work

**In Scope:**
- Package rename: `ace-context/` directory to `ace-bundle/`
- Module namespace: `Ace::Context` to `Ace::Bundle`
- CLI executable: `ace-context` to `ace-bundle`
- Configuration paths: `.ace/context/` to `.ace/bundle/`
- Cache paths: `.cache/ace-context/` to `.cache/ace-bundle/`
- Gemspec and dependencies in dependent gems
- Documentation and skills references
- Tests and test helpers

**Out of Scope:**
- Archived content in `.ace-taskflow/_archive/`
- Backward compatibility aliases
- Migration tooling for external users
- CHANGELOG entries for old ace-context versions

## Research Findings

### Dependency Graph (Reverse)

```
ace-bundle (was ace-context)
├── ace-prompt (depends on ~0.8)
├── ace-review (depends on ~0.9)
└── ace-docs (soft dependency via optional require)
```

### File Count Analysis

| Category | File Count | Notes |
|----------|------------|-------|
| Package internal (lib/) | ~20 files | Module/class renames |
| Package tests | ~20 files | Test renames |
| External requires | 8 files | ace-prompt, ace-review, ace-docs |
| Gemspecs | 3 files | ace-prompt, ace-review, root Gemfile |
| Config files | 4 files | .ace-defaults/, .ace/ |
| Documentation | 8+ primary | README, CLAUDE.md, docs/*.md |
| Skills | 9 files | .claude/skills/ references |
| Executables | 2 files | bin/, exe/ |

### Pattern Replacements Required

| Old Pattern | New Pattern | Scope |
|-------------|-------------|-------|
| `ace-context` | `ace-bundle` | Package name, paths, CLI |
| `Ace::Context` | `Ace::Bundle` | Ruby namespace |
| `require 'ace/context'` | `require 'ace/bundle'` | All requires |
| `.cache/ace-context` | `.cache/ace-bundle` | Config defaults |
| `.ace/context` | `.ace/bundle` | Config directories |

## Implementation Plan

### Planning Steps

* [x] Research all file locations requiring changes
* [x] Identify dependent gems and their require statements
* [x] Map configuration file locations
* [x] Count skill file references (66 files)

### Execution Steps

#### Phase 1: Package Rename (Core)

- [ ] **1.1** Rename directory: `mv ace-context ace-bundle`
- [ ] **1.2** Rename gemspec: `ace-context.gemspec` → `ace-bundle.gemspec`
- [ ] **1.3** Update gemspec contents:
  - `spec.name = "ace-bundle"`
  - `spec.require_paths = ["lib"]`
  - Update description
- [ ] **1.4** Rename executable: `exe/ace-context` → `exe/ace-bundle`
- [ ] **1.5** Update executable requires to `ace/bundle`

#### Phase 2: Ruby Module Namespace

- [ ] **2.1** Rename lib directory: `lib/ace/context/` → `lib/ace/bundle/`
- [ ] **2.2** Rename main module file: `lib/ace/context.rb` → `lib/ace/bundle.rb`
- [ ] **2.3** Update module declarations in all 20 lib files:
  - `module Ace::Context` → `module Ace::Bundle`
  - Update all internal requires
- [ ] **2.4** Update version file: `lib/ace/bundle/version.rb`
  - `module Ace::Bundle::VERSION`

#### Phase 3: Configuration Files

- [ ] **3.1** Rename gem defaults: `.ace-defaults/context/` → `.ace-defaults/bundle/`
- [ ] **3.2** Update nav source file: `.ace-defaults/nav/protocols/wfi-sources/ace-context.yml` → `ace-bundle.yml`
- [ ] **3.3** Rename project config: `.ace/context/` → `.ace/bundle/`
- [ ] **3.4** Update config.yml cache path references: `ace-context` → `ace-bundle`

#### Phase 4: Test Files

- [ ] **4.1** Update test_helper.rb: `require "ace/bundle"`
- [ ] **4.2** Update all 25 test files with new requires:
  - `require "ace/context/..."` → `require "ace/bundle/..."`
  - `Ace::Context::` → `Ace::Bundle::`
- [ ] **4.3** Run `ace-test ace-bundle` to verify all tests pass

#### Phase 5: Dependent Gems

- [ ] **5.1** Update ace-prompt gemspec dependency:
  - `ace-prompt/ace-prompt.gemspec`: `"ace-context"` → `"ace-bundle"`
- [ ] **5.2** Update ace-prompt requires (2 files):
  - `lib/ace/prompt/molecules/context_loader.rb`
  - `lib/ace/prompt/organisms/enhancement_session_manager.rb`
- [ ] **5.3** Update ace-prompt test requires (4 occurrences)
- [ ] **5.4** Update ace-review gemspec dependency:
  - `ace-review/ace-review.gemspec`: `"ace-context"` → `"ace-bundle"`
- [ ] **5.5** Update ace-review requires (4 files):
  - `lib/ace/review.rb`
  - `lib/ace/review/molecules/context_composer.rb`
  - `lib/ace/review/molecules/context_extractor.rb`
  - `lib/ace/review/organisms/review_manager.rb`
- [ ] **5.6** Update ace-docs requires (2 files):
  - `lib/ace/docs/prompts/consistency_prompt.rb`
  - `lib/ace/docs/prompts/document_analysis_prompt.rb`
- [ ] **5.7** Run tests for dependent gems:
  ```bash
  ace-test ace-prompt && ace-test ace-review && ace-test ace-docs
  ```

#### Phase 6: Root Gemfile and Binstub

- [ ] **6.1** Update root `Gemfile`: `gem "ace-context"` → `gem "ace-bundle"`
- [ ] **6.2** Rename binstub: `bin/ace-context` → `bin/ace-bundle`
- [ ] **6.3** Update binstub path references
- [ ] **6.4** Run `bundle install` to update lockfile

#### Phase 7: Skills (66 files)

- [ ] **7.1** Batch update all skill files:
  ```bash
  # Update allowed-tools references
  sed -i '' 's/Bash(ace-context:\*)/Bash(ace-bundle:*)/g' .claude/skills/*/SKILL.md

  # Update workflow invocations
  sed -i '' 's/ace-context wfi:/ace-bundle wfi:/g' .claude/skills/*/SKILL.md

  # Update source references
  sed -i '' 's/source: ace-context/source: ace-bundle/g' .claude/skills/*/SKILL.md
  ```
- [ ] **7.2** Verify skill updates with grep

#### Phase 8: Documentation

- [ ] **8.1** Update `README.md` references
- [ ] **8.2** Update `CLAUDE.md` references (multiple sections)
- [ ] **8.3** Update `docs/tools.md`
- [ ] **8.4** Update `docs/architecture.md`
- [ ] **8.5** Update `docs/vision.md`
- [ ] **8.6** Update `docs/ace-gems.g.md`
- [ ] **8.7** Update `docs/command-reference.md`
- [ ] **8.8** Update `ace-bundle/README.md` (package readme)
- [ ] **8.9** Update `ace-bundle/CHANGELOG.md` with rename note

#### Phase 9: CI/CD

- [ ] **9.1** Update `.github/workflows/test.yml` package list
- [ ] **9.2** Update `.ace/test/suite.yml` if present

#### Phase 10: Verification

- [ ] **10.1** Run full test suite: `ace-test-suite`
- [ ] **10.2** Verify CLI works: `ace-bundle project`
- [ ] **10.3** Verify wfi:// protocol: `ace-bundle wfi://commit`
- [ ] **10.4** Verify dependent gems work:
  ```bash
  ace-review --preset pr --dry-run
  ace-prompt --help
  ```
- [ ] **10.5** Clean up old cache: `rm -rf .cache/ace-context`

### Risk Assessment

#### Technical Risks

- **Risk:** Missed references cause runtime errors
  - **Probability:** Medium
  - **Impact:** High
  - **Mitigation:** Systematic grep verification after each phase
  - **Rollback:** Git revert to pre-rename commit

- **Risk:** CI failures due to path mismatches
  - **Probability:** Low
  - **Impact:** Medium
  - **Mitigation:** Update CI config in dedicated phase

#### Integration Risks

- **Risk:** Dependent gems fail to load ace-bundle
  - **Probability:** Low
  - **Impact:** High
  - **Mitigation:** Test each dependent gem individually
  - **Monitoring:** Run ace-test for each package

## Acceptance Criteria

- [ ] `ace-bundle` command works identically to former `ace-context`
- [ ] All 266 `Ace::Context` references updated to `Ace::Bundle`
- [ ] All 764 `ace-context` references updated (excluding archive)
- [ ] All dependent gems (ace-prompt, ace-review, ace-docs) work correctly
- [ ] All 66 skill files updated
- [ ] Full test suite passes (`ace-test-suite`)
- [ ] No references to old name remain in active codebase

## Out of Scope

- ❌ Archive content in `.ace-taskflow/_archive/`
- ❌ Backward compatibility aliases or deprecation warnings
- ❌ External documentation or migration guides
- ❌ Old CHANGELOG entries

## References

- Research conducted via codebase exploration
- ace-search analysis: 764 occurrences of "ace-context", 266 of "Ace::Context"
- Similar rename patterns from Task 202 (support gem renames)
- 66 skill files identified via grep
