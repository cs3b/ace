# Response to Feedback

## 1. What are managed documents?

**Answer**: Documents become "managed" through two methods:
- **Explicit**: Any markdown file with ace-docs frontmatter
- **Configuration-based**: Documents matching type patterns in `.ace/docs/config.yml`

## 2. How do types work?

**Answer**: Document types are defined in `.ace/docs/config.yml` with:
- Glob patterns for automatic discovery (`paths: ["docs/*.md", "**/*.wf.md"]`)
- Default settings for each type (update frequency, validation rules)
- Types can be: context, guide, template, workflow, reference, api, or custom

Priority: Frontmatter > Configuration patterns > Unmanaged

## 3. What does sync do?

**Answer**: We removed the sync command entirely. Documentation updates should be iterative with agent/human collaboration:
- `ace-docs diff` provides analysis
- Agent/human updates documents based on analysis
- `ace-docs update` only updates metadata
- No automatic content updates to preserve control

## 4. How is validation configurable?

**Answer**: Three-level hierarchy with cascading rules:
1. Global rules in `.ace/docs/validation.yml`
2. Type-specific rules in configuration
3. Document-specific overrides in frontmatter

Precedence: Document > Type > Global

## 5. How do sources work for diff?

**Answer**: ace-docs ALWAYS analyzes the full `git diff -w` (ignoring whitespace). The frontmatter `focus` field provides hints for LLM relevance filtering, but doesn't restrict the diff. Options:
- `--exclude-renames`: Skip renamed files
- `--exclude-moves`: Skip moved files
- Default: Include everything, let LLM decide relevance

## 6. Validation delegation

**Answer**: Validation is delegated appropriately:
- **Syntax**: External linters (markdownlint, yamllint)
- **Semantic**: LLM with guide context via ace-llm-query
- **Structure**: Built-in checks (sections, max-lines)

Use `--syntax`, `--semantic`, or `--all` to control validation types.

## Key Design Changes Based on Feedback

1. **Removed sync command** - Updates are iterative, not automated
2. **Clarified diff strategy** - Always full diff, LLM filters
3. **Added configuration examples** - Types and validation hierarchy
4. **Renamed 'sources' to 'focus'** - Better reflects hints vs. restrictions
5. **Emphasized tool/workflow balance** - Deterministic data, intelligent decisions