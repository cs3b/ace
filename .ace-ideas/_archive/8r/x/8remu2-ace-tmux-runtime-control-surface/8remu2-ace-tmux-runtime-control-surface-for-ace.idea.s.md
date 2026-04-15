---
id: 8remu2
status: done
title: ace-tmux runtime control surface for ace-assign tmux delegation
tags: [ace-tmux, ace-assign, tmux, runtime-control, delegation, diagnostics]
created_at: "2026-04-15 15:13:25"
---

# ace-tmux runtime control surface for ace-assign tmux delegation

Add a focused follow-up idea for ace-tmux integration with ace-assign tmux delegation. Today ace-assign still owns a parallel tmux runtime wrapper for fork execution: it resolves current session/window, creates or reuses the work-fs window, splits panes, selects windows, sends commands into panes, and captures enough state to manage interactive fork runs. Capture the idea that this should move onto a reusable ace-tmux runtime/control surface instead of continuing as raw tmux orchestration inside ace-assign. The control side should cover runtime session/window/pane resolution, ensure/reuse window semantics, pane creation/reuse, focus/selection, command dispatch, and pane-output capture for diagnostics. This idea is specifically about ace-assign consuming ace-tmux as the tmux runtime dependency while keeping assignment state as the source of truth for subtree completion and failure. Position it as a consumer-specific complement to the broader umbrella idea 8remm1 and as adjacent to 8r6.t.xeu, which covers inspectability/recording provenance rather than assignment-driving control semantics.
