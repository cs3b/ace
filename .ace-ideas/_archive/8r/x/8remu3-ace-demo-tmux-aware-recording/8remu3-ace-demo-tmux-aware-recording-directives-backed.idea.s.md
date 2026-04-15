---
id: 8remu3
status: done
title: ace-demo tmux-aware recording directives backed by ace-tmux
tags: [ace-demo, ace-tmux, tmux, recording, directives, verification]
created_at: "2026-04-15 15:13:27"
---

# ace-demo tmux-aware recording directives backed by ace-tmux

Add a focused follow-up idea for ace-demo integration with ace-tmux. Today tmux-aware demos still rely on shell-level tmux commands and sleep-based orchestration inside YAML tapes for attach, detach, current-window checks, and timing-sensitive transitions. Capture the idea that ace-demo should gain first-class tmux-aware recording directives backed by shared ace-tmux APIs rather than continuing to embed raw tmux shell commands in scenes. The intended surface is for recorder-control operations such as tmux attach, detach, wait-for-state/output transitions, send commands or keys, and optional capture for verification/debugging. These directives should make tmux demos more deterministic and remove ad hoc background detach hacks and fragile sleeps, while still allowing visible on-camera feature commands to use ace-tmux explicitly when helpful. Position this as a consumer-specific complement to the broader umbrella idea 8remm1 and as adjacent to 8r6.t.xeu, which covers generic state/recording provenance rather than tape-level orchestration primitives.
