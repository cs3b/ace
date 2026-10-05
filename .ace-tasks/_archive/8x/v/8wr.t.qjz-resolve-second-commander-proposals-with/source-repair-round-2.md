# Qjz independent review repair, round 2

## Candidate and review provenance

Rejected source: `722d079e93ef9b983252b16125249a260ea48738`.
Repair source and public contract: `d20cd8f6296c78ce14e66e1193d58d2a95a9b953`, based on frozen documentation head `36dc887f64a4084869e82b69f486be0866d7a400`, isolated in `/tmp/ace-qjz-revision-retry-repair`.

The earlier concurrent source/spec CLI invocations collided in session `review-8x43mu`. Its original spec feedback IDs `8x43p13y` and `8x43p13z` remain spec findings. The overwritten source report's five findings were recovered by root into distinct session `qjz-source-722-round2-recovered`, IDs `8x43z841` through `8x43z845`. Root independently reproduced them on the rejected source: HITL `8x43ya` (4 tests / 14 assertions, four failures), Overseer `8x43y5` (3 / 7, one failure). Both rejected verdicts are retained as historical evidence; this repair does not convert them into approvals.

## Repairs

- Stable revision operation ID and expected source revision are required through CLI, authenticated RPC and library API. The globally unique operation identity is bound to proposal/source/caller/content in the existing canonical event chain. Exact retry recovers the committed revision, including after acknowledgement, approval or another revision, without a new request or deadline reset. Changed bindings and stale-source competing operations refuse.
- Assign commits prior supersession and new prepared revision in one canonical CAS. The owner validates operation uniqueness and unresolved prior effects under that same mutation boundary, including direct lower-level API calls. Claims and revision race for one authority winner. No executor, journal or daemon is added.
- Creation returns persisted identity/current state immediately; delivery timestamp and deadline stay absent until acknowledgement.
- Ordinary questions retain the 240-character bound; canonical proposals retain their byte bound. Generic lifecycle creation refuses proposal kind before persistence.
- Requester proposal show/history and lifecycle proposal reads require current project authority; transport access remains project-scoped. File-backed grants read a fresh trusted document snapshot per authorization decision instead of retaining a stale memoized document.
- Lab status shows proposal deferral on stderr while remaining available. Object JSON additionally carries `proposal_resolution`; array JSON retains its existing schema and stderr diagnostic.

Public normative spec, acceptance cases, task usage, package usage and affected changelogs describe these intentional pre-1.0 interface changes. Task remains in progress and requires reviewed public/source acceptance and separate installed proof.

## Executed evidence

Maintained fail-before probes in this repair worktree:

| Receipt | Result | Reproduction |
|---|---|---|
| HITL `8x43va` | 1 test / 3 assertions, one failure | Lost revision response retry returns revision 3 rather than 2, even after acknowledgement/approval |
| HITL `8x43yv` | 2 / 1, one failure and one error | Generic proposal orphan accepted; ordinary multibyte question rejected |
| Overseer `8x43yv` | 4 / 8, two failures | Lab table and JSON silently hide failed tick |
| HITL `8x43z1` | 1 / 3, one failure | Original requester reads after current project grant revocation |

Final executed package gates on exact source `d20cd8f62`:

| Package | Receipt | Terminal result |
|---|---|---|
| HITL all | `8x4493` | 229 tests / 1,330 assertions, zero failures/errors, one existing multiUID skip; exit 0 |
| Overseer all | `8x446m` | 262 / 1,035, zero failures/errors; exit 0 |
| Hermes all | `8x448j` | 116 / 659, zero failures/errors; exit 0 |
| Contract all | `8x4498` | 21 / 897, zero failures/errors, one installed-consumer skip; exit 0 |
| Lab all | `8x44a4` | 179 / 603, zero failures/errors, one existing skip; exit 0 |
| Assign all | `8x44wp` | 849 / 3,693, zero failures/errors, two existing skips; exit 0, 799.48 seconds |

Hermes receipts `8x4465` and `8x447c` were failures (116 / 656, one failure), not passes: the Python plugin fixture reached a parent mise shim and refused the temporary checkout's config inside its isolated HOME. Host mise trust did not fix fixture trust. The final unchanged-source run selected the installed Ruby 3.4.8 and system Python with `PATH=/Users/mc/.local/share/mise/installs/ruby/3.4.8/bin:/opt/homebrew/bin:/usr/bin:/bin`, invoking the checkout's `bin/ace-test` and preserving deterministic isolation. Its report is under `ace-hitl-hermes/.ace-local/test/reports/hitl-hermes/8x448j`; the other final reports are under checkout `.ace-local/test/reports`.

Intermediate focused receipts are not substituted for exact final gates. The initial `--name` invocation was rejected by ace-test and the method-name `--filter` invocation selected zero files; neither is test evidence. File:line selection produced the actual fail-before `8x43va` result.

## Remaining gates

Full repaired Assign verification completed in owned session 87082 after the coordinated heavy-test slot became free. The checkout's `bin/ace-test ace-assign all` used unchanged deadlines and the same explicit Ruby/system-Python PATH documented above; `PROJECT_ROOT_PATH` selected this checkout. Its terminal exit was 0 and retained report/summary confirm receipt `8x44wp`. Original rejected-candidate full Assign remains baseline evidence only. Independent exact-source and amended public-contract re-review both approved the repair as recorded below. The installed controlled one-host sixteen-hour restart scenario (SC3) still requires execution and independent review; actual Telegram/native/multiUID and privileged operation acceptance remain separate. Source fixtures and skips satisfy none of those installed gates. No merge, push, release, task completion or installed success is claimed. No owned test session remains live.

The two spec feedback items and five recovered code items were shown, verified against the original source/root reproductions and maintained failures, and resolved against repair commit `d20cd8f62`. Feedback resolution records a repair, not independent approval.

## Independent converged verdicts

Root read the reports and empty feedback lists, and reported both terminal verdicts to the author:

- Normative specification and usage readiness: session `qjz-d20cd8-readiness-round3`, terminal 18455, **APPROVE, zero findings**, scoped to `d20cd8f6296c78ce14e66e1193d58d2a95a9b953`. This establishes public-contract readiness, not implementation or installed proof.
- Independent source repair re-review: session `qjz-d20cd8-source-round3`, terminal 34324, **APPROVE, zero findings**, same exact source head. Reviewer executed HITL 39 tests / 227 assertions and Overseer 5 / 13 with zero failures/errors. The final delta approval converges with retained prior rounds over the implementation ancestry; prior rejected heads remain rejected historical evidence.

The author did not self-review or promote the task. No runtime source or normative contract changed after `d20cd8f62`; later commits retain evidence only. Root owns integration with both independent verdicts and the executed source gates complete. Separate installed sixteen-hour and privileged-operation proof still gates program acceptance.
