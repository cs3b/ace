# Receipt key rotation admission — draft usage

Maintainer calls begin_rotation for a fixed empty/all-completed inbox context and its current key generation. Expected exclusive admission; new enqueue/sign/reconcile waits/refuses until commit. Domain installer atomically replaces the protected pair/config and calls commit_rotation after readback and signer keypair attestation. Next enqueue pins the new fingerprint.

An unresolved/requeued event, live signer admission, missing store or unknown process state refuses before replacement. Installer crash after admission retains blocked state until verified rollback/commit; timeout is not quiescence proof. Workers cannot select keys/context or invoke a force bypass.
