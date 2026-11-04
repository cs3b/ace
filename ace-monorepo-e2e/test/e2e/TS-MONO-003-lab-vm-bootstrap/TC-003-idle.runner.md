# TC-003: Observe five quiet minutes

After all pending notifications have been handled, observe one uninterrupted 300-second interval without injecting goals or changes. Preserve native session identities, model-turn boundaries and observation health at the beginning and end. Do not send polling prompts to the model.

Capture `results/tc/03/commands.stdout`, `commands.stderr`, `commands.exit`,
`state.json` and `sessions.json` as declared by the runner contract.
