---
doc-type: reference
purpose: Example document demonstrating multi-subject configuration
ace-docs:
  # Context configuration - files to include for understanding
  bundle:
    files:
      - CHANGELOG.md
      - README.md
    preset: project-base  # Use ace-bundle preset if available

  # Multi-subject configuration - categorize changes by type
  # Each subject generates its own diff file for focused analysis
  subject:
    # Code changes - Ruby implementation files
    - code:
        diff:
          filters:
            - "lib/**/*.rb"           # Library code
            - "app/**/*.rb"           # Application code
            - "test/**/*.rb"          # Test files
            - "spec/**/*.rb"          # RSpec tests

    # Configuration changes - YAML and JSON files
    - config:
        diff:
          filters:
            - "**/*.yml"              # YAML config files
            - "**/*.yaml"             # Alternative YAML extension
            - "**/*.json"             # JSON config files
            - ".ace/**/*"             # ACE configuration
            - "config/**/*"           # Config directory

    # Documentation changes - Markdown and text files
    - docs:
        diff:
          filters:
            - "**/*.md"               # Markdown documentation
            - "docs/**/*"             # Documentation directory
            - "README*"               # README files
            - "CHANGELOG*"            # Changelog files
            - "*.txt"                 # Text files

# Update tracking
update:
  frequency: weekly
  last-updated: 2025-10-20
---

# Multi-Subject Configuration Example

This example demonstrates how to use **multi-subject configuration** in ace-docs to generate separate diff files for different categories of changes.

## Benefits of Multi-Subject Configuration

1. **Focused Analysis**: Each subject (code, config, docs) gets its own diff file, allowing for targeted analysis
2. **Reduced Noise**: Documentation changes don't clutter code change analysis
3. **Better Context**: LLM can analyze each type of change with appropriate context
4. **Cleaner Reports**: Analysis reports are organized by change category

## How It Works

When you run `ace-docs analyze` on this document:

```bash
ace-docs analyze multi-subject-example.md
```

The system will:

1. Generate three separate diff files:
   - `code.diff` - Contains only Ruby file changes
   - `config.diff` - Contains configuration file changes
   - `docs.diff` - Contains documentation changes

2. Each diff is filtered according to the patterns specified in the `filters` array

3. The LLM receives all three diffs and can provide dual-mode analysis:
   - Technical analysis for code changes
   - Configuration impact analysis
   - Documentation coverage assessment

## Configuration Details

### Subject Structure

Each subject is defined as a single-key object where:
- The key is the subject name (e.g., "code", "config", "docs")
- The value contains a `diff` object with `filters` array

```yaml
- code:                    # Subject name
    diff:                  # Diff configuration
      filters:             # Array of glob patterns
        - "**/*.rb"
```

### Filter Patterns

Filters use glob patterns compatible with git pathspecs:
- `**/*.rb` - All Ruby files in any directory
- `lib/**/*.rb` - Ruby files under lib/ directory
- `config/**/*` - All files under config/ directory
- `README*` - Files starting with README

### Custom Subject Names

You can use any subject names that make sense for your project:

```yaml
subject:
  - frontend:
      diff:
        filters:
          - "src/**/*.tsx"
          - "src/**/*.ts"
  - backend:
      diff:
        filters:
          - "api/**/*.py"
  - infrastructure:
      diff:
        filters:
          - "terraform/**/*.tf"
          - "k8s/**/*.yaml"
```

## Backward Compatibility

Multi-subject configuration is fully backward compatible. Single-subject documents continue to work without modification.