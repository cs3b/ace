# N1 frozen native producer source candidate

Candidate source commit: `96f14b6d8b8b7c712bf6d1f381c789fabdfe2050`.
Upstream baseline commit: `7b116c05bfda646af39d2524c54e70c751f57ee8`, resolved
from annotated v0.9.3 tag object `7eaf574ba6362c36c3d8fe89f411bb7d5bb34660`.
The private upstream source checkout is `.ace-local/upstream/herdr`, clean at the
candidate. There is no upstream publication, binary download, product execution,
installation, N2 implementation or installed acceptance claim.

The reviewable complete source patch is `n1-native-producer.patch`; exact source,
tree, patch, Cargo.lock and Rust toolchain digests are retained in
`n1-native-source-selection.json`. Cargo.lock and rust-toolchain.toml are unchanged
from the pinned upstream baseline. The patch was applied to a separate clean
baseline checkout using `git am --committer-date-is-author-date`; reproduced HEAD
is exactly the candidate SHA, with a clean tree. This proves source reconstruction,
not native behavior.

## Executed verification

Commands ran from the private source checkout with:
`PATH=/Users/mc/.cargo/bin:/Users/mc/.local/share/mise/installs/zig/0.16.0:/usr/bin:/bin`.
Compiler selection was explicit `cargo +1.96.1`; Zig0.16.0 built the existing
vendored dependency. The Linux standard target is `aarch64-unknown-linux-gnu`.
A global Rust default created by mise installation was explicitly unset; no
project/global defaults or production activation were selected.

| Exact final command | Executed result | Scope |
|---|---|---|
| `cargo +1.96.1 test --locked --bin herdr guarded_prompt_pure_tests` | PASS19, 3501 filtered out, 0.01s; build8.90s | In-memory selected functions only |
| `cargo +1.96.1 test --locked --bin herdr api::schema::tests::generated_protocol_schema_artifact_is_current -- --exact` | PASS1, 3519 filtered, 0.03s | Pure reflected JSON versus next API artifact |
| `cargo +1.96.1 test --locked --bin herdr api::schema::tests::bundled_protocol_schema_refs_resolve_inside_bundle -- --exact` | PASS1, 3519 filtered, 0.02s | Pure schema reference traversal |
| `cargo +1.96.1 check --locked --tests` | PASS19.60s | Whole macOS source/test typechecking, no tests executed |
| `cargo +1.96.1 check --locked --tests --target aarch64-unknown-linux-gnu` | PASS13.88s | Whole Linux source/test typechecking, including actual Linux guard module; no tests executed |
| `cargo +1.96.1 fmt --all -- --check` | PASS | Formatting |
| `git diff --check` | PASS | Whitespace |

The schema artifact was regenerated with the existing explicitly inspected pure
schema test and `HERDR_UPDATE_API_SCHEMA=1`; then the normal read-only freshness
check above passed. Only docs/next were updated. The generator uses schemars,
serde JSON and local source-document file I/O; it does not start Herdr or any child.
No broad just/native/process/PTY test recipe ran. The selected test functions were
inspected individually before execution.

## Coverage by proof layer

| Requirement | Executed controlled source evidence | Static integration join | Remaining installed/native proof |
|---|---|---|---|
| Closed request/origin fields, types, exact ID grammar, text bytes bound, no wait | Serde/schema/body validation tests | AgentPromptParams guarded validation precedes guarded dispatch | Actual authenticated server/build selection |
| Exact ID-only app admission | Production exact-terminal matcher tested against names, pane aliases, changed IDs and duplicates | Guarded app resolver uses that matcher then uniqueness; never generic resolver/focus | Real external request through selected server |
| Original child/runtime replacement | Guard equality tests; actual actor queued runtime replacement refuses with zero bytes | App compares complete origin before captured runtime queue; actor compares again | Actual spawn and replacement race |
| Child exit before first write | Actual actor handles queued dead origin with zero focus/text; direct prewrite writer test | Waiter invalidates immediately; flush checks live original handle before write | Native pidfd/process/PTY timing |
| Partial text then exit | Actual actor in-memory partial write suppresses Enter and replies uncertain | Same guard check runs for every actual owned File write | Native kernel write/exit interleaving |
| Full text + Enter, ACK only after Enter | Actual actor queue/flush/text boundary/Enter scheduler/completion test; exactly one ACK | App completion channel emits submitted plus exact origin | Native terminal delivery; never agent-consumption proof |
| Queue full/closed and handoff exclusion | Actual bounded queue distinct refusal codes/permit cleanup; multi-permit handoff gate tests | Same admission gate and held permit span queue through active completion | Actual live handoff/shutdown interaction |
| Linux identity fields/birth/groups | Static synthetic status/stat/boot parser tests | Bounded /proc reads, pidfd_open, identity recheck and UUID generation compiled for Linux | Real Linux identity/pidfd capture |
| Original PTY stays pinned | Actor methods execute one supplied in-memory writer; queued replacement refuses | Default runner owns captured File; no target lookup during writes, no reused FD | Real FD lifetime/restoration/handoff proof |
| Closed guarded error/result protocol and capability | Generated schema freshness/reference checks; guard error category tests | Typed guarded error, origin/submitted completion; single capability projection | Installed consumer compatibility and actual wire |

The private runner seam is generic only over its existing owned I/O and wake
objects, defaulting to File/OwnedFd in production. Selected actor tests use an
in-memory Read/Write object and descriptor sentinel. AsRawFd/read/native readiness
paths panic if called; tests never call run, spawn, resize, handoff syscall, polling,
actual capture or native child creation. The production scheduling and FD ownership
are not replaced by a separate test controller. Full App dispatch/server/thread
composition is a static join here; tests do not instantiate a native App.

## Build-selection and delivery ownership

The existing Lab installation source must explicitly select this candidate using
upstream URL + baseline commit + retained patch digest + exact resulting source
revision and toolchain/lockfile digests. A rebuilt product artifact needs its own
content digest and provenance; version0.9.3 alone cannot authenticate this patch.
The source proposal is not an installed binary selection, and no upstream merge
or published version is assumed. Owner integration must require actual guarded
capability and complete immutable origin from the selected server; older generic
prompt acknowledgment is insufficient. N2 consumes this public producer contract
only after its own prerequisites and independent review.

Task remains in progress. This source checkpoint has independent approval recorded below. Actual selected build/install source integration is outstanding;
Linux/native/installed runtime and multi-user acceptance remain gad.2 obligations.
Guard/write checks do not make kernel exit and write atomic. Lost acknowledgment,
partial writes and unknown completion must remain uncertain with no automatic
resend, and prompt submission never authorizes protected stop or cleanup.

## Independent exact-candidate source review

Root independently reviewed `96f14b6d8b8b7c712bf6d1f381c789fabdfe2050` and
returned **APPROVE as a frozen source checkpoint**, explicitly not complete
xz9.2/N1 installation. Review covered full schema/dispatch, exact target selection,
captured actor admission gate/writes/acknowledgment, synchronous Linux birth plus
pidfd and waiter invalidation, and the source-only controlled I/O seam. No
actionable source finding remained.

Root independently executed the inspected exact pure filter on the clean candidate:
`cargo +1.96.1 test --locked --bin herdr guarded_prompt_pure_tests`.
Result: PASS19, 3501 excluded, 0.00s. Root authorized the scoped ACE artifact commit.
Build/install source integration, N2 and installed acceptance remain outstanding.
