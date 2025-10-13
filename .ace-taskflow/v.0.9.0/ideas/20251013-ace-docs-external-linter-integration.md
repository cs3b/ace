# External Linter Integration for ace-docs Syntax Validation

## Description

Integrate external linting tools into ace-docs to provide comprehensive syntax validation for markdown documents, YAML frontmatter, code blocks, and embedded content. This would delegate syntax checking to specialized tools while ace-docs orchestrates and reports results.

## Motivation

Syntax validation is best handled by specialized tools that:
- Are actively maintained by their communities
- Provide detailed rule sets and configurations
- Support multiple file formats and languages
- Offer automatic fixing capabilities
- Have extensive documentation and community support

Integrating these tools would give ace-docs professional-grade syntax validation without reinventing the wheel.

## Proposed Implementation

### Supported Linters

1. **Markdown Linting**
   - **markdownlint** (Node.js) - Comprehensive markdown rules
   - **mdl** (Ruby) - Alternative markdown linter
   - **remark-lint** (Node.js) - Pluggable markdown linter

2. **YAML Validation**
   - **yamllint** (Python) - YAML linter
   - **yaml-validator** (Node.js) - Schema validation

3. **Code Block Linting**
   - **Language-specific linters** for embedded code
   - **rubocop** for Ruby blocks
   - **eslint** for JavaScript blocks
   - **shellcheck** for bash blocks

4. **Spell Checking**
   - **cspell** (Node.js) - Programmable spell checker
   - **aspell/hunspell** - Traditional spell checkers
   - **vale** - Prose linting for technical writing

### Integration Architecture

```ruby
# lib/ace/docs/linters/linter_adapter.rb
class LinterAdapter
  def self.available_linters
    {
      markdown: detect_markdown_linter,
      yaml: detect_yaml_linter,
      spell: detect_spell_checker,
      prose: detect_prose_linter
    }
  end

  private

  def self.detect_markdown_linter
    if command_exists?('markdownlint')
      MarkdownlintAdapter.new
    elsif command_exists?('mdl')
      MdlAdapter.new
    else
      NullLinter.new
    end
  end
end
```

### Linter Adapters

```ruby
# lib/ace/docs/linters/markdownlint_adapter.rb
class MarkdownlintAdapter
  def lint(file_path, options = {})
    config = options[:config] || default_config
    fix = options[:fix] || false

    cmd = ["markdownlint"]
    cmd << "--config" << config if config
    cmd << "--fix" if fix
    cmd << file_path

    output, status = Open3.capture2e(*cmd)
    parse_results(output, status)
  end

  private

  def parse_results(output, status)
    {
      valid: status.success?,
      errors: extract_errors(output),
      warnings: extract_warnings(output),
      fixable: detect_fixable_issues(output)
    }
  end
end
```

### Configuration Management

```yaml
# .ace/docs/linters.yml
linters:
  markdown:
    tool: markdownlint
    config: .markdownlint.json
    auto_fix: false
    rules:
      MD013: false  # Line length
      MD033: false  # Allow inline HTML

  yaml:
    tool: yamllint
    config: .yamllint
    strict: true

  spell:
    tool: cspell
    config: cspell.json
    dictionaries:
      - technical-terms
      - project-specific

  prose:
    tool: vale
    config: .vale.ini
    styles:
      - Microsoft
      - write-good
```

### Command Integration

```bash
# Syntax validation with external linters
ace-docs validate --syntax                 # Use all detected linters
ace-docs validate --syntax=markdown        # Specific linter only
ace-docs validate --syntax --fix           # Auto-fix issues
ace-docs validate --syntax --strict        # Fail on warnings

# Linter management
ace-docs linters                          # Show available linters
ace-docs linters --install                # Install recommended linters
ace-docs linters --config                 # Generate config files
```

### Smart Detection and Fallback

```ruby
class LinterOrchestrator
  def validate_syntax(document)
    results = {}

    # Try external linters first
    if markdown_linter.available?
      results[:markdown] = markdown_linter.lint(document.path)
    else
      results[:markdown] = basic_markdown_check(document)
    end

    # Check frontmatter YAML
    if yaml_linter.available?
      results[:yaml] = yaml_linter.lint_frontmatter(document)
    else
      results[:yaml] = basic_yaml_check(document)
    end

    # Check embedded code blocks
    document.code_blocks.each do |block|
      linter = find_linter_for_language(block.language)
      results[:code] ||= []
      results[:code] << linter.lint(block) if linter
    end

    aggregate_results(results)
  end
end
```

### Installation Helper

```ruby
# lib/ace/docs/linters/installer.rb
class LinterInstaller
  def install_recommended
    puts "Installing recommended linters..."

    if command_exists?('npm')
      system('npm install -g markdownlint-cli cspell')
    end

    if command_exists?('pip')
      system('pip install yamllint')
    end

    if command_exists?('gem')
      system('gem install mdl')
    end

    if command_exists?('brew')
      system('brew install vale shellcheck')
    end
  end

  def generate_configs
    # Generate default config files for each linter
    create_markdownlint_config
    create_yamllint_config
    create_cspell_config
    create_vale_config
  end
end
```

### Result Aggregation

```ruby
class ValidationReport
  def initialize(linter_results)
    @results = linter_results
  end

  def to_terminal
    table = Terminal::Table.new do |t|
      t.headings = ['Linter', 'Status', 'Errors', 'Warnings']

      @results.each do |linter, result|
        status = result[:valid] ? '✓'.green : '✗'.red
        errors = result[:errors].count
        warnings = result[:warnings].count

        t.add_row [linter, status, errors, warnings]
      end
    end

    puts table
    show_detailed_issues if has_issues?
  end

  def to_json
    @results.to_json
  end
end
```

## Benefits

- **Professional Validation**: Industry-standard tools with extensive rule sets
- **Language Support**: Validate any embedded code language
- **Auto-fixing**: Many linters can automatically fix issues
- **Customization**: Fine-tune rules for project needs
- **Community**: Leverage community-maintained tools
- **Performance**: Optimized tools run faster than custom implementations

## Implementation Strategy

### Phase 1: Core Integration
- Implement adapter pattern for linters
- Support markdownlint and yamllint
- Basic result parsing and reporting

### Phase 2: Extended Support
- Add code block linting
- Implement spell checking
- Support prose linting with vale

### Phase 3: Advanced Features
- Auto-fix capability
- Custom rule configuration
- CI/CD integration
- Pre-commit hook support

## Configuration Examples

### Project-Specific Rules
```json
// .markdownlint.json
{
  "default": true,
  "MD013": false,
  "MD033": false,
  "MD041": false
}
```

### Custom Dictionaries
```json
// cspell.json
{
  "words": [
    "ace-docs",
    "frontmatter",
    "gemspec"
  ],
  "dictionaries": ["technical-terms"]
}
```

## Error Handling

- **Missing Linters**: Graceful fallback to basic validation
- **Version Conflicts**: Detect and report incompatible versions
- **Config Errors**: Validate configs before running linters
- **Performance**: Timeout long-running linters
- **Platform Issues**: Handle platform-specific tool availability

## Related Ideas

- Integration with CI/CD pipelines for automated checking
- Pre-commit hooks for validation before commits
- VS Code extension for real-time linting
- GitHub Actions for PR validation