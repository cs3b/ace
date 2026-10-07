# Protected merge consumer source checkpoint

The reviewed contract candidate is b695c8770. This source checkpoint implements the existing completion CAS delivery event, original worker service-artifact admission, strict original status/result/receipt consumption and public protected delivery routing. It creates no RPC, staging reopen, local journal fallback or recovery merge.

Executed controlled source evidence:

- Actual receiver → fixed merge CLI → neutral provider adapter → canonical import/completion → original worker Client artifact fetch → public Delivery CLI: 1/34 PASS, 42.30494s, seed 24425, git/856d6fd5-be95-4e24-b55d-6ac18e16ce60. Raw selection is exactly test_real_receiver_fixed_cli_neutral_merge_and_canonical_receipt_import. Repeated read-only consumer observations retain one delivery event and one provider POST; this is not a duplicate completion/import replay test.
- Pure completion input reconstruction, coherent changed-method/provenance refusal, decoded duplicate refusal, and pending-status exact expected input/journal commit shape: 4/18 PASS, 0.00565s, assign/b276b359-5187-4722-8875-2b7599614d66.
- Earlier worker consumer composition without public CLI: 1/27 PASS, git/aba8a5c2-108a-441f-84ec-2e8e88f97705.

Review correction: pending status originally returned before verifying the expected input digest, and its status projection exposed that digest only for succeeded merges. Every merge status now projects its source-owned original digest, which the consumer checks before returning pending/uncertain status. The journal selector accepts exactly 40 or 64 hex characters, not intermediate lengths.

Retained unsuccessful evidence: git/735fe3d6-8ff1-48fc-be01-90df04927d17 failed public prepared-input admission because the inherited result fixture stopped at bound and lacked original project journal metadata; the fixture now uses the maintained controlled gate/release handshake and original metadata. git/dbe0652e-dcf5-4f54-95d1-0e94013ffefc failed original scratch principal validation because the client kernel fixture captured the executor UID; it now captures the recorded original worker. git/f74e43b8-0847-4060-b6e1-885e3680750a executed zero tests from incorrect repository cwd (test_helper LoadError), excluded from acceptance. No deadline increase or admission bypass was used.

Required remaining consumer acceptance: actual duplicate completion/replay, lost completion reply and before/after CAS interruption, foreign worker/different birth, stale candidate/input/resource, forged or later-added result and direct-local-artifact refusal. These are required guarantees, not optional whole-task follow-up. This checkpoint does not claim their coverage. Create/update/ready ordering still awaits the separately requested policy decision; workflow/role adoption and whole qkb.1 completion remain open.

Kernel/native/provider process boundaries are injected. Canonical Git, existing Client/Server wire, fixed CLI command, neutral provider adapter and canonical import/result owners are real. No native, installed, root, systemd or external provider network acceptance is claimed.
