# Question: Integration Surface

## The Question

What exact calls and contracts exist between coworker, overseer, and workers?

## Context

We want a file-based, inspectable contract that keeps components loosely coupled.

## Prompts

- What is the minimal command set between coworker and overseer?
- What files are required for worker invocation and reporting?
- How do agents discover the “current step”?
- Should overseer expose a machine-readable status output?

## Decision Status

- [x] Decided: **Simple file-based contract**

**CLI commands:**
```bash
ace-coworker start --task 225  # auto-resume if session exists for task
ace-coworker status [--session <id>] [--json]
ace-coworker resume [--session <id>]
ace-coworker report <file>     # store any document (delegation, result)
ace-coworker list              # list sessions
```

**Session files:**
```
.cache/ace-coworker/<session>/
├── job.json       # plan + execution status
├── log.jsonl      # event log
└── reports/       # delegation docs + returned reports
```

No separate context.json - context is dynamic from job.json + workflow instructions.

**Agent discovery:**
- `ace-coworker status --json` returns current state
- job.json tracks step order and status
- Workflow instructions define what to load/update

**Output format:**
- `--json` flag for machine-readable
- Plain text default for humans
