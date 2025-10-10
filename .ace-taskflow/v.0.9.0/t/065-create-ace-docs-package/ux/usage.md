# ace-docs Usage Guide

## Overview

ace-docs is a complete documentation management solution that combines:
- **Deterministic CLI tools** for data gathering and analysis
- **Intelligent workflows** for orchestrated updates
- **Claude integration** for guided documentation maintenance

It supports iterative agent/human collaboration while preserving control over content decisions.

## Complete Solution Architecture

ace-docs provides a complete documentation management solution through:

1. **Deterministic Tools**: CLI commands for data gathering and analysis
   - `ace-docs status`: Check document freshness
   - `ace-docs diff`: Generate change analysis
   - `ace-docs update`: Modify frontmatter metadata
   - `ace-docs validate`: Check compliance with rules

2. **Intelligent Workflows**: Orchestrated processes for iterative updates
   - `update-docs.wf.md`: Guides through complete update cycle
   - Maintains proper order to prevent duplication
   - Integrates with ace-llm-query for intelligent analysis

3. **Claude Integration**: `/update-docs` command for guided maintenance
   - Triggers the complete workflow
   - Provides interactive guidance through updates
   - Ensures all documents stay current

This combination ensures documents stay current while maintaining human/agent control over content decisions.

## What Are Managed Documents?

Documents become "managed" by ace-docs through two methods:

1. **Explicit Management**: Any markdown file with ace-docs frontmatter
2. **Configuration-based**: Documents matching type patterns in `.ace/docs/config.yml`

## Key Features

- **Document discovery** via frontmatter or configuration patterns
- **Change analysis** using full git diff with LLM relevance filtering
- **Metadata management** for frontmatter updates
- **Validation hierarchy** with global, type, and document-level rules
- **Workflow support** providing data for agent/human decisions

## Command Structure

### Discovery and Status
```bash
ace-docs                              # Show status of all managed documents
ace-docs discover                     # Find and list all managed documents
ace-docs status --type context        # Show only context documents
ace-docs status --needs-update        # Show documents needing updates
```

### Change Analysis
Analyze repository changes with intelligent filtering:
```bash
ace-docs diff                          # All documents needing updates
ace-docs diff docs/architecture.md    # Specific document
ace-docs diff --all                   # All managed documents
ace-docs diff --since "7 days ago"    # Custom timeframe
ace-docs diff --exclude-renames       # Ignore file renames
ace-docs diff --exclude-moves         # Ignore file moves
```

**Note**: Always uses `git diff -w` (ignore whitespace) and provides full diff. The LLM analyzes and filters relevance based on each document's purpose.

### Metadata Management
Update frontmatter fields only (no content changes):
```bash
ace-docs update docs/tools.md --set last-updated=today
ace-docs update --preset project --set last-checked=today
ace-docs update docs/guide.md --set version=2.0.0
```

### Validation
Check documents against rules at different levels:
```bash
ace-docs validate                     # All validation types
ace-docs validate --syntax            # Linter-based syntax checks
ace-docs validate --semantic          # LLM-based semantic validation
ace-docs validate docs/*.md --all     # Specific pattern, all checks
```

## Usage Scenarios

### Scenario 1: Daily Documentation Check
**Goal**: Check which documents need updating after recent development

```bash
# Check documentation status
$ ace-docs

Managed Documents (12 found)

Core Context (docs/):
  ✓ what-do-we-build.md    context    2025-10-08 (2d ago)
  ⚠ architecture.md         context    2025-09-20 (20d ago) - needs update
  ✗ decisions.md           context    Missing frontmatter

Guides (dev-handbook/guides/):
  ✓ testing-patterns.md     guide      2025-10-09 (1d ago)
  ✓ ace-gems.md            guide      2025-10-07 (3d ago)

# Generate change analysis for stale documents
$ ace-docs diff --needs-update

Analyzing changes for 2 documents...
Analysis saved to: .cache/ace-docs/diff-20251010-142530.md

# Review the analysis and update documents manually or via workflow
```

### Scenario 2: Update After New Feature
**Goal**: Update documentation after adding a new ace-* gem

```bash
# Check what's changed since last architecture update
$ ace-docs diff docs/architecture.md

Analyzing changes since 2025-09-20...
Relevant changes found:
- New gem: ace-docs added
- Modified: ATOM architecture patterns
- New ADR: ADR-016-documentation-management
Analysis saved to: .cache/ace-docs/diff-20251010-143012.md

# Update the architecture document manually based on analysis

# Update metadata after changes
$ ace-docs update docs/architecture.md --set last-updated=today

# Validate the updated document
$ ace-docs validate docs/architecture.md
✓ Valid frontmatter schema
✓ Max lines: 145/150
✓ Required sections present
✓ No duplicate content detected
```

### Scenario 3: Iterative Documentation Update
**Goal**: Keep documentation current through agent/human collaboration

```bash
# Check what needs updating
$ ace-docs status --needs-update

⚠ docs/tools.md     context  2025-10-01 (9d ago) - needs update
⚠ docs/decisions.md context  2025-09-25 (15d ago) - needs update

# Generate change analysis
$ ace-docs diff docs/tools.md

Analyzing changes since 2025-10-01...
Using git diff -w to capture all changes
LLM filtering for relevance to tools documentation...
Analysis saved to: .cache/ace-docs/diff-20251010-145030.md

# Agent/human reads analysis and updates document iteratively
# This preserves control over content while using tool intelligence

# After manual updates, update metadata
$ ace-docs update docs/tools.md --set last-updated=today

# Validate the updated document
$ ace-docs validate docs/tools.md --all
✓ Syntax validation passed (markdownlint)
✓ Semantic validation passed (guide compliance)
```

### Scenario 4: Bulk Metadata Update
**Goal**: Mark all project documents as checked

```bash
# Update all context documents
$ ace-docs update --preset project --set last-checked=today

Updated frontmatter for 5 documents:
- docs/what-do-we-build.md
- docs/architecture.md
- docs/blueprint.md
- docs/tools.md
- docs/decisions.md
```

### Scenario 5: Add Frontmatter to New Document
**Goal**: Make a document managed by ace-docs

```bash
# Create frontmatter for a new guide
$ cat > docs/new-guide.md << 'EOF'
---
doc-type: guide
purpose: |
  Explain how to use ace-docs for documentation management
update:
  frequency: weekly
  last-updated: 2025-10-10
  sources:
    - files: "ace-docs/**"
    - changelog: ace-docs
rules:
  max-lines: 200
  sections:
    - overview
    - examples
    - reference
---

# New Guide Content
...
EOF

# Validate the new document
$ ace-docs validate docs/new-guide.md
✓ Document successfully registered
```

### Scenario 6: Workflow Integration
**Goal**: Use ace-docs in documentation update workflow

```bash
# In a workflow or Claude command:

# 1. Check status
ace-docs status --needs-update

# 2. Generate comprehensive diff
ace-docs diff --needs-update

# 3. Read and analyze changes
cat .cache/ace-docs/diff-*.md
# The diff contains full git diff -w output with LLM analysis

# 4. Iteratively update documents
# Agent/human reads analysis and updates each document
# This maintains control over content decisions

# 5. Update metadata after changes
ace-docs update --needs-update --set last-updated=today

# 6. Final validation
ace-docs validate --all
```

### Scenario 7: Using /update-docs Claude Command
**Goal**: Complete documentation update cycle with guided workflow

```claude
/update-docs

# The workflow will:
# 1. Check documentation status using ace-docs
# 2. Generate intelligent change analysis
# 3. Guide you through updates in order:
#    - what-do-we-build.md (vision)
#    - blueprint.md (structure)
#    - architecture.md (technical)
#    - tools.md (commands)
#    - decisions.md (ADRs)
# 4. Update metadata and validate

# Example interaction:
Checking documentation status...
⚠ 3 documents need updating

Generating change analysis...
Analysis saved to: .cache/ace-docs/diff-20251010-160000.md

Starting iterative update process...
[1/5] Updating docs/what-do-we-build.md
  Recent changes: Added ace-docs to capabilities
  Suggested updates: Add to "Current Capabilities" section

  [Agent updates document based on analysis...]

[2/5] Updating docs/blueprint.md
  Recent changes: New ace-docs directory structure
  Suggested updates: Add ace-docs/ to repository structure

  [Agent updates document...]

[3/5] Updating docs/architecture.md
  Recent changes: New documentation management component
  Suggested updates: Add ace-docs to Component Types section

  [Continue through all documents...]

Updating metadata...
✓ All documents updated with current dates

Final validation...
✓ All documents pass validation

Documentation update complete!
```

## Frontmatter Configuration

Example frontmatter for a managed document:

```yaml
---
# Required
doc-type: context           # context|guide|template|workflow|reference|api
purpose: |
  Technical architecture documentation for the ACE project

# Update configuration
update:
  frequency: weekly         # daily|weekly|monthly|on-change
  last-updated: 2025-10-10
  last-checked: 2025-10-10

  # NOTE: ace-docs always analyzes the FULL git diff -w
  # The 'focus' field below helps LLM prioritize what's most relevant
  focus:                    # Hints for LLM relevance filtering
    - commits: "feat:"      # Pay attention to feature commits
    - changelogs: true      # Prioritize changelog entries
    - paths: "ace-*/lib/**" # Focus on library changes
    - adrs: active          # Consider active ADRs

# Context requirements
context:
  preset: project           # ace-context preset
  includes:                 # Additional files
    - "docs/decisions/*.md"

# Content rules
rules:
  max-lines: 150           # Maximum document length
  sections:                # Required sections
    - overview
    - components
    - decisions
  no-duplicate-from:       # Avoid duplication
    - "docs/what-do-we-build.md"
  auto-generate:           # Auto-generated sections
    - tools-table: from-gemspecs
---
```

## Document Types Configuration

Document types define categories of documentation with shared characteristics. Configure them in `.ace/docs/config.yml`:

```yaml
# .ace/docs/config.yml
document_types:
  # Core context documents
  context:
    paths:
      - "docs/*.md"              # Glob pattern for discovery
      - "!docs/archive/**"       # Exclude patterns
    defaults:
      update_frequency: weekly
      max_lines: 150
      required_sections:
        - overview
        - scope

  # Development guides
  guide:
    paths:
      - "dev-handbook/guides/**/*.md"
      - "**/*.g.md"              # Extension-based pattern
    defaults:
      update_frequency: monthly
      max_lines: 500
      validation:
        - syntax: markdownlint
        - semantic: guide-compliance

  # Workflow instructions
  workflow:
    paths:
      - "**/*.wf.md"             # Extension pattern
      - "dev-handbook/workflow-instructions/**/*.md"
    defaults:
      update_frequency: on-change
      auto_generate:
        - template-refs: from-embedded

  # API documentation
  api:
    paths:
      - "*/docs/api/*.md"
      - "*/api-docs/**/*.md"
    defaults:
      update_frequency: on-change
      auto_generate:
        - endpoints: from-routes
        - schemas: from-models
```

### Type Discovery Process

1. **Explicit frontmatter** (highest priority):
   - Document has `doc-type: guide` in frontmatter
   - Overrides any configuration-based type

2. **Configuration patterns** (automatic):
   - Document path matches type patterns in config
   - First matching pattern wins

3. **Unmanaged** (no type):
   - No frontmatter and no pattern match
   - Not tracked by ace-docs

## Validation Rules Configuration

Validation rules cascade through three levels:

```yaml
# .ace/docs/validation.yml - Global rules
global_rules:
  max_lines: 1000              # Default maximum
  required_frontmatter:
    - doc-type
    - purpose
  linters:
    markdown: markdownlint
    yaml: yamllint
  semantic_validation:
    guide_reference: "dev-handbook/guides/documentation-standards.md"

# Type-specific rules (in config.yml)
document_types:
  context:
    defaults:
      max_lines: 150           # Override global
      no_duplicate_from:
        - "docs/what-do-we-build.md"
        - "docs/blueprint.md"

# Document-specific rules (in frontmatter)
---
doc-type: guide
rules:
  max_lines: 800               # Override type default
  custom_validation: special-guide-rules
---
```

### Rule Precedence

1. Document frontmatter (highest priority)
2. Type-specific defaults
3. Global rules (lowest priority)

## Workflow Integration

### The update-docs Workflow

The `ace-docs/handbook/workflow-instructions/update-docs.wf.md` workflow orchestrates the complete documentation update cycle:

1. **Status Check**: Identifies documents needing updates using `ace-docs status`
2. **Change Analysis**: Generates comprehensive diff with LLM filtering via `ace-docs diff`
3. **Guided Updates**: Steps through documents in proper order to prevent duplication
4. **Metadata Management**: Updates frontmatter after changes using `ace-docs update`
5. **Validation**: Ensures all rules are satisfied with `ace-docs validate`

### Claude Command Integration

The `/update-docs` command provides a seamless entry point:
- Triggers the complete workflow automatically
- Provides interactive guidance through each document
- Ensures proper update order (vision → structure → technical → tools → decisions)
- Maintains iterative control with agent/human collaboration

### Integration Points

- **With existing workflows**: Can replace manual git-based analysis in update-context-docs.wf.md
- **With ace-context**: Loads project context for comprehensive awareness
- **With ace-llm-query**: Analyzes changes for relevance to each document
- **With version control**: Uses `git diff -w` for complete change detection

## Integration with Other Tools

- **ace-context**: Loads project context for change analysis
- **ace-llm-query**: Provides intelligent summarization of changes
- **Workflows**: Deterministic operations for agent orchestration
- **Git**: Analyzes commit history and file changes
- **Linters**: Delegates syntax validation to external tools

## Output Files

- **Status**: Display in terminal with color indicators
- **Diff analysis**: Saved to `.cache/ace-docs/diff-{timestamp}.md`
- **Validation**: Terminal output with specific violations
- **Updated documents**: Modified in-place with new frontmatter