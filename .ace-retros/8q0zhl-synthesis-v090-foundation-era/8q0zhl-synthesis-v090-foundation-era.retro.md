---
id: 8q0zhl
title: "Synthesis: v.0.9.0 Foundation Era — Mono-Repo Bootstrap, Config Architecture, and Test Infrastructure"
type: standard
tags: [synthesis]
created_at: "2026-03-01 23:39:33"
status: active
synthesized_from:
  - 8q0pi1  # Config Discovery Architecture
  - 8q0pi2  # Test Fix Path Resolution ace-core
  - 8q0pi3  # ace-llm-providers-cli Gem Creation
  - 8q0pi4  # ace-test-runner Bin Directory Integration
  - 8q0pi5  # ace-test-runner Performance Optimization
  - 8q0pi7  # ace-test-runner Redesign
  - 8q0pi8  # ace-context Test Timing Fix
  - 8q0pi9  # Minitest Infrastructure for ace-core
  - 8q0pia  # Task 150 Subtask Numbering Convention
  - 8q0pib  # ACE Nav Gem Implementation
  - 8q0pic  # Comprehensive v.0.9.0 Release Reflections
---

# Synthesis: v.0.9.0 Foundation Era — Mono-Repo Bootstrap, Config Architecture, and Test Infrastructure

**Date**: 2026-03-01
**Context**: Synthesis of 11 retros from Sep 2025–Jan 2026 covering the initial mono-repo transition, first gem implementations (ace-core, ace-context, ace-nav, ace-llm-providers-cli, ace-test-runner), configuration architecture, and test infrastructure during the v.0.9.0 release cycle.
**Type**: Synthesis

## What Went Well

### 1. ATOM Architecture Proved Its Value (11/11 retros)
Every gem implementation confirmed that the Atoms/Molecules/Organisms/Models layering provides clear structure and testable code. It guided both new gem creation and refactoring decisions consistently across ace-core, ace-context, ace-nav, ace-llm-providers-cli, and ace-test-runner.

### 2. Test-Driven Development Caught Issues Early (7/11 retros)
Comprehensive testing from day one — 181 tests across the 4 initial gems — caught path resolution bugs, config cascade ordering issues, and timing-dependent failures before they reached production. The ace-test-support gem gave all gems consistent test infrastructure.

### 3. Centralizing Config Discovery in ace-core Eliminated a Class of Bugs (5/11 retros)
Moving config discovery, path resolution, and configuration cascade into ace-core eliminated duplicated logic across tools. The four-tier cascade (CLI > Project > User > Gem defaults) became a reliable foundation. Before centralization, each tool implemented ad-hoc config loading with inconsistent behavior.

### 4. Protocol-Based Navigation Architecture (1/11 retros, high impact)
ace-nav's `wfi://`, `tmpl://` protocol system provided a clean, extensible navigation mechanism. The security-first refactoring — from auto-scanning installed gems to explicit configuration cascade — was a critical design correction.

### 5. Performance Optimization Delivered 6x Improvement (2/11 retros)
Replacing process-per-file test execution with grouped Minitest execution cut test time from 3.4s to 0.55s for 83 tests, enabling the fast feedback loops critical for development flow.

### 6. Mono-Repo Patterns Established Definitively (3/11 retros)
Root Gemfile with path-based dependencies, `.bundle/config` pointing to parent, mise.toml for PATH — these patterns were worked out through trial and error and became the standard for all subsequent gems.

## What Could Be Improved

### 1. Assuming Behavior Instead of Reading Code (identified in 6/11 retros — most frequent)
The single most common root cause across retros. Agents and developers repeatedly assumed behavior instead of verifying it:
- mise config naming (`.mise.toml` vs `mise.toml`) — wrong assumption (8q0pi4)
- Path resolution rules — tests expected wrong behavior because implementation wasn't read (8q0pi2)
- Stubbing wrong methods — didn't trace actual call chain (8q0pi2)
- ace-llm config structure — didn't examine parent gem's patterns before extending (8q0pi3)
- Subtask numbering convention — created files by hand without checking ace-taskflow patterns (8q0pia)
- Minitest env_loader behavior — assumed `auto_load` returned `{}` instead of `nil` (8q0pi9)

### 2. Over-Engineering Before Measuring (identified in 5/11 retros)
Applying complex architecture before proving it was needed. The ace-test-runner's 20+ file ATOM structure was 9x slower and harder to maintain than a 417-line script. The ace-llm-providers-cli hardcoded model info in Ruby instead of externalizing to YAML. Multiple retros describe building the "elegant" solution first, then simplifying when it proved too slow or complex.

### 3. Manual Processes Bypassing Tool Conventions (identified in 3/11 retros)
Creating task files by hand (wrong subtask numbering, 8q0pia), testing with manual PATH overrides instead of mise (8q0pi4), and creating symlinks instead of proper wrapper scripts (8q0pi4) — all led to convention violations that broke tooling.

### 4. Timing and Initialization Order Sensitivity (identified in 2/11 retros)
Config components with caching behavior broke when initialization happened before fixtures were ready (8q0pi8). PresetManager caching empty state that persisted through test execution. Pattern: premature caching → stale/empty state → confusing failures.

### 5. Bundler Context Complexity in Mono-Repo (identified in 3/11 retros)
Child processes inheriting bundler context, missing `require "bundler/setup"` in Rakefiles, and gem executables needing explicit `BUNDLE_GEMFILE` wrappers caused repeated friction (8q0pi4, 8q0pic).

## Key Learnings

### Architecture

1. **Simplicity Scales Better Than Complexity** (3/11 retros)
The strongest technical theme. Process-per-file was architecturally clean but 9x slower than rake. Complex ATOM structure for test-runner was well-organized but harder to debug than a flat script. Start with the simplest working solution, measure, then add complexity only where proven necessary.

2. **Infrastructure Concerns Must Be Centralized Early** (2/11 retros)
Config discovery, path resolution, and configuration cascade are cross-cutting concerns. When each tool implemented its own version, the result was duplication, inconsistency, and fragility. Centralizing in ace-core created a single source of truth that eliminated a whole class of directory-dependent bugs.

3. **Security-First Design for Auto-Discovery** (1/11 retros, high impact)
Never automatically scan or load config from installed gems. ace-nav's refactoring from gem-scanning to explicit configuration cascade was a critical security correction that shaped the entire protocol system.

4. **Work With Frameworks, Not Against Them** (3/11 retros)
Fighting Minitest's autorun, reporters, and execution model created unnecessary complexity. Using native patterns (grouped execution, built-in reporters) dramatically simplified code and improved performance.

### Process

5. **Read Implementation Before Writing Tests or Extensions** (6/11 retros)
The most actionable insight. Tests that assumed wrong path resolution semantics, extensions that assumed wrong config structures, stubs targeting wrong methods — all traced to not reading the actual code first.

6. **Use Project Tools Instead of Manual Creation** (2/11 retros)
Manual task creation bypassed ace-taskflow's conventions (two-digit subtask numbering). Manual PATH overrides bypassed mise's configuration. Always use the project's own tools — they enforce conventions automatically.

7. **Benchmark Against Existing Solutions** (2/11 retros)
ace-test-runner was 9x slower than `rake test` because nobody compared them early. Establishing baseline performance metrics before building new tools prevents building something worse than what already exists.

### Ruby-Specific

8. **Mutable Default Parameters Create Shared Objects** (1/11 retros, high impact)
`files: []` in constructors creates a shared mutable object. Use `files: nil` with `@files = files || []`.

9. **`module_function` Needs Explicit Public Visibility** (1/11 retros)
Module functions in Ruby need explicit public visibility when using `module_function`.

10. **Use `require` for Gem Dependencies, Not `require_relative`** (1/11 retros)
Never use `require_relative` to traverse outside gem boundaries. Use `require 'gem/name'` for proper dependency resolution.

## Action Items

### Stop Doing

- **Assuming tool/framework behavior** — read implementation code and official docs before coding (6/11 retros)
- **Applying complex architecture before benchmarking** — measure first, architect second (5/11 retros)
- **Creating project artifacts manually** — use ace-taskflow, ace-retro, and other ACE tools that enforce conventions (3/11 retros)
- **Testing with shortcuts** (manual PATH, wrong stubs) — test the actual user workflow (2/11 retros)
- **Spawning separate processes per test file** — use grouped execution (2/11 retros)

### Continue Doing

- **ATOM architecture for gem organization** — proven across all gems, provides clear testable structure (11/11 retros)
- **Test-driven development from day one** — catches issues early, validates architecture (7/11 retros)
- **Centralizing cross-cutting concerns in ace-core/ace-support** — eliminates duplication and inconsistency (5/11 retros)
- **Pragmatic solutions over perfect ones** — simple fixes often beat complex "correct" solutions (4/11 retros)
- **Security-first design** — explicit configuration over auto-discovery (1/11 retros)
- **Incremental validation** — fix-test-verify cycles prevent regression (3/11 retros)

### Start Doing

- **Benchmark new tools against existing baselines** — compare with rake/native before shipping (2/11 retros)
- **Gem creation checklist** — verify config patterns, naming conventions, and parent gem patterns before implementation (3/11 retros)
- **Document initialization contracts** — specify when caching components can be safely instantiated (2/11 retros)
- **Convention validation tooling** — `ace-taskflow doctor --subtasks` and similar checks to catch violations early (1/11 retros)
- **Read official documentation thoroughly** before implementing tool configurations (2/11 retros)

## Technical Patterns Worth Preserving

### Mono-Repo Gem Setup Requirements
```
1. No local Gemfiles — use root Gemfile only
2. Rakefile MUST include: require "bundler/setup"
3. Executables need wrapper scripts setting BUNDLE_GEMFILE
4. mise.toml uses env._.path = ["./bin"] for PATH
5. Add gems to parent Gemfile with path: "gem-name"
```

### Configuration Cascade Priority
```
CLI flags > ENV > Project .ace/ > User ~/.ace/ > Gem .ace-defaults/
```

### Path Resolution Rules (ace-core ConfigDiscovery)
```
./  or ../  → relative to config file's directory
plain name  → relative to project root (if matches known pattern)
absolute    → passed through unchanged
```

### Test Execution: Fast vs Slow
```
SLOW: process-per-file → bundle exec ruby -Ilib:test per file (3.4s / 83 tests)
FAST: grouped execution → single Minitest process (0.55s / 83 tests)
BASELINE: rake test (~0.37s / 83 tests)
```

### Wrapper Script Pattern for Mono-Repo Executables
```ruby
#!/usr/bin/env ruby
require "pathname"
ace_meta_root = Pathname.new(__FILE__).dirname.parent.realpath
ENV["BUNDLE_GEMFILE"] = ace_meta_root.join("Gemfile").to_s
require "bundler/setup"
load ace_meta_root.join("ace-gem/exe/ace-gem").to_s
```

### Test Timing: Initialize After Fixtures
```ruby
# WRONG: component caches empty state
def setup
  @loader = ContextLoader.new   # Caches before config exists
  create_config_files            # Too late — cache is stale
end

# RIGHT: fixtures first, then component
def setup
  create_config_files            # Config exists
  @loader = ContextLoader.new   # Caches populated state
end
```

## Thematic Summary

| Theme | Retro Count | Key Pattern |
|-------|-------------|-------------|
| Config Architecture & Discovery | 3 retros | Centralize in ace-core, four-tier cascade, smart path resolution |
| Test Infrastructure & Performance | 5 retros | Grouped execution, ATOM test org, timing-aware setup |
| Gem Creation & Extension Patterns | 3 retros | Follow parent conventions, externalize config to YAML, security-first |
| Tool Convention Compliance | 3 retros | Use ace-taskflow for tasks, mise for PATH, proper naming |
| Mono-Repo Bootstrap | 3 retros | Root Gemfile, bundler wrappers, CI matrix strategy |
| Over-Engineering vs Simplicity | 3 retros | Measure first, start simple, add complexity only when proven |

## Additional Context

- **Time period**: September 2025 – January 2026 (v.0.9.0 early development)
- **Source retro count**: 11 retros synthesized (IDs 8q0pi1–8q0pic)
- **Gems covered**: ace-core, ace-context, ace-test-support, ace-test-runner, ace-nav, ace-llm-providers-cli
- **Major work streams**: Mono-repo transition, ATOM architecture rollout, config cascade design, test infrastructure, CI/CD pipeline
