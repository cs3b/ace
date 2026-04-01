# Setup Cookbook: Starting a Multi Ruby Gem Monorepo with ACE

**Created**: 2026-04-01
**Last Updated**: 2026-04-01
**Category**: setup
**Audience**: intermediate
**Estimated Time**: 2-4 hours

## Purpose

Start a new Ruby multi-package monorepo using ACE patterns for package structure, shared defaults, handbook integration, and monorepo-level verification.

## Overview

This cookbook distills monorepo setup patterns from ACE package conventions and cross-cutting E2E quickstart verification work, then turns them into a reusable sequence for new repositories.

## Source Provenance

- Source workflows/guides/docs:
  - `docs/ace-gems.g.md`
  - `ace-monorepo-e2e/README.md`
  - `.ace-retros/8quwjc-monorepo-e2e-quickstart-verification/8quwjc-monorepo-e2e-quickstart-verification.retro.md`
- Validation evidence (commands, reports, or artifacts):
  - `ace-test-e2e ace-monorepo-e2e --test-id TS-MONO-001`
  - `ace-test-e2e ace-monorepo-e2e --test-id TS-MONO-002`
  - `ace-nav resolve cookbook://setup-starting-a-multi-ruby-gem-monorepo-with-ace`
- Last source verification date: 2026-04-01

## Propagation Notes

- Documentation updates to apply:
  - Add one monorepo quickstart page that covers prerequisites, workspace bootstrap, and E2E smoke checks.
  - Add a short troubleshooting section for permission and timeout pitfalls during E2E runs.
- Agent guidance updates to apply:
  - Add concise rules only: "use `ace-test` (not bundle exec)", "run `ace-config init` + `ace-handbook sync` before nav/bundle checks", and "scope E2E scenarios to monorepo-level concerns".
- Summary-only propagation target notes (do not copy full cookbook body):
  - `README.md`
  - `docs/quick-start.md`
  - `AGENTS.md`

## Steps

### Step 1: Scaffold monorepo package layout

**Objective**: Establish consistent gem/package boundaries and shared conventions.

**Commands/Actions:**

1. Create packages with `ace-*`, `ace-support-*`, and integration naming patterns from `docs/ace-gems.g.md`.
2. Include required defaults and handbook directories in each owned package.
3. Use root-level dependency management for the repository.

**Validation:**

```bash
rg --files | rg "\.ace-defaults/.*/config\.yml"
rg --files | rg "handbook/"
```

### Step 2: Initialize local ACE configuration for repository tooling

**Objective**: Ensure discovery and bundle protocols work in a fresh workspace.

**Commands/Actions:**

```bash
ace-config init
ace-handbook sync
```

**Validation:**

```bash
ace-nav list 'wfi://*'
ace-bundle project
```

### Step 3: Add monorepo-level E2E scenario container

**Objective**: Keep cross-package verification separate from any single gem package.

**Commands/Actions:**

1. Create `ace-monorepo-e2e/test/e2e/TS-*/scenario.yml` entries for repository-wide behaviors.
2. Use one scenario for install verification and one for quickstart/docs validation.
3. Keep per-package scenarios in their package folders; keep only cross-cutting cases here.

**Validation:**

```bash
ace-test-e2e ace-monorepo-e2e
```

### Step 4: Verify quickstart and install paths under realistic conditions

**Objective**: Confirm documented setup paths work in clean environments.

**Commands/Actions:**

```bash
ace-test-e2e ace-monorepo-e2e --test-id TS-MONO-001
ace-test-e2e ace-monorepo-e2e --test-id TS-MONO-002
```

If runs are network-heavy, raise timeout budgets deliberately and record the reason in scenario docs.

**Validation:**

```bash
ace-test-e2e-suite --tags quickstart
```

### Step 5: Document guardrails learned from verification

**Objective**: Prevent repeated setup failures for new contributors.

**Commands/Actions:**

Document these defaults in repo docs and concise agent guidance:

- Use provider modes that include required permission handling for agent-run E2E.
- Do not classify operational release steps as E2E scenarios; keep E2E focused on verification behavior.
- Keep scenario scope tight; avoid adding unrelated package-specific tests without explicit need.

**Validation:**

```bash
rg -n "ace-config init|ace-handbook sync|ace-test-e2e" README.md docs AGENTS.md
```

## Validation & Testing

### Final Validation Steps

1. Verify cookbook resolves through protocol:

   ```bash
   ace-nav resolve cookbook://setup-starting-a-multi-ruby-gem-monorepo-with-ace
   ```

2. Verify monorepo scenarios are runnable:

   ```bash
   ace-test-e2e ace-monorepo-e2e
   ```

### Success Criteria

- [x] Monorepo setup sequence is reusable and action-first.
- [x] Provenance references real project artifacts and verification evidence.
- [x] Propagation guidance is concise and summary-only.
