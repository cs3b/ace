# Resolve second-commander proposals with a sixteen-hour veto window: draft usage

Target interfaces, not claims of implementation.

## Scenario 1: Propose an exact release

```text
ace-hitl proposal create --assignment A --attempt ATT --project ace --file release-proposal.json
```

Expected: Kapitan gets context/options/recommendation and deadline; publish is authorized after explicit approval or 16h of verified silence.

## Scenario 2: Change scope before execution

```text
ace-hitl proposal revise PROPOSAL --file changed-proposal.json
```

Expected: Old revision becomes superseded; the changed operation waits a fresh 16h after acknowledged delivery.
