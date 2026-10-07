# Original native guard producer checkpoint

The maintained LaunchDriver captures the exact native guard before record_launch, verifies the plain original terminal/spawn binding remains unchanged, and submits it through the existing exact-original-launcher route. Canonical accepted record data retains the strict guard separately. The private steering authenticator selects the whole accepted record event digest, including both guard and plain process binding, and refuses missing/changed/ambiguous records. Existing scope_child_bound schema stays unchanged.

All production record_launch callers and actual source fixture call sites were inspected and upgraded. The historical pure lineage append fixture does not invoke the launch RPC and retains its original purpose. No worker/supervisor/public prompt caller can record an independent guard. Public prompt/channel/stop integration remains in progress.

Executed controlled source checks:

- Full launch_lifecycle_test.rb PASS23/190,2e83f868-5478-4c8f-99fe-b2d0f40d6401,3m29s, including maintained Driver/native capture, canonical accepted-record digest and original actor refusal.
- Actual accepted terminal owner through native readiness, proof and reservation release PASS1/14,047416a3-bd76-40bf-b399-cc161986e118,31.7s, after shared fixture record provenance upgrade.

No native/installed/PTY probes or default suite executed. Independent exact-candidate source review remains required. Channel WIP files are excluded.
