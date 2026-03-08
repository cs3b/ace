---
name: docs/update
purpose: Update documentation with ace-docs tool orchestration
bundle: documentation-management
parameters:
  input:
    description: Documents to update - can be specific files, preset, type, or 'all'
    required: false
    default: needs-update
  options:
    description: Additional options for filtering or processing
    required: false
doc-type: workflow
update:
  frequency: on-change
  last-updated: '2025-10-18'
---

# Update Documentation with ace-docs

Orchestrate ace-docs tools for iterative documentation updates through agent/human collaboration.

## Quick Start

### Specific File Update (Direct Path)

When updating a specific document, go straight to analysis:

```bash
# Analyze specific document immediately
ace-docs analyze docs/api.md

# Review the analysis report
cat .ace-local/docs/analyze-*/analysis.md

# Update document based on recommendations
ace-docs update docs/api.md --set last-updated=today
```

### Bulk Update (Status Check First)

When updating multiple documents or checking what needs updates:

```bash
# Check which documents need updates
ace-docs status --needs-update

# Analyze all documents needing updates
ace-docs analyze --needs-update

# Review analysis report and update documents
cat .ace-local/docs/analyze-*/analysis.md
ace-docs update [file] --set last-updated=today

# Or filter by type
ace-docs status --type guide
ace-docs analyze --all --type guide

# Scope to one package
ace-docs status --package ace-assign
ace-docs validate --package ace-assign --all

# Scope with glob (bare package path is normalized)
ace-docs status --glob ace-assign
ace-docs validate --glob "ace-assign/docs/**/*.md" --syntax
```

## Input Handling

Accept flexible input for document selection:

### Direct Analysis (Skip Status Check)

When specific file(s) are provided, the workflow proceeds directly to analysis:

1. **Specific documents**: List of file paths
   - `docs/api.md handbook/guide.md`
   - Goes straight to `ace-docs analyze [files]`

### Status-First (Check What Needs Updates)

When using filters or bulk operations, the workflow starts with status check:

2. **Preset selection**: Use configured preset
   - `--preset standard`
3. **Type filtering**: Update by document type
   - `--type guide`
4. **Scope filtering**: Restrict by package or path glob
   - `--package ace-assign`
   - `--glob ace-assign` (normalized to `ace-assign/**/*.md`)
   - `--glob "ace-assign/docs/**/*.md"`
5. **Status-based**: Documents needing update
   - `--needs-update` (default when no files specified)
6. **All documents**: Process everything
   - `--all`

**Decision Rule**: If specific file paths are provided → skip to analysis. Otherwise → start with status check.

## Workflow Steps

### Decision Point: Specific File or Bulk Operation?

**If specific file(s) provided** → Skip to Step 2 (Analyze Documents)
**If bulk/filter operation** → Start at Step 1 (Load Document Status)

### 1. Load Document Status (Bulk Operations Only)

**Skip this step if specific file(s) were provided.**

For bulk operations, check current state of managed documents:

```bash
ace-docs status [options]
```

Review the table showing:
- Document names and types
- Last updated dates
- Freshness status (current/stale/outdated)
- Update frequency configuration

If no documents match criteria, exit with message.

### 2. Analyze Documents (Always Required)

Generate LLM-powered analysis for selected documents:

```bash
ace-docs analyze [file|--all|--needs-update] [options]
```

Options:
- `--since DATE`: Analyze from specific date/commit
- `--exclude-renames`: Skip renamed files
- `--exclude-moves`: Skip moved files

The analysis is saved to `.ace-local/docs/analyze-{timestamp}/analysis.md`

**Note**: The analyze directory contains additional files (context.md, *.diff, prompts) for debugging purposes only. The workflow uses `analysis.md` as the primary output.

**Decision Point**: If no changes detected, exit workflow.

### 2.5 Review Analysis Report

Read the generated analysis report:

```bash
cat .ace-local/docs/analyze-*/analysis.md
```

The report contains:
- **Summary**: Overview of changes affecting the document
- **Changes Detected**: Categorized by priority (HIGH/MEDIUM/LOW)
- **Recommended Updates**: Specific sections to update with reasoning
- **Additional Notes**: Context and patterns to consider

Use these LLM recommendations to guide your document updates in the next step.

### 3. Review and Update Documents

For each document with changes:

#### a. Load Document Context
- Read current document content
- Review frontmatter configuration
- Note update focus areas if specified

#### b. Apply Analysis Recommendations
Using the analysis.md report:
- Focus on HIGH priority changes first
- Review specific "Recommended Updates" for the document
- Consider the reasoning provided for each recommendation
- Maintain document style while incorporating changes

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

## Document-Specific Guidelines

### Tool Documentation (tools.md, reference docs)

When updating tool documentation and command references:

**Best Practices for Examples:**
- Only include meaningful, practical examples that demonstrate real usage
- Skip trivial commands like `--version`, `--help`, `-h`, `-v`
- Show actual usage that demonstrates the tool's purpose
- Aim for 2-4 practical examples per tool
- Focus on common use cases and workflows

**Example - Good:**
```bash
# Analyze documents needing updates
ace-docs status --needs-update

# Update specific document metadata
ace-docs update docs/api.md --set last-updated=today
```

**Example - Skip:**
```bash
ace-docs --version      # Trivial, not useful
ace-docs -h             # Help text, not practical usage
```

### Architecture Decision Records (ADRs)

For ADR lifecycle management (creation, evolution, archival, scope updates):

**Creating new ADRs:**
`wfi://docs/create-adr`

**Maintaining existing ADRs:**
`wfi://docs/maintain-adrs`

ADR maintenance includes:
- Evolution documentation when patterns change
- Archival of obsolete decisions
- Scope updates for partially outdated decisions
- Synchronization with `docs/decisions.md` summary

### Context Documents (vision.md, architecture.md, etc.)

For core context documents with specific requirements (line limits, update order, duplication prevention), see the specialized workflow:

`wfi://docs/update-context`

This workflow provides:
- Specific update order to prevent duplication
- Target line counts for each document
- Content ownership rules
- Cross-document validation

## Error Handling

- **Missing frontmatter**: Suggest adding ace-docs frontmatter
- **Validation failures**: Report specific issues, continue with other docs
- **Git errors**: Check repository state, suggest fixes
- **LLM unavailable**: The analyze command will fail - it requires LLM for generating recommendations
- **Empty analysis**: Check if document has subject configuration and if changes exist in the time period

## Integration Points

### With ace-bundle
Load project context for documentation:
```bash
ace-bundle --preset docs
```

### With LLM Analysis
The `ace-docs analyze` command automatically integrates with LLM for intelligent change analysis. The `analysis.md` output provides:
- Prioritized changes (HIGH/MEDIUM/LOW)
- Specific recommendations for document updates
- Context-aware reasoning

No manual LLM integration is needed - it's built into the analyze command.

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

### Multi-Subject Configuration
Configure multiple subjects in document frontmatter for categorized analysis:
```yaml
ace-docs:
  subject:
    - code:
        diff:
          paths: ["**/*.rb", "**/*.js"]
    - config:
        diff:
          paths: ["**/*.yml", "**/*.yaml"]
    - docs:
        diff:
          paths: ["**/*.md"]
```

The `analyze` command will generate separate diffs for each subject, providing more focused analysis.

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

### Update specific document (Direct Path)
```bash
# When you know exactly which document to update
# Skip status check and go straight to analysis
ace-docs analyze ace-docs/README.md

# Review the analysis report
cat .ace-local/docs/analyze-*/analysis.md

# Update document based on recommendations
# [Review analysis.md and update content]
ace-docs update ace-docs/README.md --set last-updated=today
```

### Update stale guides (Bulk Operation)
```bash
# Start with status check for bulk operations
ace-docs status --type guide --freshness stale

# Analyze changes and generate recommendations
ace-docs analyze --type guide --freshness stale

# Review the analysis report
cat .ace-local/docs/analyze-*/analysis.md

# Update each document based on recommendations
# [Review analysis.md and update content]
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

### Analyze and update workflow

#### For specific file (direct):
```bash
# Direct analysis when you know the file
ace-docs analyze docs/architecture.md
cat .ace-local/docs/analyze-*/analysis.md
# Review recommendations and update document
ace-docs update docs/architecture.md --set last-updated=today
```

#### For bulk updates (status-first):
```bash
# Check what needs updating first
ace-docs status --needs-update
ace-docs analyze --needs-update
cat .ace-local/docs/analyze-*/analysis.md
# Review recommendations and update documents
ace-docs update [file] --set last-updated=today
```

## Notes

- The workflow is designed for iterative updates with human/agent oversight
- Change analysis provides data, but update decisions remain with the operator
- Metadata-only updates are safe and reversible
- Content updates should be reviewed before committing
