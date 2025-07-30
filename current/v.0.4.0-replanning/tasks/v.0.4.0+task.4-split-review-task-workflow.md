---
id: v.0.4.0+task.4
status: pending
priority: high
estimate: 10h
dependencies: [v.0.4.0+task.3]
---

# Rename review-task to plan-task for Implementation Planning

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 dev-handbook/workflow-instructions | grep -E "(review-task|plan-task|draft-task)" | sed 's/^/    /'
```

_Result excerpt:_

```
    ├── draft-task.wf.md (from task 3)
    ├── review-task.wf.md (to be renamed)
```

## Objective

Rename `review-task.wf.md` to `plan-task.wf.md` and refocus it entirely on implementation planning (defining HOW). This complements the `draft-task.wf.md` workflow (from task 3) which handles behavioral specification (defining WHAT). Together they form a clear specification pipeline: ideas → draft → plan → execute.

## What: Behavioral Specification

### User Experience
- **Input**: Draft task with validated behavioral specification
- **Process**: Research technical approaches, select tools, plan implementation
- **Output**: Task with complete implementation plan, promoted to pending status
- **Iteration**: Can be run multiple times as technical understanding evolves

### Expected Behavior

#### plan-task.wf.md (Implementation Planning)
1. Load draft task with behavioral specification
2. Research technical implementation approaches
3. Select appropriate tools, libraries, and patterns
4. Define specific file modifications and dependencies
5. Create detailed execution steps with test blocks
6. Add rollback strategies and risk mitigation
7. Promote task from draft to pending status

#### Integration with draft-task.wf.md
- draft-task creates behavioral specification (WHAT)
- plan-task creates implementation plan (HOW)
- Clear handoff: draft status → plan-task → pending status

### Key Workflow Separation
- **draft-task** (task 3): WHAT - behavioral specification, interfaces, success criteria
- **plan-task** (this task): HOW - technical implementation, tools, file changes
- **work-on-task**: EXECUTE - follow the implementation plan

## How: Implementation Plan

### Planning Steps
* [ ] Analyze current review-task.wf.md structure and content
  > TEST: Structure Analysis Check
  > Type: Pre-condition Check
  > Assert: Current workflow mixes behavioral validation with implementation planning
  > Command: grep -E "(implementation|planning|tool|file)" dev-handbook/workflow-instructions/review-task.wf.md | wc -l
* [ ] Research implementation planning best practices from industry
  > TEST: Research Integration Check
  > Type: Research Validation
  > Assert: Key patterns documented for technical design workflow
  > Command: test -f implementation-planning-research.md
* [ ] Design clear handoff format from draft-task to plan-task
* [ ] Identify all review-task references for update tracking

### Execution Steps
- [ ] Search for all review-task references across the project
  > TEST: Reference Discovery
  > Type: Pre-execution Check
  > Assert: All review-task references found and tracked
  > Command: grep -r "review-task" dev-handbook/ dev-taskflow/ docs/ --include="*.md" | grep -v "done/" > review-task-references.txt && wc -l review-task-references.txt
- [ ] Copy review-task.wf.md to plan-task.wf.md
  > TEST: File Creation Check
  > Type: Action Validation
  > Assert: New plan-task.wf.md file exists
  > Command: test -f dev-handbook/workflow-instructions/plan-task.wf.md && echo "File exists"
- [ ] Refocus plan-task.wf.md on implementation planning
  - Remove all behavioral validation sections
  - Add "Prerequisites" section requiring draft task
  - Add "Technical Research" section with patterns
  - Add "Tool Selection" guidelines
  - Add "File Modification Planning" section
  - Add "Risk Analysis and Rollback" section
  - Add "Embedded Test Planning" requirements
  > TEST: Content Transformation Check
  > Type: Content Validation
  > Assert: plan-task focuses only on HOW, not WHAT
  > Command: grep -E "(behavioral|interface contract|success criteria)" dev-handbook/workflow-instructions/plan-task.wf.md | wc -l
- [ ] Add implementation planning templates
  - Technical approach template
  - Tool selection matrix
  - File modification checklist
  - Risk assessment template
  > TEST: Template Embedding Check
  > Type: Content Validation
  > Assert: Templates embedded in XML format
  > Command: grep -A5 "<documents>" dev-handbook/workflow-instructions/plan-task.wf.md
- [ ] Update workflow invocation examples
  - For Claude Code: /plan-task <task-path>
  - For other agents: Read and follow plan-task.wf.md
- [ ] Update all review-task references to plan-task
  - Work through review-task-references.txt systematically
  - Update each file in tracking list
  > TEST: Reference Update Validation
  > Type: Post-update Check
  > Assert: No review-task references remain (except historical)
  > Command: grep -r "review-task" dev-handbook/ dev-taskflow/ docs/ --include="*.md" | grep -v "done/" | grep -v "rename" | wc -l
- [ ] Delete review-task.wf.md after all references updated
- [ ] Update workflow README with plan-task entry
- [ ] Add clear integration examples with draft-task workflow

## Scope of Work

### Deliverables

#### Create
- dev-handbook/workflow-instructions/plan-task.wf.md

#### Modify
- dev-handbook/workflow-instructions/README.md (update workflow list)
- All files with review-task references (update to plan-task)

#### Delete
- dev-handbook/workflow-instructions/review-task.wf.md (after reference updates)

## Acceptance Criteria

- [ ] plan-task.wf.md focuses exclusively on HOW (implementation planning)
- [ ] Clear prerequisite: requires draft task with behavioral specification
- [ ] Comprehensive implementation planning sections included
- [ ] All review-task references updated project-wide
- [ ] Examples demonstrate draft-task → plan-task pipeline
- [ ] Task state transition documented (draft → pending)
- [ ] Embedded test blocks validate critical operations
- [ ] Templates for technical planning embedded
- [ ] Integration with ideas-manager → draft-task → plan-task clear

## Example

### Scenario 1: Complete Specification Pipeline

```bash
# Step 1: Capture initial idea
ideas-manager capture "Add real-time collaboration features"
# Output: dev-taskflow/backlog/ideas/20250131-0930-realtime-collaboration.md

# Step 2: Draft behavioral specification
# For Claude Code: /draft-task dev-taskflow/backlog/ideas/20250131-0930-realtime-collaboration.md
# Creates: dev-taskflow/current/v.0.5.0/tasks/v.0.5.0+task.1-realtime-collaboration.md (draft status)

# Step 3: Plan implementation details
# For Claude Code: /plan-task dev-taskflow/current/v.0.5.0/tasks/v.0.5.0+task.1-realtime-collaboration.md
# Updates task with implementation plan and promotes to pending status
```

### Scenario 2: Task Planning Process

Starting with a draft task that needs behavioral validation and implementation planning:

```bash
# Initial task state: draft
# Task: dev-taskflow/current/v.0.4.0-replanning/tasks/v.0.4.0+task.5-implement-search-feature.md
```

Starting with a draft task containing behavioral specification:

```bash
# Task state: draft
# Task has behavioral specification from draft-task workflow:
# - User Experience: Users can search with fuzzy matching
# - Interface Contract: search-tool --query "term" --fuzzy
# - Success Criteria: Results return in <500ms for 10k items
```

#### Implementation Planning with plan-task
```bash
# For Claude Code:
/plan-task dev-taskflow/current/v.0.4.0-replanning/tasks/v.0.4.0+task.5-implement-search-feature.md

# For other agents:
# Read dev-handbook/workflow-instructions/plan-task.wf.md and follow steps
```

**plan-task.wf.md workflow performs:**

1. **Technical Research Phase**
   - Research fuzzy search algorithms and libraries
   - Evaluate performance characteristics
   - Review existing search implementations in codebase
   
2. **Tool Selection**
   - Select fuse.js for fuzzy matching (based on research)
   - Choose Redis for search result caching
   - Decide on async/await pattern for performance
   
3. **File Modification Planning**
   ```
   Create:
   - dev-tools/lib/coding_agent_tools/organisms/search_engine.rb
   - dev-tools/spec/organisms/search_engine_spec.rb
   
   Modify:
   - dev-tools/exe/search-tool (add CLI interface)
   - dev-tools/lib/coding_agent_tools.rb (register component)
   ```
   
4. **Implementation Steps with Tests**
   - [ ] Install fuse.js dependency
     > TEST: Dependency Installation
     > Command: bundle show fuse
   - [ ] Create SearchEngine organism
     > TEST: Class Creation
     > Command: ruby -r./lib/coding_agent_tools -e "p CodingAgentTools::Organisms::SearchEngine"
   - [ ] Implement fuzzy search algorithm
   - [ ] Add performance optimization
   
5. **Risk Analysis**
   - Risk: Performance degradation with large datasets
   - Mitigation: Implement pagination and caching
   - Rollback: Feature flag to disable fuzzy search

**Result:** Task promoted to pending status with complete technical implementation plan.

### Iterative Refinement Example

```bash
# Initial draft with basic specification
/draft-task "implement search feature"
# Creates draft task with behavioral specification

# First planning attempt
/plan-task dev-taskflow/current/v.0.4.0-replanning/tasks/v.0.4.0+task.5-implement-search-feature.md
# Discovers need for performance requirements

# Update behavioral specification
/draft-task dev-taskflow/current/v.0.4.0-replanning/tasks/v.0.4.0+task.5-implement-search-feature.md
# Adds performance criteria to behavioral spec

# Re-plan with updated requirements
/plan-task dev-taskflow/current/v.0.4.0-replanning/tasks/v.0.4.0+task.5-implement-search-feature.md
# Creates implementation plan addressing performance

# Task state transitions: draft → (plan) → draft → (plan) → pending
```

### Clear Workflow Separation

**What draft-task.wf.md produces (from task 3):**
- WHAT: Search functionality must support fuzzy matching
- WHAT: Interface must return structured results  
- WHAT: Performance must handle 10k+ items
- WHAT: Success criteria and validation questions

**What plan-task.wf.md produces (this task):**
- HOW: Use fuse.js library for fuzzy search implementation
- HOW: Implement SearchEngine organism in ATOM architecture
- HOW: Add search-tool executable with CLI interface
- HOW: Cache results in Redis for performance
- HOW: Test with RSpec including performance benchmarks

## Out of Scope

- ❌ Behavioral specification concerns (handled by draft-task)
- ❌ Automatic workflow chaining
- ❌ Tool implementation changes
- ❌ Task execution concerns
- ❌ Cascade review functionality
- ❌ Changes to draft-task workflow (completed in task 3)

## Implementation Planning Templates

The following templates should be embedded in plan-task.wf.md:

### Technical Approach Template
```markdown
## Technical Approach

### Architecture Pattern
- [ ] Pattern selection and rationale
- [ ] Integration with existing architecture

### Technology Stack
- [ ] Libraries/frameworks needed
- [ ] Version compatibility checks
- [ ] Performance implications
```

### File Modification Template
```markdown
## File Modifications

### Create
- path/to/new/file.ext
  - Purpose: [why this file]
  - Key components: [what it contains]

### Modify  
- path/to/existing/file.ext
  - Changes: [what to modify]
  - Impact: [effects on system]

### Delete
- path/to/obsolete/file.ext
  - Reason: [why removing]
  - Dependencies: [what depends on this]
```

## References

- Implementation planning research findings
- Current review-task.wf.md workflow
- v.0.4.0+task.3 (draft-task implementation)
- Software implementation best practices
- Guide: dev-handbook/guides/documents-embedding.g.md