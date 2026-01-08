# Investigation Report: idea-manager Templates

## Summary

**Recommendation: SKIP (no action needed)**

The dev-handbook `idea-manager/` templates are **obsolete** - ace-taskflow has its own integrated implementation that is actively used and more complete.

## Implementation Flow

```
ace-taskflow idea create --llm-enhance "raw idea text"
         │
         ▼
    IdeaCommand (commands/idea_command.rb)
         │
         ▼
    IdeaArgParser (parses --llm-enhance flag)
         │
         ▼
    IdeaWriter → IdeaEnhancer (molecules/)
         │
         ▼
    templates/idea_enhancement.system.md  ← ACTIVE TEMPLATE
         │
         ▼
    ace-context project-base (embedded context)
         │
         ▼
    Ace::LLM::QueryInterface (gflash model)
         │
         ▼
    JSON output: {filename, title, enhanced_description}
```

## Template Comparison

| Aspect | ace-taskflow (ACTIVE) | dev-handbook (LEGACY) |
|--------|----------------------|----------------------|
| **Location** | `ace-taskflow/templates/idea_enhancement.system.md` | `_legacy/dev-handbook/templates/idea-manager/` |
| **Status** | Actively used by IdeaEnhancer | Unused, archived |
| **Context source** | `ace-context project-base` via Open3 | Inline references only |
| **Output format** | JSON → YAML frontmatter + markdown | Structured template sections |
| **Focus** | Concise enhancement with filename suggestion | Detailed validation/assumptions |

### ace-taskflow System Prompt (52 lines)
- JSON output with `filename`, `title`, `enhanced_description`
- Filename rules (type-context-keywords format)
- References ACE components and ATOM architecture
- Embedded project context via `{project_context}` placeholder

### dev-handbook System Prompt (81 lines)
- Detailed sections: Intention, Problem, Solution, Questions, Assumptions, Unknowns
- Template variable approach (`{title}`, `{specific_issue_N}`, etc.)
- References old project structure (handbook-meta, dev-handbook, dev-tools, dev-taskflow)
- Outdated terminology (doesn't mention ace-* gems)

### dev-handbook idea.template.md (66 lines)
- Structured template with placeholder variables
- Sections: Intention, Problem It Solves, Key Patterns, Solution Direction, Critical Questions, Assumptions, Benefits, Big Unknowns
- More comprehensive but requires separate template + system prompt

## Key Findings

1. **Active Implementation**: `IdeaEnhancer` in ace-taskflow is the active implementation, using `idea_enhancement.system.md`

2. **Different Philosophies**:
   - ace-taskflow: Quick enhancement with filename suggestion (5-10 second LLM call)
   - dev-handbook: Deep analysis with validation questions (would require longer generation)

3. **Integration**: ace-taskflow implementation embeds project context dynamically via `ace-context`, while dev-handbook had static inline context references

4. **Outdated References**: dev-handbook templates reference old structure (handbook-meta, dev-taskflow directory) that no longer exists

5. **No Code References**: Grep confirmed no code references to dev-handbook idea-manager templates

## Recommendation

**SKIP** - No migration or integration needed.

**Rationale:**
1. ace-taskflow has a complete, working implementation
2. dev-handbook templates use outdated project references
3. The ace-taskflow approach (JSON output → frontmatter) is cleaner
4. Integration would add complexity without clear benefit
5. Files are already archived in `_legacy/dev-handbook/`

**Optional Future Enhancement:**
If deeper idea analysis is desired (the "Critical Questions" and "Assumptions" sections from dev-handbook), this could be a separate `ace-taskflow idea analyze` subcommand or a `--deep` flag. This would be a new feature, not a migration.

## Investigation Checklist

- [x] Document how `ace-taskflow idea create --llm` works
- [x] Compare dev-handbook templates with ace-taskflow templates
- [x] Document whether `--llm` flag is actively used (yes, via `--llm-enhance`)
- [x] Make recommendation (SKIP - no action needed)
- [x] Follow-up task needed? **No**

## Verification

```bash
# Verify ace-taskflow template exists
ls ace-taskflow/templates/idea_enhancement.system.md

# Verify dev-handbook templates are archived
ls _legacy/dev-handbook/templates/idea-manager/

# No code references to dev-handbook idea-manager
grep -r "idea-manager" ace-* --include="*.rb" 2>/dev/null
# (returns empty - no references)
```
