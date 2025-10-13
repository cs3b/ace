# Configuration

ace-lint supports project-wide configuration via a `.ace-lint.yml` file.

## Quick Start

Create `.ace-lint.yml` in your project root:

```yaml
# Line width for markdown formatting (default: 120)
line_width: 120

# Generate anchor IDs for headings (default: false)
auto_ids: false

# Hard wrap lines (default: false)
hard_wrap: false
```

## Configuration Options

### `line_width`

Controls the line width for markdown formatting when using `--fix` or `--format`.

**Type:** Integer
**Default:** 120

```yaml
line_width: 120
```

### `auto_ids`

Generate anchor IDs for markdown headings (e.g., `# Heading {#heading}`).

**Type:** Boolean
**Default:** false

```yaml
auto_ids: false  # Recommended for clean markdown
```

When `false`, headings won't get anchor IDs:
```markdown
# Clean Heading
```

When `true`, kramdown adds IDs (not recommended for most cases):
```markdown
# Clean Heading {#clean-heading}
```

### `hard_wrap`

Hard wrap lines at the specified `line_width`.

**Type:** Boolean
**Default:** false

```yaml
hard_wrap: false  # Soft wrap (recommended)
```

## Configuration File Locations

ace-lint looks for configuration in these locations (in order):

1. `.ace-lint.yml`
2. `.ace-lint.yaml`

The first file found is used.

## Override via CLI

CLI options override config file settings:

```bash
# Use config file line_width (120)
ace-lint file.md --fix

# Override with CLI option
ace-lint file.md --fix --line-width 80
```

## Example Configurations

### For Documentation Projects

```yaml
# Clean markdown without anchor IDs
line_width: 120
auto_ids: false
hard_wrap: false
```

### For GitHub Wikis

```yaml
# Enable anchor IDs for wiki navigation
line_width: 100
auto_ids: true
hard_wrap: false
```

### For Strict Line Limits

```yaml
# Hard wrap at 80 characters
line_width: 80
auto_ids: false
hard_wrap: true
```

## Complete Example

`.ace-lint.yml` for ace-meta project:

```yaml
# ace-lint configuration for ace-meta project

# Line width for markdown formatting
line_width: 120

# Don't generate anchor IDs (keeps markdown clean)
auto_ids: false

# Don't hard wrap lines
hard_wrap: false
```

## Verification

Check if your config is being loaded:

```bash
# With config file (line_width: 120)
ace-lint file.md --fix

# Should format to 120 character lines
```
