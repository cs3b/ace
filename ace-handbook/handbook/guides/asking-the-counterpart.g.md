---
doc-type: guide
title: Asking the Counterpart
purpose: Default agent behavior for asking a human or another owner a question through ace-hitl
ace-docs:
  last-updated: 2026-10-27
  last-checked: 2026-10-27
---

# Asking the Counterpart

When your work needs a decision, an approval, or a secret from another owner, ask the actual counterpart directly — for the Captain, that is the captain route (`ace-hitl ask "…" --to captain --question "…"`), never a relay chain through other agents or panes. `ask` is the last action of your turn: it creates the question, sends it through the configured route, arms your own wake for the answer, and ends the turn — so never wrap it in sleep-poll waits, blocking waits, or asker-side timeouts, and never add urgency language or deadlines to the ask text (the Captain replies whenever he wants). The answer arrives as a wake carrying the content; on wake, act on it immediately — and a secret such as an OTP goes into an environment variable only: never echoed, never passed as a command argument, never written to logs, task files, or reports. completion ping: an agent that finishes work for another agent pings its pane directly (herdr agent prompt).
