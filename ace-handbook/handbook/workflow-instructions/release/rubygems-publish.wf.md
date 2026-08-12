---
name: release-rubygems-publish
description: RubyGems publication guidance (blocked until project opts into a publish contract)
allowed-tools: Bash, Read
argument-hint: "[gem-name...] [--dry-run]"
doc-type: workflow
purpose: specialized RubyGems publication baseline with non-mutating default
update:
  frequency: on-change
  last-updated: "2026-08-12"
---

# RubyGems Publish Workflow (Baseline)

## Goal

Describe a safe RubyGems publication path for projects that ship gems. **This baseline does
not push gems by default.** It inventories readiness and stops until the project opts into an
explicit publication contract (project overlay or confirmed operator publish intent with
credentials and dry-run evidence).

## Prep vs publication

| Phase | Allowed in this baseline by default |
|-------|-------------------------------------|
| Inventory gemspecs, versions, dependency order | Yes |
| Credential presence check (non-secret) | Yes |
| `gem build` / dry-run planning | Yes when explicitly requested |
| `gem push` / registry mutation | **No** until publication contract + explicit publish path |

## Prerequisites

- One or more `*.gemspec` files (or a documented gem build surface)
- Versions already bumped via local release preparation when releasing new versions
- For real pushes later: RubyGems credentials (`~/.gem/credentials` or `GEM_HOST_API_KEY`)

## Project Context Loading

- `ace-bundle project`
- Prefer completing `wfi://release/local` (or project release prep) before any publish attempt

## Process Steps

### 1. Discover gem targets

```bash
# Example discovery — adapt to the repository layout
ls ./*.gemspec 2>/dev/null
ls ./*/*.gemspec 2>/dev/null
```

If arguments name specific gems, filter to those and fail clearly when a name is missing.

### 2. Build a publish plan (no push)

For each gem:

1. Read the local version from the gemspec / version file.
2. Note runtime dependencies that are also local gems (publish dependencies first).
3. Produce an ordered plan (topological order for internal gem deps).

```text
Publish plan (dry):
1. <gem-a> <version>  (deps: ...)
2. <gem-b> <version>  (deps: gem-a)
```

### 3. Credential check (non-mutating)

```bash
[ -f ~/.gem/credentials ] && echo "credentials file present" || echo "credentials file missing"
echo "${GEM_HOST_API_KEY:+GEM_HOST_API_KEY is set}"
```

If unset, try loading tooling env (for example `mise env`) without printing secrets, then re-check.
Do not print secret values.

### 4. Publication gate

**Stop here by default.** Report:

- The ordered publish plan
- Whether credentials appear present
- That registry mutation requires a project overlay or an explicit operator-approved publish
  contract that replaces/extends this baseline

Only if a higher-priority project workflow authorizes pushes **and** the operator requested a
real publish (not merely prep/dry-run) may `gem build` + `gem push` proceed under that
project contract's steps and verification gates.

### 5. OTP-burst contract for project overlays (do not run from this baseline)

When a project overlay authorizes live `gem push`, use this timing contract so one OTP can cover a large queue:

1. Resolve credentials and the pending queue first
2. **Build every pending `.gem` artifact** before asking for OTP
3. Show the final queue (order, versions, artifact paths, count)
4. Prompt once for OTP — codes are short-lived (**~30–45s**)
5. Push immediately in dependency-respecting waves of **up to 5 concurrent** `gem push --otp` calls; aim to finish the burst in **≤30s**
6. Verify RubyGems metadata **after** the burst (not between pushes)
7. On expired/incorrect OTP: stop, list remaining gems, request a fresh OTP, resume without rebuilding unless an artifact is missing

Suggested overlay commands (executed only under a project publication contract):

```bash
# gem build <gemspec>   # all pending artifacts first
# gem push <built-gem> --otp <OTP>   # waves of ≤5 concurrent
```

## Override

Ship project-specific publish behavior at
`.ace-handbook/workflow-instructions/release/rubygems-publish.wf.md` (or another higher-priority
WFI source). Keep URI `wfi://release/rubygems-publish` stable for the distributed skill.

## Success Criteria

- [ ] Ordered publish plan produced for requested gems
- [ ] Credential presence reported without leaking secrets
- [ ] No `gem push` / registry mutation from this baseline alone
- [ ] Overlay guidance documents build-all → OTP → ≤5 concurrent wave publish → deferred verify

## Common Issues

- ACE monorepo operators may use a specialized overlay; plain projects must not depend on it.
- Missing credentials should block publish contracts, not local planning.
- Asking for OTP before builds complete wastes the short OTP window on slow work.
