---
doc-type: user
title: ace-docs
purpose: Documentation for ace-docs/README.md
ace-docs:
  last-updated: 2026-03-12
  last-checked: 2026-03-21
---

# ace-docs

Documentation management system with frontmatter-based tracking, LLM-powered analysis, and cross-document consistency checking.

## Features

- **Document Discovery**: Automatically find and index documents with ace-docs frontmatter
- **Change Analysis**: Track which documents need updates based on code changes
- **LLM-Powered Updates**: Get intelligent suggestions for document improvements
- **Consistency Analysis**: Detect terminology conflicts, duplicate content, and version inconsistencies across documents
- **Multi-Subject Support**: Track different code areas for different document sections
- **Validation**: Syntax checking with ace-lint and semantic validation with LLM

## Installation

```bash
gem install ace-docs
```

## Quick Start

### 1. Mark Documents as Managed

Add ace-docs frontmatter to your documents:

```yaml
---
ace-docs:
  doc-type: guide
  purpose: Installation instructions
  last-updated: 2026-03-12
  # Or use date-only: 2025-11-15
  subject:
    diff-filters:
      - "lib/**/*.rb"
      - "bin/*"
---

# Installation Guide
...
```

### 2. Check Document Status

```bash
# Show all managed documents
ace-docs status

# Show only documents needing updates
ace-docs status --needs-update

# Filter by document type
ace-docs status --type guide

# Scope to one package
ace-docs status --package ace-assign

# Scope by glob (bare path is normalized)
ace-docs status --glob ace-assign
```

### 3. Analyze Changes

```bash
# Analyze what changed since a document was last updated
ace-docs analyze README.md

# Analyze changes since a specific date
ace-docs analyze docs/guide.md --since "2025-01-01"
```

### 4. Check Cross-Document Consistency

```bash
# Analyze all documents for consistency issues
ace-docs analyze-consistency

# Focus on specific issue types
ace-docs analyze-consistency --terminology  # Terminology conflicts only
ace-docs analyze-consistency --duplicates   # Duplicate content only
ace-docs analyze-consistency --versions     # Version inconsistencies only

# Analyze specific documents
ace-docs analyze-consistency "docs/*.md"

# Save report for later reference
ace-docs analyze-consistency --save

# Output as JSON for processing
ace-docs analyze-consistency --output json
```

### 5. Update Documents

```bash
# Update with current date only
ace-docs update README.md --set last-updated=today

# Update with current UTC date and time in ISO 8601 format
ace-docs update README.md --set last-updated=now  # Generates: 2025-11-15T08:30:45Z

# Set explicit ISO 8601 UTC timestamp
ace-docs update CHANGELOG.md --set last-updated="2025-11-15T08:30:45Z"

# Legacy format still supported (converted to UTC internally)
ace-docs update CHANGELOG.md --set last-updated="2025-11-15 14:30"

# Update all documents of a type
ace-docs update --preset guides --set last-updated=now

# Bulk update scoped to a package
ace-docs update --package ace-assign --set last-updated=today
```

### 6. Validate Documents

```bash
# Run all validations
ace-docs validate docs/guide.md --all

# Syntax validation only (uses ace-lint)
ace-docs validate docs/guide.md --syntax

# Semantic validation with LLM
ace-docs validate docs/guide.md --semantic
```

## Consistency Analysis Examples

### Example Output

```bash
$ ace-docs analyze-consistency

Analyzing all managed documents
Focus areas: terminology, duplicates, versions, consolidation

# Cross-Document Consistency Report

Generated: 2025-01-21 10:00:00
Documents analyzed: 12
Issues found: 8

## Terminology Conflicts (3)

### "gem" vs "package"
- README.md: uses "gem" (5 occurrences)
- docs/guide.md: uses "package" (8 occurrences)
**Recommendation**: Standardize to "gem" for Ruby context

### "analyze" vs "analyse"
- docs/workflow.md: "analyse" (UK spelling)
- All other docs: "analyze" (US spelling)
**Recommendation**: Standardize to "analyze"

## Duplicate Content (2)

### Installation Instructions
Files with duplicate content (85% similarity):
- README.md (lines 45-67)
- docs/getting-started.md (lines 12-34)
**Recommendation**: Keep in getting-started.md, reference from README

## Version Inconsistencies (2)

### ace-docs version
- README.md: "0.4.5"
- CHANGELOG.md: "0.4.6"
- docs/api.md: "0.4.4"
**Recommendation**: Update all to 0.4.6

✅ Analysis complete

Summary:
  Documents analyzed: 12
  Total issues found: 8
  Issue breakdown:
    - Terminology conflicts: 3
    - Duplicate content: 2
    - Version inconsistencies: 2
    - Consolidation opportunities: 1
```

### Common Use Cases

```bash
# Weekly documentation review
ace-docs status --needs-update
ace-docs analyze-consistency --save

# Pre-release documentation check
ace-docs analyze-consistency --versions --strict
# Exit code 1 if issues found (for CI/CD)

# Find and fix terminology issues
ace-docs analyze-consistency --terminology
# Then manually update documents based on recommendations

# Check for duplicate content
ace-docs analyze-consistency --duplicates --threshold 80
# Higher threshold = more similar content required
```

## Migrating to ISO 8601 UTC Timestamps

**v0.7.0+** introduced support for **ISO 8601 UTC timestamps** (`YYYY-MM-DDTHH:MM:SSZ`), the industry-standard format used by GitHub, Git, and most modern APIs. Your existing date-only timestamps continue to work without any changes.

### Should You Migrate?

**Migrate to ISO 8601 UTC if you:**
- Publish multiple releases per day and need precise, unambiguous timestamps
- Want timezone-independent timestamps that work globally
- Need to correlate documentation changes with specific commit times
- Want standards-compliant timestamps that integrate with CI/CD and APIs
- Benefit from sortable timestamps (lexicographic sorting works correctly)

**Keep date-only if you:**
- Only update documents once per day or less frequently
- Don't need time-of-day precision
- Have external integrations that expect date-only format

### Migration Approaches

**Option 1: Selective Migration (Recommended)**
```bash
# Migrate critical documents to ISO 8601 UTC using "now"
ace-docs update CHANGELOG.md --set last-updated=now
ace-docs update docs/api.md --set last-updated=now
# Generates: 2025-11-15T08:30:45Z

# Keep other documents with date-only
ace-docs update ace-*/handbook/guides/*.g.md --set last-updated=today
# Generates: 2025-11-15
```

**Option 2: Bulk Migration**
```bash
# Update all managed documents to ISO 8601 UTC
ace-docs update --all --set last-updated=now
```

**Option 3: Gradual Migration**
```bash
# New updates use ISO 8601 UTC going forward
# Existing timestamps stay as-is until next update
# Just change your workflow to use "now" instead of "today"
ace-docs update README.md --set last-updated=now
# Generates: 2025-11-15T08:30:45Z
```

### Format Reference

```yaml
---
ace-docs:
  # ISO 8601 UTC (recommended)
  last-updated: 2025-11-15T08:30:45Z

  # Date-only (still supported)
  last-updated: 2025-11-15

  # Legacy date+time (supported for backward compatibility, converted to UTC)
  last-updated: 2025-11-15 14:30
---
```

### Special Values

- `today` → Date-only format (e.g., `2025-11-15`)
- `now` → ISO 8601 UTC format (e.g., `2025-11-15T08:30:45Z`)

### Timestamp Format Details

**ISO 8601 UTC (Recommended)**
- Format: `YYYY-MM-DDTHH:MM:SSZ`
- Example: `2025-11-15T08:30:45Z`
- Benefits:
  - Unambiguous - `Z` suffix indicates UTC
  - Universal - Same timestamp for all users globally
  - Sortable - Lexicographic sorting works correctly
  - Standards-compliant - Matches GitHub API, Git commits, ISO 8601

**Date-only**
- Format: `YYYY-MM-DD`
- Example: `2025-11-15`
- Use for: Documents updated less frequently

**Legacy Format** (Backward Compatibility)
- Format: `YYYY-MM-DD HH:MM`
- Example: `2025-11-15 14:30`
- Interpreted as local time, converted to UTC internally
- Will be deprecated in future major version

## Configuration

Create `.ace/docs/config.yml`:

```yaml
# Document types and their validation rules
document_types:
  guide:
    required_sections: ["introduction", "usage", "examples"]
  api:
    required_sections: ["overview", "methods", "parameters"]

# Global validation rules
global_rules:
  max_line_length: 120
  require_toc: true

# Analysis settings
cache_dir: ".ace-local/docs"
llm_timeout: 120  # Seconds for LLM queries
```

## Requirements

- Ruby 3.1+
- ace-core gem (for configuration)
- ace-llm gem (for LLM features, optional but recommended)
- ace-lint gem (for syntax validation, optional)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/acedev/ace-docs.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
