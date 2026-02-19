---
id: v.0.9.0+task.254
status: done
priority: medium
estimate: 11h
---

# Multi-Agent Research Synthesis

## Overview

Implement multi-agent research synthesis capabilities in ACE, based on research report `8ous1t`. This enables combining outputs from multiple AI agents (e.g., Claude, Gemini, Codex) into unified, higher-quality results.

## Research Source

`.ace-taskflow/v.0.9.0/tasks/254-llm-feat/research/8ous1t-multi-agent-synthesis-report.md`

## Subtasks

| Task | Title | Package | Est | Status |
|------|-------|---------|-----|--------|
| **01** | Multi-Agent Research Guide | ace-handbook | 2h | done |
| **02** | Research Comparison Template | ace-handbook | 1h | done |
| **03** | Synthesize Research Workflow | ace-handbook | 3h | done |
| **04** | Synthesize Research Skill | ace-integration-claude | 1h | done |
| **05** | Parallel Research Workflow | ace-handbook | 2h | done |
| **06** | Parallel Research Skill | ace-integration-claude | 1h | done |
| **07** | Create Research Workflow | ace-handbook | 1h | done |

## Dependency Graph

```
254.01 (Guide) ─────────────────────┐
                                    │
254.02 (Template) ──────────────────┼──► 254.03 (Synthesize WF) ──► 254.04 (Skill)
                                    │
254.05 (Parallel WF) ──► 254.06 (Skill)
                                    │
254.07 (Research WF) ◄──────────────┘
```

## Files Created

| File | Task | Verified |
|------|------|----------|
| `ace-handbook/handbook/guides/multi-agent-research.g.md` | 254.01 | ✓ |
| `ace-handbook/handbook/templates/research-comparison.template.md` | 254.02 | ✓ |
| `ace-handbook/handbook/workflow-instructions/synthesize-research.wf.md` | 254.03 | ✓ |
| `.claude/skills/ace_synthesize-research/SKILL.md` | 254.04 | ✓ |
| `ace-handbook/handbook/workflow-instructions/parallel-research.wf.md` | 254.05 | ✓ |
| `.claude/skills/ace_parallel-research/SKILL.md` | 254.06 | ✓ |
| `ace-handbook/handbook/workflow-instructions/research.wf.md` | 254.07 | ✓ |
| `.ace/nav/protocols/tmpl-sources/ace-handbook.yml` | config | ✓ |

## Verification Results

All protocols verified working:

1. `ace-bundle guide://multi-agent-research` ✓
2. `ace-bundle tmpl://research-comparison` ✓
3. `ace-bundle wfi://synthesize-research` ✓
4. `ace-bundle wfi://parallel-research` ✓
5. `ace-bundle wfi://research` ✓
6. `/ace:synthesize-research` skill registered ✓
7. `/ace:parallel-research` skill registered ✓

## Summary

All 7 subtasks completed. The multi-agent research synthesis system is now fully implemented with:

- **Guide**: Explains when/how to use multi-agent research
- **Template**: Structured comparison matrix for synthesis
- **Workflows**: Parallel research setup and synthesis processes
- **Skills**: Claude Code commands for easy invocation
- **Integration**: Updated research workflow with multi-agent option
