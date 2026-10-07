# Exact selected startup execution — N1 source join

Owner: existing xz9.2 N1 selected-build/install source, consumed by lab-config gad.a/gad.b Assembly and Installer. This does not create another executor, controller, package manager, ledger or installed acceptance gate. Root independently APPROVE the exact API contract below before implementation.

`ProtectedArtifactSet#with_readonly_handle!(reference)` operates only inside an active `with` verification. It uses the existing protected read/reference budgets and protections, authenticates and verifies the held set before yielding a read-only duplicate of the retained regular file, verifies the set afterward, and closes the duplicate on success or error. It does not reopen the selected pathname. No handle survives the callback or grants maintenance authority.

`BoundedProcess.call(..., descriptor_mapping: {})` preserves the current default. Its trusted internal mapping is a Hash of at most16 entries with strict Integer child descriptor keys3..63 and live read-only regular-file handles. It refuses stdio overwrite, invalid types, closed/writable/nonregular handles before spawning. It uses standard Ruby/Open3 spawn descriptor mapping, never a path or ambient-descriptor fallback. Existing bounded stdin carries the exact protected-read selected entry Ruby body.

The Lab consumer retains the exact selected interpreter handle in that same verification callback, maps it to fixed child FD4 and selects `/proc/self/fd/4`; it sends the exact authenticated entry body via stdin. Entry references, interpreter reference and original configuration assets are literal accepted Assembly selections. No mutable selected entry or interpreter pathname is reopened for execution. A closed descriptor or unsupported handoff refuses without fallback.

Read-only supporting source: util-linux v2.40.2 tag object9325a454b2c8b0e037f0376edf65349cf19df671, peeled commit1cebcc34373ed34266f726fff71030a83b4df7da, [su-common.c](https://github.com/util-linux/util-linux/blob/1cebcc34373ed34266f726fff71030a83b4df7da/login-utils/su-common.c). The non-PTY direct-exec path performs group/PAM/identity setup and execvp without an explicit inherited descriptor close; NOFILE reset lowers soft limit only. This is source design evidence, not installed runuser/PAM preservation proof. Actual selected host PAM and FD handoff remain unchecked gad.2 installed acceptance; no native/root probe is run here.

- [x] Implement scoped retained handle with authentication/mutation/error/lifetime tests using controlled protection and real temporary files.
- [x] Implement bounded descriptor mapping with real ordinary Ruby temporary-file child +stdin, selected inode replacement, default descriptor isolation, closed/writable/nonregular/stdio/type/count refusal tests.
- [x] Independent root source APPROVE exact scoped PAS/BoundedProcess diffs and full new tests; author executed Runtime15/69 receipt97b1e5cc and Herdr4/24 receipt7a2e1279 before integration.
- [ ] Lab actual maintained startup consumes exact interpreter/entry/asset selections; missing/changed inputs refuse before effects; configuration failures keep durable inhibition and retry same transaction.
- [ ] Actual source installer composition and independent review; installed execution remains gad.2.

No native/PTY/process/security/root/VM/installed probe or Herdr product execution is authorized by this contract. Tests exercise only owned ordinary bounded pure-source children.

## Test responsibility map

| Behavior | Risk | Source layer / evidence | Deferred installed scope |
|---|---|---|---|
| Exact authenticated retained inode, no reopening, read-only callback lifetime, exception cleanup and before/after mutation refusal | High | Runtime controlled real temporary files; inject only filesystem protection | Actual root filesystem/ACL model remains gad.2 |
| Explicit mapped regular read-only descriptor plus bounded stdin reaches ordinary owned Ruby child, no ambient descriptor inheritance | High | Herdr bounded real temporary-file child integration; no product/native probe | Real runuser/PAM interpreter handoff remains gad.2 |
| Strict mapping keys/types/count/stdio/closed/writable/nonregular refuse before child effect | High | Herdr validation + no child output marker; real readonly/writable/pipe/closed IO objects | No runtime fallback |
| Concurrent pathname replacement cannot choose replacement selected content | High | Runtime retained file descriptor + Herdr ordinary temp child, snapshot recheck refusal afterward | Actual installed owner exclusion/profile separately verified |
| Caller-selected startup/configuration failure leaves inhibition, no restart, same transaction retry without repeated original cleanup | High | Lab controlled actual Installer composition and maintained startup with injected host commands | Central gad.2 actual configuration/boot acceptance |

Existing tests already cover protected budgets/root model and ordinary bounded deadlines/output; this checkpoint adds handoff-specific tests without duplicating those behaviors. The process tests run only a local Ruby interpreter and temp-file source/data. No native binary, PTY, UID change, PAM, mount, root, VM or security probe is executed.

Preparation: managed worktree `/Users/mc/.codex/worktrees/xz9-selected-startup-fds/ace`, branch `codex/xz9-selected-startup-fds`; unchanged doctor785 tasks/460 historical warnings/zero errors. No primary checkout edit.

Initial executed verification: Runtime15tests/69assertions PASS97b1e5cc. New Herdr descriptor target4tests/24assertions FAIL1 report37ce7cfe; record before inspection/repair, no claim of handoff acceptance. Base87748c41d8cd5e4bbab6e5253a57bda8e4efcf0a.

The failed assertion demonstrated that Ruby/Open3 preserves a caller descriptor with close-on-exec disabled unless `close_others: true` is explicit. Existing bounded owner now explicitly closes all unmapped descriptors; only stdin/stdout/stderr and the validated mapping may cross. This removes ambient handoff rather than relying on interpreter defaults. No alternate path is selected.

Executed new Herdr descriptor target PASS4/24 receipt7a2e1279 after explicit close_others repair. Existing broad bounded_process_test includes real Process.kill identity/absence probes and is intentionally not run under current restriction; new selected tests only execute ordinary Ruby temp-file children and validate no ambient descriptor inheritance. Full installed interpreter/PAM acceptance remains gad.2.

Final scoped independent root APPROVE reviewed complete APIs/tests in this frozen worktree; only concise Unreleased/checklist evidence was added afterward. Source consumer and installed rows remain unchecked. No version bump/publication; root performs main integration after receiving scoped commit.
