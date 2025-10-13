---
name: update-docs
purpose: Update documentation with ace-docs tool orchestration
context: documentation-management
parameters:
  input:
    description: "Documents to update - can be specific files, preset, type, or 'all'"
    required: false
    default: "needs-update"
  options:
    description: "Additional options for filtering or processing"
    required: false
---

# Update Documentation with ace-docs

Orchestrate ace-docs tools for iterative documentation updates through agent/human collaboration.

## Quick Start

```bash
# Update all documents needing updates
ace-docs status --needs-update
ace-docs diff --needs-update
# Review changes and update documents
ace-docs update [file] --set last-updated=today

# Update specific type
ace-docs status --type guide
ace-docs diff --all --type guide
```

## Input Handling

Accept flexible input for document selection:

1. **Specific documents**: List of file paths
   - `docs/api.md handbook/guide.md`
2. **Preset selection**: Use configured preset
   - `--preset standard`
3. **Type filtering**: Update by document type
   - `--type guide`
4. **Status-based**: Documents needing update
   - `--needs-update` (default)
5. **All documents**: Process everything
   - `--all`

## Workflow Steps

### 1. Load Document Status

Check current state of managed documents:

```bash
ace-docs status [options]
```

Review the table showing:
- Document names and types
- Last updated dates
- Freshness status (current/stale/outdated)
- Update frequency configuration

If no documents match criteria, exit with message.

### 2. Analyze Changes

Generate change analysis for selected documents:

```bash
ace-docs diff [file|--all|--needs-update] [options]
```

Options:
- `--since DATE`: Analyze from specific date/commit
- `--exclude-renames`: Skip renamed files
- `--exclude-moves`: Skip moved files

The diff is saved to `.cache/ace-docs/diff-{timestamp}.md`

**Decision Point**: If no changes detected, exit workflow.

### 3. Review and Update Documents

For each document with changes:

#### a. Load Document Context
- Read current document content
- Review frontmatter configuration
- Note update focus areas if specified

#### b. Analyze Relevant Changes
Using the generated diff:
- Filter changes relevant to document purpose
- Consider focus hints in frontmatter
- Identify sections needing updates

#### c. Update Document Content
**Agent/Human Decision**: Based on changes:
- Update technical details
- Add new sections
- Remove outdated information
- Maintain document style/voice

#### d. Update Metadata
After content updates:

```bash
ace-docs update [file] --set last-updated=today --set last-checked=today
```

Additional metadata updates:
- Version numbers if applicable
- Custom metadata fields
- Context requirements

### 4. Validate Updates

Run validation on updated documents:

```bash
ace-docs validate [file|pattern] [--syntax|--semantic|--all]
```

Check for:
- Required frontmatter fields
- Max line limits
- Required sections
- Syntax errors (if linter available)
- Semantic issues (if LLM available)

### 5. Present Summary

Generate summary of updates:
- Number of documents updated
- Types of changes made
- Any validation issues
- Documents skipped/deferred

## Error Handling

- **Missing frontmatter**: Suggest adding ace-docs frontmatter
- **Validation failures**: Report specific issues, continue with other docs
- **Git errors**: Check repository state, suggest fixes
- **LLM unavailable**: Fall back to basic diff without summarization

## Integration Points

### With ace-context
Load project context for documentation:
```bash
ace-context load --preset docs
```

### With ace-llm-query
For intelligent change summarization:
```bash
ace-llm-query --prompt "Summarize changes relevant to: [purpose]" < diff.md
```

### With git workflow
After updates, commit changes:
```bash
git add [updated-files]
git commit -m "docs: Update documentation via ace-docs

- Updated [list of documents]
- Synchronized with recent changes
- Validated against configured rules"
```

## Configuration

### Document Discovery
Configure in `.ace/docs/config.yml`:
```yaml
document_types:
  guide:
    paths: ["**/*.g.md", "handbook/guides/**/*.md"]
    defaults:
      update_frequency: monthly
  api:
    paths: ["*/docs/api/*.md"]
    defaults:
      update_frequency: on-change
```

### Global Rules
```yaml
global_rules:
  max_lines: 1000
  required_frontmatter: ["doc-type", "purpose"]
```

## Exit Conditions

Workflow exits when:
- No documents match selection criteria
- No changes detected in diff analysis
- All selected documents processed
- Critical error prevents continuation

## Usage Examples

### Update stale guides
```bash
# Find stale guide documents
ace-docs status --type guide --freshness stale

# Analyze changes
ace-docs diff --type guide --freshness stale

# Update each document
# [Review and update content]
ace-docs update guide1.md --set last-updated=today
```

### Bulk metadata update
```bash
# Update all documents of a type
ace-docs update --preset standard --set version=2.0
```

### Pre-commit validation
```bash
# Validate all changed documents
ace-docs validate $(git diff --name-only -- '*.md')
```

## Notes

- The workflow is designed for iterative updates with human/agent oversight
- Change analysis provides data, but update decisions remain with the operator
- Metadata-only updates are safe and reversible
- Content updates should be reviewed before committing