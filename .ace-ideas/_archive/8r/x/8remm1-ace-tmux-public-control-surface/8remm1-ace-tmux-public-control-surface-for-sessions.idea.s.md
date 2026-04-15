---
id: 8remm1
status: done
title: ace-tmux public control surface for sessions panes and recording flows
tags: [ace-tmux, tmux, ace-assign, ace-demo, interaction, recording]
created_at: "2026-04-15 15:04:29"
---

# ace-tmux public control surface for sessions panes and recording flows

Add a public ace-tmux interaction/control surface so higher-level tools stop shelling out to raw tmux commands. Today ace-tmux exposes start/window/list, but ace-assign and ace-demo still compensate with direct tmux calls for querying current session/window/pane, sending commands into panes, capturing recent pane output, waiting for visible state transitions, and forcing attach/detach from external controllers. Capture this as one umbrella idea, separate from the existing ace-tmux state/recording draft: keep ace-tmux state as the read-side inventory/provenance surface, and add a sibling control surface for runtime interaction. Prefer ACE-managed sessions by default, but allow explicit session/window/pane targets so demo tooling and detached controllers can use it directly. Public surface candidates: ace-tmux state with explicit targeting; ace-tmux send to send commands or keys to a pane; ace-tmux capture to read recent pane output or pane tail; ace-tmux wait to wait for conditions like pane exists, window exists, active window changed, output contains pattern, pane quiet for N seconds, or pane exit/remain-on-exit observed; ace-tmux attach and ace-tmux detach helpers so demos do not need raw tmux attach-session and detach-client. Primary consumers: ace-assign tmux fork execution and diagnostics, plus ace-demo recording/verification flows. Success looks like replacing brittle sleep-plus-raw-tmux orchestration with reusable ace-tmux control commands, enabling cleaner pane-tail diagnostics, detached-session handling, and recorder-friendly attach/detach/wait behavior. Treat this as ACE-managed by default, explicit targets allowed, and as an interaction/control complement to the existing ace-tmux inspectability and recording direction in 8r6.t.xeu rather than a replacement for it.
