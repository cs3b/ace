---
id: v.0.9.0+task.006
status: draft
priority: high
estimate: TBD
dependencies: []
---

# Create ace-taskflow-review package

## Behavioral Specification

### User Experience
- **Input**: User invokes review commands via ace-taskflow CLI (e.g., `ace-taskflow review code`, `ace-taskflow review synthesize`)
- **Process**: System performs code reviews or synthesizes multiple reviews into actionable insights
- **Output**: Structured review documents with findings, suggestions, and synthesized patterns across reviews

### Expected Behavior

Users experience comprehensive code review workflows accessible through ace-taskflow. The system provides:

**Review Code**: Analyzes code for quality, patterns, and potential improvements
- Accepts file paths, directories, or commit references
- Performs automated code analysis (structure, patterns, best practices)
- Identifies potential issues, improvements, and learning opportunities
- Generates structured review document with categorized findings
- Links findings to specific code locations

**Synthesize Reviews**: Analyzes multiple code reviews to identify patterns and systemic issues
- Reads review documents from specified period or release
- Identifies recurring code patterns (good and problematic)
- Highlights systemic issues requiring architectural attention
- Generates synthesis with prioritized improvement recommendations
- Tracks progress on previously identified issues

The workflows integrate with .ace-taskflow structure, storing reviews organized by release, making review insights accessible for planning refactoring work and process improvements.

### Interface Contract

```bash
# Review code files or commits
ace-taskflow review code <path-or-commit> [--type <architecture|quality|security>]
# Executes: wfi://review-code
# Analyzes specified code
# Output: Review document in .ace-taskflow/<release>/docs/reviews/

# Review specific task implementation
ace-taskflow review task <task-id>
# Executes: wfi://review-code with task context
# Reviews code changes for specific task
# Output: Task-linked review document

# Synthesize multiple reviews
ace-taskflow review synthesize [--release <version>] [--since <date>]
# Executes: wfi://synthesize-reviews
# Reads: .ace-taskflow/<release>/docs/reviews/*.md
# Output: Synthesis document with patterns and recommendations

# List reviews
ace-taskflow review list [--release <version>]
# Output: List of reviews with dates and focus areas
```

**Error Handling:**
- Invalid path or commit: Report error with helpful message
- No reviews found for synthesis: Report empty state, suggest running reviews first
- Analysis failure: Provide partial results with error context

**Edge Cases:**
- Very large codebase: Provide progress updates, allow interruption
- No issues found: Acknowledge good code quality, suggest deeper analysis
- Conflicting recommendations: Highlight trade-offs, prioritize by impact

### Success Criteria

- [ ] **Automated Analysis**: System identifies common code quality issues and improvement opportunities
- [ ] **Actionable Feedback**: Reviews provide specific, implementable suggestions
- [ ] **Pattern Recognition**: Synthesis identifies recurring issues across multiple reviews
- [ ] **Task Integration**: Reviews can be linked to specific tasks for context
- [ ] **Progress Tracking**: System tracks improvement on previously identified issues

### Validation Questions

- [ ] **Review Scope**: What aspects should reviews cover (architecture, style, security, performance)?
- [ ] **Analysis Depth**: How deep should automated analysis go vs. human review guidance?
- [ ] **Storage Organization**: Should reviews be per-release, per-feature, or time-based?
- [ ] **Tool Integration**: Should system integrate with existing linters/analyzers or complement them?
- [ ] **Issue Prioritization**: What criteria determine which findings are most important?

## Objective

Create a dedicated review package (ace-taskflow-review) that enables automated code review and pattern synthesis, supporting code quality improvement and architectural decision-making across releases.

## Scope of Work

### Package Structure
New package: **ace-taskflow-review** (Ruby gem)
- Location: `dev-tools/ace-taskflow-review/`
- CLI namespace: `ace-taskflow review`
- Workflows to integrate:

### Workflows to Migrate
1. **review-code** (ace-taskflow → ace-taskflow-review)
   - Source: `/Users/mc/Ps/ace-meta/ace-taskflow/handbook/workflow-instructions/review-code.wf.md`
   - Integration: `ace-taskflow-review` calls wfi://review-code
   - Command: `ace-taskflow review code`

2. **synthesize-reviews** (dev-handbook → ace-taskflow-review)
   - Source: `/Users/mc/Ps/ace-meta/dev-handbook/workflow-instructions/synthesize-reviews.wf.md`
   - Integration: `ace-taskflow-review` calls wfi://synthesize-reviews
   - Command: `ace-taskflow review synthesize`

### Interface Scope
- CLI commands under `ace-taskflow review` namespace
- wfi:// protocol integration for workflow delegation
- Code analysis and pattern detection
- Review document generation and management
- Synthesis and pattern recognition logic
- Task and release context integration

### Deliverables

#### Behavioral Specifications
- Code review user experience
- Analysis criteria and patterns
- Synthesis algorithm behavior
- Integration with ace-taskflow core

#### Package Structure
- Ruby gem structure with CLI interface
- Workflow integration layer
- Code analysis framework
- Configuration management
- Documentation and examples

## Out of Scope

- ❌ **Implementation Details**: Ruby class structure, AST parsing, pattern matching algorithms
- ❌ **Deep Static Analysis**: Compiler-level optimizations, complex security vulnerability detection
- ❌ **IDE Integration**: Editor plugins, inline suggestions, real-time feedback
- ❌ **Team Collaboration**: Review assignments, approval workflows, discussion threads

## References

- Workflow files: `/Users/mc/Ps/ace-meta/ace-taskflow/handbook/workflow-instructions/review-code.wf.md`
- Workflow files: `/Users/mc/Ps/ace-meta/dev-handbook/workflow-instructions/synthesize-reviews.wf.md`
- Package pattern: Existing ace-taskflow gem structure
- Template: `/Users/mc/Ps/ace-meta/ace-taskflow/handbook/workflow-instructions/draft-task.wf.md`
