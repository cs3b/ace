# Protected Inbox factory source review

Verdict: **APPROVE**, bounded checkpoint at exact `b9ae6a1b3475bcd3f2cc7f5752128d113c21da85`, delta atop reviewed static context `802324209dfd7d9e6d5f954aeba3acd052a754ad`.

Own isolated checkout `/Users/mc/Ps/ace/.ace-wt/review-9c2-runtime`; no source edits, native endpoint/system manager/privilege/VM probes, broad suite or external actions.

No verified actionable findings in this delta. Factory `ace-herdr/lib/ace/herdr/organisms/protected_inbox.rb` directly constructs Inbox with fixed collaborators; no Inbox.from_config/global routing call. Deep-copy mapping is augmented only by original canonical server_identity/socket_identity/workspace_id stage fields. ProtectedNativeControl initialization performs no I/O; existing peer/socket/process pre/post checks apply when pane.get is actually required. PaneReader exposes only pane_get_bounded and adapts `{result: {pane: ...}}` shape. PiIdentity exposes only pi_identity; its source-owned runner enforces exactly `[fixed_client, "--identity"]`, empty stdin, existing deadline and empty sanitized environment, and refuses oversized output. No submit/wake wrapper is exposed. Public-only RSA is required, and paths/key/client validation remains the previously reviewed Deployment owner responsibility at startup/every operation.

Construction is not proof admission: Inbox reconciliation retains exact registration under its event lock, bound event/attempt/claim/digest/binding checks and actual RSA signature verification. Consumed exact signed replay after endpoint shutdown needs no native request. Superseded replacement observation uses existing Inbox identity verification through the original fixed endpoint; it cannot invent replacement identity. Canonical reader resolution and every-operation Deployment validation must be enforced by the later Assign integration; this checkpoint does not deliver that integration, handler or full service startup.

BoundedProcess's optional explicit environment sets unsetenv_others only when supplied; omitted environment preserves prior existing callers' inherited behavior. Existing deadline, output caps, process-group handling and post-launch error distinctions are unchanged by the delta.

Executed independent local receipts under `.ace-wt/review-9c2-runtime/.ace-local/test/reports/herdr/`:

- Factory plus existing BoundedProcess tests: **13 tests / 66 assertions PASS**, `65b9da31-b737-443e-9cad-823bdb0a132e` (actual local RSA retained consumed reconciliation/replay, controlled pane endpoint, real local fixed identity script/environment and existing process deadline/cleanup checks).
- Existing NativeQueueExecutor focused tests: **11 tests / 39 assertions PASS**, `4e995f98-d281-4c24-b276-13538d734803`.
- Independent ordinary Ruby child environment checks: **2 tests / 8 assertions PASS**, `b95710af-028e-41eb-8771-ea90e9b0e6fa`. Explicit environment excludes poisoned inherited variable, preserves literal supplied value; omitted environment retains inherited value; malformed environment refuses before spawn. Scratch test `.ace-local/review/protected_factory_environment_test.rb` in reviewer checkout.

Approval covers this source construction/environment checkpoint only. It is not complete xz9.0/9c2 or installed native acceptance, and does not authorize opening startup gates.
