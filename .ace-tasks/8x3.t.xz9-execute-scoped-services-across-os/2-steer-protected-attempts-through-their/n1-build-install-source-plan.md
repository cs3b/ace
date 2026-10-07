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

Protected binary reader responsibility: existing ProtectedArtifactSet gains explicit trusted per-instance file/total byte budgets, positive Integer and file<=total, keeping defaults1MiB/16MiB and fixed256reference count unchanged. Installer code selects its256MiB binary cap; no untrusted pin or CLI flag chooses budgets. Its selection/receipt reads remain individually64KiB. Controlled existing owner tests cover default large-file refusal, custom exact bound/retained reference identity, per-file+per-read refusal, over-total refusal across reads, and malformed budgets. Native mount/ownership protection is injected; no new generic root-protection reader. Executed `bin/ace-test ace-runtime fast test/molecules/protected_artifact_set_test.rb`: PASS9/34, report40ffbe83-e5f9-454d-a89d-252552e4fb27, 10.62ms. Independent review pending before this small source checkpoint commit.

Independent root APPROVE exact reader budget diff (source440de07af/tests5749d29ee): trusted positive Integer file<=total, unchanged default1MiB/16MiB and count, generic protection retained. Root independently executed `bin/ace-test ace-runtime fast test/molecules/protected_artifact_set_test.rb`: PASS9/34, report514a6b0c-415e-4b30-b9a8-e015a194d9a0. This approval covers the small shared byte-budget source checkpoint only.

Operational Lab installer next source slice (before implementation): domain `lab_herdr_native.rb` consumes the existing dedicated exact-version ACE bundle, fixed independently protected `/etc/lab/herdr-native-selection.json`, fixed artifact root `/var/lib/lab/herdr-native-artifacts/<artifact-sha256>/`, fixed output `/usr/local/lib/lab/herdr`, and fixed installed provenance. Root-selected source metadata supplies exact package versions, not generated native provenance. The selected pin has closed schema, explicit source/artifact/receipt SHA+length+target and original/candidate descriptor digests plus the exact trusted stop set. No caller flags select units/paths/budgets. Use generic ProtectedArtifactSet held bytes and NativeSource verification; install retained held bytes rather than reopening copy source.

Before binary effects, validate all selection, package, artifact and descriptor bindings. Native paths in all selected fixed roots must select the same artifact. Durable domain inhibitor is fsynced with its parent before service stop; error leaves it present. Inside LaunchLifecycle.with_execution_slots: validate every immutable context with slot_reusable!, perform retire_released_parent! for every context, publish held binary/provenance and candidate descriptor, invoke required gad.8/.b current-boot host refresh, verify complete candidate publication, then clear inhibitor with parent fsync. Listener stop does not prove worker closure. Actual host refresh source API is still an explicitly tracked domain producer prerequisite; no successful refresh is invented.

Controlled Lab test map: strict independent-pin mismatch/type/unknown/duplicate/refusal; real temporary filesystem held-byte first install and idempotence; canonical owner composition order+all-context preflight; active/uncertain gate refusal leaves old binary; exact stop selection; faults before/between binary/provenance/descriptor publication and host refresh retain inhibitor; full validated update clears it. Service/native/kernel operations injected, never executed. Fixture native bytes are nonexecuted ELF-shaped data. Actual generic owner joins use existing9c2 source where supported and final combined source contract verification follows its frozen review. Central installed native acceptance remains gad.2.

Operational fixture friction: first controlled Lab test refused a macOS /var temporary-path symlink ancestor through the real generic artifact reader (no native protection invoked). Canonicalize only disposable fixture roots with File.realpath; production root paths remain exact/non-normalizing. Recorded before fixture repair.

Installer WIP review findings recorded: root identified published-original-only check defeating candidate idempotence; incomplete service stop set; unprotected refresh File.file? check; insufficient total budget for selected+old max binaries; and long-lived output ancestor snapshots invalidated by our inhibitor. Repairs in progress, no final approval or activation claim. Current controlled Lab test exercises first installation, exact published-candidate idempotence, old-runtime→new update, active/uncertain gate refusal preserving old bytes/inhibition, failed-refresh same-transaction recovery, and independent pin mismatch. PASS `python3 -m unittest tests.test_herdr_native_install` (one source composition test, multiple disposable scenarios,0.111s), eligibility/service owners controlled; this does not execute or prove actual canonical eligibility. Remaining service inventory/refresh ownership, release bootstrap and actual9c2 source composition remain explicit.

Controlled path suite friction before continuation: `python3 -m unittest tests.test_chief tests.test_authorize_scope tests.test_hitl_channels tests.test_herdr_native_install` executed177 tests with one existing fixture leak: ChannelLivenessTest.test_labd_channel_state_comes_from_the_root_pane_observation called unstubbed broker pane listing and attempted absent /usr/bin/setpriv (FileNotFoundError on macOS; no native/security command executed). Must stub that product boundary before rerunning; no broad native or installed claim.

### Mapping digest source seam (2026-10-07)
Root authorized public Deployment.mapping_digest(id); n0n confirmed no overlap, frozen combined/readiness source untouched. First pure test run 820d7dd5-0616-4dd6-9714-9f6e246fc971 failed one test because test referenced nonexistent ExecutionScopeObserver instead of actual ExecutionScopeObservation; no kernel method invoked. Correct class name before rerun. Lab WIP now retains distinct immutable original/candidate boundary manifests keyed descriptor/slot; controlled same-slot changed-manifest regression passed. All service commands use bounded runner. Producer summary plus actual baseline reader integration remains source WIP, no installed claim.

Root independent scoped APPROVE public mapping_digest API and pure tests; independently executed PASS2/9 dccc1ac9-c7fd-4a5d-a59e-6a75b8be3687. Author corrected run PASS2/9 3878133d-777f-4892-bdf9-78ccec09f697. Observer adoption remains separate frozen-source integration; no installed acceptance.
