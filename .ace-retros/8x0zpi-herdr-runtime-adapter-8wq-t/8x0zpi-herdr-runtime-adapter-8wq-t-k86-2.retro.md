---
id: 8x0zpi
title: herdr-runtime-adapter-8wq-t-k86-2
type: standard
tags: [ace-herdr, ace-runtime, assignment]
created_at: "2026-10-01 23:48:21"
status: active
---

# Herdr runtime adapter (8wq.t.k86.2)

## What Went Well

- The ace-runtime shared contract suite could exercise the production adapter through a native-shaped fake executor. It covered 42 adapter cases, while Herdr-specific tests checked JSON parsing and condition-specific waits.
- A disposable live Herdr workspace exposed actual `pane get`, `tab get`, and `process-info` responses. The `ace-runtime send` callback reached a plain pane and produced captured output.
- Scoped assignment attempts retained checks and artifact digests at the implementation and verification heads. The local v0.2.0 release stayed separate from publication.

## What Could Be Improved

- The first fake assumed `pane current` would honor `HERDR_PANE`; the live CLI returned the focused pane instead. The adapter now resolves the explicit pane with `pane get`.
- The fake treated an empty foreground-process list as the only exit proof. Herdr reports the retained shell itself, so process exit detection now accepts a list containing only `shell_pid` while preserving malformed evidence as unknown.
- The planner completed after implementation had begun and described stale files. The assignment report was a more useful execution plan in this run.

## Key Learnings

- A retained shell pane and an active foreground command are different states. Lifecycle `pane-exited` can succeed while `pane-exists` remains true; neither observation proves assignment completion.
- Native CLI errors need distinct `agent_prompt_stalled`, `timeout`, and socket-unavailable classifications before they can map faithfully to contract errors.
- Herdr tab listing has no preset provenance. Cross-process idempotence needs a small identity record plus a native-state check.

## Action Items

- Add a live Herdr E2E scenario that creates a disposable workspace, prepares a pane, sends a command, checks lifecycle observations, and cleans up. Include an agent start/wait path when the agent runtime is available.
- Keep native JSON fixtures in adapter tests synchronized with installed Herdr releases when upgrading the CLI.
