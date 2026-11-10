# Independent simple-session review — harness reviewer

Review scope: local release-preparation work, no VM or paid model execution.

Baseline snapshot: `8db86b703a49b8a73a90ebafe8c0cd755b1bc749`.
Git HEAD while reviewing: `1031127cace3c04cedccb62c3b199619c570978f`. This is a review of the working implementation,
not an assertion that every working change is committed at that HEAD. Exact file
hashes below bind the reviewed versions. Later changes require delta review.

## Independent findings and verdict

**No outstanding confirmed blocking finding in the independently reviewed files
listed below**, after the following corrections:

- LocalCommand could skip group KILL if wait2 had reaped its leader just before
  interruption and the local reaped flag was stale. ECHILD is now caught locally
  without skipping descendant cleanup. Trap setup is inside the protected region,
  so a failure there cannot strand a spawned process. The author added real child
  regressions (7 tests / 13 assertions, report
  `4983b408-625a-45f2-8045-cd5bf7a79b68`); the fix was independently re-read.
- Local Service preserves role/repository/principal/TTL checks, atomic correlation
  issuance, single execution and explicit unresolved cleanup. Root agent execution
  is refused; static role files do not require a running issuer. Hard death is not
  silently reported as confirmed descendant cleanup.
- Passive deployment data replaces system issuer installation checks. Project role
  environment files select credentials; launch validates the installed runtime and
  refuses a missing manifest. Project observations use that project's environment,
  without copying model credentials on every poll.
- Startup failure closes its newly allocated pane before removing auth. An uncertain
  close preserves credentials and reports a blocker. Duplicate error reports retry
  retirement without rewriting acceptance or dispatching a successor.
- Darwin eyes uses the existing native process birth identity through a bounded
  bridge; readiness rejects unavailable identities and dead processes. Linux retains
  its /proc identity. No false cross-platform readiness fallback was introduced.
- Reviewer workflow now uses ordinary project-scoped credentials, optional temporary
  grants for individual forge operations, and exact candidate review/test gates.

This is a **scoped independent verdict**, not full PR approval and not VM acceptance.
The surrounding integration and release HEAD still need their combined test/review
record. No claim of malicious same-UID isolation is made.

## Corrections authored in this review lane

These are implementation work and require peer review rather than self-approval:

- Commission preservation under a stable sidecar lock; prepare no longer overwrites
  an execution binding. Recommissioning a changed bound assignment refuses.
- WorkOn/Handoff serialize allocation per task. Native launch validates credentials
  before persisting launch intent, records real terminal/session identity, refuses
  uncertain dispatch, unretired predecessor, retired reuse and noninteractive restore.
- Coordinator eyes and recipient resolve from the coordinator pane's actual root,
  using canonical `.ace-local/overseer/eyes.json`; reviewer maps to verifier only at
  the environment boundary.
- TS-MONO-003/004 and fixtures use ordinary processes, static scoped role credentials,
  and operator-only temporary credential probes. An unrelated private repository
  allows a real forge-side scope-denial check. No old issuer probes remain.
- Scenario reset exports private evidence and removes tasks, Forgejo data, operator
  auth, role secrets and mo-owned temporary session material. It retains OS/runtime
  and records diagnostic reuse separately from explicit fresh cold acceptance.

Local evidence (all via bin/ace-test):

| Coverage | Result | Report |
|---|---|---|
| Harness deterministic package | 114 tests / 448 assertions | `75413668-2518-4bcb-b421-a31ce3987536` |
| Final reset + scenario contract checks | 5 / 87 | `52e5ca51-5132-4ded-8a7c-5749a8ea285c` |
| Native launcher including real child process/worktree/env/report/reuse/retirement | 10 / 57 | `f3b26a43-dd4b-4df9-ba76-53baa8330946` |
| Immutable gem build, equal release VERSION, rebuilt-byte identity, new package allowlists | 6 / 35 | `86995a78-46a0-4c77-951f-94536baaf155` |
| WorkOn/Handoff and commission/config ownership | 63 / 301 | `b2e107a3-bc86-47a9-8c9a-09bdac4b37e8` |
| Initial launcher/environment behavior including actual child env | 12 / 63 | `24c1b84d-070f-4b38-a497-eeabdf6a6297` |

The actual-child test uses an injected native API seam to launch a Ruby process;
it proves the orchestration bridge without claiming Pi/model autonomy. The child
writes its own session and report, receives only the explicit environment, starts
once across retries, and is dead before its private auth is removed. Session
evidence remains available after retirement.

All listed runs had zero failures/errors. Later code changes are covered by targeted
reruns or the parent's current broader suite; these counts are evidence, not a sum
of unique tests. Harness Ruby syntax and path-scoped whitespace checks passed.

Remaining unexecuted: real model delegation, live local Forgejo role cycle,
five-minute idle behavior, real UTM scenario reset, and two fresh acceptance pairs.
The task remains in-progress and UTM acceptance remains unverified.

## Independently reviewed file fingerprints

| File | SHA-256 |
|---|---|
| `ace-lab/lib/ace/lab/auth/local_command.rb` | `05ed88a585c1b14cf51072e27c9ed66edbb5b288046d5dae4134802ee6ea465a` |
| `ace-lab/lib/ace/lab/auth/service.rb` | `63eb68cb0c67eba518817c7244010eda179d5ba614bfc0ba7ce983b2c360bfb1` |
| `ace-lab/lib/ace/lab/auth/lease_store.rb` | `7a28ab8d863876ae95a6f61275b4f5a9fe4593875f23d52e57f017903df352dc` |
| `ace-lab/lib/ace/lab/auth/credential_handoff.rb` | `3cca9a701f5659337977f9c35cb5a58362961d7a992608213177d8d1d2b890ca` |
| `ace-lab/lib/ace/lab/auth/session_configuration.rb` | `39085c4d67f59a49461c55d2b59c42afb9d3374172a76c12bac68b5e3ad66723` |
| `ace-lab/lib/ace/lab/atoms/install_schema.rb` | `efb853004d8caa7f87ac1541770af78ee1bec216885bd632f969d9cf09b80881` |
| `ace-lab/lib/ace/lab/organisms/prepare.rb` | `c0d64075573231cf24953f8115ba60ee94df5d270fb33ea6f7696f59680b9c07` |
| `ace-lab/lib/ace/lab/organisms/verify.rb` | `621a5922394eeba78f0f2ccb3a3f4d65d448593a2da9c915c4bc750b493a9239` |
| `ace-overseer/lib/ace/overseer/molecules/session_environment.rb` | `f63952ea306c8688f98819847e921cac38ff4e9675bf5481382011bcc36904ce` |
| `ace-overseer/lib/ace/overseer/molecules/project_observations.rb` | `963688a56becc9087ee90722e9ff8766d6e66942dacfd2c207710cc1a665d6bb` |
| `ace-overseer/lib/ace/overseer/molecules/eyes_evidence.rb` | `095592c6418390ff513010bdb2e6870ad1e834159b03007109f9e3f0cfe05732` |
| `ace-overseer/lib/ace/overseer/molecules/eyes_session_evidence.rb` | `3a873da42d577e6ce45e92cf0291635461114e4ea085616602145c4bf8dc202b` |
| `ace-overseer/lib/ace/overseer/organisms/start_orchestrator.rb` | `635734982d7290bd2f0d7092761fbacd8276affc8343d045f7736db655e80467` |
| `ace-overseer/lib/ace/overseer/organisms/report_processor.rb` | `938cafa6070de7bc77c509c6001f3896368e35e2b72cafe27420cb220f87c0da` |
| `ace-coworker/handbook/workflow-instructions/coworker/reviewer.wf.md` | `e58c1ab5e3ee8015f6c1d70e4a3b1b0d4d666a0369e4e7030b747aebfda64e13` |
| `ace-wake/handbook/extensions/ace-wake/wake/eyes-runtime.js` | `ed9e29a9a67299f090d2ea71f6a7e0a24e0c552384ef43f7f8776ff9d98e41de` |

## Final repeat-fixture corrections

Independent native review found two real diagnostic repeat blockers. The retained
native integration was rejected by a missing-file precondition, and Herdr's native
user state was not reset alongside its socket. Fixture setup now reinstalls the
pinned embedded integration asset and verifies current status. Reset exports and
removes `.config/herdr` and `.local/state/herdr` for the dedicated fixture account.
The local regression actually clears snapshot files on two distinct simulated runs
and preserves the installed runtime. The shell setup sequence executes twice with a
fake native boundary, and refuses symlinks and a noncurrent integration result.

`bin/ace-test` targeted result: 5 tests / 9 Ruby assertions plus Python filesystem
assertions, zero failures/errors, report `609bee79-60cd-4d86-988b-5d37a6fde872`.
Obsolete explicit libnss-systemd installation and Yama scope mutation were removed
from future fixture provisioning. No VM or guest configuration was changed.
Incident register: UTM-48 through UTM-50.
