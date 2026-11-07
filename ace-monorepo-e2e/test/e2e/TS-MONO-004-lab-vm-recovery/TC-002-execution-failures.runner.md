# TC-002: Worker interruption and unavailable observation/runtime

Commission a new readiness check through the project Overseer. Wait until
Herdr and the coworker observation both identify its real worker's terminal.
Stop that exact worker unit and capture the revised executor observation and
owner response. Allow up to ten minutes from the successful stop for the
owner to respond. If there is no response, capture the unchanged assignment
and session evidence, then report the failed interruption check.

In separate restored initial states, make one configured observation source
unavailable and then one required installed executable unavailable. For HITL,
record the configured store's original permissions and temporarily deny
directory access to the project Overseer. Confirm the actual observation
reports `hitl: degraded`. Keep the fault active until the Overseer observes
it and refuses dispatch, or for at most five minutes. Restore the exact
original permissions. Moving the store away alone can expose a healthy
empty source and does not inject this fault. Use host-only operator fault
instrumentation. Restore each original file or unit condition before advancing.
For the runtime fault, capture the installed executable path before hiding
it. While it is hidden, run the normal public start from the project root
with the installed toolchain and capture the refusal and unchanged native
session inventory. Source degradation alone does not prove launch refusal.
After restoring the executable, verify its installed path and health.
If the next fault's prerequisites are unmet,
record which prerequisite failed. Do not fix project work for the agents.

Capture `results/tc/02/commands.stdout`, `commands.stderr`, `commands.exit`,
`state.json` and `sessions.json` as declared by the runner contract.
