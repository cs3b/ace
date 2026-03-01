# Self-Improve Workflow

## Goal

Transform mistakes into system improvements. Fix the process first, then fix the immediate issue.

## Anti-Pattern

❌ User points out mistake → Agent re-runs instruction → Same mistake can happen again

## Correct Pattern

✅ User points out mistake → Analyze root cause → Update process → Fix immediate issue

## Prerequisites

- User has identified an agent mistake or suboptimal behavior
- Access to workflow instructions, guides, and skills that may need updates
- Willingness to pause immediate work to improve the system

## High-Level Execution Plan

### Analysis Phase
- [ ] Capture the incident details
- [ ] Identify the root cause category
- [ ] Find the source file(s) that need updates

### Proposal Phase
- [ ] Draft specific changes to prevent recurrence
- [ ] Present analysis and proposal to user
- [ ] Get user approval before implementing

### Implementation Phase
- [ ] Apply process improvements
- [ ] Fix the immediate issue (or defer to user)

## Process Steps

### Step 1: Capture the Incident

Document exactly what happened:

| Question | Details |
|----------|---------|
| **Original request** | What did the user ask for? |
| **Agent action** | What did the agent do? |
| **Actual result** | What was the output? |
| **Expected result** | What should have happened? |
| **User correction** | How did the user describe the problem? |

**Example:**
```
Original request: Reorganize commits into logical groups
Agent action: Reorganized only 5 commits (mentioned in plan)
Actual result: Only 5 of 12+ commits were reorganized
Expected result: All commits on the branch should be reorganized
User correction: Provided full commit list showing 12+ commits
```

### Step 2: Identify Root Cause Category

Ask: "Why did this happen?" Categorize the root cause:

| Category | Description | Example |
|----------|-------------|---------|
| **Ambiguous instructions** | Workflow allows misinterpretation | "Reorganize commits" without specifying scope source |
| **Missing validation** | No checkpoint to catch the error | No step to verify scope before executing |
| **Assumed context** | Agent didn't have necessary information | Agent used plan data instead of querying actual state |
| **Scope narrowing** | Agent under-scoped the task | Followed plan literally instead of understanding intent |
| **Scope creep** | Agent over-scoped the task | Made changes beyond what was requested |
| **Missing example** | No example of correct behavior | Workflow lacks example showing full scope discovery |
| **Redundant computation** | Multiple agents/computations derive same value independently, causing divergence | Orchestrator computes report directory via Ruby `short_id`, but LLM agent re-derives via different logic and gets wrong path |

### Step 3: Find the Source

Search for the relevant process files:

```bash
# Search workflow instructions
ace-bundle wfi://{relevant-workflow}

# Search guides
ace-bundle guide://{relevant-guide}

# Search skills
ace-bundle skill://{relevant-skill}
```

**Search targets (in preference order):**

1. **Workflow instructions** (`ace-handbook/handbook/workflow-instructions/*.wf.md`) - Preferred for process improvements
2. **Guides** (`ace-handbook/handbook/guides/*.g.md`) - Preferred for best practices and conventions
3. **Skills** (`.claude/skills/*/SKILL.md`) - Only when workflow/guide doesn't exist for the topic
4. **CLAUDE.md files** - Project-level overrides only

**Why prefer workflows/guides over skills?**
- Workflows and guides are versioned with the handbook package
- Skills are local to the Claude integration and harder to share/version
- Workflows support embedding and protocol references (`wfi://`, `guide://`)
- When a skill exists without a backing workflow, consider creating the workflow first

### Step 4: Draft the Fix

Propose specific edits. The fix should:

1. **Address the root cause** - Not just the symptom
2. **Be minimal** - Only change what's necessary
3. **Include validation** - Add checkpoints where missing
4. **Add examples** - Show correct behavior if unclear

**Fix templates by category:**

**For ambiguous instructions:**
```markdown
## Before
Reorganize the commits into logical groups.

## After
Reorganize the commits into logical groups.

**Scope Discovery**: Before reorganizing, always query the actual commit list:
- Run `git log --oneline main..HEAD` to get the full commit list
- Do NOT rely on plan estimates - query the actual state
- Confirm scope with user if the actual count differs significantly from expectations
```

**For missing validation:**
```markdown
## Before
### Step 3: Execute Reorganization
- [ ] Perform interactive rebase

## After
### Step 3: Validate Scope
- [ ] Query actual commits: `git log --oneline main..HEAD`
- [ ] Compare to expected scope
- [ ] If mismatch, confirm with user before proceeding

### Step 4: Execute Reorganization
- [ ] Perform interactive rebase
```

**For missing examples:**
```markdown
## Add Example Section

### Example: Scope Discovery

**Incorrect approach** (using stale plan data):
> Plan says "5 commits ahead" → reorganize 5 commits

**Correct approach** (query actual state):
> Run `git log --oneline main..HEAD` → shows 12 commits → reorganize 12 commits
```

**For redundant computation:**
```markdown
## Before
The orchestrator computes a value, and the subagent independently derives it:

```yaml
# Orchestrator computes report_dir from task_id
report_dir: ".cache/ace-test-e2e/#{short_id}-reports/"
# But subagent re-derives via:
report_dir = ".cache/ace-test-e2e/#{timestamp}-reports/"  # Wrong!
```

## After
Pass computed values explicitly; don't re-derive:

```yaml
# Orchestrator computes once and passes to subagent
- phase: run-test
  params:
    report_dir: "{{computed_report_dir}}"  # Passed explicitly
```

# In subagent instructions
**Use the provided `report_dir` variable.** Do not compute or derive this value — it is passed from the orchestrator to ensure consistency.
```

### Step 5: Present to User

Before making any changes, present:

```markdown
## Root Cause Analysis

**What happened**: [Concise description]

**Why it happened**: [Root cause category and explanation]

**Systemic issue found in**: [File path(s)]

## Proposed Process Changes

**File**: `{path/to/file}`

**Change**: [Description of what will be added/modified]

**Diff preview**:
```diff
- [old content]
+ [new content]
```

## Questions

1. Does this analysis match your understanding of the issue?
2. Should I proceed with these process changes?
3. After updating the process, should I also fix the immediate issue?
```

### Step 6: Implement Changes

After user approval:

1. **Update the process file(s)**
   - Apply the proposed edits
   - Verify the changes are valid markdown/yaml

2. **Fix the immediate issue** (if requested)
   - Apply the correct behavior this time
   - Reference the updated process

3. **Commit the process improvement**
   - Use a commit message that references the improvement
   - Example: `docs(workflow): Add scope validation to reorganize-commits`

## Success Criteria

- Root cause is identified (not just symptoms)
- Process fix prevents recurrence
- User approves changes before implementation
- Both process and immediate issue are addressed

## Related Resources

- [Manage Workflow Instructions](wfi://handbook/manage-workflows) - Creating and updating workflows
- [Manage Guides](wfi://handbook/manage-guides) - Creating and updating guides
- [Create Retro](skill://ace-create-retro) - Documenting learnings from incidents
