# Native and harness independent review — 2026-11-10

Reviewed retained change against origin/main and simplification against preserved baseline `8db86b703a49b8a73a90ebafe8c0cd755b1bc749`.

## Native

The primary reviewer independently inspected the native retained diff against source `7a2e78b4e92d2b694bd8a06c1ef4943915c399b2`, including explicit-environment RPC/CLI, immutable terminal addressing, Pi integration response validation, cold-restore refusal, private input validation and final child-lifecycle credential cleanup. Final selected source: `f475b86b1fc0a72103fbdf5cc0aba7dfc54cdcb4`. No remaining confirmed blocker in this reviewed scope.

The native author executed 3,732 local Rust tests (12 configured skips), final affected checks and clippy. The ACE source-builder tests passed 22 tests/110 assertions. A Linux ARM64 musl binary was cross-built and verified through the owner builder on macOS; it was **not executed on Linux**. Binary SHA256 `0ee169b8ec16b4678fd2e1c2b0ee0ff2fb2aca5396419787758884972c82acf6`; provenance SHA256 `9c6ba420622d5db68f26b79a1e94d2cc5b7160c1294f442c7bb2de9556e6453c`.

The helper cleans only the private copied `auth.json`, preserving transcripts. Same-UID processes are trusted; abrupt SIGKILL can leave credentials requiring existing owner reconciliation. This is not an OS sandbox or an always-on issuer.

## Harness

Independent reviewer `/root/review_native` reviewed the full retained fresh/repeat/reset flow, ownership/UUID/export guards, immutable source/artifact graph/native cache, role credential setup, Forgejo seed/protection and TS-MONO-003/004 evidence. Primary reviewer additionally inspected the modified reset/setup/role/build paths. Two confirmed repeat blockers were fixed by the harness author and independently rechecked: retained native integration now reinstalls idempotently with current-version verification, and reset exports/deletes native Herdr configuration/state snapshots. Obsolete ptrace lockdown/systemd identity dependencies were removed. No remaining confirmed blocker in reviewed scope.

All this is local component/runner verification. Neither reviewer claims VM acceptance, model autonomy, live provider scopes, five-minute idle behavior, or two clean UTM cycles.

## File identities at review

- `ace-herdr/lib/ace/herdr/native_source/selection.json`: `3ccd76b253a5b8698cfa756534785dbb969a5ededc92289c461755fac0de65f7`
- `ace-herdr/lib/ace/herdr/native_source/guarded-prompt.patch`: `f6c60630cf64472e2bb9d9a6ff11590730191f88fc5793e0e5fb171004514429`
- `ace-herdr/lib/ace/herdr/native_source/zig-linker`: `ea829d5f19674ee740f7527842ff6ad7be819b0cad50dbe57435b39babf52518`
- `ace-herdr/lib/ace/herdr/organisms/native_source_builder.rb`: `c44b72f4eb909ca2fa9337215aa570f2352db0e41c8ee07eadab7e247aebe661`
- `ace-monorepo-e2e/lab-vm/reset-fixture.py`: `dc1a69415681490cd1238a3a3bd75925c46fdc433bec2635fb3afe637078aa8c`
- `ace-monorepo-e2e/lab-vm/session-fixture.rb`: `ba8e0e5e67245d07129c8e2e1723aec2636f997c47d604e52585abbcea486c92`
- `ace-monorepo-e2e/bin/lab-vm-fixture`: `8e68bf722304a5d02b74841e166bd0eade51f76ff00ebc8326ee7875e1c311c4`
- `ace-monorepo-e2e/bin/lab-vm-fixture-reset`: `53fe25f45354ff5c60556acff4f61d4ce831bd62d9abe4d5cd733862f8743458`
- `ace-monorepo-e2e/bin/lab-vm-build-gem`: `fe9473a52e9f4c4b6411edb24a85c2601796845ebb2ddb6a0c034b6d26e60ab5`
- `ace-monorepo-e2e/bin/lab-vm-scenario-setup`: `f49533903484812c7c159c29ec6f22b83173bc500e9e64c6aa09404386d894d9`
