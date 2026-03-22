---
id: 8qlsgy
title: t-pm3-drive-recovery-precision
type: standard
tags: []
created_at: "2026-03-22 18:58:51"
status: done
task_ref: t.pm3
---

# t-pm3-drive-recovery-precision

## What Went Well

- **Recovery children pattern worked**: Injecting 020.04.01 (recovery-onboard) + 020.04.02 (continue-work) as children of the failed step correctly kept recovery inside the subtree scope. The re-fork picked them up and completed successfully.
- **Agent improvised despite weak instructions**: The forked recovery agent found and read the plan-task report on its own, correctly assessed partial progress, and completed the remaining work — even though the injected instructions didn't tell it where to look.

## What Could Be Improved

### 1. Recovery-onboard instructions must explicitly list report file paths

**What happened:** The driver injected recovery-onboard with: *"Read reports from plan-task and work-on-task steps to understand progress."*

**What should have happened:** The instructions must enumerate every prior report file that the recovery agent MUST read:

```
Read these reports to understand completed work before continuing:
- .ace-local/assign/8qlpqx/reports/020.01-onboard-base.r.md
- .ace-local/assign/8qlpqx/reports/020.02-task-load.r.md
- .ace-local/assign/8qlpqx/reports/020.03-plan-task.r.md
Also read the failure evidence: /tmp/8qlpqx-020.04-fail.md
```

**Why:** A forked recovery agent starts with zero context. Semantic references ("read the plan-task report") assume the agent knows the assignment directory structure and naming convention. Explicit paths guarantee the agent loads the right context — no guessing.

### 2. Continue-work instructions must copy the original failed step verbatim

**What happened:** The driver wrote a compressed 1-line instruction for continue-work: *"Complete the mise exec removal task (t.pm3). Check git log and existing files to avoid redoing work..."*

**What should have happened:** The continue-work step IS the restart of the same work — its instructions should be an exact copy of the original `020.04-work-on-task.st.md` body (lines 12-88). That's 76 lines of critical execution guidance: Start State context, Plan Retrieval Guard, Primary Directive (implement→verify→commit cycle), Principles (spec adherence, execution discipline, task lifecycle), Code Conventions, Task Folder rules, and Done criteria.

**Why:** Only the recovery-onboard step needs special "catch up on what happened" instructions. The continue-work step is literally "do the same job again from where it stopped" — it needs the same rules the original agent had. The recovery agent got none of those rules and succeeded by luck, not by design.

### 3. `release-minor.step.yml` catalog entry missing `workflow:` field

**What happened:** Fork agent on step 020.07 (release-minor) tried running `ace-release --help` → command not found. There is no `ace-release` CLI. The step generated minimal boilerplate instructions because the catalog entry had no workflow reference.

**What should have happened:** `release-minor.step.yml` should have `workflow: wfi://release/publish` — the same field that `release.step.yml` already has. The correct invocation is via the `/as-release` skill, which loads `wfi://release/publish`.

**Evidence:**
- `ace-assign/.ace-defaults/assign/catalog/steps/release.step.yml` line 20: `workflow: wfi://release/publish` (correct)
- `ace-assign/.ace-defaults/assign/catalog/steps/release-minor.step.yml`: had no `workflow:` field (fixed in this retro)

## Action Items

- **Fixed now**: Added `workflow: wfi://release/publish` to `release-minor.step.yml` + updated test sandbox to include the release workflow path
- **Fix in drive.wf.md**: Update crash recovery protocol example to enumerate all completed subtree report paths in recovery-onboard instructions (not just semantic step names)
- **Fix in drive.wf.md**: Specify that continue-work instructions must be a verbatim copy of the original failed step's instruction body
- **Audit**: Check other step catalog entries for missing `workflow:` fields where a workflow exists

