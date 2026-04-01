# Setup Cookbook: Starting an Astro Project with ACE

**Created**: 2026-04-01
**Last Updated**: 2026-04-01
**Category**: setup
**Audience**: intermediate
**Estimated Time**: 45-90 minutes

## Purpose

Bootstrap a new Astro project with ACE workflow tooling and assignment sequencing that avoids common rework and deployment blockers.

## Overview

This cookbook captures the proven ordering and operating pattern from a completed Astro + Tailwind + Firebase project, then reframes it as reusable setup guidance.

## Source Provenance

- Source workflows/guides/docs:
  - `.ace-tasks/8qs.t.x2b-migrate-cookbook-ownership-to-ace/2-seed-handbook-with-canonical-cookbook/astro-project-with-ace.input.md`
  - `wfi://assign/create`
  - `wfi://assign/drive`
- Validation evidence (commands, reports, or artifacts):
  - `ace-bundle wfi://assign/create`
  - `ace-bundle wfi://assign/drive`
  - `ace-nav resolve cookbook://setup-starting-an-astro-project-with-ace`
- Last source verification date: 2026-04-01

## Propagation Notes

- Documentation updates to apply:
  - Add a short project quickstart section for Astro prerequisites and deployment caveats.
  - Add a mobile-browser gotchas section only if those issues were observed in that project.
- Agent guidance updates to apply:
  - Add concise rules only: "design tokens first", "mark interactive cloud auth tasks manual", "run 2 review cycles for static-site MVP work".
- Summary-only propagation target notes (do not copy full cookbook body):
  - `README.md`
  - `CLAUDE.md`
  - `AGENTS.md`

## Steps

### Step 1: Initialize Astro and styling baseline

**Objective**: Create a clean Astro project with Tailwind wired into the build.

**Commands/Actions:**

```bash
npm create astro@latest -- --template minimal
npm install tailwindcss @tailwindcss/vite
```

Update `astro.config.mjs` and global styles:

```js
import { defineConfig } from 'astro/config';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  vite: { plugins: [tailwindcss()] }
});
```

```css
@import "tailwindcss";
```

**Validation:**

```bash
npm run build
```

### Step 2: Initialize ACE and project guidance

**Objective**: Add handbook-aware workflow scaffolding before task execution.

**Commands/Actions:**

```bash
ace-handbook sync
ace-nav list 'wfi://handbook/*'
```

Create concise project-specific rules in `CLAUDE.md` and `AGENTS.md` for commit scope, design system references, and immutable project facts.

**Validation:**

```bash
ace-bundle project
```

### Step 3: Plan task sequence with design tokens first

**Objective**: Prevent styling drift and reduce component rework.

**Commands/Actions:**

1. Create the design-token task first.
2. Add component/layout tasks after token decisions are fixed.
3. Mark interactive authentication steps as manual and outside fork execution.

Recommended sequence:

1. Design tokens and global styles
2. Header/navigation
3. Hero section
4. Content sections
5. Contact/CTA
6. Footer and floating CTA
7. Image processing
8. Hosting/deploy (manual)

**Validation:**

```bash
ace-task list --status pending
```

### Step 4: Create and drive assignment

**Objective**: Execute planned work with stable review depth and clear boundaries.

**Commands/Actions:**

```bash
ace-assign create work-on-task --taskrefs <task-refs>
ace-assign drive
```

Execution recommendations for Astro/static-site initial builds:

- Use 2 review cycles (`valid`, `fit`), skip `shine`.
- Run sequential fork execution unless sections are truly independent.
- Keep deployment/auth tasks manual.

**Validation:**

```bash
ace-assign status
```

### Step 5: Run post-build polish and release checks

**Objective**: Catch real browser/device issues before release.

**Commands/Actions:**

- Verify mobile behavior, especially iOS Safari menu/scroll handling.
- Verify social preview metadata and non-WebP OG image output.

**Validation:**

```bash
npm run build
```

## Validation & Testing

### Final Validation Steps

1. Verify cookbook resolves through protocol:

   ```bash
   ace-nav resolve cookbook://setup-starting-an-astro-project-with-ace
   ```

2. Verify assignment workflows load:

   ```bash
   ace-bundle wfi://assign/create
   ace-bundle wfi://assign/drive
   ```

### Success Criteria

- [x] Setup flow is action-first and reusable.
- [x] Provenance is explicit and traceable to real work artifacts.
- [x] Propagation guidance is concise and summary-only.
