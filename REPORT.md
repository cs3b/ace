# Release worker report: gemset-20261026

Role: release worker for the gad.2 cycle 1 release phase, dispatched by the
ACE project overseer. Worktree
`/lab/projects/ace/.ace-wt/release-gemset-20261026` (branch
`release-gemset-20261026`, base `9b75eb44e` = merged main with PR #77).
Release range: `e38c669fe..9b75eb44e` (the single range commit). Date:
2026-10-26.

Closure status: artifact built + staged, suite green, committed locally.
**No push, no PR, no publication** — the live publish is handed off to the
operator (see §7).

---

## 1. Inventory

### 1.1 Release range

Exactly one merged commit in the range `e38c669fe..HEAD`:

- `9b75eb44e` — `feat(lab): converge the declared gem set into the target
  lab runtime` (PR #77; closes gad.2 acceptance gap #1, owner spec
  8xg.t.sbz.7, L8 install group).

One package affected: **ace-lab** (all 17 changed files live under
`ace-lab/`).

### 1.2 Tool inventory (`.ace-bin/ace-rubygems-needs-release`, pre-bump)

Output: header only (`gem local remote status`, exit 0) — every local
version equals the highest published version, i.e. nothing is pending
**until the version bump below is applied**. Spot check confirmed remote
state: `ace-lab (0.13.0)` via read-only `gem search --remote ^ace-lab$`.

### 1.3 Packaged-change inventory (git `e38c669fe..9b75eb44e`, verified against the ace-lab gemspec file lists)

The gemspec globs are `lib/**/*`, `docs/**/*`, `exe/*`,
`.ace-defaults/**/*`, `*.md`, `LICENSE`, `Rakefile`. Of the 17 changed
files, **9 are packaged** (plus `lib/ace/lab/version.rb` changed by the
bump itself → 10 verified inside the artifact, §4.3):

| Package | Bump | Changed packaged files | Source commit |
|---|---|---|---|
| ace-lab | 0.13.0 → **0.13.1** | `CHANGELOG.md`, `docs/usage.md`, `lib/ace/lab/atoms/install_schema.rb`, `lib/ace/lab/cli/commands/prepare.rb`, `lib/ace/lab/cli/commands/verify.rb`, `lib/ace/lab/molecules/gemset_provisioner.rb`, `lib/ace/lab/organisms/install.rb`, `lib/ace/lab/organisms/prepare.rb`, `lib/ace/lab/organisms/verify.rb` | `9b75eb44e` (PR #77) |

Changed in the range but **not packaged** (correctly excluded): the 8
`ace-lab/test/*` files (`test/atoms/install_schema_test.rb`,
`test/commands/install_test.rb`, `test/commands/prepare_test.rb`,
`test/molecules/gemset_provisioner_test.rb`,
`test/organisms/install_test.rb`, `test/organisms/prepare_test.rb`,
`test/organisms/verify_test.rb`, `test/test_helper.rb`) — `test/` is not
in the gemspec globs; tests do not ship. Confirmed against the built
artifact: no `test/` files inside the gem (§4.3).

Dependency pins: no gemspec edits required. The ace-lab runtime deps
(`ace-support-cli ~> 0.6`, `ace-support-core ~> 0.31`,
`ace-support-config ~> 0.18`, `ace-git-forgejo ~> 0.7`) are unchanged by
the range and none of them are republished.

## 2. Version bump + CHANGELOG (committed)

Single patch bump: `ace-lab/lib/ace/lab/version.rb` `0.13.0` → **0.13.1**.
`ace-lab/CHANGELOG.md` gained the dated `## [0.13.1] - 2026-10-26` /
`### Added` section (Keep a Changelog) from the previously Unreleased
gem-set entry, now referencing PR #77; an empty `## [Unreleased]` section
remains on top (same shape as the wake-20261025 cut). `Gemfile.lock`
refreshed by `bundle install` — exactly the one `ace-lab (0.13.1)` PATH
version line changed, nothing else.

## 3. Test suite (raw output)

Full suite, deterministic mode (`bin/ace-test ace-lab all` via the
checkout binstub, `ACE_TOOLCHAIN=auto`):

```
$ bin/ace-test ace-lab all
⚠️ 594 tests, 2808 assertions, 0 failures, 0 errors, 4 skipped (18.48s)
report: .ace-local/test/reports/lab/9412000a-732d-47df-ab17-fe2b3a550d15/
summary: passed 590, failed 0, errors 0, skipped 4, total 594, assertions 2808, success true
```

Matches the brief's expectation of ~594 tests with zero failures/errors.
Reproduced twice through the runner (18.48s / 18.52s, same totals).
Per-phase subtotals (full run): atoms 85, molecules 294, organisms 132,
models 22, commands 61 = 594.

### 3.1 The 4 skips — environmental, identified individually

Molecules phase (3), all `ForgejoMergeAdapterTest` (guard at
`test/molecules/forgejo_merge_adapter_test.rb:33`):

```
ACE_LAB_TEST_FORGE_TOKEN is not set — adapter acceptance needs a scoped token
against https://forgejo.tail6c0887.ts.net (deployed acceptance happens later
against the provisioned /etc/lab/ace-lab/forge-merge.yml)
```

Commands phase (1):

```
FreshInstallTest#test_installed_cli_succeeds_with_controlled_grants
(test/commands/fresh_install_test.rb:56): requires root plus
ACE_LAB_TEST_SYSTEM_GRANTS=1 on a disposable host to provision
/etc/lab/ace-lab/authorization.yml
```

Both guards are deliberate deterministic-mode postures (no live
credentials, no root provisioning during release verification); they skip
identically regardless of the release changes. Note these are separate
from the `build_and_install_gem` sandbox skips in `test_helper.rb` (which
did NOT fire — the gem-toolchain fixture built and installed cleanly).

### 3.2 Monorepo-level checks (same as wake-20261025 cut)

```
$ gitleaks detect --log-opts="e38c669fe..HEAD" --redact
1 commits scanned … no leaks found          (exit 0)

Trailing whitespace in added lines:
git diff e38c669fe..HEAD --check → 0 hits; working diff --check → 0 hits
```

## 4. Build + artifact verification

Builder: `.ace-bin/ace-rubygems-publish` (publisher, repo-local), `--dry-run`
then `--prepare` — the wake-20261025 recipe that produced the
`.ace-local/rubygems-publish/pending-queue.yml`. **No OTP consumed, no
push, no `--interactive`.**

```
$ .ace-bin/ace-rubygems-publish --dry-run ace-lab
[DRY RUN] Would publish 1 gem(s) in 1 wave(s):
   1. wave 1  ace-lab                              0.13.1     ace-lab/ace-lab-0.13.1.gem

$ .ace-bin/ace-rubygems-publish --prepare ace-lab
✓ 1 artifact(s) ready: 1 newly built, 0 reused from disk (no rebuild)
Prepared all artifacts. Publish with: .ace-bin/ace-rubygems-publish --interactive
```

The artifact was built from the post-bump tree, i.e. it matches release
commit `01d6b77a6` byte-for-byte in packaged content (proven in §4.3).

### 4.1 Staged publish queue (recorded by the publisher)

`.ace-local/rubygems-publish/pending-queue.yml`, recorded_at
2026-10-26T14:06:52Z:

| wave | gem | version | artifact |
|---|---|---|---|
| 1 | ace-lab | 0.13.1 | `ace-lab/ace-lab-0.13.1.gem` |

(The manifest lives under gitignored `.ace-local/` by publisher contract —
the live run re-resolves from a fresh remote snapshot and treats the
manifest as ephemeral local state; the queue record above is the committed
trace.)

### 4.2 Artifact SHA256 digest

```
2bd349c2b1924c798023d4ce3ab6b412064785af3745d50e1270ba585dd557ba  ace-lab/ace-lab-0.13.1.gem
```

(104960 bytes; gitignored by design via `*.gem` in `.gitignore`, remains on
disk for the operator.)

### 4.3 Artifact content verification

- Gem spec: `ace-lab` version `0.13.1` (`gem specification`).
- All **10** changed packaged files (§1.3, incl. the bump-touched
  `lib/ace/lab/version.rb` and `CHANGELOG.md`) extracted from the gem's
  `data.tar.gz` and **byte-identical to source** (`cmp`): 10 identical,
  0 differ.
- Negative check: no `test/` files inside the gem — the 8 unpackaged test
  files correctly do not ship.
- Full gem file list matches the gemspec globs: 58 packaged files
  (`lib/**/*`, `docs/usage.md`, `exe/ace-lab`, `.ace-defaults/lab/config.yml`,
  `README.md`, `CHANGELOG.md`, `LICENSE`, `Rakefile`).

Deviation vs. wake-20261025 §4.3 (per brief scope): the isolated-host
GEM_HOME install + activation regression proof was not repeated; the brief
scoped step 5 to digest + extract/`cmp` content verification, and the
changed code's behavior is regression-proven in-tree by the PR #77 test
files (gemset provisioner/schema/verify organisms), which run in the §3
suite.

## 5. Commits (local only — no push)

| Commit | Content |
|---|---|
| `01d6b77a6` | `chore(release): prepare the ace-lab 0.13.1 gem-set convergence gem` — 3 files: `ace-lab/lib/ace/lab/version.rb`, `ace-lab/CHANGELOG.md`, `Gemfile.lock` |
| *(this report)* | `docs(release)` commit of `REPORT.md`, created immediately after `01d6b77a6` |

Built `.gem` artifact and the pending queue are gitignored by design and
remain on disk for the operator. No other files touched; worktree clean
after both commits.

## 6. Environment / toolchain

- ruby 3.4.8 (mise), gitleaks at `/usr/bin/gitleaks`, node v24.19.0
  available.
- Publisher: `.ace-bin/ace-rubygems-publish` (repo-local, same recipe as
  wake-20261025). Inventory: `.ace-bin/ace-rubygems-needs-release`.
- Tests via `bin/ace-test` binstubs (BUNDLE_GEMFILE pinned to this
  checkout; `ACE_TOOLCHAIN=auto` authorized in this worktree for test
  execution only). Vendor bundle pre-provisioned at `.ace-local/vendor/bundle`.
- Network use: read-only `gem search --remote` probe only. No push, no
  publication, no credential read/print, no OTP consumed.

## 7. Handoff (operator runs separately, with OTP)

Everything is prepared. The single live command for the operator is:

```text
Everything is ready — run in your terminal (FROM THE MERGED MAIN CHECKOUT):
  .ace-bin/ace-rubygems-publish --interactive

It reuses the prepared artifact, then prompts once (silent) for the OTP.
Wave: 1 ace-lab 0.13.1
```

Note: the staged queue record (§4.1) points at this worktree's absolute
artifact path; running `--interactive` from the merged main checkout after
the overseer lands the release commit re-resolves and rebuilds/reuses the
`ace-lab-0.13.1.gem` from that checkout per publisher contract (fresh
remote snapshot, ephemeral local state). The digest in §4.2 is the
worktree-built artifact of record for this cut.

After the publish: post-publish verification per
`ace-handbook/handbook/workflow-instructions/release/rubygems-publish.wf.md`
(fresh dry-run + RubyGems metadata).
