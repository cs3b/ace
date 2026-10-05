# Source implementation and verification

Source candidate before this evidence-only report: `467c68b59452d6153fe3101751a1339f9f2835ae`, based on main `7ebb11c3fda2178a399786fac76e60edb02eb79a`. Worktree: `.ace-wt/codex-wave4-hitl-integration`; branch: `codex/wave4-hitl-integration`.

The pure `ace.hitl.managed/v1` codec and shared examples ship in the existing dependency leaf. Requests bind assignment/attempt, kernel-attributed requester, incarnation and exact runtime reverse. DaemonBinding, CompositeBinding, Work validation/forms and managed folder projection waiting are removed. The explicit LiveClient owns in-process delivery/watch and authenticated pane-less consumption. Registered Hermes transport publication completes the request-to-question source path without a hidden watcher or second poll owner.

Herdr Inbox preserves the managed envelope and owns durable submission plus the existing signed verifier. Assign owns accepted binding/reconciliation journal events and the read-only runtime binding accessor. Native queue acceptance/wake, signed actual consumption and service business callback receipts remain separate. OTP bytes/hash never enter the managed envelope or native inbox; protected operation-scoped IPC remains the answer path. No timer establishes success or authorizes uncertain resend.

Executed receipts (under `.ace-local/test/reports/<package>/<id>/`):

- HITL all: `8x40f3`, 193 tests / 1081 assertions, zero failures/errors, one existing multi-UID skip.
- Assign all: `8x40j2`, 807 / 3152, zero failures/errors, two existing installed-boundary skips; 9m38s including real journal feature coverage.
- Herdr all: `8x40br`, 456 / 1474, zero failures/errors. Retain earlier `8x40ah`: existing bounded-process post-launch cleanup race failed under concurrent package load, passed in full serial rerun.
- Contract all: `8x40jw`, 19 / 891, zero failures/errors, one normal opt-in installed test skip. Explicit configured clean-install run `8x40jf`: 1 / 67, zero failures/errors.
- Hermes all: `8x40kp`, 112 / 642, zero failures/errors, including built installed OTP CLI proof.
- Hermes shared envelope/ingress consumer tests: `8x40dn`, 31 / 133; registered pending producer `8x408b`, 3 / 18; all green.
- Default concurrent suite: retain its executed failure receipt: 50/51 packages passed, 10284 passing tests / 30636 assertions; Assign exceeded unchanged 120-second package limit while full Assign all was concurrently executing. A two-worker rerun also hit the unchanged Assign limit under concurrent load. The independent executed full Assign receipt is green; no global timeout is changed and no further unrelated suite rerun is claimed.

The leaf install fixture explicitly clears BUNDLER_SETUP as well as BUNDLE/RUBY fields, skips archives only for this Ruby's default gems, and selects empty GEM_HOME/GEM_PATH without RubyGems `--install-dir` (which ignores default gems). Retained successful graph artifacts: `.ace-local/install/vs2-isolated`; failed original fixture artifacts remain in `.ace-local/install/vs2-current`. Hermes local installed executable/plugin proof artifacts remain in `.ace-local/test/artifacts/hitl-hermes/`; they explicitly report live_telegram=false and lab_gad2=false.

Acceptance limits: SC2 and lab-config:gad.2/.8/.b remain open. No real Telegram destination was used; native adapter/coordinator fixtures are labelled and cannot prove native consumption. Actual signer/private-key installation, requester/signer OS users, native observation and Lab death/recovery must be executed separately. The new protected-authority task's later source integration must preserve/recheck these public interfaces. This report does not mark the task done, approve source, merge, push, publish or bump versions; an independent exact-head reviewer is still required.
