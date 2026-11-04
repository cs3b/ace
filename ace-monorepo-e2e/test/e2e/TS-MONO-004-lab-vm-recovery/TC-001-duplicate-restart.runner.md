# TC-001: Redelivery and coordinator restart

Use an accepted report from the preceding bootstrap. Redeliver its exact existing content through its owner transport, then restart only the selected lab Overseer session through the documented native/systemd lifecycle and public start. Preserve session evidence before stopping it. Do not reset the VM or recreate completed work.

Capture `results/tc/01/commands.stdout`, `commands.stderr`, `commands.exit`,
`state.json` and `sessions.json` as declared by the runner contract.
