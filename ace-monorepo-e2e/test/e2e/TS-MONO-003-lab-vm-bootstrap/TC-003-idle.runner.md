# TC-003: Observe five quiet minutes

After all pending notifications have been handled, observe one uninterrupted 300-second interval without injecting goals or changes. Preserve native session identities, model-turn boundaries and observation health at the beginning and end. Check both Overseers.
A full hourly delivery window can defer pending revisions. Allow up to 65
minutes from entering this case to drain them while observation continues.
An actual breaker is a failure. Use read-only observation and do not send
polling prompts to the model.

Use each native agent's actual session path and the host-only operator
channel to capture the latest `ace-wake-eyes` entry at both endpoints.
Extract only entry time, enabled/retired, error count, breaker, pending
count, observation unavailable flag and `observerEvidence` process,
sample time and source statuses. Keep raw session lines private. Require
fresh healthy samples from both agents throughout the interval and newer
sample times at the end. A historical tool response or an idle status bar
alone cannot prove observer liveness.

Capture `results/tc/03/commands.stdout`, `commands.stderr`, `commands.exit`,
`state.json` and `sessions.json` as declared by the runner contract.
