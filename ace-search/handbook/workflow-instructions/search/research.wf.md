---
doc-type: workflow
title: Research Workflow
purpose: research workflow instruction
ace-docs:
  last-updated: 2026-02-22
  last-checked: 2026-03-21
---

# Research Workflow

## Purpose

Plan and execute systematic codebase investigations using multiple ace-search queries to understand architecture, implementation patterns, and component relationships.

## Role

**You are NOT the search workflow** (that executes single commands).

**You ARE the research workflow** that:
- Breaks research goals into searchable questions
- Plans multi-step search strategies
- Executes searches systematically via ace-search
- Synthesizes findings into reports
- Adapts strategy based on results

## Research Process

### 1. Goal Analysis
Break goal into specific questions:
```
Goal: "How is authentication implemented?"
→ What classes exist? Where? What methods? How used? Configuration?
```

### 2. Plan Searches
Design sequence (files → structure → details → usage):
```bash
ace-search "auth" --file --glob "**/*.rb"
ace-search "class.*Auth" --content --glob "**/*.rb"
ace-search "def.*authenticate" --content
ace-search "authenticate" --content --max-results 20
ace-search "authentication" --content --glob "**/*.yml"
```

### 3. Execute & Adapt
Run searches, adjust based on findings:
```bash
# Step 1: Discovery
ace-search "topic" --file
# → Found 45 files in lib/topic/, spec/topic/, config/

# Step 2: Narrow (based on step 1)
cd lib/topic/ && ace-search "class" --content --glob "**/*.rb"
# → Found 3 main classes: Manager, Handler, Validator

# Step 3: Deep dive
ace-search "class Manager" --content --context 10
# → Understands implementation

# Step 4: Usage
ace-search "Manager.new" --content
# → Found 8 call sites
```

### 4. Synthesize Report
Structured findings with file:line references.

## Research Patterns

### Architecture: "How is X structured?"
```bash
ace-search "X" --file                           # Find files
ace-search "class.*X" --content                 # Find classes
ace-search "< .*X|require.*X" --content         # Find relationships
ace-search "X" --content --glob "**/test/**/*"  # Check tests
```

### Implementation: "How does X work?"
```bash
ace-search "class X" --content --context 10     # Main class
cd lib/x/ && ace-search "def " --content        # Methods
ace-search "require|import" --content --include "lib/x/**/*"  # Dependencies
ace-search "X\." --content --max-results 20     # Usage
```

### Pattern: "Where is Y used?"
```bash
ace-search "pattern" --content                  # Direct usage
ace-search "pattern" --files-with-matches       # Scope understanding
ace-search "pattern" --content --glob "**/*.rb" # By file type
ace-search "pattern" --content --glob "**/*.yml"  # In config
```

### Dependency: "What uses X?"
```bash
ace-search "require.*X|import.*X" --content     # Requires
ace-search "X\.|X.new" --content                # Usage/instantiation
ace-search "X" --content --glob "**/Gemfile*"   # Package deps
```

## Adaptive Strategy

**Too many results (500+):**
- Add `--glob` filter
- Use `--include` for path limiting
- Add `--whole-word` or refine pattern
- Set `--max-results 20`

**Too few results (0-2):**
- Try `--case-insensitive`
- Broaden pattern (use regex alternation)
- Try file search instead of content
- Check different file types

**Unclear results:**
- Add `--context 5` for surrounding code
- Use `--files-with-matches` to see scope
- Navigate to directory and search locally

## Response Format

```markdown
## Research: [Goal]

### Search Strategy
1. [search command and reasoning]
2. [search command and reasoning]
...

### Key Findings

**[Component Name]** (file.rb:42)
- [Key observation]
- [Implementation detail]

**[Component Name]** (file2.rb:15)
- [Key observation]

### Architecture Summary
[High-level synthesis of structure/patterns]

### Code Examples
[1-2 critical snippets with file:line]

### Related Components
- [Dependencies, callers, config]

### Gaps
- [What wasn't found or needs clarification]

### Searches Executed
1. `ace-search "..." --flags`
2. `ace-search "..." --flags`
```

## Example Research

**Goal:** "Find error handling patterns"

**Searches:**
```bash
1. ace-search "error" --file --glob "**/*.rb"
   → Found lib/errors.rb, 15 files with "error" in name

2. ace-search "class.*Error" --content --glob "**/*.rb"
   → Found AceError, ConfigError, ValidationError hierarchy

3. ace-search "rescue.*Error" --content --glob "**/*.rb" --max-results 15
   → Found 12 rescue patterns, mostly in organisms/

4. ace-search "error_handling" --content --glob "**/*.yml"
   → Found config in .ace/core/config.yml
```

**Report:**
```markdown
## Research: Error Handling Patterns

### Key Findings

**Error Hierarchy** (lib/ace/core/errors.rb:10)
- Base: AceError < StandardError
- Specific: ConfigError, ValidationError, ExecutionError
- Custom message formatting with context

**Usage Pattern** (12 occurrences in organisms/)
- Consistent: `rescue AceError => e` with logging
- Configuration-driven: raise_on_error flag

**Configuration** (.ace/core/config.yml:15)
- Settings: log_level, raise_on_error, error_reporter

### Architecture Summary
Three-tier approach: custom hierarchy → consistent rescue → centralized config

### Gaps
- No error codes found
- Error reporting integration unclear
```

## Best Practices

- **Start broad, narrow progressively** - Files → structure → details → usage
- **Limit initially** - Use `--max-results 10` for exploration
- **Always include references** - file:line for all findings
- **Track searches** - List commands for reproducibility
- **Adapt dynamically** - Adjust strategy based on intermediate results
- **Synthesize clearly** - Group findings by component/pattern

Remember: You **orchestrate searches**, not execute single commands. Plan → Execute → Synthesize.