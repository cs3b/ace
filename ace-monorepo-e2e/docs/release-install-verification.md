# Release Install Verification Guide

This guide documents the public install verification job behind
`TS-MONO-001-rubygems-install`.

## Goal

Prove that a clean installation through the ordinary supported ACE dependency
graph resolves the intended released versions, and classify post-release
install behavior using real RubyGems installs as one of:

- `SAFE`
- `LAG_DETECTED`
- `METADATA_BROKEN`

Registry classification, exact-version acceptance against the frozen release
manifest, and scenario completion are three separate results. None of them
alone — and none of the install goals themselves — proves the Lab is
installed or ready; Lab deployment and full system acceptance belong to the
lab-config gad.a/gad.2 line.

## Run The Verification

```bash
ace-test-e2e ace-monorepo-e2e TS-MONO-001
```

The scenario validates the frozen release manifest during setup, runs normal
install, then full-index fallback, records lockfile/activated receipts and
consumer-only dependency-edge resolutions for both modes, then writes a
classification proof and the machine-readable exact-version acceptance.

### Finalize (after the run completes)

The final machine-readable verdict is produced once the pipeline has finished
(it gates on the report `metadata.yml`, which only exists after the runner
session completes):

```bash
ACE_E2E_SOURCE_ROOT=$PWD .ace-local/test-e2e/<run>/ace-monorepo-e2e/test/e2e/TS-MONO-001-rubygems-install/install_receipt.rb \
  finalize \
  --manifest .ace-local/test-e2e/<run>/results/tc/01/release-manifest.json \
  --source-manifest .ace-local/release/installation-manifest.json \
  --normal .ace-local/test-e2e/<run>/results/tc/02 \
  --full-index .ace-local/test-e2e/<run>/results/tc/03 \
  --pipeline-report .ace-local/test-e2e/<run>-reports \
  --results-root .ace-local/test-e2e/<run> \
  --out .ace-tasks/<task>/evidence/installation-acceptance.json
```

`finalize` exits non-zero unless the exact-version acceptance passes, the
sandbox manifest copy is byte-identical to the validated source manifest, the
recorded classification agrees with the classification recomputed from the
install exits, the runner-side acceptance artifact passes, and the pipeline
completed (`status: pass`, no `uncertain_execution`). The emitted artifact is
the immutable final verdict retained with the task evidence.

## Frozen Release Manifest

Setup reads an exact-version manifest before any install can happen:

- Input: `ACE_RELEASE_MANIFEST` in the invoking process, an absolute JSON file
  path. This is the only host environment variable the runner carries into
  scenario setup. Without it, setup defaults to
  `<ACE_E2E_SOURCE_ROOT>/.ace-local/release/installation-manifest.json`.
- Setup validates the manifest and copies the exact bytes to
  `results/tc/01/release-manifest.json` before network installation. Missing,
  unreadable, malformed, or conflicting input is a setup failure with no
  install attempt.
- The generated manifest lives under `.ace-local/release/`; the immutable
  acceptance copy belongs with the task evidence.

Schema (`schema_version: 1`):

```json
{
  "schema_version": 1,
  "source_sha": "<full 40-character commit the manifest was frozen at>",
  "packages": [
    {
      "name": "ace-git-github",
      "artifact_version": "0.2.0",
      "source_sha": "<full 40-character commit for this artifact>",
      "supersedes": ["0.1.2"]
    }
  ]
}
```

Validation is strict: names must be unique ACE gem names; artifact versions
must be one exact valid `Gem::Version` string, never a requirement; source
SHAs must be full 40-character commits; `supersedes` is an optional array of
earlier versions of the same package; unknown fields, duplicate names, absent
required fields, and unsupported schema versions fail validation.

### Supersession

`supersedes` records explicit replacement: the artifact version supersedes the
listed older releases. Acceptance requires the chosen exact versions to be
installed — old-but-compatible versions do not satisfy the contract, and a
superseded version still present in any lockfile or activated receipt is a
finding. Absence of a version is never proof of replacement. Count packages
from the manifest, not from reported bundle totals.

## Receipts And Exact-Version Acceptance

Each install mode records machine-readable evidence (never console output):

- `<mode dir>/Gemfile.lock` plus `lockfile-receipt.json` (resolved versions)
- `<mode dir>/install-receipt.json` (activated versions and gem paths)
- `<mode dir>/consumer/<gem>/` — for `ace-bundle`, `ace-review`, and
  `ace-task`, an isolated consumer-only resolution whose Gemfile names only
  that consumer at its exact manifest version. With no direct
  `ace-git-github` entry, the provider version in the resolved graph can only
  come from the consumer's published dependency edge.

TC-004 runs `install_receipt.rb verify`, which compares every manifest entry
against both modes and emits `results/tc/04/exact-version-acceptance.json`.
Exact-version acceptance fails when an entry is missing, resolves to an
old-but-compatible version, loads from a source/path checkout or any location
outside the mode's isolated gem directories, when the lockfile and activated
receipt disagree, or when a superseded version is still present.

After a completed run, `install_receipt.rb finalize` adds the pipeline
completion gate (report `metadata.yml` must record `status: pass` with no
`uncertain_execution` flag) and a single final verdict. A wrapper ERROR keeps
the scenario incomplete even when every bundle exit was zero; existing
captured exits are credited only as partial historical evidence.

## Classification Meaning

| Normal install | Full-index install | Classification | Operator guidance |
| --- | --- | --- | --- |
| exit `0` | any | `SAFE` | Normal install path is safe for onboarding. |
| non-zero | exit `0` | `LAG_DETECTED` | Use `bundle install --full-index` until propagation catches up. |
| non-zero | non-zero | `METADATA_BROKEN` | Treat release metadata as broken; investigate before onboarding-safe claims. |

## Evidence Priority

Use this order when reviewing results:

1. Final install outcomes (normal and fallback exit behavior)
2. `results/tc/04/exact-version-acceptance.json` (acceptance verdict and findings)
3. Installed gem end state from scenario artifacts (receipts, consumer edges)
4. Supporting command telemetry (`stdout`, `stderr`, extra captures)

A release receipt is only complete when the classification, the acceptance
verdict, and a completed runner/verifier pipeline all agree.
