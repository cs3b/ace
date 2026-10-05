# Independent controlled installed SC3 review

Verdict: **APPROVE**, zero verified defects within this candidate and controlled installed scope.

Reviewed frozen candidate `b3b5447343fa87012c44b0d9319b05fdc2953b32`, base `bb7da4dd2289c7be2ef4ce37a26c7c2b0feb1715`; all eight changed test/docs files (810 added lines), task SC1–5, execution/proof/responsibility map, installed consumer and relevant runtime contracts. Reviewer worked independently in managed worktree `/Users/mc/.codex/worktrees/qjz-installed-independent/ace`. No source edits, publication, task completion or merge.

## Executed independent check

Command, from that worktree:

```sh
PATH=/Users/mc/.local/share/mise/installs/ruby/3.4.8/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin PROJECT_ROOT_PATH=/Users/mc/.codex/worktrees/qjz-installed-independent/ace bin/ace-test ace-hitl edge --filter installed_proposal_test --config-path /Users/mc/.codex/worktrees/qjz-installed-independent/ace/.ace-local/qjz-independent-review/runner.yml
```

Config duplicates the maintained opt-in config with only retention directory changed to `/tmp/ace-installed-sc3-independent`; no deadline/runtime mode overrides. Terminal exit 0; receipt `hitl/8x486t`: **1 test, 18,552 assertions, zero failures/errors/skips, 59.88698 seconds**. Raw receipt: `.ace-local/test/reports/hitl/8x486t/{report.md,report.json,summary.json,raw_output.txt,raw_stderr.txt}`. Stderr contains only existing Ruby benchmark deprecation warning.

Artifacts `/private/tmp/ace-installed-sc3-independent/run-6c9b7eb5b052`: `result.json`, `artifacts.json`, `build-provenance.json`, `processes.jsonl`, `canonical-evidence.json`, actual `effects` marker and fixture receipt. Source provenance binds exact candidate b3b5447; consumer SHA256 `447569704fa9cd926d04e7d9372d600043030446d1d82dec39e2b403cd8b25ff`; Ruby 3.4.8 SHA256 `569556af3cc4b3f3a7d5194c23f98c161b82af257bd67f0ee5fa692db6a28518`.

Consumer 38 meaningful behavior checks; controlled 57,600-second UTC policy advancement; decision approved-by-silence, actual final proposal succeeded. Exactly one succeeded canonical claim, marker `sc3-effect`, and executor start. Three service and eight actor starts, each paired with final exit provenance. Native binding records actual tmux `$0`/`%0`, shell PID96559 birth darwin:1791177996:629576, consumer PID96564 birth darwin:1791177996:665077, UID504. Installed versions, isolated GEM_HOME paths, loaded features and cached archive SHA256 assertions passed for all children.

Reviewed code creates via authenticated Client, asks Hermes Runtime to publish canonical pending proposals and polls normally. No manually injected inbox/queue, checkpoint, authorization, synthetic process identity or replacement binding/coordinator/executor/receipt verifier. Telegram adapter is explicitly controlled; executor is an actual fixed subprocess. Real kernel peer credentials and real process births remain active. False-success prevention includes failed submit leaving deadline absent, exact +16h acknowledgement deadline, before-deadline refusal, unchanged deadline after restart/retry, changed-input technical refusal before effect, single claim/effect after retry, failed poll refusal and subsequent healthy poll not inventing lost coverage.

## Retained evidence and criteria

Independently read original `hitl/8x4493` and `overseer/8x446m` summaries: HITL229 total with one skip, Overseer262 with none; both success/zero failures/errors. These are retained prior executions, not reruns by this reviewer. Verified `git diff --quiet d20cd8..b3b5447 -- ace-hitl/lib ace-overseer` exit0. Verified runtime lib/exe diff bb7..b3 is empty. Original installed proof integrity separately verified: all six retained evidence hashes and all 38 listed gem archive hashes match actual files.

| Criterion | Assessment |
|---|---|
| SC1 | Maintained policy tests cover before/exact/after16h and explicit approval/veto. Lifecycle tests cover revision, restart, uncertain delivery, ingress/claim races. New installed check independently covers before/exact, delivery failure, real restarts and lost coverage. Other cases rely on retained unchanged-source suite/review evidence. |
| SC2 | Reviewed maintained `test_all_precisely_presented_operation_classes_are_eligible` including deploy/privilege expansion, and lower-level exact authorization refusal. Independent installed scenario proves changed technical scope remains unauthorized after silence; no privileged deployment performed. |
| SC3 | Required full HITL/Overseer prior executed receipts remain applicable to unchanged runtime. New exact-candidate installed consumer independently passed, with one canonical authorization/receipt and no manual queue injection. |
| SC4 | Reviewed maintained stable revision identity, lost response after delivery/approval/later revision, changed binding and concurrent revision/effect winner tests; prior full source gate applies. Independent installed scenario creation retry preserves acknowledged deadline and execution retry returns existing receipt. |
| SC5 | Reviewed maintained character-bound/orphan-refusal, current-project grant and table/object/array-visible-deferral tests; prior full source gate applies. Installed consumer is not an additional deployed CLI proof. |

## Limits and policy

Approval is for the test/docs delta and controlled current-UID, one-host local installed SC3 scope. It establishes a controlled16h policy scenario, not16h wall-clock soak. It does not certify live Telegram, protected Herdr launcher, root-owned deployed grants, multiUID privilege separation, actual Lab deployment or operation-specific privileged acceptance. The test and docs state these limits accurately. Prior failures remain failures; none relabeled. No protected09j probes or broad parallel suite ran.

Loaded repository review/test skills and workflows. Full PR campaign/multi-round protocol is not certified here: this is one independent frozen-candidate verdict under the Captain executed-tests plus independent-review gate and the parent's narrowly authorized installed acceptance check. Existing converged source/public-contract reviews are referenced as retained evidence, not manufactured new review rounds. Parent owns final task acceptance and integration.
