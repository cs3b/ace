# Release worker report: cycle-2b hotfix (REL3, 2026-10-29)

Role: release worker for the hotfix release phase (REL3), dispatched by the
ACE project captain. Worktree
`/lab/projects/ace/.ace-wt/overseer-lab92` (branch
`release-cycle2b-20261029`, base `7bb6c9e0a1af` = merged main with PR #82,
approval #236; PR #81 closed as duplicate). Release range:
`a9761fb5a..7bb6c9e0a` — the two hotfix commits from PR #82. Date:
2026-10-29.

Closure status: artifacts built + staged, suites green, committed and pushed
to the PR review lane. **No publication, no OTP, no merges** — the live
publish is handed off to the overseer/Captain lane via the staged pending
queue (see §6). Publisher needs an OTP from the Captain.

---

## 1. Inventory

### 1.1 Release range

Exactly the PR #82 merge content in `a9761fb5a..7bb6c9e0a`:

- `82b5e8d6f` — fix(hitl): fail closed on invalid case frontmatter and guard
  the ask/reply cycle
- `7bb6c9e0a` — fix(support-items): quote frontmatter flow elements and add
  strict parsing for mutations

### 1.2 Tool inventory (`.ace-bin/ace-rubygems-needs-release`, installed lab92-v2 toolchain)

Pre-bump: header only (`gem local remote status`, exit 0) — nothing pending
until the bumps below were applied. Post-bump (exit 0):

```
gem                local    remote   status
ace-support-items  0.15.16  0.15.15  pending
ace-hitl           0.24.3   0.24.2   pending
ace-hitl-hermes    0.9.6    0.9.5    pending
```

Exactly the expected hotfix set; no other gem pending.

### 1.3 Final release list (one line of evidence per package)

| Package | Bump | Evidence |
|---|---|---|
| ace-support-items | 0.15.15 → **0.15.16** | 7 changed files in range (`frontmatter_serializer.rb`, `frontmatter_parser.rb`, `field_updater.rb`, 3 test files, CHANGELOG); has `ace-support-items.gemspec` |
| ace-hitl | 0.24.2 → **0.24.3** | 2 changed files in range (`hitl_manager.rb` strict parse on the three case-file rebuild paths, CHANGELOG); has `ace-hitl.gemspec` |
| ace-hitl-hermes | 0.9.5 → **0.9.6** | 2 changed files in range (live-evidence E2E regression in `native_sync_test.rb`, CHANGELOG); has `ace-hitl-hermes.gemspec` |

Dependency floors need no edits: `ace-hitl` depends on
`ace-support-items ~> 0.15` and `ace-hitl-hermes` on `ace-hitl ~> 0.24` —
both cover the patch bumps.

## 2. Version bump + CHANGELOG (this release commit)

- ace-support-items 0.15.16: frontmatter flow-sequence elements serialize
  with the same quoting rules as flat values (a `: ` scalar round-trips as a
  string, not a single-pair hash); compound elements raise `ArgumentError`;
  strict `parse!` variant; `FieldUpdater` refuses to rewrite a file with
  invalid frontmatter YAML.
- ace-hitl 0.24.3: answer and field-update rebuilds parse the case file
  strictly — an unparsable block aborts the mutation instead of silently
  rebuilding from an empty frontmatter.
- ace-hitl-hermes 0.9.6: live-evidence regression for the answer-wake cycle
  (colon-bearing ask survives delivery stamping; native sync consumes the
  captain's reply; case answered; reply spool acked).

Dated 0.x changelog sections; Gemfile.lock refreshed (three PATH version
lines only).

## 3. Test suites (worktree binstubs, `ACE_TOOLCHAIN=auto` for source deps)

Run from the release worktree at the bumped versions:

| Package | Result |
|---|---|
| ace-support-items | 344 tests, 647 assertions, 0 failures, 0 errors |
| ace-hitl | 365 tests, 1918 assertions, 0 failures, 0 errors, 5 skipped (pre-existing skips) |
| ace-hitl-hermes | 221 tests, 1323 assertions, 0 failures, 0 errors |

The same suites were green in two independent checkouts during the PR #82
review (worker + reviewer panes); the monorepo fast suite ran 12,822 tests
with 51/53 packages green — the 2 non-green packages (`ace-herdr`,
`ace-test-runner-e2e`) fail identically without this diff (environmental:
`bwrap` binary absent; runtime namespace policy on the lab mount).

## 4. gitleaks

```
$ gitleaks detect --log-opts="a9761fb5a..7bb6c9e0a" --redact
2 commits scanned … no leaks found          (exit 0)
```

Re-run over the release range including the local release commits after
committing — still `no leaks found` (the release commits touch only version
files, changelogs, Gemfile.lock and this report).

## 5. Build + staged publish queue (`.ace-bin/ace-rubygems-publish`, installed toolchain)

### 5.1 Dry run → prepare

`--dry-run` printed exactly the 3 hotfix gems in 3 dependency waves;
`--prepare` validated credentials, built all 3 artifacts (3 newly built,
0 reused) and recorded `.ace-local/rubygems-publish/pending-queue.yml`:

```
1. wave 1  ace-support-items  0.15.16  ace-support-items/ace-support-items-0.15.16.gem
2. wave 2  ace-hitl           0.24.3   ace-hitl/ace-hitl-0.24.3.gem
3. wave 3  ace-hitl-hermes    0.9.6    ace-hitl-hermes/ace-hitl-hermes-0.9.6.gem
```

Every other ace-* gem reported `already published on RubyGems`. **No
publish, no interactive prompt, no OTP consumed.**

### 5.2 Staged artifacts — sha256 digests

| Artifact (wave) | sha256 |
|---|---|
| ace-support-items-0.15.16.gem (1) | `0ee763ea066f135375c3d9de7be92ccd81bfedc6fbdd86332dbf0608845bd951` |
| ace-hitl-0.24.3.gem (2) | `033fb8998d52f1004d3adc93984ad4c11cb9c89bb3efae46e48df86312d68853` |
| ace-hitl-hermes-0.9.6.gem (3) | `6a52a851d066a65434eba7c2d18957b2cb141f74248e4a99758e96dabdff2e5b` |

Artifact spot checks: the built versions are inside the artifacts
(`gem specification` reports 0.15.16 / 0.24.3 / 0.9.6) and none of the three
artifacts ship any `test/` files (0 matches per gem).

## 6. Handoff

The staged queue (`.ace-local/rubygems-publish/pending-queue.yml`) is the
publish contract: a later live run publishes exactly these 3 gems in wave
order (`ace-rubygems-publish --interactive`, OTP from the Captain, or
`--otp`/`GEM_HOST_OTP_CODE` per the tool contract). The overseer reports
staged-state to the Captain via HITL: **staged, publisher needs OTP**. No
publication, no OTP, no merges were performed by this worker.
