# Settle an authority-issued native observation

`ace-assign inbox-settle` runs as the distinct installed signer. It fetches one
opaque observation ID from the protected assignment authority, validates its
canonical provenance and current context correlation, then signs and reconciles
through the existing authority consumer. Callers cannot provide a key, receipt,
JSON observation, outcome, observer identity or native endpoint.

```sh
ace-assign inbox-settle --project PROJECT --mapping MAPPING \
  --assignment ASSIGNMENT --attempt ATTEMPT --inbox-context CONTEXT \
  --event EVENT --evidence EVIDENCE_ID --mutation MUTATION \
  --expected-generation GENERATION
```

Every selector is required. Project and mapping must agree with the installed
map. The context must configure the caller as a signer, distinct from observer,
worker, launcher, context owner and assignment authority. The retained admission
excludes key rotation until validation, signing and reconciliation return. The
context snapshot is checked again immediately before signing; downstream event
locking still refuses stale generation or registration.

The fixed `receipt_private_key` reference contains `path`, `bytes` and `sha256`.
The root-owned file and its ancestry must satisfy protected artifact checks.
The private file's access ACL grants read only to its named signer, with no group
or other permissions; root remains the installed owner. RSA keys smaller than
2048 bits, public-only keys, unsafe ACLs and a public DER fingerprint differing
from the event's pinned verifier refuse. The retained inode and content identity
are checked across the signing operation.

A lost reply retains uncertainty. Retry with the same evidence, selectors,
mutation and expected generation. Proof bytes and RSA signature are deterministic
for that evidence; the existing canonical consumer owns exact-proof replay.
No receipt files or second settlement ledger are created. Source support currently
accepts only validated Codex 0.159.3 completed-turn consumed observations;
supersession and Pi observations refuse. Completed consumption does not prove
assignment or business success.

This command does not establish installed Lab permissions or system acceptance.
Those remain the central Lab installation and acceptance task's responsibility.
