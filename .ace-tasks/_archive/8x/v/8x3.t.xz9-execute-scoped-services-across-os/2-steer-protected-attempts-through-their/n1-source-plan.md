# N1 source ownership and test responsibility map

ACE baseline f1c76890d, branch codex/xz9-2-native-guard. Native source baseline
Herdr v0.9.3 annotated tag7eaf574ba6362c36c3d8fe89f411bb7d5bb34660 resolves to
commit7b116c05bfda646af39d2524c54e70c751f57ee8. Only source was cloned into
.ace-local/upstream/herdr; no external repository mutation is authorized.

The private source owner will retain its complete reviewed source patch and commit
in this task. Proposed later build selection is upstream URL + original commit +
patch content digest + resulting source revision, owned by the existing Lab
installation source. No published upstream version, merge or installed capability
is invented. N1 remains incomplete until source checks, review and actual selected
build/install source integration. N2 is not implemented here.

Recorded source friction before implementation: native TerminalId is term_ plus
hex micros/counter, not UUID. Normative UUID wording needs correction to actual
immutable source-owned terminal identity; runtime incarnation can remain UUID.
Root independently corrected normative identity in ACE462cdcd13, cherry-picked as fc7f50735; no terminal identity migration is introduced.

The task-plan CLI returned no output for several minutes and was interrupted with exit130; the exact accepted
N1 scope is the narrowed execution plan below, without speculative N2 code.
Toolchain selection is repository rust-toolchain.toml Rust1.96.1 plus required
Zig0.16.0. Compiler setup is authorized; no global configuration is selected.

## Implementation sequence

1. Closed guarded origin/request/outcome values and native read-only capability.
2. Linux original-child capture before wait: bounded identity reads, pidfd retained
   across verified birth, per-spawn runtime incarnation, immediate exit invalidation.
   Non-Linux/restored/handoff origins cannot claim guarded capability.
3. Carry exact origin from spawn through captured runtime to the existing PTY actor.
4. Exact ID-only app lookup and guarded focus/text/Enter submission, typed outcomes.
5. Actor first-write admission and immutable PTY pin; subsequent writes/Enter check
   exit/closure, truthful partial/unknown outcome; queue/full/handoff refusals.
6. Pure controlled producer checks plus static/type/build verification; source
   review, reproducible patch/commit and build-selection proposal.

## Test responsibility

| Behavior | Controlled layer | Boundary excluded |
|---|---|---|
| Closed fields/types/identity/text/wait | schema pure Rust values | no server/socket |
| Exact terminal ID versus name/pane | pure state/target selection | no spawn/PTY |
| Origin mismatch, unavailable/replaced child | pure guard value/state tests | native capture not executed |
| Prewrite dead/closed guard zero bytes | injected writer and origin state | no OS process/pidfd/PTY |
| Partial text/Enter failure or guard death | existing actor logic with controlled I/O seam | no real fd writes |
| Full focus/text/Enter acknowledgement | controlled writer, exact guard | not consumption |
| Queue-full/close/handoff | controlled queue/state gates | no native handoff |
| Bounded stat/status/boot parser | static synthetic bytes | no /proc read in tests |
| Cross-platform compile | cargo check/build-only | no product execution |

Only inspected pure test filters may execute. Broad just check/test recipes contain
real process/PTY tests and are excluded by Captain's restriction. Actual Linux
process birth/pidfd/PTY FD and installed multi-UID proof remain gad.2 obligations.
No source-only result may substitute for those acceptance rows.
