---
id: 8vc.t.j3p
status: done
priority: medium
created_at: "2026-08-13 12:44:08"
estimate: TBD
dependencies: []
tags: []
github_issue: 315
bundle:
  presets: [project]
  files: [docs/quick-start.md]
  commands: []
needs_review: false
---

# Add application capability packages to default quick start

## Objective

Expand the quick start guide to introduce a recommended `application` default package set alongside the minimal primitives option. This ensures that new applications immediately project capability skills (`ace-idea`, `ace-search`, `ace-docs`, `ace-hitl`, `ace-retro`, `ace-test`, `ace-test-runner`) so that developers and agents can execute advertised walkthrough commands (like `ace-idea create`) immediately after setup without encountering missing gem or missing executable errors.

## Behavioral Specification

### User Experience

- **Input**:
  - Developers or agents setting up a new project following `docs/quick-start.md`.
  - Selecting either the `minimal` primitive path or the default recommended `application` path.
- **Process**:
  - Running `bundle add --group "development, test" ...` with the recommended 7 capability packages (`ace-idea`, `ace-search`, `ace-docs`, `ace-hitl`, `ace-retro`, `ace-test`, `ace-test-runner`) plus core primitives and LLM providers.
  - Running `bundle exec ace-handbook sync` to project canonical skills.
  - Running quick start verification commands (`ace-idea --help`, `ace-search --version`, `ace-test --version`, `ace-test-suite --version`, `ace-config doctor`).
- **Output**:
  - A fully functional ACE environment with 64+ projected skills.
  - Initial walkthrough commands work out-of-the-box without missing package errors.

### Expected Behavior

- **Clear Tiered Quick Start Options**:
  - `docs/quick-start.md` documents an explicit `application` quick-start command set as the recommended default.
  - The `minimal` option remains documented for users who only want task and context primitives (`ace-task`, `ace-bundle`, `ace-handbook`, `ace-llm`, `ace-llm-providers-cli`).
  - The `full-stack` path explicitly lists `ace-hitl`, `ace-test`, and `ace-test-runner` to match its claimed capability surface.
- **Explanation of Test Package Pair**:
  - `docs/quick-start.md` explicitly documents the division of responsibility between `ace-test` (workflow/skill surface) and `ace-test-runner` (owns `ace-test` and `ace-test-suite` executables).
  - Clarifies why both must be installed together to prevent Bundler "can't find executable" errors.
- **Verification Commands**:
  - Quick start instructions guide the user to verify setup using:
    ```bash
    bundle exec ace-handbook sync
    bundle exec ace-idea --help
    bundle exec ace-search --version
    bundle exec ace-test --version
    bundle exec ace-test-suite --version
    bundle exec ace-config doctor
    ```

### Interface Contract

```bash
# Recommended Application Quick Start Installation
bundle add --group "development, test" \
  ace-task ace-idea \
  ace-bundle ace-handbook ace-search ace-docs \
  ace-hitl ace-retro ace-test ace-test-runner \
  ace-llm ace-llm-providers-cli

# Verification Sequence
bundle exec ace-handbook sync
bundle exec ace-idea --help
bundle exec ace-search --version
bundle exec ace-test --version
bundle exec ace-test-suite --version
bundle exec ace-config doctor
```

#### Error Handling:
- Missing executable when invoking `ace-test` or `ace-test-suite`: Quick start explains that `ace-test-runner` provides the binaries for `ace-test` skills, preventing common setup confusion.
- Missing skill projection: Quick start specifies running `ace-handbook sync` post-install so all 64+ skills are projected into `.agents/skills/`.

#### Edge Cases:
- Minimal setup path: Explicitly noted that running commands like `ace-idea create` requires installing `ace-idea` package.
- Idempotent sync: Re-running `ace-handbook sync` produces zero unnecessary changes or errors.

## Success Criteria

1. **Recommended Application Set**: The quick start guide recommends and details the 7 capability packages (`ace-idea`, `ace-search`, `ace-docs`, `ace-hitl`, `ace-retro`, `ace-test`, `ace-test-runner`) alongside core primitives and LLM providers.
2. **Minimal Path Preserved**: The minimal primitive setup path remains clearly documented for minimal integration scenarios.
3. **Test Package Pairing Documented**: The relationship and necessity of co-installing `ace-test` and `ace-test-runner` is explicitly documented.
4. **Walkthrough Command Parity**: A fresh installation using the application set can execute `ace-idea`, `ace-search`, `ace-test`, and `ace-test-suite` cleanly.
5. **Full-Stack Alignment**: The full-stack package list explicitly includes `ace-hitl`, `ace-test`, and `ace-test-runner`.
6. **Idempotence**: `ace-handbook sync` projects advertised skills reliably and idempotently.

## Scope of Work

### User Experience Scope
- Updating `docs/quick-start.md` to structure installation tiers (`minimal`, `application`, `full-stack`).
- Providing post-installation verification commands.

### System Behavior Scope
- Ensuring standard workflow skills (idea, search, docs, HITL, retro, test) are projected by default when using the application quick start package set.

### Interface Scope
- `docs/quick-start.md` documentation changes.

## Out of Scope

- Modifying Ruby code in gem packages.
- Changing gem specs or dependency trees of individual gems.
- Automated installer scripts (this task focuses strictly on documentation and quick start accuracy).

## Concept Inventory

| Concept | Introduced by | Removed by | Status |
| --- | --- | --- | --- |
| Application Quick Start Tier | 8vc.t.j3p | - | KEPT |
| Test Runner Companion Pairing | 8vc.t.j3p | - | KEPT |

## Vertical Slice Decomposition

- **Slice Type**: Standalone task (Single flat task)
- **Outcome**: `docs/quick-start.md` updated with application capability packages, test package pairing explanation, verification steps, and aligned full-stack list.
- **Advisory Size**: Small
- **Context Dependencies**: `docs/quick-start.md`

## Verification Plan

### Unit / Component Validation

- Validate markdown syntax and link structure in `docs/quick-start.md` using `ace-lint docs/quick-start.md`.

### Integration / E2E Validation

- Execute quick start verification commands in a clean/sandbox environment or against repo binaries:
  - `bundle exec ace-handbook sync`
  - `bundle exec ace-config doctor`

### Failure / Invalid Path Validation

- Verify that the minimal path documentation accurately notes which commands (e.g. `ace-idea`) will be unavailable unless capability gems are added.

### Verification Commands

- `ace-lint docs/quick-start.md`
- `ace-config doctor`

