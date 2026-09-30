---
id: 8ws.t.lq1.1
status: in-progress
priority: high
created_at: "2026-09-29 14:29:08"
estimate: medium
dependencies: [8ws.t.lq1.0]
tags: [release, e2e]
parent: 8ws.t.lq1
title: Verify the published dependency graph and complete installation proof
needs_review: false
bundle:
  presets: [project]
  files: [ace-bundle/ace-bundle.gemspec, ace-review/ace-review.gemspec, ace-task/ace-task.gemspec, ace-monorepo-e2e/test/e2e/TS-MONO-001-rubygems-install/scenario.yml, ace-monorepo-e2e/test/e2e/TS-MONO-001-rubygems-install/TC-004-classify-result.verify.md, .ace-tasks/8ws.t.lq1-close-foundation-gaps-and-integrate/evidence/release-proof-2026-09-29.md, .ace-tasks/8ws.t.lq1-close-foundation-gaps-and-integrate/evidence/install-observations.json]
  commands: []
---

# Verify the published dependency graph and complete installation proof

## Outcome and user experience
A clean installation through the ordinary supported ACE dependency graph resolves the intended released versions, including ace-git-github 0.2.x, and TS-MONO-001 completes with a genuine final verifier verdict. Distinguish registry availability, dependency reachability, successful install goals and the full scenario result. None of these proves the Lab is installed or ready.

## Expected behavior and interface
Owner: release coherence for ace-bundle/ace-review/ace-task dependency metadata plus ace-monorepo-e2e installed acceptance. Source already requires ace-git-github ~> 0.2. Version/release the consumer artifacts whose published metadata still pins ~> 0.1.1, under the normal release workflow and applicable publication authorization. Do not widen back to 0.1 to make installation pass, directly pin the provider to hide consumer constraints, overwrite a published version, or mutate global user gems.

Before verification, freeze an exact version manifest for the 17 reported publication events across 16 distinct packages (the later ace-test-runner 0.27.1 supersedes 0.27.0) plus newly required consumer/wrapper releases. Record source SHA, artifact version and actual resolved/loaded version. Supersession must be explicit; require the chosen exact versions, not merely compatible older ones. Count from the manifest, not the reported 45/48 package totals.

### Exact manifest input
TS-MONO-001 setup reads `ACE_RELEASE_MANIFEST` from the invoking process as an absolute JSON file path, defaulting to `<ACE_E2E_SOURCE_ROOT>/.ace-local/release/installation-manifest.json`. The runner carries only this explicitly allowed input to scenario setup; it does not import arbitrary host environment variables or ask an LLM to discover versions. Setup validates and copies it into sandbox `results/tc/01/release-manifest.json` before network installation. Missing, unreadable, malformed or conflicting input is a setup failure with no install attempt.

Schema: `schema_version: 1`, `source_sha` (full 40-character commit), `packages` (nonempty array of `{name, artifact_version, source_sha, supersedes?}`). Names are unique ACE gem names, artifact_version is one exact valid Gem::Version string (not a requirement), source_sha is the full commit used for that artifact, supersedes is an optional array of earlier version strings of the same package. Duplicate names, unknown fields, absent required fields and unsupported schema version fail validation. The checked-in scenario documentation gives this schema; the generated manifest lives under .ace-local/release and the immutable acceptance copy belongs with task evidence.

Each of TC002/003 records actual resolved and loaded versions and package paths in a machine-readable receipt. TC004 compares these and the corresponding lockfile to every manifest entry; missing entries, old-but-compatible versions, source/path dependencies and loads outside the isolated gem directories fail exact-version acceptance. Only artifact versions explicitly recorded as superseding older releases satisfy the replacement; absence is not success. Also perform an isolated consumer-only resolution for the released ace-bundle, ace-review and ace-task without a direct ace-git-github Gemfile entry, proving their dependency edges select the intended provider. All normal constraints remain unchanged by the verification manifest.

Use `bin/ace-test-e2e ace-monorepo-e2e TS-MONO-001` with the scenario's existing isolated Ruby/GEM/BUNDLE and env contract. Normal and full-index paths both produce lockfiles, executed exit results and bundle/load evidence. Do not use direct gem install as a substitute for dependency graph reachability. Keep existing registry classifications SAFE/LAG_DETECTED/METADATA_BROKEN separate from wrapper/scenario completion; wrapper ERROR remains incomplete even with successful goals.

## Success criteria and verification
- [ ] SC1: Versioned released consumer gemspecs permit the chosen ace-git-github 0.2.x in the normal graph; constraints in source and published artifacts agree. Record which artifacts supersede the previously published set.
- [ ] SC2: In a fresh isolated install with no local source/path overrides or old lock, normal and full-index runs resolve and load all manifest versions. Explicitly show ace-git-github through ace-bundle/review/task and the four afternoon patches. Preserve sanitized lockfile/exit/version receipts under this task.
- [ ] SC3: TS-MONO-001 runner and verifier both complete and the final machine-readable verdict agrees with raw goals and classification. No manual result editing or suppressed timeout. Existing captured exits are credited only as partial historical evidence.
- [ ] SC4: Negative scenario verification rejects stale-but-compatible installed versions, missing manifest entries and a wrapper ERROR despite bundle exit zero. Tests cover classification without requiring repeated registry calls.
- [ ] SC5: Normal release checks include executed affected tests and independent candidate review; no CI-green requirement. End receipt states explicitly that Lab deployment/full system acceptance belongs to lab-config gad.a/gad.2.

## Slice and sequencing
One medium end-to-end published installation slice, including the scenario manifest-input and receipt-validation changes above. Metadata release preparation can proceed while lq1.0 is repaired; final E2E acceptance depends on lq1.0. Current task is a spec, not an instruction to publish now. No new installer, global cleanup or Lab rollout.

## Current evidence / resolved questions
Read parent evidence/release-proof-2026-09-29.md. The existing proof is SAFE for its tested subset; raw normal/full-index logs install ace-git-github 0.1.2 and the older pre-afternoon wrapper/runner releases. Their success does not prove the full 17-release graph. User-reported publication verification is retained as reported; no fresh registry query was performed in this spec pass. No additional Captain decision required.
