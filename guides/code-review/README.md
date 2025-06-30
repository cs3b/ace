# Code Review System

This directory contains tools and templates for AI-assisted code review of Ruby gems. The system provides comprehensive, structured feedback on code changes with a focus on Ruby best practices, ATOM architecture compliance, and maintainability.

## Overview

The code review system consists of three main components:

1. **`bin/cr`** - Command-line wrapper for easy access
2. **`dev-handbook/tools/generate-code-review-prompt`** - Ruby script that generates review prompts
3. **`_code-review-from-diff.md`** - Comprehensive review template

Together with the documentation review system (`bin/cr-docs`), these tools ensure both code and documentation maintain high quality standards.

## Quick Start

```bash
# Generate a code review prompt from a diff file
bin/cr -d changes.diff

# Specify custom output location
bin/cr -d changes.diff -o my-review-prompt.md

# Include full project context (complete content of docs, ADRs, Gemfile, gemspec)
bin/cr -d changes.diff --include-dependencies

# Get verbose output for debugging
bin/cr -d changes.diff --verbose
```

## How It Works

1. **Create a diff file** containing the changes you want reviewed:

   ```bash
   git diff > changes.diff
   # or for staged changes
   git diff --cached > changes.diff
   # or for a specific commit range
   git diff main..feature-branch > changes.diff
   ```

2. **Generate the review prompt**:

   ```bash
   bin/cr -d changes.diff
   ```

3. **Use the generated prompt** with your AI agent (Claude, GPT-4, etc.) to get comprehensive feedback

## What Gets Reviewed

The code review system analyzes:

### Architecture & Design

- ATOM pattern compliance (Atoms, Molecules, Organisms, Ecosystems)
- Separation of concerns
- Module boundaries and dependencies
- Design patterns and anti-patterns

### Ruby Best Practices

- Idiomatic Ruby code
- Gem structure and conventions
- Dependency management
- Performance considerations

### Code Quality

- RuboCop compliance
- Code smells and refactoring opportunities
- Naming conventions
- Method and class complexity

### Testing

- Test coverage impact
- RSpec best practices
- Test design and organization
- Edge case coverage

### Security

- Input validation
- Dependency vulnerabilities
- Secure coding practices
- Data handling safety

### CLI Design

- Command structure and usability
- Error messages and help text
- AI agent compatibility
- Unix philosophy adherence

### Project Context (with --include-dependencies)

- Full content of project documentation files
- Full content of Architecture Decision Records (ADRs)
- Full content of root documentation (README, CHANGELOG, etc.)
- Complete Gemfile and gemspec configuration

## Benefits

### For Individual Developers

- **Learning Tool**: Get detailed feedback on Ruby best practices
- **Quality Gates**: Catch issues before they reach code review
- **Consistency**: Maintain consistent code standards
- **Time Savings**: Identify issues early in development

### For Teams

- **Onboarding**: Help new team members understand standards
- **Knowledge Sharing**: Document architectural decisions
- **Review Efficiency**: Focus human reviews on higher-level concerns
- **Quality Metrics**: Track code quality trends over time

### For AI-Assisted Development

- **Structured Feedback**: Consistent, parseable review format
- **Comprehensive Analysis**: Cover more ground than manual reviews
- **Pattern Recognition**: Identify recurring issues across codebase
- **Documentation Sync**: Ensure code and docs stay aligned

## Integration with Documentation Review

For comprehensive project maintenance, use both review systems:

```bash
# 1. Review code changes
bin/cr -d changes.diff -o code-review.md

# 2. Review documentation impact
bin/cr-docs -d changes.diff -o doc-review.md

# 3. Use both prompts with your AI agent for complete coverage
```

## Advanced Usage

### Custom Project State Collection

The tool automatically collects:

- Current test coverage (from coverage/index.html)
- StandardRB status and offense count (via bin/lint)
- Gem dependencies from Gemfile

When using `--include-dependencies`, it also collects:

- Full content of project documentation from `dev-taskflow/*.md`
- Full content of Architecture Decision Records from `docs/decisions/` and `dev-taskflow/current/*/decisions/`
- Full content of root documentation files (`*.md` in project root)
- Full Gemfile and gemspec content for context

### Review Priority Levels

Reviews are organized by priority:

- 🔴 **CRITICAL**: Security, data corruption, breaking changes
- 🟡 **HIGH**: Significant bugs, performance issues
- 🟢 **MEDIUM**: Code quality, maintainability
- 🔵 **LOW**: Style improvements, minor refactoring

### Customizing Reviews

You can modify the review template (`_code-review-from-diff.md`) to:

- Add project-specific checks
- Emphasize certain aspects
- Include custom rubrics
- Add team-specific guidelines

## Example Workflow

1. **Make changes to your Ruby gem**:

   ```bash
   # Implement new feature
   vim lib/my_gem/new_feature.rb

   # Add tests
   vim spec/my_gem/new_feature_spec.rb
   ```

2. **Generate diff**:

   ```bash
   git add .
   git diff --cached > feature.diff
   ```

3. **Generate review prompt**:

   ```bash
   bin/cr -d feature.diff
   ```

4. **Review with AI agent**:
   - Copy the generated prompt content
   - Paste into your AI assistant
   - Review and address feedback
   - Iterate as needed

5. **Update documentation if needed**:

   ```bash
   bin/cr-docs -d feature.diff
   ```

## Tips for Best Results

1. **Keep diffs focused**: Smaller, focused changes get better reviews
2. **Include context**: The AI can see the diff but not the full codebase
3. **Run tests first**: Include coverage results for better feedback
4. **Fix StandardRB issues**: Clean up style issues before review
5. **Iterate**: Use feedback to improve, then re-review

### Troubleshooting

### "Template not found" Error

Ensure you're running from the project root or that `docs-dev` is properly set up.

### Coverage/StandardRB Not Available

Install and configure these tools for richer analysis:

```bash
bundle add simplecov --group test
bundle add standard --group development
```

Ensure you have a `bin/lint` script that runs StandardRB for linting analysis.

### Large Diffs

For very large diffs, consider:

- Breaking into smaller logical chunks
- Focusing on specific subsystems
- Using `--include-dependencies` sparingly

## Contributing

To improve the code review system:

1. **Template improvements**: Edit `_code-review-from-diff.md`
2. **Tool enhancements**: Modify `generate-code-review-prompt`
3. **Add checks**: Extend project state collection
4. **Share patterns**: Document common issues and fixes

## See Also

- [Project Architecture](docs/architecture.md)
- [Ruby Style Guide](https://rubystyle.guide)
- [RSpec Best Practices](https://www.betterspecs.org)
