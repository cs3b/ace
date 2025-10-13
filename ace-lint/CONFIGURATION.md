# Configuration

ace-lint follows the standard ace-* configuration pattern with explicit configuration files in `.ace/lint/`.

## Quick Start

Create `.ace/lint/kramdown.yml` in your project root:

```yaml
# Kramdown Configuration for ace-lint
# Documentation: https://kramdown.gettalong.org/options.html

# Parser input format
input: GFM

# Line width for formatting (default: 120)
line_width: 120

# Generate anchor IDs for headings (default: false)
auto_ids: false

# Hard wrap lines (default: false)
hard_wrap: false

# Parse HTML tags
parse_block_html: true
parse_span_html: true
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

ace-lint follows the ace-* standard and looks for configuration in these locations (in order):

1. `.ace/lint/kramdown.yml` (project-level, recommended)
2. `.ace/lint/kramdown.yaml` (alternative extension)
3. `~/.ace/lint/kramdown.yml` (user-level)
4. `~/.ace/lint/kramdown.yaml` (alternative extension)

The first file found is used. This follows the same pattern as other ace-* gems (e.g., `.ace/llm/providers/*.yml`).

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

`.ace/lint/kramdown.yml`:
```yaml
# Clean markdown without anchor IDs
input: GFM
line_width: 120
auto_ids: false
hard_wrap: false
parse_block_html: true
parse_span_html: true
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

`.ace/lint/kramdown.yml` for ace-meta project:

```yaml
# Kramdown Configuration for ace-lint
# This file configures kramdown parser and formatter behavior
# Documentation: https://kramdown.gettalong.org/options.html

# Parser input format (GFM = GitHub Flavored Markdown)
input: GFM

# Line width for formatting (--fix, --format commands)
line_width: 120

# Generate anchor IDs for headings (e.g., # Heading {#heading})
# Set to false for clean markdown without IDs
auto_ids: false

# Hard wrap lines at line_width
# Set to false for soft wrapping (recommended)
hard_wrap: false

# Parse block-level HTML tags
parse_block_html: true

# Parse span-level HTML tags
parse_span_html: true
```

## Verification

Check if your config is being loaded:

```bash
# With config file (line_width: 120)
ace-lint file.md --fix

# Should format to 120 character lines
```
