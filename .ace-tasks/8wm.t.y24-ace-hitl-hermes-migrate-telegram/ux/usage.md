# Provide correlated Telegram transport through the Hermes package: draft usage

Target interfaces; these examples do not claim current implementation.

## Scenario 1: Reply to a question

```text
Telegram Reply to the request message: "Use option B"
```

Expected: Only the correlated request receives the answer; other requests stay pending.

## Scenario 2: Send a new direction

```text
Plain Telegram message in the project's channel
```

Expected: Creates a new instruction for the configured project target; does not answer an outstanding question.
