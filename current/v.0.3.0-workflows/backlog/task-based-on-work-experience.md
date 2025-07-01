# Task Backlog Based on Development Experience

## Executive Summary

This document consolidates 68+ development insights gathered from real-world experience working with AI coding agents and the Coding Agent Tools (CAT) project. The notes have been organized into 10 logical categories, prioritized by impact and dependencies, with specific improvement recommendations for each area.

## Priority Matrix & Dependencies

### Foundation Layer (Complete First)

1. **AI Agent Optimization & Context Management** (Priority: Critical)
2. **Task Management & Organization** (Priority: Critical)

### Implementation Layer (Build on Foundation)

3. **Testing & Quality Assurance** (Priority: High)
4. **Development Tools & CLI Enhancement** (Priority: High)

### Enhancement Layer (Polish & Optimize)

5. **Documentation & Knowledge Management** (Priority: Medium)
6. **Code Architecture & Structure** (Priority: Medium)
7. **Code Review & Quality Gates** (Priority: Medium)

### Optional Layer (Nice to Have)

8. **Workflow & Process Optimization** (Priority: Low)
9. **External Integration & Security** (Priority: Low)
10. **Development Environment** (Priority: Low)

---

## 1. AI Agent Optimization & Context Management

**Priority: Critical | Dependencies: None | Items: 3, 9, 21, 22, 29, 41, 43, 80, 98, 128, 149, 222, 225, 229**

### Current Issues

- **Context Pollution**: Agents read unnecessary tokens, increasing costs
- **Inefficient Delegation**: No system for cheaper models to handle simple tasks
- **Token Waste**: Complex algorithms passed to AI instead of code execution
- **Context Redundancy**: Agents re-read same files multiple times

### Key Items

- **Item 3**: Task context preload on cheaper models for file reading
- **Item 9**: Prevent coding agents from reading sensitive tokens
- **Item 21**: Self-improvement prompts based on diff/session/commits
- **Item 22**: Run tasks in subprocess when context isn't important
- **Item 29**: Use cheaper models for batch processing with progress tracking
- **Item 41**: Coding agent orchestrating other agents (cheaper, less context per task)
- **Item 43**: Group similar errors and fix in batches with smaller context models
- **Item 80**: AI writes code to execute algorithms rather than following complex instructions
- **Item 98**: Workflow instructions should have high-level plans for agent integration
- **Item 128**: Context preparation for tasks (choose tools/files to prevent re-reading)
- **Item 149**: Preflight with cheaper models, then use premium for execution
- **Item 222**: Workflow instructions should read context explicitly, not reference other workflows
- **Item 225**: Update workflow instructions to avoid cross-references
- **Item 229**: Compress guides into rules for current tasks

### Concrete Implementation Strategies

#### Strategy A: LLM-Query Integration for Labor-Intensive Workflows
**Leverage existing `dev-tools/exe/llm-query` infrastructure for workflow optimization**

- **Target workflows**: "load project context" and similar file-reading intensive operations
- **Model selection**: Use cheapest/fastest models (gflash, haiku) for simple file concatenation and reading tasks
- **Implementation**: Modify workflow instructions to delegate file reading to cheap models via llm-query
- **Cost optimization**: Reduce token costs by 60-80% for context loading operations
- **Integration points**: Workflow instructions that currently read multiple documentation files

#### Strategy B: LLM-Agent Command Infrastructure  
**Create `llm-agent` command similar to `llm-query` but for coding agent orchestration**

- **API design**: Similar to llm-query but with agent+model selection (e.g., `claude:sonet`, `codex:o3`)
- **Agent configurations**: Each coding agent needs different setup:
  - **Claude Code**: Current directory passing, full tool access, session management
  - **Codex/OpenAI**: API key management, limited tool subset, context boundaries
  - **Local agents**: LM Studio integration, custom tool permissions
- **Command structure**: `llm-agent claude:sonet "implement feature X" --context=session`
- **Tool permissions**: Configurable tool access per agent type and model
- **Directory management**: Automatic current directory context passing per agent

#### Strategy C: Project Content Utility Command
**Alternative approach: Build utility commands for context preparation**

- **File concatenation**: Command to combine multiple project files into single context
- **Path resolution**: Helper for agents struggling to find specific files
- **Context templates**: Pre-built context packages for common scenarios
- **Usage**: `project-context load-architecture` or `project-context find-file task-management`
- **Integration**: Used by both human developers and AI agents for consistent context access

### Improvement Recommendations

1. **Implement LLM-Query Workflow Integration** (Strategy A): Modify workflow instructions to delegate file-reading tasks to cheap models via existing `dev-tools/exe/llm-query` infrastructure. Target 60-80% cost reduction for context loading operations.

2. **Build LLM-Agent Command Infrastructure** (Strategy B): Create `llm-agent` command with agent+model selection (`claude:sonet`, `codex:o3`) and configurable tool permissions. Enable agent orchestration with proper directory and context management.

3. **Develop Project Content Utilities** (Strategy C): Build helper commands for file concatenation, path resolution, and context template management. Alternative to complex agent setups for simple context needs.

4. **Create Agent Hierarchy**: Implement main agent orchestrating specialized sub-agents using the new llm-agent infrastructure. Each sub-agent handles specific task types with appropriate model tiers.

5. **Implement Smart Context Caching**: Build system to cache project context and reuse across tasks, integrated with both llm-query and llm-agent commands for maximum efficiency.

6. **Token Usage Optimization**: Track and optimize token consumption across all agent interactions, with specific focus on measuring cost savings from Strategy A implementations.

7. **Batch Processing Framework**: Group similar tasks and process with appropriate model tiers using the new agent infrastructure for parallel execution and cost optimization.

### Implementation Specifications

#### Command Line Interface Specifications

**LLM-Agent Command Structure:**
```bash
# Basic usage
llm-agent <agent>:<model> "<task>" [options]

# Examples
llm-agent claude:sonet "implement feature X" --context=session --tools=all
llm-agent codex:o3 "fix bug in auth.rb" --context=minimal --tools=edit,read
llm-agent local:hermes "analyze logs" --context=files --tools=read

# Options
--context=<session|minimal|files|none>    # Context level
--tools=<all|edit,read|read>              # Tool permissions  
--directory=<path>                        # Working directory
--cost-limit=<tokens>                     # Token budget limit
--model-fallback=<model>                  # Backup model if primary fails
```

**Project-Context Command Structure:**
```bash
# Context loading
project-context load-architecture         # Load arch docs
project-context load-blueprint            # Load project structure
project-context load-tasks               # Load current tasks

# File operations  
project-context find-file <pattern>       # Find files by pattern
project-context concat-docs <type>        # Combine documentation
project-context prepare-context <workflow> # Workflow-specific context

# Cache management
project-context cache-clear              # Clear cached context
project-context cache-status             # Show cache statistics
```

#### Integration Points with Existing Infrastructure

**Dev-Tools Integration:**
- Extend `dev-tools/exe/llm-query` with agent orchestration capabilities
- Reuse existing provider configurations (Google, LM Studio, etc.)
- Leverage current authentication and API key management
- Build on existing cost tracking and usage reporting

**Workflow Instruction Integration:**
- Modify `dev-handbook/workflow-instructions/load-project-context.wf.md` to use cheap models
- Update task-related workflows to delegate context loading
- Add agent selection guidance to workflow templates
- Include cost optimization targets in workflow success criteria

**Tool Permission Matrix:**
| Agent Type | Read | Edit | Bash | Task | WebFetch | Git |
|------------|------|------|------|------|----------|-----|
| claude:sonet | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| claude:haiku | ✓ | ✗ | ✗ | ✗ | ✓ | ✗ |
| codex:o3 | ✓ | ✓ | Limited | ✗ | ✗ | ✓ |
| local:hermes | ✓ | ✗ | ✗ | ✗ | ✗ | ✗ |

#### Cost Optimization Targets

**Phase 1 (Workflow Integration):**
- Reduce context loading costs by 60-80% using cheap models for file reading
- Target workflows: load-project-context, task preparation, documentation review
- Expected monthly savings: $200-400 for active development teams

**Phase 2 (Agent Infrastructure):**
- Enable parallel processing with cost-aware model selection
- Implement automatic model fallback based on task complexity
- Target 40% overall reduction in agent orchestration costs

**Phase 3 (Advanced Optimization):**
- Context caching with 90% cache hit rate for repeated operations
- Batch processing with optimal model selection per task type
- Integration with existing dev-tools cost tracking for comprehensive monitoring

---

## 2. Task Management & Organization

**Priority: Critical | Dependencies: None | Items: 14, 18, 25, 27, 44, 54, 55, 58, 61, 68**

### Current Issues

- **Poor Task Sorting**: No standardized numbering system
- **Missing Metadata**: Tasks lack creation/update timestamps and proper structure
- **Unclear Status**: Confusion between "done" vs "closed" status
- **Directory Clutter**: Hard to see only pending tasks

### Key Items

- **Item 14**: Prefix tasks with numbers (001, 002) for sorting; subtasks as 7.1, 7.2
- **Item 18**: Review value of README files in release folders
- **Item 25**: Tasks should list required guides/files to read before starting
- **Item 27**: Add created_at and updated_at metadata to tasks
- **Item 44**: Task names should be prefixed with task numbers for sorting
- **Item 54**: `bin/tn --next=5` to create multiple tasks upfront
- **Item 55**: Comprehensive task metadata structure with ID, status, priority, dependencies
- **Item 58**: Organize tasks into d/ (done) and x/ (skipped) folders for clarity
- **Item 61**: Tasks should have clear assignee and label structure
- **Item 68**: Distinguish between "closed" (stopped for any reason) vs "done" (completed)

### Improvement Recommendations

1. **Standardize Task Metadata**: Implement the YAML frontmatter structure from item 55
2. **Improve Directory Structure**: Add d/ and x/ folders for better task organization
3. **Batch Task Creation**: Implement `bin/tn --next=5` for efficient task creation
4. **Task Context System**: Pre-define required reading for each task type
5. **Status Clarity**: Clearly define and document task status lifecycle

---

## 3. Testing & Quality Assurance

**Priority: High | Dependencies: Task Management | Items: 5, 7, 12, 13, 24, 28, 38, 104, 219**

### Current Issues

- **Inefficient Test Execution**: No targeted failure testing
- **Token Waste**: Full stack traces pollute AI context
- **No Quality Gates**: Tests don't run before task completion
- **Poor Test Reporting**: Default formatters provide too much information

### Key Items

- **Item 5**: Ensure clean state with `bin/lint` and `bin/test` before task completion
- **Item 7**: Run only failing tests (`bin/test -f` or `bin/test --next-failure`)
- **Item 12**: Update project documentation after task implementation
- **Item 13**: Group test errors by type and fix in batches
- **Item 24**: Sub-agent to analyze test output and provide actionable insights
- **Item 28**: Verify test success with `bin/test | tail 10`
- **Item 38**: Fixing tests is ineffective without proper error grouping
- **Item 104**: Set default test formatter to progress (less token usage)
- **Item 219**: Implement `bin/lint --fix` for automated fixes

### Improvement Recommendations

1. **Smart Test Execution**: Implement failure-only test runs with targeted fixes
2. **Test Analysis Agent**: Create sub-agent to parse test output and suggest solutions
3. **Quality Gates**: Mandatory lint/test success before task completion
4. **Error Library**: Build database of common test errors and solutions
5. **Minimal Test Output**: Configure progress formatter to reduce token usage

---

## 4. Development Tools & CLI Enhancement

**Priority: High | Dependencies: Task Management | Items: 1, 6, 16, 49, 64, 115, 147, 160, 200, 219**

### Current Issues

- **Limited Testing Interface**: No console for interactive testing
- **Inefficient Directory Scanning**: No tree structure reading
- **Missing Ruby Context**: No way to run Ruby in current project context
- **No Cost Tracking**: LLM usage costs not monitored

### Key Items

- **Item 1**: Use `bin/console` for interactive code testing
- **Item 6**: Read tree structure instead of scanning directories individually
- **Item 16**: Implement `bin/rb` for running Ruby in current context
- **Item 49**: Track LLM query tokens in/out and costs
- **Item 64**: Implement `bin/lint --fix` for automated fixes
- **Item 115**: Secure handling of API keys and secrets
- **Item 147**: Batch processing tools with context cache
- **Item 160**: Enhanced `bin/tn` with multiple task creation
- **Item 200**: Fish shell fuzzy search autocompletion for tools
- **Item 219**: File-specific linting with automatic fixes

### Improvement Recommendations

1. **Interactive Development**: Implement `bin/console` for REPL-style testing
2. **Cost Monitoring**: Add comprehensive LLM usage tracking and reporting
3. **Batch Operations**: Build tools for parallel processing with context caching
4. **Shell Integration**: Add fuzzy search and autocompletion for common tools
5. **Smart Linting**: Implement targeted linting with automatic fixes

---

## 5. Documentation & Knowledge Management

**Priority: Medium | Dependencies: Task Management | Items: 8, 18, 20, 29, 34, 36, 47, 54, 59, 65**

### Current Issues

- **Knowledge Duplication**: Multiple documents contain similar information
- **Poor Cross-referencing**: No standard linking between documents
- **Inconsistent Structure**: Different documentation styles across project
- **Missing Documentation**: Some areas lack proper guides

### Key Items

- **Item 8**: Create documentation in correct release folder structure
- **Item 18**: Review README file value in release folders
- **Item 20**: Reduce duplication between README, docs/, and project docs
- **Item 29**: Move core docs to docs/ folder, keep temporal docs in project folders
- **Item 34**: High-level overview of files and tools as part of blueprint
- **Item 36**: Tools to prepare context and prevent re-reading files
- **Item 47**: Implement diff filtering for docs-project and other paths
- **Item 54**: Standard markdown link format for cross-references
- **Item 59**: Zed integration issues with top-level directory paths
- **Item 65**: Consider compressing guides into rules for current tasks

### Improvement Recommendations

1. **Documentation Consolidation**: Audit and merge duplicate content
2. **Standard Cross-referencing**: Implement consistent linking format
3. **Context Preparation**: Build tools to prepare documentation context efficiently
4. **Structural Reorganization**: Move permanent docs to docs/, temporal to project folders
5. **Template Standardization**: Create templates for different document types

---

## 6. Code Architecture & Structure

**Priority: Medium | Dependencies: Documentation | Items: 6, 17, 19, 30, 31, 51, 57, 109, 154, 156**

### Current Issues

- **Unclear Load Order**: Dependency order matters but isn't documented
- **Architecture Confusion**: Cross-cutting concerns in ATOM architecture unclear
- **Naming Inconsistency**: No standard for singular vs plural directory names
- **Missing Code Maps**: No overview of Ruby code structure

### Key Items

- **Item 6**: Require order matters (atoms first, then molecules, etc.)
- **Item 17**: Separate project management tools from solution architecture
- **Item 19**: Clarify cross-cutting elements in ATOM architecture
- **Item 30**: Extract Ruby-specific parts from ATOM architecture guide
- **Item 31**: Build map of Ruby code (path → class → methods with parameters)
- **Item 51**: Create ATOM house rules in architectures/ directory
- **Item 57**: Custom linting beyond StandardRB for architectural rules
- **Item 109**: Define Ruby code structure and navigation
- **Item 154**: Establish ATOM architecture guidelines
- **Item 156**: Standardize directory naming conventions

### Improvement Recommendations

1. **Architectural Documentation**: Create comprehensive ATOM architecture guide
2. **Code Mapping**: Build automated code structure documentation
3. **Naming Standards**: Establish and enforce directory/file naming conventions
4. **Custom Linting**: Implement architectural rule checking
5. **Separation of Concerns**: Clearly separate project management from product architecture

---

## 7. Code Review & Quality Gates

**Priority: Medium | Dependencies: Testing, Tools | Items: 22, 25, 27, 190, 205, 212, 217**

### Current Issues

- **No Automated Review**: Code review is manual and inconsistent
- **Missing Context**: Reviews lack proper context and documentation
- **No Pre-commit Checks**: Quality gates happen after commit
- **Limited Diff Analysis**: No structured code comparison tools

### Key Items

- **Item 22**: Code review tasks with automatic model assignment (Gemini/O3)
- **Item 25**: Code review changes before commit
- **Item 27**: Address coupling and over-engineering in reviews
- **Item 190**: Standard markdown link format for reviews
- **Item 205**: Generate filtered diffs with additional context
- **Item 212**: Code diff analysis by project parts (tests, lib, docs)
- **Item 217**: Whole project or partial diff analysis

### Improvement Recommendations

1. **Automated Code Review**: Implement AI-powered code review system
2. **Pre-commit Quality Gates**: Run reviews before commits
3. **Contextual Reviews**: Include relevant documentation and context
4. **Structured Diff Analysis**: Build tools for meaningful code comparison
5. **Review Templates**: Standardize code review formats and outputs

---

## 8. Workflow & Process Optimization

**Priority: Low | Dependencies: All above | Items: 26, 47, 61, 67, 76, 98, 135, 222, 225, 233**

### Current Issues

- **Complex Workflows**: Instructions are too long and complex
- **Poor Verification**: Hard to verify model outputs and results
- **Process Inefficiency**: Workflows could be streamlined
- **Rule Complexity**: Current rules are too complex for consistent following

### Key Items

- **Item 26**: High-level plans in workflow instructions
- **Item 47**: Implement filtered diff tools
- **Item 61**: Improve task workflow efficiency
- **Item 67**: Focus on result verification ease
- **Item 76**: Session replay for workflow comparison
- **Item 98**: Integration between workflow instructions and coding agents
- **Item 135**: Batch processing with parallel execution
- **Item 222**: Explicit context reading in workflow instructions
- **Item 225**: Avoid cross-references in workflow instructions
- **Item 233**: Simplify verification of model results

### Improvement Recommendations

1. **Workflow Simplification**: Reduce complexity while maintaining effectiveness
2. **Result Verification**: Build tools to easily verify model outputs
3. **Process Automation**: Automate repetitive workflow steps
4. **Rule Optimization**: Simplify rules while maintaining quality
5. **Session Analysis**: Implement workflow effectiveness measurement

---

## 9. External Integration & Security

**Priority: Low | Dependencies: Tools | Items: 32, 115, 123, 124**

### Current Issues

- **Security Exposure**: API keys and secrets might be readable by AI
- **Limited Model Options**: Need more LLM provider options
- **No Containerization**: Development environment not containerized
- **Missing Worktree Support**: No Git worktree functionality

### Key Items

- **Item 32**: Secure agent handling of keys and secrets
- **Item 115**: Prevent AI from reading environment variables and config files
- **Item 123**: Containerization of software development environment
- **Item 124**: Implement Git worktrees functionality

### Improvement Recommendations

1. **Security Hardening**: Implement secure credential handling
2. **Environment Isolation**: Add containerization support
3. **Git Enhancement**: Add worktree support for parallel development
4. **Provider Expansion**: Add more LLM provider options
5. **Access Control**: Implement fine-grained access controls

---

## 10. Development Environment

**Priority: Low | Dependencies: Tools, Security | Items: 50, 119, 121, 198, 200**

### Current Issues

- **Environment Setup**: No standardized development environment
- **Path Issues**: Zed integration has path problems
- **Limited Autocompletion**: Missing fuzzy search for tools
- **Model Selection**: No easy way to select models and providers

### Key Items

- **Item 50**: Preflight with cheaper models before expensive ones
- **Item 119**: Containerization of development environment
- **Item 121**: Git worktree implementation
- **Item 198**: Fix Zed top-level directory path issues
- **Item 200**: Fish shell fuzzy search autocompletion

### Improvement Recommendations

1. **Environment Standardization**: Create reproducible development environment
2. **Editor Integration**: Fix and improve Zed integration
3. **Tool Enhancement**: Add fuzzy search and autocompletion
4. **Model Management**: Improve model selection and switching
5. **Path Resolution**: Fix directory and path handling issues

---

## Implementation Roadmap

### Phase 1: Foundation (Weeks 1-4)

- Implement AI agent optimization and context management
- Standardize task management and organization
- Focus on items from groups 1 and 2

### Phase 2: Core Development (Weeks 5-10)

- Enhance testing and quality assurance
- Improve development tools and CLI
- Focus on items from groups 3 and 4

### Phase 3: Enhancement (Weeks 11-16)

- Optimize documentation and knowledge management
- Refine code architecture and structure
- Implement code review and quality gates
- Focus on items from groups 5, 6, and 7

### Phase 4: Polish (Weeks 17-20)

- Optimize workflows and processes
- Enhance external integrations and security
- Improve development environment
- Focus on items from groups 8, 9, and 10

## Success Metrics

### Quantitative Metrics

- **Token Usage Reduction**: 40% reduction in token consumption for routine tasks
- **Development Speed**: 30% faster task completion time
- **Test Coverage**: Maintain >95% test coverage with improved efficiency
- **Error Reduction**: 50% fewer test failures per sprint

### Qualitative Metrics

- **Developer Experience**: Improved workflow satisfaction
- **Code Quality**: Consistent architecture and standards
- **Documentation Quality**: Reduced duplication and improved navigation
- **Agent Efficiency**: More reliable and predictable AI assistance

---

*This document represents a comprehensive analysis of development experience and should be used as the primary source for sprint planning and feature prioritization. Regular updates should be made as new insights are gathered.*
