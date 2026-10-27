# Release worker report: cycle-2 (wake-20261027)

Role: release worker for the gad.2 cycle 2 release phase, dispatched by the
ACE project overseer (wake-20261025 recipe). Worktree
`/lab/projects/ace/.ace-wt/release-cycle2-20261027` (branch
`release-cycle2-20261027`, base `351368c5a3` = merged main, PR #79 "boring
broker"). The cycle's work was already merged into the base itself, so the
release range is `eb416468f..351368c5a3` — the 11 commits after the
gemset-20261026 release report commit (`eb416468f`) up to the base. Date:
2026-10-27.

Closure status: artifacts built + staged, suites green, committed locally.
**No push, no PR, no publication, no OTP** — the live publish is handed off
to the overseer/Captain lane via the staged pending queue (see §6).

---

## 1. Inventory

### 1.1 Release range

11 merged commits in `eb416468f..351368c5a3` (PR #79 lane):

- `491cbb020` — feat(hitl): add one-turn ask command
- `d8b239437` — feat(wake): top-level ace-wake source with statfs poll fallback and ask bridge
- `6e223c6ca` — feat(hitl)!: ask arms the answer wake and ends the turn
- `8b348922b` — feat(hitl-hermes): transport guards warn and proceed, never block
- `aae333f87` — feat(hitl-hermes): sync reads the project route config, one source per project
- `94289b725` — feat(hitl): formalize route recipients as first-class ordered data
- `1c42ac2b6` — docs(handbook): one-paragraph default instructions for asking the counterpart
- `c148ac240` — chore(ci): register ace-wake in the package test suite
- `15a2e2c14` — fix(wake): drive the pi-SDK acceptance harness at the moved ace-wake home
- `ee19182f7` — fix(hitl): ask completes on accepted-queued frames, rejects only on genuine failure
- `351368c5a` — docs(wake): make the documented test command reproducible in a bare checkout

Note on the `feat(hitl)!` marker (`6e223c6ca`): it reworked the `ask`
command introduced in the same unreleased cycle (`491cbb020`), so the net
change against released ace-hitl 0.24.1 is additive — patch bumps are
correct, no major/minor jump needed.

### 1.2 Tool inventory (`.ace-bin/ace-rubygems-needs-release`, installed lab92-v2 toolchain)

Pre-bump: header only (`gem local remote status`, exit 0) — nothing pending
until the bumps below are applied. Post-bump (exit 0):

```
gem                          local   remote  status
ace-hitl                     0.24.2  0.24.1  pending
ace-handbook                 0.36.2  0.36.1  pending
ace-hitl-hermes              0.9.5   0.9.4   pending
ace-handbook-integration-pi  0.7.2   0.7.1  pending
```

### 1.3 Final release list (one line of evidence per package)

| Package | Bump | Evidence |
|---|---|---|
| ace-hitl | 0.24.1 → **0.24.2** | 7 changed files in range (`lib/ace/hitl/cli.rb`, new `cli/commands/ask.rb`, `molecules/hitl_route_loader.rb`, docs, tests); has `ace-hitl.gemspec` |
| ace-hitl-hermes | 0.9.4 → **0.9.5** | 7 changed files in range (`hermes/cli.rb`, `hermes_native.rb`, native_folder/native_sync, docs, tests); has `ace-hitl-hermes.gemspec` |
| ace-handbook | 0.36.1 → **0.36.2** | new packaged guide `handbook/guides/asking-the-counterpart.g.md` (commit `1c42ac2b6`); gemspec globs `handbook/**/*` → packaged content changed |
| ace-handbook-integration-pi | 0.7.1 → **0.7.2** | 4 changed files in range (provider defaults `pi.yml`, docs, fast + feat tests); has `ace-handbook-integration-pi.gemspec` |
| ace-wake | **NOT a releasable gem** | top-level JS package: has `package.json`, **no `.gemspec`** in `ace-wake/` (verified: the gemspec listing covers 52 gems, none named ace-wake); verified via `node --test`, §3.5 |

### 1.4 Handbook conditional

The cycle's diff touches the handbook paragraph file itself (it creates
`ace-handbook/handbook/guides/asking-the-counterpart.g.md`), so the
conditional fired: appended exactly one line to that paragraph —
"completion ping: an agent that finishes work for another agent pings its
pane directly (herdr agent prompt)." — and verified the line is inside the
built ace-handbook-0.36.2.gem artifact (§5.2).

## 2. Version bump + CHANGELOG (committed as `ea4e99d71`)

Four patch bumps: `ace-hitl` 0.24.1 → **0.24.2**, `ace-hitl-hermes` 0.9.4 →
**0.9.5**, `ace-handbook` 0.36.1 → **0.36.2**,
`ace-handbook-integration-pi` 0.7.1 → **0.7.2** (each package's
`lib/**/version.rb`). Each `CHANGELOG.md` gained a dated
`## [x.y.z] - 2026-10-27` section under the empty `## [Unreleased]`
(Keep a Changelog), describing that package's cycle-2 changes. No gemspec
dependency-pin edits required (dependents' `~>` constraints still resolve:
e.g. hermes pins `ace-hitl ~> 0.24`, pi pins `ace-handbook ~> 0.33` /
`ace-hitl-hermes ~> 0.9.3`). `Gemfile.lock` refreshed by `bundle install` —
exactly the four PATH version lines changed, nothing else.

## 3. Test suites (worktree binstubs, `ACE_TOOLCHAIN=auto` for source deps)

### 3.1 ace-hitl — `bin/ace-test ace-hitl` (fast)

```
⚠️ 365 tests, 1858 assertions, 0 failures, 0 errors, 5 skipped (42.35s)
report: .ace-local/test/reports/hitl/98dc3ff0-7651-463b-860f-f699683ed2a5/
```

The 5 skips are all `CredentialPathPolicyTest`
(`test/fast/lifecycle/credential_path_policy_test.rb`) root guards
(`skip "exact provisioning layout requires root …" unless
Process.euid.zero?`) — environmental, unrelated to the cycle changes.

### 3.2 ace-hitl-hermes — `bin/ace-test ace-hitl-hermes` (fast)

```
✅ 220 tests, 1305 assertions, 0 failures, 0 errors (32.16s)
```

### 3.3 ace-handbook — `bin/ace-test ace-handbook` (fast)

```
✅ 64 tests, 397 assertions, 0 failures, 0 errors (941.88ms)
```

### 3.4 ace-handbook-integration-pi — fast + feat target

```
$ bin/ace-test ace-handbook-integration-pi
✅ 10 tests, 60 assertions, 0 failures, 0 errors (2.91s)
$ bin/ace-test ace-handbook-integration-pi feat
✓ feat complete (10.01s, 1 tests, 0 failures)
✅ 1 tests, 5 assertions, 0 failures, 0 errors (10.01s)
```

The feat target (`test/feat/pi_sdk_acceptance_test.rb`) is green as the
recipe requires.

### 3.5 ace-wake — `node --test test/*.test.mjs` (from `ace-wake/`)

```
ℹ tests 128   ℹ suites 19   ℹ pass 128   ℹ fail 0   ℹ duration_ms ~2550
```

Environmental note: run with `ACE_TOOLCHAIN=auto` exported. Under the
ambient `ACE_TOOLCHAIN=installed` posture the suite's first run showed
2 failures, both `ace-hitl create failed:` in
`test/report-wake-worktree.test.mjs` — that test spawns the worktree
`bin/ace-hitl` binstub, which (correctly) refuses to load source deps in
installed mode. With `auto` (the worktree-binstub posture the recipe
mandates for suites) all 128 pass. Not a code failure; no ace-wake change
made.

## 4. gitleaks

```
$ gitleaks detect --log-opts="eb416468f..351368c5a" --redact
11 commits scanned … no leaks found          (exit 0)
```

Re-run over the release range including the local release commits after
committing — still `no leaks found` (see receipt; the release commits
touch only version files, changelogs, the handbook guide line, Gemfile.lock
and this report).

## 5. Build + staged publish queue (`.ace-bin/ace-rubygems-publish`, installed toolchain)

### 5.1 Dry run → prepare

`--dry-run` printed exactly the 4 release gems in 4 dependency waves;
`--prepare` validated credentials, built all 4 artifacts (4 newly built,
0 reused) and recorded `.ace-local/rubygems-publish/pending-queue.yml`:

```
1. wave 1  ace-handbook                 0.36.2  ace-handbook/ace-handbook-0.36.2.gem
2. wave 2  ace-hitl                     0.24.2  ace-hitl/ace-hitl-0.24.2.gem
3. wave 3  ace-hitl-hermes              0.9.5   ace-hitl-hermes/ace-hitl-hermes-0.9.5.gem
4. wave 4  ace-handbook-integration-pi  0.7.2   ace-handbook-integration-pi/ace-handbook-integration-pi-0.7.2.gem
```

Every other ace-* gem reported `already published on RubyGems`. **No
publish, no interactive prompt, no OTP consumed.**

### 5.2 Staged artifacts — sha256 digests

| Artifact (wave) | sha256 |
|---|---|
| ace-handbook-0.36.2.gem (1) | `01991a7db276dfc831b974276cd343045116704e16fc38c615eee748765c90fc` |
| ace-hitl-0.24.2.gem (2) | `3d94213c05ff194066428d919c80f820d58faf30ad05ccea2b1ec005245452fc` |
| ace-hitl-hermes-0.9.5.gem (3) | `95a69b928347f250565ae34ee271ed99105c049da436a457ce2299d975e5d2a3` |
| ace-handbook-integration-pi-0.7.2.gem (4) | `cb278c86e64048e0a672847978f022775793acf7e5849afc729bb2c563f33757` |

Artifact spot checks: the built versions are inside the artifacts
(`VERSION = "0.24.2" / "0.9.5" / "0.7.2"` extracted from the gems), the
ace-handbook gem packages
`handbook/guides/asking-the-counterpart.g.md` **including** the
completion-ping line, and none of the four artifacts ship any `test/`
files (0 matches per gem).

## 6. Handoff

The staged queue (`.ace-local/rubygems-publish/pending-queue.yml`) is the
publish contract: a later live run publishes exactly these 4 gems in wave
order. The overseer reports staged-state to the Captain via Lab::ACE. No
pushes, no PRs, no merges, no HITL sends were performed by this worker.
