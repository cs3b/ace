# Runtime acceptance scenarios — 8wq.t.k86.0

Target contract; implementation evidence is collected later. See this task and k86.0 for the ordered send matrix and typed error model.

## Select backend and callback once

`ace-overseer work-on --task TASK --runtime herdr`

Expected: a tab at the task worktree through the Herdr adapter. Consumer fork inherits ACE_RUNTIME=herdr and its exact caller target.

`ace-runtime send --runtime herdr --pane TARGET --msg "completed" --key Enter`

Expected: one submission to an agent pane; exactly one trailing Enter is suppressed/reported. With --runtime tmux the plain-pane callback submits once too. Flag > inherited ACE_RUNTIME > runtime config > detect resolves callbacks.

## Reject uncertainty without automatic retry

An unavailable explicitly selected or auto-detected backend returns RuntimeUnavailableError. Only assign auto with no detected runtime selects headless. SendRejectedError means pre-send rejection; SendStalledError means possible submission and prohibits automatic resend.

## Wait and lifecycle evidence

`Ace::Runtime.resolve("herdr").wait_lifecycle(condition: "pane-exited", target: target, timeout: 10)`

Expected: positive observation of exit/absence satisfies the wait. It does not prove assignment success or preservation for prune. Adapter contract examples test all four lifecycle conditions on both backends; live acceptance confirms actual Herdr behavior.
