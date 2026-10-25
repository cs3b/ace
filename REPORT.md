# Release worker report: wake-20261025

Role: release worker per `WORKER-BRIEF.md`. Worktree
`/lab/projects/ace/.ace-wt/release-wake-20261025` (branch `release-wake-20261025`,
base `57b2f7fc` = merged main with PR74+PR75). Release range: `5f430fd6..57b2f7fc`
(changes since the eyes-20261023 cut). Date: 2026-10-25.

Closure status: artifacts built + staged, suites green, committed locally.
**No push, no PR, no publication** — the live publish is handed off to the
publisher (see §7).

---

## 1. Inventory

### 1.1 Tool inventory (`.ace-bin/ace-rubygems-needs-release`, pre-bump)

Network read-only (`gem search --remote`). Output: header only — every local
version equals the highest published version, i.e. nothing is pending **until
the version bumps below are applied**. Spot check of the five candidates
confirmed remote state: `ace-handbook (0.36.0)`, `ace-hitl (0.24.0)`,
`ace-hitl-hermes (0.9.3)`, `ace-overseer (0.26.0)`,
`ace-handbook-integration-pi (0.7.0)`.

### 1.2 Packaged-change inventory (git `5f430fd6..57b2f7fc`, verified against gemspec file lists)

Files changed in the range (21 files) were mapped to packages and filtered by
each gemspec's `spec.files` globs. A workflow-text change counts only where
`handbook/**/*` (or `lib/**/*`) is packaged — it is, in all five packages
below.

| Package | Bump | Changed packaged files | Source commit(s) |
|---|---|---|---|
| ace-handbook | 0.36.0 → **0.36.1** | `handbook/workflow-instructions/release/rubygems-publish.wf.md`, `handbook/skills/as-release-rubygems-publish/SKILL.md` | `80d606eca` (PR74) |
| ace-hitl | 0.24.0 → **0.24.1** | `handbook/workflow-instructions/hitl.wf.md` | `b5c684cc3` (PR74) |
| ace-hitl-hermes | 0.9.3 → **0.9.4** | `lib/ace/hitl/adapters/hermes_native.rb`, `lib/ace/hitl/hermes/molecules/native_folder.rb`, `lib/ace/hitl/hermes/organisms/native_sync.rb` | `57b2f7fc2` (PR75) |
| ace-overseer | 0.26.0 → **0.26.1** | `handbook/workflow-instructions/overseer.wf.md` | `f31597129` (PR74) |
| ace-handbook-integration-pi | 0.7.0 → **0.7.1** | `handbook/extensions/ace-wake/index.js`, `handbook/extensions/ace-wake/wake/types.js`, `handbook/extensions/ace-wake/wake/wake-registry.js`, `handbook/extensions/ace-wake/wake/watch-subscription.js` | `60b8c8b50` (PR74) |

Adjusted vs. the brief's expectation (two packages): the inventory says **five** —
the PR74 handbook/workflow text is packaged inside `ace-handbook`, `ace-hitl`
and `ace-overseer` via their `handbook/**/*` gemspec globs, so those packages'
shipped content changed too.

Changed in the range but **not packaged** (correctly excluded): `.ace-handbook/*`
and `.agents/skills/*` (worktree sync copies, no gem), `.ace-tasks/*` (task
data), `ace-handbook-integration-pi/docs/usage.md` + `test/js/*` (outside the
pi gemspec globs), `ace-hitl-hermes/test/*` (tests do not ship).

Dependency pins: no gemspec edits required. Verified no pin excludes the new
patch versions (`~> 0.9.3` allows 0.9.4; `~> 0.24` allows 0.24.1; `~> 0.26`
allows 0.26.1; `~> 0.32/0.33` allows 0.36.1; `~> 0.22` allows 0.24.1).

## 2. Version bumps + CHANGELOGs (committed)

Per-package patch bumps with Keep-a-Changelog entries dated 2026-10-25,
referencing PR74/PR75 (see §6 commit for full text). `Gemfile.lock` refreshed
by `bundle install` (exactly the five version lines changed — same as the
eyes-20261023 release commit).

## 3. Test suites (raw outputs)

All five affected packages, full suite (`bin/ace-test <package> all` = fast +
feat + edge; deterministic mode). Raw outputs + `report.json`/`summary.json`
retained under each report path.

```
$ bin/ace-test ace-hitl-hermes all
✅ 218 tests, 1277 assertions, 0 failures, 0 errors (32.08s)
report: .ace-local/test/reports/hitl-hermes/ac918d8e-6448-41bc-bbc0-128dbfea1ae6/
summary: passed 218, failed 0, errors 0, skipped 0, total 218, assertions 1277, success true
```
(Eyes-20261023 release baseline was 212/1228; +6 tests are the PR75
`native_hitl_adapter_test.rb` regressions, incl. the child-process
lazy-entrypoint NameError reproduction.)

```
$ bin/ace-test ace-handbook-integration-pi all
✅ 10 tests, 99 assertions, 0 failures, 0 errors (12.9s)
report: .ace-local/test/reports/handbook-integration-pi/8c825729-b145-478b-b0bb-6f7cb055f1f7/
summary: passed 10, failed 0, errors 0, skipped 0, total 10, assertions 99, success true
```
(Same 10/99 as the eyes cut's real-SDK validation; the fast suite shells out to
`node --test` for the extension JS suite. Node v24.19.0.)

```
$ cd ace-handbook-integration-pi && node --test test/js/*.test.mjs   # explicit raw record
ℹ tests 117
ℹ suites 17
ℹ pass 117
ℹ fail 0
ℹ cancelled 0
ℹ skipped 0
ℹ todo 0
ℹ duration_ms 2542.267467
```

```
$ bin/ace-test ace-hitl all
⚠️ 357 tests, 1806 assertions, 0 failures, 0 errors, 6 skipped (42.57s)
report: .ace-local/test/reports/hitl/6a8e923e-e377-4d3d-bf43-c755831cc004/
summary: passed 351, failed 0, errors 0, skipped 6, total 357, assertions 1806, success true
```
(Byte-identical to the eyes cut's release-validated full run: 357/1806, zero
failures/errors, six skips. The 6 skips are environmental `CredentialPathPolicyTest`
root-owned-layout cases + `MultiUidBoundaryTest`, requiring root/multi-uid;
they skip identically on the validated baseline.)

```
$ bin/ace-test ace-overseer all
✅ 373 tests, 1674 assertions, 0 failures, 0 errors (28.41s)
report: .ace-local/test/reports/overseer/f9ff0b3f-9f63-4c83-8699-4785353acee9/
summary: passed 373, failed 0, errors 0, skipped 0, total 373, assertions 1674, success true
```
(Identical totals to the eyes cut's 373/1674.)

```
$ bin/ace-test ace-handbook all
✅ 82 tests, 603 assertions, 0 failures, 0 errors (14.34s)
report: .ace-local/test/reports/handbook/2241ca59-da91-4018-a134-5a341aae0ff7/
summary: passed 82, failed 0, errors 0, skipped 0, total 82, assertions 603, success true
```

### 3.1 Monorepo-level checks (same as eyes-20261023 cut)

```
$ bin/ace-task doctor
860 tasks … 509 warnings … 📈 Health Score: 0/100 (Poor) — 509 warnings, completed in 4.13s
```
(Exactly the eyes-cut baseline: 509 pre-existing warnings, unchanged score.)

```
$ gitleaks detect --log-opts="5f430fd6..HEAD" --redact
8 commits scanned … no leaks found          (exit 0)
$ gitleaks detect --no-git --source <working diff> --redact
no leaks found                              (exit 0)
```
(Note: `gitleaks detect --no-git` on the worktree ignores file args in this
version and scans everything — 59 pre-existing findings across task/retro
fixtures, out of release scope. Both release-scoped scans are clean.)

```
Trailing whitespace in added lines: git diff 5f430fd6..HEAD → 0 hits; working diff → 0 hits
```

## 4. Build + artifact verification (same builder recipe as eyes-20261023)

Builder: `.ace-bin/ace-rubygems-publish` (publisher), `--dry-run` then
`--prepare` — the recipe that produced the eyes cut's
`.ace-local/rubygems-publish/pending-queue.yml`. `--prepare` validated the
credential via the read-only ownership probe (`gem owner ace-support-core`),
built all five artifacts with `gem build`, and recorded the queue. **No OTP
consumed, no push.**

```
$ .ace-bin/ace-rubygems-publish --dry-run ace-handbook ace-handbook-integration-pi ace-hitl ace-hitl-hermes ace-overseer
[DRY RUN] Would publish 5 gem(s) in 5 wave(s):
   1. wave 1  ace-handbook                         0.36.1     ace-handbook/ace-handbook-0.36.1.gem
   2. wave 2  ace-hitl                             0.24.1     ace-hitl/ace-hitl-0.24.1.gem
   3. wave 3  ace-hitl-hermes                      0.9.4      ace-hitl-hermes/ace-hitl-hermes-0.9.4.gem
   4. wave 4  ace-overseer                         0.26.1     ace-overseer/ace-overseer-0.26.1.gem
   5. wave 5  ace-handbook-integration-pi          0.7.1      ace-handbook-integration-pi/ace-handbook-integration-pi-0.7.1.gem

$ .ace-bin/ace-rubygems-publish --prepare …
✓ 5 artifact(s) ready: 5 newly built, 0 reused from disk (no rebuild)
Prepared all artifacts. Publish with: .ace-bin/ace-rubygems-publish --interactive
```

### 4.1 Staged publish queue (recorded by the publisher)

`.ace-local/rubygems-publish/pending-queue.yml`, recorded_at 2026-10-25T22:00:27Z:

| wave | gem | version | artifact |
|---|---|---|---|
| 1 | ace-handbook | 0.36.1 | `ace-handbook/ace-handbook-0.36.1.gem` |
| 2 | ace-hitl | 0.24.1 | `ace-hitl/ace-hitl-0.24.1.gem` |
| 3 | ace-hitl-hermes | 0.9.4 | `ace-hitl-hermes/ace-hitl-hermes-0.9.4.gem` |
| 4 | ace-overseer | 0.26.1 | `ace-overseer/ace-overseer-0.26.1.gem` |
| 5 | ace-handbook-integration-pi | 0.7.1 | `ace-handbook-integration-pi/ace-handbook-integration-pi-0.7.1.gem` |

(The manifest lives under gitignored `.ace-local/` by publisher contract — the
live run re-resolves from a fresh remote snapshot and treats the manifest as
ephemeral local state; the queue record above is the committed trace.)

### 4.2 Artifact SHA256 digests

```
62dd7319d219a36a3d19ff680a4b968fa5da0b7f60050e51fc2d089fd75055c1  ace-handbook/ace-handbook-0.36.1.gem
40917cc06e9a1599e00370508900a56fa4a8be4560ae9c78b8bc08d0430cf5cb  ace-hitl/ace-hitl-0.24.1.gem
59d28ee11a3dee9102800d437acc76b02eb2e409887d9a8182801a469d913b7c  ace-hitl-hermes/ace-hitl-hermes-0.9.4.gem
bdc7d6f317dc9ff3f6c777f1442d2352b245c973e4e02f3419eb79d622b1144c  ace-overseer/ace-overseer-0.26.1.gem
643e6b592fc2803e3104ec8d9a7f8d4e6c9f0359bb11cf604c65d4047b64e066  ace-handbook-integration-pi/ace-handbook-integration-pi-0.7.1.gem
```

### 4.3 Artifact content verification

- All 11 changed packaged files (§1.2) are present inside the built gems and
  **byte-identical to source** (`cmp` on extracted `data.tar.gz` members):
  11 identical, 0 differ.
- Publisher `validate_artifact!` confirmed each artifact's spec name/version.
- Isolated host GEM_HOME install (eyes-cut release verification): all five
  artifacts + published dependencies (43 gems total) installed into a clean
  temp `GEM_HOME` without source-path gems or Bundler/RUBYOPT/RUBYLIB
  overrides; all five exact versions (`ace-handbook 0.36.1`, `ace-hitl 0.24.1`,
  `ace-hitl-hermes 0.9.4`, `ace-overseer 0.26.1`,
  `ace-handbook-integration-pi 0.7.1`) activated together from the private
  install; PR75 regression proven on the **installed** artifact — the live
  lazy-entrypoint order raises `Ace::Hitl::Hermes::ContractError`, never
  `NameError`; the wake asset (`handbook/extensions/ace-wake/wake/watch-subscription.js`)
  ships in the pi gem. Temp GEM_HOME removed afterwards.

## 5. Commits (local only — no push)

| Commit | Content |
|---|---|
| `cb7876a24` | `chore(release): prepare semantic wake and hermes require-chain gems` — 11 files: 5 × `version.rb`, 5 × `CHANGELOG.md`, `Gemfile.lock` |
| *(this report)* | `docs(release)` commit of `REPORT.md`, created immediately after `cb7876a24` (`git log --oneline -3` shows both) |

`WORKER-BRIEF.md` remains untracked (brief input, mirroring the eyes cut).
Built `.gem` artifacts are gitignored by design (`*.gem` in `.gitignore`) and
remain on disk for the publisher.

## 6. Environment / toolchain

- ruby 3.4.8 (mise), node v24.19.0, gitleaks installed at `/usr/bin/gitleaks`.
- Publisher: `.ace-bin/ace-rubygems-publish` (repo-local, same recipe as eyes-20261023).
- Tests via `bin/ace-test` binstubs (BUNDLE_GEMFILE pinned to this checkout).
- Network use: read-only `gem search`/`gem owner` probes, `gem install` of
  published dependencies in the isolated GEM_HOME. No push, no publication,
  no credential read/print (existence + ownership probe only).

## 7. Handoff (publisher runs separately, with OTP)

Everything is prepared. The single live command for the operator is:

```text
Everything is ready — run in your terminal:
  .ace-bin/ace-rubygems-publish --interactive

It reuses the five prepared artifacts, then prompts once (silent) for the OTP.
Waves: 1 ace-handbook 0.36.1 · 2 ace-hitl 0.24.1 · 3 ace-hitl-hermes 0.9.4 ·
4 ace-overseer 0.26.1 · 5 ace-handbook-integration-pi 0.7.1
```

After the burst: post-publish verification per
`ace-handbook/handbook/workflow-instructions/release/rubygems-publish.wf.md`
(fresh dry-run + RubyGems metadata + `ace-test-e2e ace-monorepo-e2e TS-MONO-001`
with `ace-handbook/docs/release-rubygems-proof.md` classification).
