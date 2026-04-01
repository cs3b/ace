# Setup Cookbook: Setup Starting an Astro Project with ACE

**Created**: 2026-04-01
**Last Updated**: 2026-04-01
**Category**: setup
**Audience**: intermediate
**Estimated Time**: 45 minutes

## Purpose

Set up a new Astro project with ACE workflow tooling so cookbook users can bootstrap a reproducible handbook-aware project layout.

## Source Provenance

- Source workflows/guides/docs: `wfi://handbook/init-project`, `ace-handbook/docs/usage.md`
- Validation evidence (commands, reports, or artifacts): `ace-bundle wfi://handbook/init-project`, `ace-nav list 'wfi://handbook/*'`
- Last source verification date: 2026-04-01

## Overview

Initialize project structure, confirm handbook protocol discovery, and verify workflow loading in a fresh Astro-oriented project.

## Steps

### Step 1: Initialize handbook structure

**Objective**: Create handbook scaffolding for project-local customization.

**Commands/Actions:**

```bash
ace-bundle wfi://handbook/init-project
```

**Validation:**

```bash
ace-nav list 'wfi://handbook/*'
```

## Propagation Notes

- Documentation updates to apply: add project-specific quickstart notes under `docs/cookbooks/`.
- Agent guidance updates to apply: add only short references to this cookbook in agent context docs.
- Summary-only propagation target notes (do not copy full cookbook body): `README.md`, `AGENTS.md`.

## Validation & Testing

### Success Criteria

- [ ] Handbook workflows are discoverable.
- [ ] Handbook init workflow loads successfully.
- [ ] Project notes reference this cookbook by summary.
