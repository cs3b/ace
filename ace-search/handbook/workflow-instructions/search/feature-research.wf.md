---
doc-type: workflow
title: Feature Research Workflow
purpose: feature-research workflow instruction
ace-docs:
  last-updated: 2026-02-22
  last-checked: 2026-03-21
---

# Feature Research Workflow

## Purpose

Research codebases to identify feature gaps, analyze implementation patterns, and discover how specific features are implemented across projects using multi-step ace-search analysis.

## Core Concept

Feature research answers questions like:
- "How is authentication implemented across this codebase?"
- "What patterns are used for error handling?"
- "Where are API endpoints defined and how are they structured?"
- "What logging frameworks are used and how are they configured?"

## Research Process

### 1. Understand the Feature
Break down the feature into searchable components:
```
Feature: "User authentication"
→ Login methods, session management, token handling, password reset
```

### 2. Plan Multi-Step Search Strategy
Design a search sequence from broad to specific:

**Step 1: File Discovery**
```bash
# Find files related to the feature
ace-search "auth" --file
ace-search "session" --file
ace-search "login" --file
```

**Step 2: Component Identification**
```bash
# Find classes and modules
ace-search "class.*Auth" --content --glob "**/*.rb"
ace-search "module.*Session" --content --glob "**/*.rb"
```

**Step 3: Implementation Analysis**
```bash
# Find method definitions
ace-search "def.*authenticate" --content
ace-search "def.*login" --content
```

**Step 4: Usage Patterns**
```bash
# Find how components are used
ace-search "Authentication.new" --content
ace-search "Session.create" --content
```

**Step 5: Configuration**
```bash
# Find config files
ace-search "auth" --content --glob "**/*.yml"
ace-search "authentication" --content --glob "**/*.yml"
```

**Step 6: Tests**
```bash
# Find test coverage
ace-search "auth" --content --glob "**/test/**/*"
ace-search "authenticate" --content --glob "**/spec/**/*"
```

### 3. Execute Searches Systematically
Run each search, analyze results, and adapt strategy based on findings.

### 4. Synthesize Findings
Create a comprehensive report with:
- Feature components and their locations
- Implementation patterns observed
- Code examples with file:line references
- Configuration dependencies
- Test coverage assessment
- Gaps or areas for improvement

## Search Patterns for Feature Research

### Pattern Discovery
```bash
# Find all files in feature domain
ace-search "feature-name" --file

# Narrow by file type
ace-search "feature-name" --file --glob "**/*.rb"

# Find classes/modules
ace-search "class.*Feature|module.*Feature" --content
```

### Implementation Analysis
```bash
# Find key methods
ace-search "def.*(key_action|key_behavior)" --content

# Find usage patterns
ace-search "FeatureClass.new|FeatureModule.method" --content

# Find dependencies
ace-search "require.*feature|import.*feature" --content
```

### Configuration and Setup
```bash
# Find config files
ace-search "feature" --content --glob "**/*.yml"

# Find environment variables
ace-search "FEATURE_" --content

# Find initialization
ace-search "Feature.configure|Feature.setup" --content
```

### Integration Points
```bash
# Find where feature is called
ace-search "Feature\\.method" --content --max-results 20

# Find related components
ace-search "feature" --content --glob "**/README.md"
```

## Adaptive Strategy

### Too Many Results
- Add `--glob` to filter file types
- Use `--include` to limit paths
- Add `--whole-word` for precise matching
- Set `--max-results 20` for initial scan

### Too Few Results
- Use `--case-insensitive`
- Try broader patterns with regex alternation
- Search for related terms
- Check different file types

### Unclear Implementation
- Add `--context 10` for surrounding code
- Use `--files-with-matches` to understand scope
- Navigate to specific directories and search locally

## Response Format

```markdown
## Feature Research: [Feature Name]

### Research Summary
[Brief overview of what was discovered]

### Component Architecture

**[Component Name]** (path/to/file.rb:42)
- [Purpose and role]
- [Key methods and behaviors]

**[Component Name]** (path/to/file2.rb:15)
- [Purpose and role]

### Implementation Patterns

[Pattern 1]: [Description with code example]
[Pattern 2]: [Description with code example]

### Configuration

[Configuration files and settings]
[Environment variables]
[Dependencies]

### Test Coverage

[Test locations and coverage assessment]
[Test gaps identified]

### Usage Examples

[1-2 key examples with file:line references]

### Integration Points

- [Dependencies and relationships]
- [Where and how feature is used]

### Gaps and Recommendations

- [Missing implementations]
- [Areas for improvement]
- [Potential refactoring opportunities]

### Search Strategy

1. `ace-search "..." --flags`
2. `ace-search "..." --flags`
...
```

## Best Practices

1. **Start broad, narrow progressively** - Files → components → details
2. **Document all searches** - List commands for reproducibility
3. **Include file:line references** - For all code examples
4. **Identify patterns** - Look for consistent approaches
5. **Check test coverage** - Verify feature has tests
6. **Note configuration** - Capture setup and dependencies
7. **Look for gaps** - Identify missing or incomplete implementations

## Example Research

**Goal:** "How is error handling implemented?"

**Searches:**
```bash
1. ace-search "error" --file --glob "**/*.rb"
2. ace-search "class.*Error" --content --glob "**/*.rb"
3. ace-search "rescue.*Error" --content --max-results 20
4. ace-search "error_handling" --content --glob "**/*.yml"
5. ace-search "error" --content --glob "**/test/**/*"
```

**Report excerpts:**
```markdown
## Feature Research: Error Handling

### Component Architecture

**AceError** (lib/ace/core/errors.rb:10)
- Base error class for all ACE errors
- Provides context-aware error messages

**ConfigError** (lib/ace/core/errors.rb:25)
- Raised for configuration-related issues
- Includes config path in error message

### Implementation Patterns

Consistent rescue pattern across organisms:
```ruby
rescue AceError => e
  logger.error(e.message)
  raise if config.raise_on_error
end
```

### Configuration

```yaml
# .ace/core/config.yml
error_handling:
  log_level: error
  raise_on_error: true
```

### Gaps

- No error codes for programmatic handling
- Inconsistent error logging in some modules
```

Remember: Feature research is about **discovery and understanding**, not modification. Provide comprehensive, actionable insights about how features are implemented.