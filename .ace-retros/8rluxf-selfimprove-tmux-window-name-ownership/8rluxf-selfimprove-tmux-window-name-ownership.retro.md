---
id: 8rluxf
title: selfimprove tmux window-name ownership
type: standard
tags: [self-improvement, process-fix, tmux, ace-tmux]
created_at: "2026-04-22 20:37:08"
status: active
---

# selfimprove tmux window-name ownership

## What Went Well
- The bug was correctly re-scoped after review: tmux window naming and targeting policy belongs in `ace-tmux`, while `ace-assign` and `ace-overseer` should consume the shared policy instead of inventing local name rules.
- The final fix centralized sanitization in `Ace::Tmux::Atoms::WindowNameSanitizer`, returned sanitized names from `ace-tmux window`, and kept post-creation operations on tmux window IDs.

## What Could Be Improved
- The first tactical fix placed sanitization in `ace-assign`, which addressed the visible fork failure but left the creator/navigator package (`ace-tmux`) with the original unsafe-name behavior.
- Planning should explicitly ask which package owns the primitive before fixing the first caller that exposes the failure.

## Action Items
- For tmux/session/window bugs, inspect `ace-tmux` creation and navigation paths first, then update consumers only to call the shared behavior.
- When a helper package creates external resource names, add the canonical normalizer there and test both direct CLI usage and downstream callers.
- Keep downstream packages on dependency constraints that require the package version introducing the shared API.
