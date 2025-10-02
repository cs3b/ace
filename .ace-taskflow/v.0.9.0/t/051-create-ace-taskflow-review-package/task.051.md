---
id: v.0.9.0+task.051
status: draft
priority: high
estimate: TBD
dependencies: []
needs_review: true
---

# Create ace-taskflow-review package

## Review Questions (Pending Human Input)

### [HIGH] Package Structure & Integration Strategy

- [ ] **Should ace-taskflow-review be a separate gem or integrated into ace-taskflow core?**
  - **Research conducted**:
    - Examined ace-git-commit (standalone gem with own CLI)
    - Reviewed ace-taskflow CLI structure (subcommands: idea, task, release, retro)
    - Current code-review tools in dev-tools/ are standalone executables
  - **Pattern analysis**:
    - ace-git-commit: Standalone gem with `ace-git-commit` CLI
    - ace-taskflow: Single gem with subcommands via `ace-taskflow <subcommand>`
  - **Two viable approaches**:
    1. **Separate gem**: `ace-review` with `ace-review code` / `ace-review synthesize` commands
    2. **Integrated subcommand**: Extend ace-taskflow with `ace-taskflow review code` / `ace-taskflow review synthesize`
  - **Why needs human input**:
    - Architectural decision affecting installation, versioning, and user experience
    - Task description mentions "ace-taskflow-review package" but also "ace-taskflow review" namespace
    - Need clarity on whether reviews are core to task management or separate concern

- [ ] **Where should code reviews be stored by default?**
  - **Research conducted**:
    - Found `.ace-taskflow/v.X.X.X/docs/` directory structure in current releases
    - Completed releases have `/docs/` directories with various markdown files
    - Config supports release-based organization (v.0.9.0 structure)
  - **Suggested default**: `.ace-taskflow/<release>/docs/reviews/` for release-specific reviews
  - **Alternative options**:
    - `.ace-taskflow/<release>/reviews/` (top-level in release)
    - `.ace-taskflow/reviews/<release>/` (reviews-first organization)
    - Configurable via `.ace/review/config.yml`
  - **Why needs human input**: Storage pattern affects discoverability and integration with other ace-taskflow features

### [MEDIUM] Migration Strategy

- [ ] **Should existing dev-tools code-review implementation be migrated or wrapped?**
  - **Research conducted**:
    - Current implementation in `dev-tools/lib/coding_agent_tools/` with full ATOM architecture
    - Executables: `dev-tools/exe/code-review` and `dev-tools/exe/code-review-synthesize`
    - Implementation includes: ReviewManager organism, preset system, LLM integration
  - **Migration options**:
    1. **Full migration**: Move all code to new gem, update imports, deprecate dev-tools version
    2. **Wrapper approach**: New gem delegates to existing dev-tools implementation
    3. **Incremental**: Start with wrapper, migrate incrementally
  - **Suggested default**: Wrapper approach initially for faster delivery
  - **Why needs human input**: Affects development effort, timeline, and backward compatibility

- [ ] **How should we handle backward compatibility with existing code-review commands?**
  - **Research conducted**:
    - Current commands: `code-review`, `code-review-synthesize` in dev-tools/exe/
    - Workflow files reference these commands directly
    - No version constraints found in workflow documentation
  - **Suggested default**:
    - Keep existing commands working via symlinks or PATH priority
    - Add deprecation notices recommending new ace-review/ace-taskflow commands
    - Document migration path in CHANGELOG
  - **Why needs human input**: User migration strategy and deprecation timeline decision

### [MEDIUM] Feature Scope & Interface

- [ ] **Should review commands support task-specific reviews out of the box?**
  - **Research conducted**:
    - Interface contract mentions: `ace-taskflow review task <task-id>`
    - Would require integration with ace-taskflow task file parsing
    - Need to extract file changes associated with specific task
  - **Implementation considerations**:
    - Tasks don't currently track associated file changes
    - Would need git history analysis or manual file specification
    - Could use task branch naming convention (if exists)
  - **Suggested default**: Start without task-specific reviews, add in v2
  - **Why needs human input**: Feature complexity vs initial release scope trade-off

- [ ] **What configuration should be exposed for review storage location?**
  - **Research conducted**:
    - ace-core provides configuration cascade (.ace/ directories)
    - ace-taskflow has extensive config in `.ace/taskflow/config.yml`
    - Other ace-* gems use `.ace/<gem-name>/config.yml` pattern
  - **Suggested configuration structure**:
    ```yaml
    review:
      storage:
        strategy: "release-based"  # or "time-based", "feature-based"
        base_path: ".ace-taskflow/%{release}/docs/reviews"
        auto_organize: true
      defaults:
        model: "google:gemini-2.5-flash"
        preset: "pr"
    ```
  - **Why needs human input**: Balance between flexibility and simplicity

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
