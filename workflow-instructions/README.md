# AI-Assisted Development Workflow Integration Guide

## Overview

This comprehensive guide documents end-to-end workflow orchestration for AI agents, providing clear guidance for navigating the complete development lifecycle from project initialization through release deployment. It addresses the critical need for integrated workflow navigation that enables AI agents to make informed decisions about which workflows to execute in different scenarios.

## Table of Contents

1. [Workflow Ecosystem Overview](#workflow-ecosystem-overview)
2. [Common Development Scenarios](#common-development-scenarios)
3. [Workflow Selection Decision Tree](#workflow-selection-decision-tree)
4. [Integration Patterns and Hand-offs](#integration-patterns-and-hand-offs)
5. [Error Recovery and Rollback Procedures](#error-recovery-and-rollback-procedures)
6. [Practical Examples](#practical-examples)
7. [Quick Reference](#quick-reference)

## Workflow Ecosystem Overview

The AI-assisted development workflow ecosystem consists of 19 interconnected workflows organized into logical groups:

### 1. Project Foundation & Setup

- **initialize-project-structure** - Bootstrap new projects with AI-assisted structure
- **load-project-context** - Load essential project understanding (for custom work outside predefined workflows)

### 2. Release Management

- **draft-release** - Create release structure and break down scope into tasks
- **publish-release** - Finalize and archive completed releases
- **update-roadmap** - Maintain strategic roadmap documentation

### 3. Task Management

- **create-task** - Transform requirements into formal task files
- **work-on-task** - Execute task implementation following embedded plans
- **review-task** - Review and refine task definitions before implementation

### 4. Code Quality & Review

- **review-code** - Comprehensive code review with configurable focus areas
- **synthesize-reviews** - Synthesize multiple review reports into unified recommendations
- **fix-tests** - Systematically diagnose and fix failing tests

### 5. Documentation

- **create-adr** - Document architectural decisions
- **create-api-docs** - Generate/update API documentation
- **create-user-docs** - Create user-facing documentation
- **update-blueprint** - Update project structure documentation

### 6. Quality Assurance

- **create-test-cases** - Generate comprehensive test scenarios

### 7. Session Management

- **save-session-context** - Capture session summaries for context restoration
- **create-reflection-note** - Document learnings and improvements

### 8. Development Operations

- **commit** - Create well-structured Git commits

## Common Development Scenarios

### Scenario 1: New Project Setup

**When to use**: Starting a completely new project from scratch

**Workflow Sequence**:

```
initialize-project-structure → load-project-context → draft-release (v.0.1.0)
```

**Key Decision Points**:

- Do we have existing documentation (PRD, README)?
- What type of project are we building?
- What's the initial release scope?

**Entry Conditions**:

- New empty or minimal project repository
- Basic project requirements or vision

**Exit Conditions**:

- Core project structure established
- Initial release planned with tasks defined
- Ready for feature development

**Expected Duration**: 2-4 hours

---

### Scenario 2: Feature Development Cycle

**When to use**: Implementing new features during active development

**Workflow Sequence**:

```
create-task → review-task → work-on-task → commit → review-code
```

**Key Decision Points**:

- Is this a new feature or enhancement?
- Does it require architectural changes?
- Are there dependencies on other tasks?
- What's the complexity level?

**Entry Conditions**:

- Project structure exists
- Feature requirements defined
- Development environment ready

**Exit Conditions**:

- Feature implemented and tested
- Code reviewed and approved
- Changes committed to version control

**Expected Duration**: 4-16 hours (depends on feature complexity)

---

### Scenario 3: Bug Fix Workflow

**When to use**: Addressing reported bugs or test failures

**Workflow Sequence (Fast Track)**:

```
work-on-task → commit → fix-tests
```

**Workflow Sequence (Standard)**:

```
create-task → work-on-task → commit → fix-tests → review-code
```

**Key Decision Points**:

- Is this a critical/urgent bug?
- Does it affect multiple components?
- Are there existing tests that need fixing?
- Should we skip code review for urgent fixes?

**Entry Conditions**:

- Bug identified and isolated
- Test failures or error reports available
- Access to affected code

**Exit Conditions**:

- Bug fixed and verified
- Tests passing
- Fix documented and committed

**Expected Duration**: 1-8 hours

---

### Scenario 4: Release Preparation and Completion

**When to use**: Preparing for or completing a release milestone

**Workflow Sequence**:

```
synthesize-reviews → create-reflection-note → publish-release → update-roadmap
```

**Key Decision Points**:

- Are all release tasks completed?
- Have we captured lessons learned?
- What's the next release scope?
- Are there blockers for publishing?

**Entry Conditions**:

- All release tasks marked as done
- Code reviews completed
- Tests passing
- Documentation updated

**Exit Conditions**:

- Release published and archived
- Roadmap updated for next cycle
- Lessons learned documented

**Expected Duration**: 2-6 hours

---

### Scenario 5: Code Review and Quality Assurance

**When to use**: Dedicated code review sessions or quality improvement

**Workflow Sequence**:

```
review-code → synthesize-reviews → create-task (for fixes)
```

**Key Decision Points**:

- What's the scope of review (files, timeframe)?
- Which LLM models should we use?
- Are there specific focus areas?
- Do we need follow-up tasks?

**Entry Conditions**:

- Code changes ready for review
- Review objectives defined
- LLM tools configured

**Exit Conditions**:

- Comprehensive review completed
- Issues identified and documented
- Follow-up tasks created if needed

**Expected Duration**: 1-4 hours

---

## Workflow Selection Decision Tree

### Decision Tree for AI Agents

```
START: What is the current situation?

├── 📁 NEW PROJECT
│   ├── No project structure exists?
│   │   └── → initialize-project-structure
│   ├── Need to do custom work outside predefined workflows?
│   │   └── → load-project-context
│   └── Ready for first release?
│       └── → draft-release
│
├── 🔧 DEVELOPMENT WORK
│   ├── Have specific requirements/features to implement?
│   │   ├── Requirements are informal/unstructured?
│   │   │   └── → create-task
│   │   ├── Task exists but needs review?
│   │   │   └── → review-task
│   │   └── Task is ready for implementation?
│   │       └── → work-on-task
│   │
│   ├── Need to fix bugs or failing tests?
│   │   ├── Is this urgent/critical?
│   │   │   └── → work-on-task (fast track)
│   │   └── → create-task → work-on-task
│   │
│   └── Working on complex implementation?
│       ├── Need architectural decisions?
│       │   └── → create-adr
│       ├── Need test coverage?
│       │   └── → create-test-cases
│       └── Need documentation?
│           ├── API documentation? → create-api-docs
│           └── User documentation? → create-user-docs
│
├── 🔍 QUALITY ASSURANCE
│   ├── Need code review?
│   │   └── → review-code
│   ├── Have multiple review reports?
│   │   └── → synthesize-reviews
│   └── Tests are failing?
│       └── → fix-tests
│
├── 📦 RELEASE MANAGEMENT
│   ├── Starting a new release?
│   │   └── → draft-release
│   ├── Ready to publish release?
│   │   └── → publish-release
│   └── Need to update roadmap?
│       └── → update-roadmap
│
├── 📚 DOCUMENTATION
│   ├── Project structure changed?
│   │   └── → update-blueprint
│   ├── Need architectural decision record?
│   │   └── → create-adr
│   └── Need user-facing documentation?
│       └── → create-user-docs
│
└── 🔄 SESSION MANAGEMENT
    ├── Need to save progress/context?
    │   └── → save-session-context
    ├── Session ending, want to capture learnings?
    │   └── → create-reflection-note
    └── Ready to commit changes?
        └── → commit
```

### Selection Criteria

**High Priority Triggers**:

- No project structure → `initialize-project-structure`
- Custom work needed → `load-project-context`
- Ready task → `work-on-task`
- Test failures → `fix-tests`
- Code ready to commit → `commit`

**Medium Priority Triggers**:

- New requirements → `create-task`
- Code changes → `review-code`
- Release milestone → `draft-release` or `publish-release`

**Low Priority Triggers**:

- Documentation gaps → `create-*-docs`
- Process improvements → `create-reflection-note`
- Session boundaries → `save-session-context`

## Integration Patterns and Hand-offs

### Pattern 1: Context-Driven Initialization

**Pattern**: Workflows handle context loading internally

```
Predefined Workflow → (loads context automatically) → Executes workflow steps
Custom Work → load-project-context → Proceed with custom implementation
```

**Implementation**:

- Most predefined workflows load project context automatically as their first step
- Use `load-project-context` explicitly only for custom work outside predefined workflows
- Context files: `docs/what-do-we-build.md`, `docs/architecture.md`, `docs/blueprint.md`
- If context files missing, trigger `initialize-project-structure`

### Pattern 2: Task-Driven Development

**Pattern**: Structured task creation and execution

```
Requirements → create-task → review-task → work-on-task → commit
```

**Hand-off Points**:

- `create-task` → `review-task`: Task file with embedded plan
- `review-task` → `work-on-task`: Reviewed and approved task
- `work-on-task` outputs: Completed implementation ready for commit

### Pattern 3: Quality Gates

**Pattern**: Multiple quality checks during development

```
work-on-task → commit → review-code → fix-tests
```

**Integration Points**:

- Tests failing during `work-on-task` → trigger `fix-tests`
- Code changes ready → trigger `review-code`
- Multiple reviews → trigger `synthesize-reviews`

### Pattern 4: Release Lifecycle

**Pattern**: Complete release management

```
draft-release → work-on-task (multiple) → publish-release → update-roadmap
```

**State Transitions**:

- `draft-release` creates release structure and tasks
- `work-on-task` executes individual tasks
- `publish-release` finalizes and archives release
- `update-roadmap` plans next cycle

### Pattern 5: Documentation Generation

**Pattern**: Context-driven documentation creation

```
Implementation → create-adr/create-api-docs/create-user-docs → update-blueprint
```

**Trigger Conditions**:

- Architectural changes → `create-adr`
- API changes → `create-api-docs`
- User-facing features → `create-user-docs`
- Structure changes → `update-blueprint`

## Error Recovery and Rollback Procedures

### Common Error Scenarios

#### 1. Workflow Execution Failure

**Symptoms**:

- Workflow exits with error
- Expected outputs not created
- Dependencies not met

**Recovery Steps**:

1. Check prerequisites and dependencies
2. Verify input files and parameters
3. Review error logs and context
4. Retry with corrected inputs
5. If persistent, escalate to manual intervention

**Rollback Strategy**:

- Restore previous state using Git
- Clean up partial outputs
- Update task status to reflect current state

#### 2. Test Failures During Implementation

**Symptoms**:

- Tests fail during `work-on-task`
- Build process fails
- Linting errors

**Recovery Steps**:

1. Immediately trigger `fix-tests` workflow
2. If tests cannot be fixed, revert changes
3. Create task for test fix if complex
4. Document issue for future reference

**Rollback Strategy**:

- Git reset to last known good state
- Preserve test failure information
- Update task with blocker status

#### 3. Incomplete Context Loading

**Symptoms**:

- Missing project context files
- Inconsistent project understanding
- Workflows failing due to missing context

**Recovery Steps**:

1. Verify project structure with `initialize-project-structure`
2. Force reload context with `load-project-context`
3. Update blueprint if structure changed
4. Retry original workflow

**Rollback Strategy**:

- No rollback needed (context loading is safe)
- Re-establish baseline understanding

#### 4. Release Publishing Failure

**Symptoms**:

- `publish-release` fails midway
- Partial release state
- Broken release artifacts

**Recovery Steps**:

1. Identify failure point in release process
2. Fix specific issue (build, tests, documentation)
3. Resume from failure point
4. Verify complete release integrity

**Rollback Strategy**:

- Git tag removal if created
- Revert to pre-release state
- Clean up release artifacts
- Update release status

### Error Prevention Strategies

#### 1. Dependency Checking

**Implementation**:

- Verify prerequisites before workflow execution
- Check file existence and validity
- Validate tool availability

#### 2. Atomic Operations

**Implementation**:

- Use Git for state management
- Create checkpoints during long workflows
- Implement transactional changes

#### 3. Context Validation

**Implementation**:

- Verify project context before proceeding
- Check for required files and structure
- Validate configuration consistency

## Practical Examples

### Example 1: New Feature Implementation

**Scenario**: Adding a new API endpoint to an existing service

**Step-by-Step Workflow**:

1. **Create Task** (`create-task`)

   ```
   Input: "Add GET /api/v1/users/:id endpoint with authentication"
   Output: Task file with implementation plan and acceptance criteria
   ```

2. **Review Task** (`review-task`)

   ```
   Input: Task file
   Output: Reviewed task with implementation approach validated
   ```

3. **Implement Feature** (`work-on-task`)

   ```
   Subtasks:
   - Create route handler
   - Add authentication middleware
   - Write unit tests
   - Update API documentation
   ```

4. **Review Code** (`review-code`)

   ```
   Input: Changed files (routes, tests, docs)
   Output: Code review report with recommendations
   ```

5. **Fix Issues** (if needed)

   ```
   Input: Review recommendations
   Output: Addressed code review feedback
   ```

6. **Commit Changes** (`commit`)

   ```
   Input: Completed implementation
   Output: Atomic commit with conventional message
   ```

**Expected Outcome**: New API endpoint implemented, tested, documented, and committed

---

### Example 2: Bug Fix Workflow

**Scenario**: Fixing a critical authentication bug

**Step-by-Step Workflow**:

1. **Create Urgent Task** (`create-task`)

   ```
   Input: Bug report with reproduction steps
   Output: High-priority task with fix plan
   ```

2. **Implement Fix** (`work-on-task`)

   ```
   Subtasks:
   - Reproduce bug locally
   - Identify root cause
   - Implement fix
   - Add regression test
   ```

3. **Fix Tests** (`fix-tests`)

   ```
   Input: Test failures
   Output: All tests passing
   ```

4. **Fast-Track Commit** (`commit`)

   ```
   Input: Critical bug fix
   Output: Hotfix commit with detailed message
   ```

**Expected Outcome**: Bug fixed, tests passing, fix deployed quickly

---

### Example 3: Release Preparation

**Scenario**: Preparing v1.2.0 release

**Step-by-Step Workflow**:

1. **Review All Changes** (`review-code`)

   ```
   Input: All changes since last release
   Output: Comprehensive review of release candidate
   ```

2. **Synthesize Reviews** (`synthesize-reviews`)

   ```
   Input: Multiple review reports
   Output: Unified assessment of release readiness
   ```

3. **Create Follow-up Tasks** (`create-task`)

   ```
   Input: Review recommendations
   Output: Tasks for any required fixes
   ```

4. **Complete Final Tasks** (`work-on-task`)

   ```
   Input: Release preparation tasks
   Output: All release blockers resolved
   ```

5. **Document Learnings** (`create-reflection-note`)

   ```
   Input: Release development experience
   Output: Process improvements and lessons learned
   ```

6. **Publish Release** (`publish-release`)

   ```
   Input: Completed release
   Output: Published package, documentation, and tags
   ```

7. **Update Roadmap** (`update-roadmap`)

   ```
   Input: Completed release and future plans
   Output: Updated roadmap for next release cycle
   ```

**Expected Outcome**: v1.2.0 released successfully with lessons learned documented

## Quick Reference

### Workflow Categories Quick Access

| Category | Workflows | Usage |
|----------|-----------|-------|
| **Foundation** | `initialize-project-structure`, `load-project-context` | New projects, custom work outside workflows |
| **Task Management** | `create-task`, `review-task`, `work-on-task` | Feature development, implementation |
| **Quality** | `review-code`, `synthesize-reviews`, `fix-tests` | Code review, quality assurance |
| **Release** | `draft-release`, `publish-release`, `update-roadmap` | Release management |
| **Documentation** | `create-adr`, `create-api-docs`, `create-user-docs`, `update-blueprint` | Documentation generation |
| **Session** | `save-session-context`, `create-reflection-note`, `commit` | Session management |

### Common Workflow Sequences

| Scenario | Sequence | Duration |
|----------|----------|----------|
| **New Project** | `initialize-project-structure` → `load-project-context` → `draft-release` | 2-4h |
| **Feature Development** | `create-task` → `review-task` → `work-on-task` → `commit` → `review-code` | 4-16h |
| **Bug Fix** | `work-on-task` → `commit` → `fix-tests` | 1-8h |
| **Release** | `synthesize-reviews` → `create-reflection-note` → `publish-release` → `update-roadmap` | 2-6h |
| **Code Review** | `review-code` → `synthesize-reviews` → `create-task` | 1-4h |

### Decision Points Checklist

**Before Starting Any Workflow**:

- [ ] Is project context loaded?
- [ ] Are dependencies met?
- [ ] Are required tools available?
- [ ] Is the workspace clean?

**During Workflow Execution**:

- [ ] Are intermediate outputs valid?
- [ ] Are tests passing?
- [ ] Are there any blockers?
- [ ] Should we escalate or continue?

**After Workflow Completion**:

- [ ] Are all outputs created?
- [ ] Are success criteria met?
- [ ] Should we trigger follow-up workflows?
- [ ] Is the state ready for next steps?

---

## Individual Workflow Reference

### Core Workflow

- [Load Project Context](./load-project-context.wf.md): Load project context, guides, and task information.
- [Review Task](./review-task.wf.md): Review and analyze a task before implementation.
- [Work on Task](./work-on-task.wf.md): Select and understand a task before implementation (includes TDD cycle).
- [Commit](./commit.wf.md): Create well-structured Git commits.

### Project Initialization & Setup

- [Initialize Project Structure](./initialize-project-structure.wf.md): Initialize `docs-dev` and `dev-taskflow` structures.
- [Update Blueprint](./update-blueprint.wf.md): Update the `docs/blueprint.md` project overview.

### Release Management

- [Draft Release](./draft-release.wf.md): Prepare content, documentation, and perform pre-flight checks for a release.
- [Publish Release](./publish-release.wf.md): Execute the release process (versioning, tagging, building, publishing).

### Task Management

- [Create Task](./create-task.wf.md): Transform unstructured notes, feedback, or requirements into well-structured, actionable task files.

### Documentation Generation

- [Create ADR](./create-adr.wf.md): Create structured Architecture Decision Record documents.
- [Create API Docs](./create-api-docs.wf.md): Generate comprehensive API documentation with code comments and examples.
- [Create Test Cases](./create-test-cases.wf.md): Generate comprehensive test cases and scenarios for features or APIs.
- [Create User Docs](./create-user-docs.wf.md): Create user-facing documentation including guides, tutorials, and references.

### Testing & Quality

- [Fix Tests](./fix-tests.wf.md): Debug and fix failing tests.

### Project Management & Reflection

- [Update Roadmap](./update-roadmap.wf.md): Update project roadmap and task priorities.
- [Save Session Context](./save-session-context.wf.md): Log a compact summary of the current session for context saving/reloading.
- [Create Reflection Note](./create-reflection-note.wf.md): Capture individual observations and learnings using the standard reflection template.

---

*This integration guide provides comprehensive orchestration guidance for AI agents navigating the complete development lifecycle. It should be updated as workflows evolve and new integration patterns emerge.*
