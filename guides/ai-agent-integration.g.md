# AI Agent Integration Guide

## Overview

This guide provides comprehensive instructions for integrating AI agents into development workflows, covering command wrapper
patterns, context management, error handling, and best practices derived from extensive analysis of AI agent usage patterns.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Command Wrapper Patterns](#command-wrapper-patterns)
3. [Context Management](#context-management)
4. [Error Handling](#error-handling)
5. [Common Pain Points](#common-pain-points)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)
8. [Examples](#examples)

## Quick Start

### Prerequisites

- Access to project repository with workflow instructions
- Understanding of project structure and submodules
- Familiarity with CLI tools and Git operations

### Essential Commands

```bash
# Find next task to work on
bin/tn

# Review recent tasks
bin/tr

# Get current release context
bin/rc

# Run tests and validation
bin/test
bin/lint

# Multi-repository operations
bin/gs     # git status across all repos
bin/gc -i "intention"  # coordinated commits
```

### Initial Setup

1. **Verify Project Structure**

   ```bash
   # Always verify file locations before operations
   ls dev-taskflow/current/
   find . -name "*.wf.md" -type f
   ```

2. **Check Submodules**

   ```bash
   git submodule update --init --recursive
   ```

3. **Validate Environment**

   ```bash
   bin/test
   bin/lint
   ```

## Command Wrapper Patterns

### @work-on-task Pattern

**Purpose**: Systematic task execution with validation and todo management

**Usage**:

```bash
# Follow work-on-task workflow
@work-on-task dev-taskflow/current/v.X.Y.Z-release/tasks/task-file.md
```

**Key Components**:

- Todo list management for progress tracking
- Embedded test validation at each step
- Plan mode for user approval
- Systematic completion verification

**Example Implementation**:

```markdown
## Implementation Plan

### Planning Steps
* [ ] Research existing patterns
  > TEST: Pattern Analysis Complete
  > Type: Pre-condition Check
  > Assert: Patterns documented
  > Command: ls patterns/

### Execution Steps
- [ ] Implement feature
  > TEST: Feature Validation
  > Type: Action Validation
  > Assert: Tests pass
  > Command: bin/test
```

### @review-code Pattern

**Purpose**: Multi-file analysis with structured XML packaging

**Usage**:

```bash
# Review multiple workflow files
@review-code workflows
```

**Architecture**:

- XML packaging for structured content
- Semantic tags for organization
- Comprehensive analysis reports

**XML Structure**:

```xml
<project-context>
  <focus-areas>
    <focus>Primary analysis target</focus>
  </focus-areas>
  <documents>
    <document path="file1.md">
      <![CDATA[content]]>
    </document>
  </documents>
</project-context>
```

### @handbook-review Pattern

**Purpose**: Multi-model review orchestration

**Usage**:

```bash
# Systematic workflow analysis
@handbook-review workflows
```

**Features**:

- Cost-effective multi-model comparisons
- System prompt separation
- Structured analysis reports

### Multi-Repository Commands

**Purpose**: Coordinated operations across main + submodules

**Usage**:

```bash
# Intention-based commits across all repos
bin/gc -i "implement feature X"

# Status across all repositories
bin/gs

# Logs across all repositories
bin/gl
```

## Context Management

### File Path Validation

**Problem**: AI agents frequently assume file locations without verification

**Solution**: Always verify before operations

```bash
# Validate file existence
ls /path/to/file
find . -name "filename" -type f
grep -r "pattern" directory/

# Use targeted file reading
grep -n "pattern" file.md
sed -n '10,20p' file.md
```

### XML Packaging for Multi-File Analysis

**Purpose**: Structured content organization for LLM processing

**Benefits**:

- Improves LLM processing efficiency
- Maintains content structure
- Enables semantic analysis

**Template**:

```xml
<project-context>
  <focus-areas>
    <focus>Specific analysis target</focus>
    <focus>Secondary concern</focus>
  </focus-areas>
  <documents>
    <document path="relative/path/file1.md">
      <![CDATA[
      File content here
      ]]>
    </document>
    <document path="relative/path/file2.md">
      <![CDATA[
      More content here
      ]]>
    </document>
  </documents>
</project-context>
```

### Session Documentation

**Structure**:

```text
session-YYYYMMDD-HHMMSS-description/
├── README.md              # Session overview
├── context/              # Input context
├── analysis/             # Generated analysis
├── outputs/              # Final deliverables
└── session-log.md        # Process documentation
```

### Todo List Management

**Purpose**: Systematic progress tracking

**Implementation**:

```bash
# Create and update todos
TodoWrite: [
  {"id": "task-1", "content": "Description", "status": "pending", "priority": "high"},
  {"id": "task-2", "content": "Description", "status": "in_progress", "priority": "medium"}
]

# Mark completed immediately
{"id": "task-1", "status": "completed"}
```

## Error Handling

### Validation-First Approach

**Pattern**: Always validate file existence before operations

**Implementation**:

```bash
# File existence checks
if [ -f "file.md" ]; then
    echo "File exists"
else
    echo "File not found"
    exit 1
fi

# Directory validation
if [ -d "directory/" ]; then
    echo "Directory exists"
else
    echo "Directory not found"
    exit 1
fi
```

### API Reliability Management

**Problem**: External API failures disrupt workflows

**Solution**: Multi-level fallback strategies

```bash
# API health check before expensive operations
if curl -f -s "https://api.example.com/health" > /dev/null; then
    echo "API available"
else
    echo "API unavailable, using fallback"
    # Implement fallback logic
fi
```

### Timeout Configuration

**Pattern**: Configure timeouts based on content size

**Implementation**:

```bash
# Small files: 30 seconds
# Medium files: 60 seconds  
# Large files: 120 seconds
timeout 60 command_here
```

### Cost-Aware Processing

**Pattern**: Prioritize zero-cost operations

**Strategy**:

1. Use direct agent capabilities first
2. Implement cost-benefit analysis
3. Fallback to external APIs only when necessary

## Common Pain Points

### 1. File Path Discovery Errors

**Problem**: Assuming file locations without verification

**Symptoms**:

- "File not found" errors
- Operations on wrong directories
- Missing files in multi-file operations

**Solution**:

```bash
# Always verify before operations
find . -name "target-file.md" -type f
ls -la expected/directory/
grep -r "search-pattern" .
```

### 2. Task Completion Accuracy

**Problem**: Premature task completion without full validation

**Symptoms**:

- Tasks marked done with incomplete work
- Missing files in deliverables
- Scope creep without validation

**Solution**:

- Create explicit completion checklists
- Verify against original requirements
- Use embedded tests for validation

### 3. Template Format Conversion

**Problem**: Complex migrations between formats

**Symptoms**:

- Four-tick vs three-tick markdown confusion
- XML template compliance issues
- Large-scale conversion errors

**Solution**:

```bash
# Validate template synchronization
handbook sync-templates --dry-run

# Check compliance
bin/lint
```

### 4. Context Token Management

**Problem**: Exceeding context limits with large files

**Symptoms**:

- Truncated responses
- Incomplete analysis
- Processing failures

**Solution**:

- Use targeted file reading
- Implement content chunking
- Prioritize relevant sections

## Best Practices

### 1. Systematic Workflow Following

**Principle**: AI agents perform best with documented workflows

**Implementation**:

- Use established workflow patterns consistently
- Follow work-on-task.wf.md structure
- Embed comprehensive examples

### 2. Plan Mode Execution

**Principle**: Get user approval before major changes

**Usage**:

```bash
# Present plan before execution
exit_plan_mode: {
  "plan": "Detailed implementation plan"
}
```

### 3. Incremental Validation

**Principle**: Validate each step before proceeding

**Implementation**:

- Embedded tests in task plans
- File existence checks
- Completion verification

### 4. Multi-Model Strategy

**Principle**: Leverage different AI models for optimal results

**Strategy**:

- Google Pro for cost-effective coverage
- Claude for detailed technical analysis
- Synthesis approach for insights

## Troubleshooting

### Common Issues

#### Issue: Command Not Found

**Symptoms**: `bin/command` results in "command not found"

**Solution**:

```bash
# Verify script exists and is executable
ls -la bin/command
chmod +x bin/command
```

#### Issue: File Path Errors

**Symptoms**: Operations fail with "No such file or directory"

**Solution**:

```bash
# Use absolute paths
pwd
ls -la /full/path/to/file
```

#### Issue: Submodule Out of Sync

**Symptoms**: Missing files in submodules

**Solution**:

```bash
git submodule update --init --recursive
```

#### Issue: API Authentication Failures

**Symptoms**: 401 errors from external APIs

**Solution**:

```bash
# Check environment variables
echo $API_KEY
# Verify API key configuration
```

### Diagnostic Commands

```bash
# Project health check
bin/test
bin/lint
bin/gs

# File system validation
find . -name "*.md" -type f | head -10
ls -la dev-taskflow/current/

# Dependency verification
git submodule status
```

## Examples

### Example 1: Basic Task Execution

```bash
# 1. Find next task
bin/tn

# 2. Follow work-on-task workflow
@work-on-task dev-taskflow/current/v.0.3.0-workflows/tasks/task-file.md

# 3. Validate completion
bin/test
bin/lint
```

### Example 2: Multi-File Analysis

```bash
# 1. Prepare XML context
cat > context.xml << 'EOF'
<project-context>
  <focus-areas>
    <focus>Workflow analysis</focus>
  </focus-areas>
  <documents>
    <document path="workflow1.md">
      <![CDATA[content]]>
    </document>
  </documents>
</project-context>
EOF

# 2. Execute analysis
@review-code workflows
```

### Example 3: Error Recovery

```bash
# 1. Detect error
if ! bin/test; then
    echo "Tests failed"
    
    # 2. Diagnose issue
    bin/lint
    git status
    
    # 3. Fix and retry
    # ... fix issues ...
    bin/test
fi
```

### Example 4: Multi-Repository Coordination

```bash
# 1. Check status across repos
bin/gs

# 2. Coordinated commit
bin/gc -i "implement feature X"

# 3. Verify changes
bin/gl
```

## Advanced Patterns

### Template-Driven Development

**Pattern**: Use templates and standardized formats

**Implementation**:

```bash
# XML template embedding
handbook sync-templates --verbose

# Conventional commit patterns
bin/gc -i "feat: add new feature"
```

### Context Preservation

**Pattern**: Maintain context across sessions

**Implementation**:

- Comprehensive session documentation
- Structured output directories
- Progress tracking with todos

### Cost Optimization

**Pattern**: Minimize external API usage

**Strategy**:

1. Use direct agent capabilities
2. Implement caching where appropriate
3. Batch operations efficiently

## Conclusion

This guide provides a comprehensive framework for AI agent integration based on real-world usage patterns and proven strategies.
Success depends on systematic validation at each step, proper context management, robust error handling, cost-aware processing,
and following established workflows. By implementing these patterns and avoiding common pitfalls, AI agents can effectively
contribute to complex development workflows while maintaining reliability and efficiency.
