---
ace-docs:
  last-updated: '2025-10-14'
  context:
    presets: 
      - project-base
    files:
      - CHANGELOG.md 
  subject:
    - code:
      diff:
        filters:
          - ace-docs/**/*.rb 
    - config:
      diff:
        filters:
          - ace-docs/**/*.md 
    - docs:
      diff:
        filters:
          - ace-docs/.ace.example/*.md 
purpose: Overview and quick start guide for ace-docs
doc-type: reference
---

# ace-docs

Documentation management system with frontmatter, change analysis, and intelligent updates.

ace-docs is a comprehensive documentation management solution that combines deterministic tooling with intelligent workflow orchestration. It discovers documents via frontmatter, analyzes changes, validates against rules, and supports iterative agent/human collaboration for keeping documentation current.

## Features

- **Document Discovery**: Automatically finds markdown files with ace-docs frontmatter
- **Freshness Tracking**: Shows last-updated dates and identifies stale documents
- **Change Analysis**: Generates relevant change summaries using git diff
- **Batch Analysis**: LLM-powered diff compaction for efficient documentation updates
- **Metadata Management**: Updates frontmatter fields (dates, versions) accurately
- **Rule Validation**: Enforces max-lines, required sections, and no-duplicate rules
- **ace-lint Integration**: Delegates syntax validation to ace-lint when available
- **LLM Integration**: Uses ace-llm-query for intelligent change summarization
- **Context Integration**: Leverages ace-context for project awareness
- **Configuration Cascade**: Uses ace-core config system for flexible settings

## Installation

Add to your Gemfile:

```ruby
gem 'ace-docs'
```

Or install directly:

```bash
gem install ace-docs
```

## Quick Start

### 1. Add frontmatter to your documents

```yaml
---
doc-type: context           # context|guide|template|workflow|reference|api
purpose: |
  Technical architecture documentation for the ACE project
update:
  frequency: weekly         # daily|weekly|monthly|on-change
  last-updated: 2025-10-10
---

# Your Document Content
```

### 2. Check documentation status

```bash
# Show status of all managed documents
ace-docs status

# Show only documents needing update
ace-docs status --needs-update

# Filter by document type
ace-docs status --type context
```

### 3. Analyze changes

```bash
# Analyze documents needing updates
ace-docs diff --needs-update

# Analyze specific document
ace-docs diff docs/architecture.md

# Analyze all documents
ace-docs diff --all
```

### 4. Batch analysis with LLM compaction

```bash
# Analyze documents needing updates with LLM compaction
ace-docs analyze --needs-update

# Analyze specific documents
ace-docs analyze docs/architecture.md docs/tools.md

# Analyze with custom time range
ace-docs analyze --needs-update --since "1 week ago"

# Filter by document type or freshness
ace-docs analyze --type guide --freshness stale
```

### 5. Update metadata

```bash
# Update single document
ace-docs update docs/tools.md --set last-updated=today

# Update all documents of a type
ace-docs update --preset project --set last-checked=today
```

### 6. Validate documents

```bash
# Validate all documents (delegates to ace-lint if available)
ace-docs validate

# Validate specific pattern
ace-docs validate "docs/*.md" --all

# Run syntax validation only
ace-docs validate --syntax

# Run semantic validation with LLM
ace-docs validate --semantic
```

## Configuration

Create `.ace/docs/config.yml` in your project:

```yaml
document_types:
  context:
    paths:
      - "docs/*.md"
    defaults:
      update_frequency: weekly
      max_lines: 150

  guide:
    paths:
      - "dev-handbook/guides/**/*.md"
    defaults:
      update_frequency: monthly
      max_lines: 500

global_rules:
  max_lines: 1000
  required_frontmatter:
    - doc-type
    - purpose
```

See `.ace.example/docs/config.yml` for complete configuration options.

## Frontmatter Schema

Required fields:

- `doc-type`: Document type (context, guide, template, workflow, reference, api)
- `purpose`: Description of the document's purpose

Optional `ace-docs:` namespace fields:

**Update tracking:**

- `ace-docs.frequency`: Update frequency (daily, weekly, monthly, on-change)
- `ace-docs.last-updated`: Last update date

**Subject configuration (what we're analyzing):**

Single subject format:
- `ace-docs.subject.diff.filters`: Array of paths to filter in git diffs

Multi-subject format (for categorizing changes):
```yaml
ace-docs:
  subject:
    - code:
        diff:
          filters:
            - "**/*.rb"
    - config:
        diff:
          filters:
            - "**/*.yml"
            - "**/*.yaml"
    - docs:
        diff:
          filters:
            - "**/*.md"
```

When using multi-subject configuration, ace-docs generates separate diff files for each subject (e.g., code.diff, config.diff, docs.diff), allowing for focused analysis of different types of changes.

**Context configuration (information for understanding):**

- `ace-docs.context.keywords`: Array of LLM relevance keywords (for future use)
- `ace-docs.context.preset`: ace-context preset to use (e.g., "project", "architecture")

**Validation rules:**

- `ace-docs.rules.max-lines`: Maximum document length
- `ace-docs.rules.sections`: Required sections array
- `ace-docs.rules.no-duplicate-from`: Avoid duplication from specified documents

**Note**: Legacy `update.`, `context.`, and `rules.` fields at root level are deprecated but supported via backward compatibility fallback.

## Commands

### status

Show document freshness and update status

```bash
ace-docs status [OPTIONS]
  --type TYPE           # Filter by document type
  --needs-update        # Show only documents needing update
  --freshness STATUS    # Filter by freshness (current/stale/outdated)
```

### discover

Find and list all managed documents

```bash
ace-docs discover
```

### diff

Analyze repository changes

```bash
ace-docs diff [FILE] [OPTIONS]
  --all                 # Analyze all managed documents
  --needs-update        # Analyze documents needing update
  --since DATE          # Date or commit to diff from
  --exclude-renames     # Exclude renamed files
  --exclude-moves       # Exclude moved files
```

### update

Update document frontmatter

```bash
ace-docs update FILE [OPTIONS]
  --set KEY=VALUE       # Fields to update
  --preset PRESET       # Update all documents matching preset
```

### validate

Validate documents against rules

```bash
ace-docs validate [FILE|PATTERN] [OPTIONS]
  --syntax              # Run syntax validation using linters
  --semantic            # Run semantic validation using LLM
  --all                 # Run all validation types
```

## Integration

### With Workflows

ace-docs provides deterministic tools for workflow orchestration:

1. Check status to identify documents needing updates
2. Generate diff analysis for change detection
3. Let agent/human update document content
4. Update metadata after changes
5. Validate updated documents

### With ace-context

Documents can specify context requirements:

```yaml
context:
  preset: project
  includes:
    - "docs/decisions/*.md"
```

### With ace-llm-query

Change analysis uses LLM for intelligent summarization:

```bash
# Diff analysis automatically uses ace-llm-query
ace-docs diff --needs-update

# Results saved with LLM-analyzed relevance
cat .cache/ace-docs/diff-*.md
```

## Architecture

ace-docs follows the ATOM architecture pattern:

- **Atoms**: Pure functions (frontmatter_parser)
- **Molecules**: Composed functions (document_loader, change_detector)
- **Organisms**: Complex logic (document_registry, validator)
- **Models**: Data structures (document)
- **Commands**: CLI commands (status, diff, update, validate)

## Development

After checking out the repo:

```bash
# Install dependencies
bundle install

# Run tests
bundle exec rake test

# Run console
bin/console

# Install locally
bundle exec rake install
```

## Contributing

Bug reports and pull requests are welcome at <https://github.com/ace-meta/ace-docs>
