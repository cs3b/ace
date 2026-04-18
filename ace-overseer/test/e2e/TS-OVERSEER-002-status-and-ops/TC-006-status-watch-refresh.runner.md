# Goal 6 -- Status Watch Refresh

## Goal

Demonstrate public status refresh behavior by running `ace-overseer status --watch` in a bounded interval and capturing successive refresh output.

## Workspace

Save all output to `results/tc/06/`. Capture:

- Baseline status in table mode (`ace-overseer status --format table`)
- Watch-mode output for a short bounded interval (for example 5-10 seconds)
- Exit code and stderr for the watch command

## Constraints

- Use only public status commands.
- Keep watch execution bounded; do not leave long-running watch sessions.
- Before the watch run, create a scenario-local `.ace/overseer/config.yml` with short watch intervals so at least two refreshes are observable inside the bounded run.
- Capture at least two refresh frames or clear repeated status updates in watch output.
- All artifacts must come from real tool execution, not fabricated.
