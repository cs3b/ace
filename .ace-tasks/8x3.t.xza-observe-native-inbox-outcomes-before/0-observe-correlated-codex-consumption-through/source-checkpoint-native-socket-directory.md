# Selected native-owned socket directory — bounded source checkpoint

Root independently accepted the design precision: the positive native process
cannot create a socket beneath a root-owned0750 directory. Root provisioning
therefore owns the protected ancestry and creates only the final directory as
exact selected native UID, connect GID and0750 mode. Its root-owned parent prevents
directory replacement. EndpointProtection validates this exact final exception,
retains every directory identity and preserves all other ancestry/ACL/filesystem
checks. Leaf0660/inode and connected original peer/birth/pidfd checks remain.

Executed source tests from ace-herdr package cwd, with the previously documented
absolute worktree-only bundle config:

```text
../bin/ace-test test/fast/molecules/codex_runtime_endpoint_test.rb test/fast/organisms/inbox_context_service_test.rb -c /Users/mc/.codex/worktrees/xza-codex-queue-producer/ace/.ace-local/test/config/codex-bundle.yml --timeout30
```

PASS16tests/123assertions/1.1s, report
`7db871b7-bfd4-423b-be15-38cd35294e0a`. Real positive fixture owner creates its
directory/socket; only Linux ACL/mount and root-ancestor ownership/mode observations
are injected. Wrong native owner, native-owned/writable ancestor, root native
principal and same-UID socket replacement refuse. Existing actual typed
factory/socket/service test still refuses same-UID different PID before native
bytes and validates original retained correlation/lost-reply behavior.

Retained failures: `e54a8ca5` and `7429515c`, each16/119 with one positive fixture
admission error. The fixture needed explicit protected ancestor mode observations
and selection of its own permitted GID; production checks were unchanged after
the first source delta. The corrected fixture sets its own temporary directory
GID and retains the same real inode/native ownership.

Independent source review is required before integration. No real native,
root/systemd, ACL, installed or producer startup acceptance. Dedicated app-server
unit/installation specialization and actual Lab bootstrap remain separate source
joins under the existing producer contract.
