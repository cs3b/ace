# Binstub References Audit Results

## Summary

Comprehensive audit of binstub references (bin/tn, bin/gc, bin/tnid, etc.) across the project reveals that **documentation cleanup is still needed** in dev-handbook, contrary to initial assessment.

## Findings by Repository

### dev-handbook (ACTION REQUIRED)

Found **extensive binstub references** in active documentation:

#### Most Common References
- `bin/test`: 77 occurrences
- `bin/lint`: 24 occurrences  
- `bin/tn`: 18 occurrences
- `bin/tnid`: 14 occurrences
- `bin/tr`: 12 occurrences
- `bin/gc`: 9 occurrences
- `bin/gs`: 8 occurrences
- `bin/gl`: 6 occurrences
- `bin/rc`: 4 occurrences
- `bin/tal`: 1 occurrence

#### Files Requiring Updates

**Workflow Instructions** (highest priority):
- `workflow-instructions/work-on-task.wf.md`
- `workflow-instructions/initialize-project-structure.wf.md`
- `workflow-instructions/fix-tests.wf.md`
- `workflow-instructions/rebase-against.wf.md`
- `workflow-instructions/save-session-context.wf.md`
- `workflow-instructions/plan-task.wf.md`
- `workflow-instructions/draft-release.wf.md`
- `workflow-instructions/publish-release.wf.md`
- `workflow-instructions/improve-code-coverage.wf.md`
- `workflow-instructions/update-blueprint.wf.md`

**Guides** (high priority):
- `guides/ai-agent-integration.g.md` (critical - used by AI agents)
- `guides/project-management.g.md`
- `guides/version-control-system-git.g.md`
- `guides/task-definition.g.md`
- `guides/embedded-testing-guide.g.md`
- `guides/testing.g.md`
- `guides/release-publish.g.md`

**Templates** (medium priority):
- `templates/release-v.0.0.0/*.task.template.md` (all 5 templates)
- `templates/project-docs/architecture.template.md`
- `templates/project-docs/blueprint.template.md`
- `templates/task-management/task.pending.template.md`
- `templates/binstubs/test.template.md`
- `templates/binstubs/lint.template.md`

### dev-tools

**CLEAN** - No binstub references found in documentation

### docs (root)

**CLEAN** - No binstub references found

### dev-taskflow

Only historical references in:
- `done/` folders (historical records - no action needed)
- `backlog/ideas/` (idea files mentioning the cleanup task)
- Current task file documenting this audit

## Replacement Mapping

All binstub references should be replaced with dev-tools executable paths:

| Old Pattern | New Pattern (from submodule) | New Pattern (gem installed) |
|------------|------------------------------|----------------------------|
| `bin/tn` | `dev-tools/exe/task-manager next` | `task-manager next` |
| `bin/tnid` | `dev-tools/exe/task-manager generate-id` | `task-manager generate-id` |
| `bin/gc` | `dev-tools/exe/git-commit` | `git-commit` |
| `bin/gs` | `dev-tools/exe/git-status` | `git-status` |
| `bin/gl` | `dev-tools/exe/git-log` | `git-log` |
| `bin/tr` | `dev-tools/exe/task-manager recent` | `task-manager recent` |
| `bin/rc` | `dev-tools/exe/release-manager current` | `release-manager current` |
| `bin/tal` | `dev-tools/exe/task-manager list` | `task-manager list` |
| `bin/test` | Project-specific test command | Project-specific |
| `bin/lint` | Project-specific lint command | Project-specific |

## Recommendations

1. **Immediate Action**: Update `guides/ai-agent-integration.g.md` as it directly affects AI agent operations
2. **Systematic Update**: Process workflow instructions next as they guide development processes
3. **Template Updates**: Update templates to prevent propagation of old patterns
4. **Verification**: After updates, run comprehensive search to confirm cleanup:
   ```bash
   rg "bin/(tn|gc|tnid|rc|tr|test|lint|gs|gl|tal)" dev-handbook --type md
   ```

## Task Status Update

The original task assessment was incorrect. The documentation is **NOT clean** and requires significant updates across dev-handbook. The task should be changed from "verification complete" to "implementation required".

## Audit Command Used

```bash
rg "bin/(tn|gc|tnid|rc|tr|test|lint|gs|gl|tal)" /Users/michalczyz/Projects/CodingAgent/handbook-meta/dev-handbook --type md -n -o | sort | uniq -c | sort -rn
```

This audit was performed on 2025-08-09 and found 200+ references requiring updates.