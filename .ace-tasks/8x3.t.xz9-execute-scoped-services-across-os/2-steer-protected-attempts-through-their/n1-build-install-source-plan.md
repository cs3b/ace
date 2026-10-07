# N1 packaged source selection and Lab build/install integration

Scope continues xz9.2 N1 on reviewed producer source96f14b6d8b8b7c712bf6d1f381c789fabdfe2050,
patch SHA2566478a65a19276e952906211276b23b1e3579073a9c465efa65f636191f137eb2.
Task remains in progress. No native build/product execution, root/VM/native probes,
deployment, publication or installed acceptance is authorized in this source pass.

## Existing owners and shipped assets

ACE ace-herdr owns generic pinned native source/build/provenance validation. Its
existing gemspec ships lib/**, so the reviewed patch and strict source selection
live under lib/ace/herdr/native_source/, not .ace-tasks or a developer checkout.
No new daemon, signer, authority or delivery ledger is introduced.
Lab-config owns installation policy, deployment selection and Lab consumer paths.
All Lab-owned servers and CLI routing select /usr/local/lib/lab/herdr, with no
mutable mo mise/latest fallback and no changes to mo's global mise/default tools.

## Public source interface

`ace-herdr native-source selection` prints one JSON object containing the packaged
selection path/digest and full closed source descriptor. It does not contact a
server or run a native product.

`ace-herdr native-source build --source BASELINE_GIT_CHECKOUT --output NEW_DIRECTORY
--target x86_64-unknown-linux-musl` builds only from the selected pinned source.
The aarch64-unknown-linux-musl target is also allowed, matching upstream release
source. Output must not exist. The builder creates an isolated source copy from
local Git objects, applies the exact packaged patch with reproducible commit
metadata, verifies exact candidate commit/tree, unchanged Cargo.lock/toolchain
file digests, and a clean tracked source. It selects Rust1.96.1 and Zig0.16.0,
records actual selected compiler executable digests, then uses upstream's release
recipe `cargo build --release --locked --target TARGET`. It never executes the
resulting Herdr program. No caller changes the accepted source or patch selection.
Compilation will not run in the present source task; controlled tests inject only
the compiler boundary. Output is herdr plus provenance.json.

`ace-herdr native-source verify --artifact DIRECTORY` validates the closed receipt
against packaged source selection and observed binary bytes, returning one JSON
object with verified source/build/artifact fields. Receipt validation is provenance,
not deployment authorization. A generated receipt cannot select its own trust.

Source descriptor includes repository URL, baseline commit, candidate commit/tree,
patch filename/digest, Cargo.lock and rust-toolchain file digests, Rust/Zig versions,
upstream native version/protocol, deterministic committer metadata, allowed targets.
Build receipt `ace.herdr.native-build/v1` binds packaged selection SHA256, complete
selected source, target/release profile, observed tool versions/executable digests,
and artifact filename/size/SHA256. Unknown fields/types, invalid digests, wrong
source/patch/lock/toolchain, unsupported target, dirty or mismatching source,
missing tools, compiler failure, partial/missing/symlink output all refuse success.

## Domain installation interface and trust

Lab's existing installer invokes the exact accepted ACE package owner selected by
a root/deployment-owned installation descriptor, not highest installed gem version.
The independent deployment selection `lab.herdr.native-selection/v1` binds accepted
ACE package version, packaged selection digest, target, artifact SHA256 and build
receipt SHA256. Actual artifact digest is populated only after an authorized real
build plus review; examples are nonactivated and no fake digest/version is shipped.
The provenance's own artifact digest never supplies this independent pin.

The Lab installer validates trusted regular files and complete non-writable parent
paths before any replacement. It calls ACE's canonical provenance verifier, holds
and hashes input bytes, compares independent deployment pins, and installs one
root-owned fixed binary plus matching source/build provenance. No product is run
to obtain a version or capability during install. A missing/mismatching selection
refuses before Herdr integration hooks/server startup. Same selected bytes are
idempotent; failure preserves the previously accepted binary/provenance.

Recorded integration friction: existing install.sh blindly copies mutable
mo mise/latest twice, and main/mo units plus lab.py/labd.py route there while scoped
servers route to /usr/local/lib/lab/herdr. That split cannot select guarded source.
Existing install-host's legacy Work check is not protected maintenance admission.

Required final update join remains in this SAME source scope: gad.8/gad.b installation
owner consumes exact9c2 with_execution_slots, slot_reusable! and
retire_released_parent! to prove whole affected deployment eligibility before any
runtime replacement. Host maintenance executor/runtime/auth verifier and durable
receipt sink remain outside replaced deployment. No caller exemption or a
provenance-only authorization gate is allowed. First-install/idempotence with
safe different-artifact refusal can be implemented as WIP; permanent refusal is
not complete delivery. The exact frozen9c2 interface and complete inventory/history
producer join must land before promoting the final updater. No hidden child/task
or installed-only transfer of missing source is introduced.

## Test responsibility

| Behavior/risk | Layer and executed source plan | Excluded acceptance |
|---|---|---|
| Shipped patch/descriptor and gem export, high | ACE package fixture built/extracted from actual gemspec; paths/digests verified outside task tree | RubyGems publication |
| Closed selection/receipt, tampered fields and bytes, high | Ruby value/parser tests with static bytes | Authentic build host |
| Git baseline/patch/exact source reconstruction, high | Ordinary local Git fixture repository and controlled source-only checkout | No native process execution |
| Compiler/tool selection/order/failure and partial output, high | Builder orchestration with injected compiler runner; actual source owner not mocked | Actual native build |
| Public selection/verify/build CLI and errors, high | ACE command tests with compiler boundary seam | Product runtime/wire |
| Independent deployment pin versus self-asserted receipt, high | Lab installer synthetic trusted files; real temporary filesystem bytes/atomic writes, root/ACL policy boundary controlled | Real Linux root/ACL acceptance |
| Fixed common Lab path and no latest fallback, medium | Installer/unit/consumer source contracts and bash syntax; existing focused Lab tests | Service restart/native probe |
| Maintenance replacement refusal and final exact9c2 join, high | WIP refusal tests now; controlled exact canonical admission/inventory/history integration once frozen | Installed surviving writers/quiescence |
| Failure preservation/idempotence, high | Temp filesystem old/new artifact receipts; no effects on rejection | Production rollback/reboot |

ACE package tests use bin/ace-test directly, scoped to inspected new controlled
source tests. Lab tests use python3 unittest focused modules and portable installer
contracts after inspection; native/root/Docker/Incus test bodies are excluded.
Source ship tests export actual reviewed source and assert freshness/asset presence.
Changes to Lab task files require tests.test_task_ids and ace-task doctor. Root
independent exact-candidate review precedes scoped commits/push. This plan preserves
actual build/install selection and final maintenance consumer obligations.

Source verification friction: the initial focused test load failed before executing tests because the RubyGems package require used `gem/package`; corrected to `rubygems/package`. No pass was claimed.

Build host boundary: source build supports only a native Linux host matching the selected x86_64 or aarch64 musl target. Cross compilation is rejected. The build owner must provision a native musl-gcc toolchain, pinned Rust and Zig beforehand; the builder selects and hashes the resolved musl-gcc executable, sets the exact target Cargo linker and explicit ZIG/RUSTC paths. No global tool installation/default changes. Controlled tests verify selection and invocation, and do not establish that a real product build has succeeded.

Controlled verification checkpoints: packaged model/CLI/gem archive target passed 13 tests/41 assertions (report e564d16d-d382-414d-b715-e4ddac6a321c); actual local Git reproduction plus intercepted compiler target passed 7 tests/43 assertions (db5783dd-0923-4c65-aaaa-7e5e7cf069dc). Initial source test failures revealed parser duplicate-key handling and missing CLI runtime helper; repaired before these passing runs. A builder fixture initially compared lexical /var paths with selected /private/var realpaths; fixture now uses canonical paths. No native compiler, product, PTY, process-identity/security/root/VM/installed acceptance was executed. Existing broad bounded-process tests include process probes and were not run; controlled Git reproduction exercises the added absolute chdir support.

This checkpoint delivers the packaged source model/public CLI/builder only. Lab selected installer, canonical 9c2 update authorization/release join, root-selected actual build artifact, N2, and central gad.2 installed acceptance remain required. No deployment pin or published native/gem version is invented.

Frozen source checkpoint for independent review (uncommitted atop a0742c6c): final model/CLI/installed asset default lookup target PASS13/42, receipt cc8f4bee-5963-4360-863d-0269aa000e86; builder target PASS7/43, receipt9378c8cc-c58c-4c04-8629-9f82c13d7e37. Embedded source protocol float is rejected by canonical typed validation. Actual extracted package module is loaded in an isolated Ruby module and resolves its default assets outside the task/source checkout.

```json
{
  "ace-herdr/lib/ace/herdr.rb": "f50337700e5c93e3dfde89cc054c85f546019c3b9c778f95e65ebe8cc31d48e7",
  "ace-herdr/lib/ace/herdr/cli.rb": "6095ea4421d0d837dde58f70943b8ff2cbdead4e9dea26c84eb52d9a3e189c9f",
  "ace-herdr/lib/ace/herdr/cli/commands/native_source.rb": "13a7067a921c3033fbb8ddbe844856eb4871b6059bef4405bec447e6f51f45de",
  "ace-herdr/lib/ace/herdr/molecules/bounded_process.rb": "71da95bffb5481e37db813eabf5ea2e68d27a1cf49ea3d27f6360cec85169a1c",
  "ace-herdr/lib/ace/herdr/molecules/native_source.rb": "1a1b33e34ba4811d73b8fcb0c3d4925a41d937b6dab5f69022586276b329d658",
  "ace-herdr/lib/ace/herdr/organisms/native_source_builder.rb": "7de7927f88c8feca6054ea676a1267e9909b94a9a0b548932672f7c46faaae23",
  "ace-herdr/test/fast/molecules/native_source_test.rb": "a211ef8d9da58018dde416fd278bcf3df724ba59101eef225144fb6702c11de1",
  "ace-herdr/test/fast/organisms/native_source_builder_test.rb": "202a047d782fee3d3c036c735916b045ce43881e478e839c51552dd8844b0cc3",
  "ace-herdr/docs/usage.md": "fd70fdb5f167faf19e288aa8dd6aa2ea0db15f0053fad87543099c5c4acb0c7b",
  "ace-herdr/lib/ace/herdr/native_source/HERDR-LICENSE": "c71d239df91726fc519c6eb72d318ec65820627232b2f796219e87dcf35d0ab4",
  "ace-herdr/lib/ace/herdr/native_source/guarded-prompt.patch": "6478a65a19276e952906211276b23b1e3579073a9c465efa65f636191f137eb2",
  "ace-herdr/lib/ace/herdr/native_source/selection.json": "e69b414bf6989d74924614af0735b1f12e59d7dbb9176bddb56fc164e2223a9b"
}
```

Independent root source/CLI/assets/builder review APPROVE this checkpoint after the narrow docs clarification: Cargo may fetch locked dependencies over the network; the builder does not contact a running Herdr server. Root independently executed `bin/ace-test ace-herdr fast test/fast/molecules/native_source_test.rb test/fast/organisms/native_source_builder_test.rb`: PASS20/85, receipt c65362f6-e04d-49aa-9259-90f48fe8c6ed. This is source checkpoint approval, not native build/install/whole N1 acceptance.
