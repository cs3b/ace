---
doc-type: workflow
title: Fork Recovery Workflow
purpose: Recover from fork-run failures — crash with partial completion, provider unavailability, or mixed subtree state
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# Fork Recovery Workflow

## Purpose

Recover from `fork-run` failures during assignment execution. This workflow is invoked by the driver when a fork subtree exits non-zero. It covers three scenarios: crash with partial progress, provider unavailability, and mixed subtree state after provider failure.

## Prerequisites

- A fork subtree that exited non-zero (`fork-run` failed)
- The driver has the `ASSIGNMENT_ID` and `FORK_ROOT` pinned
- The driver has NOT started executing fork work inline (fork boundary intact)

## Variables

- `$ASSIGNMENT_ID`: The pinned assignment identifier
- `$FORK_ROOT`: The root step number of the failed fork subtree (e.g., `020`)
- `$failed_step`: The specific step that was active when the fork crashed

## Detection: When to Use This Workflow

Invoke this workflow when `fork-run` exits non-zero. Determine the scenario:

| Signal | Scenario | Go to |
|--------|----------|-------|
| `exit != 0` AND (`git status --short` shows changes OR mixed step status) | Crash with partial progress | Scenario 1 |
| `exit != 0` AND error indicates timeout/hang/empty response (no stack trace, no test failure) | Provider unavailability | Scenario 2 |
| `exit != 0` AND subtree has mix of done + failed + pending children after provider failure | Mixed state after provider failure | Scenario 3 |

---

## Scenario 1: Crash with Partial Completion

The fork crashed due to a code issue, environment error, or timeout — but made partial progress.

### Step 1: Commit Partial Work

Stage and commit any uncommitted changes from the crashed fork:

```bash
git add -A
ace-git-commit -i "partial: save fork progress for ${FORK_ROOT}"
```

### Step 2: Write Progress Report for the Active Step

Document what was accomplished and what remains:

```bash
cat > /tmp/partial-report.md << 'EOF'
## Partial Completion (fork crashed)

### Completed
- [list of files created/modified]
- [tests passing: X tests, Y assertions]

### Remaining
- [list of components not yet implemented]
- [tests not yet written]
EOF
ace-assign finish --message /tmp/partial-report.md --assignment ${ASSIGNMENT_ID}@${failed_step}
```

### Step 3: Inject Recovery Steps

Add two child steps inside the failed step's subtree. **Never inject as top-level siblings.**

#### Recovery Step Construction Rules

**recovery-onboard** — Must enumerate all completed subtree report paths explicitly:

```bash
# 1. List all completed reports in the subtree
REPORT_DIR=".ace-local/assign/${ASSIGNMENT_ID}/reports"
REPORT_LIST=$(ls ${REPORT_DIR}/${FORK_ROOT}.* 2>/dev/null | sort)

# 2. Build the instruction with explicit file paths
RECOVERY_INSTRUCTIONS="Read these reports to understand completed work before continuing:
$(echo "$REPORT_LIST" | sed 's/^/- /')
Also read the failure evidence from the failed step."

# 3. Inject the step
ace-assign add "recovery-onboard" --after ${failed_step} --child \
  --assignment ${ASSIGNMENT_ID}@${FORK_ROOT} \
  -i "$RECOVERY_INSTRUCTIONS"
```

The recovery-onboard instructions MUST list every report file path — not semantic references like "read the plan-task report". A forked recovery agent starts with zero context and cannot infer the directory structure.

**continue-work** — Must be a verbatim copy of the original failed step's instructions:

```bash
# 1. Read the original failed step file
STEP_FILE=$(ls .ace-local/assign/${ASSIGNMENT_ID}/steps/${failed_step}-*.st.md)

# 2. Extract the instruction body (everything after YAML frontmatter)
ORIGINAL_INSTRUCTIONS=$(sed '1,/^---$/{ /^---$/!d; /^---$/d }' "$STEP_FILE" | sed '1,/^---$/d')

# 3. Inject continue-work with the SAME instructions
ace-assign add "continue-work" --after recovery-onboard --child \
  --assignment ${ASSIGNMENT_ID}@${FORK_ROOT} \
  -i "$ORIGINAL_INSTRUCTIONS"
```

The continue-work step IS the restart of the same work — it needs the same execution rules, principles, conventions, and done criteria that the original agent had. Do NOT compress or summarize the instructions. Only the recovery-onboard step gets special "catch up" instructions.

### Step 4: Reset Downstream Steps

If any steps after the failed step were completed during a prior (incorrect) recovery attempt, reset them:

- Set their status back to `pending` in the step file frontmatter
- Delete their report files from `.ace-local/assign/${ASSIGNMENT_ID}/reports/`

### Step 5: Re-Fork

The injected recovery steps are pending, so `fork-run` will pick them up:

```bash
ace-assign fork-run --assignment ${ASSIGNMENT_ID}@${FORK_ROOT}
```

---

## Scenario 2: Provider Unavailability

The fork failed because the LLM provider timed out, hung, or returned no output — not because of a code bug. Re-forking would crash the same way.

### Step 1: Confirm Provider Failure

Read the fork's last message and failed step error. Look for:
- Model timeout or API unavailability
- Empty or truncated response
- Connection reset or socket hangup
- Tool hang with no output

NOT provider failure: stack traces, test failures, syntax errors — those are code bugs (use Scenario 1).

### Step 2: Classify the Failed Step

| Step Type | Description | Example Steps |
|-----------|-------------|---------------|
| **LLM-tool step** | Invokes an LLM-backed tool as its primary action | `ace-review`, `ace-lint`, audit, summarize |
| **Code step** | Produces or modifies source code | implement, fix, refactor, work-on-task |

### Step 3: Fork-Side Action (if still inside fork)

The fork MUST only fail and exit. It must NEVER inject steps:

```bash
# Mark the crashed step as failed with evidence, then exit
ace-assign fail --message "Provider unavailable: <error details>" \
  --assignment ${ASSIGNMENT_ID}@${failed_step}
# EXIT — do not add steps, do not retry, do not modify the assignment tree
```

**Forks NEVER inject steps outside their subtree scope. Recovery decisions belong to the driver.**

### Step 4: Driver-Side Recovery

After detecting the fork failure, the driver classifies and recovers:

**LLM-tool steps** → execute equivalent work inline at driver level:

```bash
# Option A: Execute inline (for LLM-tool steps only)
# Read changed files, analyze each, write review report directly

# Option B: Add retry as a child of the failed step's parent
ace-assign add "retry-<step-name>" --after <failed_step> --child \
  --assignment ${ASSIGNMENT_ID}@${FORK_ROOT} \
  -i "Provider was unavailable for forked <step-name>. Execute equivalent work inline: <specific instructions>"
```

**Code steps** → do NOT execute inline. Wait for provider recovery or escalate:

```bash
# Ask user whether to wait and retry later
# Do NOT attempt the code work inline — context isolation is required
```

**Inline execution constraint**: Only LLM-tool steps may go inline during provider unavailability. Code-producing steps always require a fork for context isolation — wait for recovery or ask the user.

---

## Scenario 3: Re-Fork After Partial Provider Failure

The fork subtree has a mix of done, failed, and pending children after a provider failure. The driver recovers by re-forking — not by absorbing remaining work inline.

### Protocol

1. **Inject retry as a child** of the failed step's parent subtree (never as a top-level sibling):

```bash
ace-assign add "retry-<step-name>" --after ${failed_child} --child \
  --assignment ${ASSIGNMENT_ID}@${FORK_ROOT} \
  -i "Retry <step-name> after provider recovery."
```

2. **Re-fork the subtree** — fork-run re-enters and picks up pending/retry children:

```bash
ace-assign fork-run --assignment "${ASSIGNMENT_ID}@${FORK_ROOT}"
```

3. **Do NOT inject steps as top-level siblings** — retry steps must be children of the original subtree root, never top-level steps like `101` or `121`.

**Anti-pattern**: Driver sees subtree 110 with 110.01 failed, 110.02 and 110.03 pending. Driver executes 110.02 and 110.03 inline. This defeats context isolation and violates the fork-delegation constraint.

---

## Key Principles

1. **Never execute fork work inline** — except for LLM-tool steps during provider unavailability. The fork boundary exists for context isolation.
2. **Recovery steps are always children, never top-level siblings** — injecting at the top level breaks subtree scope and causes downstream steps to run without prerequisite work.
3. **Recovery-onboard lists explicit file paths** — never semantic references. The recovery agent has zero context.
4. **Continue-work copies original instructions verbatim** — the restart needs the same rules as the original. Only recovery-onboard gets special instructions.
5. **Reset downstream steps after incorrect recovery** — if steps ran without their prerequisite work, they must be reset to pending with their reports deleted.

## Success Criteria

- Failed fork subtree is recovered without breaking fork isolation
- Recovery children are injected inside the correct subtree scope
- Recovery agent receives explicit report paths and complete original instructions
- Re-fork picks up pending recovery steps and completes the subtree
- No fork work is absorbed into the driver (except LLM-tool inline during provider unavailability)
