# Route scoped role services with verifiable execution receipts: draft usage

Target interfaces; these examples do not claim current implementation.

## Scenario 1: Preview a scoped publish

```text
ace-lab service request --project ace --assignment A --attempt ATT --operation publish --input release.json --authorization DECISION --request-id REQUEST --dry-run
```

Expected: Shows exact target/version/executor and validation result; no publication or lease acquisition.

## Scenario 2: Recover an uncertain operation

```text
ace-lab service status --request REQUEST --format json
```

Expected: Reports existing uncertain receipt; operator reconciles outcome rather than blindly resubmitting.
