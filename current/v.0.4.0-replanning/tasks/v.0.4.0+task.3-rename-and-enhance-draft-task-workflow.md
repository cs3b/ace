* * *

id: v.0.4.0+task.3 status: done priority: high estimate: 8h dependencies: \[v.0.4.0+task.2\] ---

# Rename draft-task to draft-task with Behavior-First Focus

## 0. Directory Audit ✅

*Command run:*

```bash
tree -L 2 dev-handbook/workflow-instructions | grep -E "(draft-task|draft-task|plan-task)" | sed 's/^/    /'
```

*Result excerpt:*

```bash
    ├── draft-task.wf.md
    ├── plan-task.wf.md

## Objective

Transform the existing `draft-task.wf.md` workflow into `draft-task.wf.md` with a fundamental shift to behavior-first specification. This workflow becomes the
Blueprint Generator phase, focusing on WHAT the system should do (UX/DX/AX) rather than HOW to implement it.

## What: Behavioral Specification

### User Experience

* **Input**: Enhanced ideas or direct requirements
* **Process**: Create high-level natural language task specifications
* **Output**: Draft tasks with clear behavioral contracts and interface definitions

### Expected Behavior

1.  Focus on end-user experience and interfaces first
2.  Define success criteria before implementation details
3.  Specify public APIs, CLI interfaces, or UI behaviors
4.  Leave implementation details for the replan phase
5.  Create tasks in "draft" status for further planning

### Key Transformation

* **FROM**: Mixing what and how in a single pass
* **TO**: Pure behavioral specification with interface contracts
* **Result**: Clear handoff to implementation planning phase

## How: Implementation Plan

### Planning Steps

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Analyze current draft-task.wf.md structure and pain points
  > TEST: Structure Analysis Check Type: Pre-condition Check Assert: Current workflow mixes WHAT and HOW concerns Command: grep -E
  > "(implementation\|file\|code\|function)" dev-handbook/workflow-instructions/draft-task.wf.md \| wc -l

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Research best practices for behavioral specification from reflections
  > TEST: Learning Integration Check Type: Research Validation Assert: Key patterns from task 1 and reflections are documented Command: grep -E
  > "(validation\|question\|unknown\|assumption)" current-analysis.md

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Design new workflow structure with clear behavioral sections
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Identify all project references to draft-task for immediate update

### Execution Steps

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Search for all draft-task references across the project and maintain tracking
  list
  > TEST: Reference Discovery Type: Pre-execution Check Assert: All draft-task references found and documented in a list Command: grep -r "draft-task"
  > dev-handbook/ dev-taskflow/ docs/ --include="\*.md" \| grep -v "done/" > draft-task-references.txt && wc -l draft-task-references.txt

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Copy draft-task.wf.md to draft-task.wf.md
  > TEST: File Creation Check Type: Action Validation Assert: New draft-task.wf.md file exists with correct content Command: test -f
  > dev-handbook/workflow-instructions/draft-task.wf.md && echo "File exists"

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Rewrite workflow goals to emphasize behavior-first approach
  * Focus on WHAT the system should do (UX/DX/AX)
  * Remove all implementation (HOW) concerns
  * Emphasize validation questions and unknowns
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Add "Behavioral Specification" mandatory section with embedded template
  * Use XML documents container per documents-embedding.g.md
  * Update task template in dev-handbook/templates/release-tasks/task.template.md
  * Embed updated template in draft-task.wf.md
> TEST: Template Section Check Type: Content Validation Assert: Behavioral specification template is embedded in XML format Command: grep -A5 "<documents>"
> dev-handbook/workflow-instructions/draft-task.wf.md</documents>
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Add "Interface Contract" definition requirements with examples
  * CLI interface examples (from ideas-manager pattern)
  * API endpoint contracts
  * UI component behaviors
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Add "Success Criteria" as mandatory first step
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Add "Integration with ideas-manager" section showing optional input
  > TEST: Integration Documentation Type: Content Validation Assert: ideas-manager integration example exists Command: grep -A10 "ideas-manager"
  > dev-handbook/workflow-instructions/draft-task.wf.md

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Remove all implementation-focused sections (file lists, code details)
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Update task template to always use draft status
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Add comprehensive examples from task 1 patterns
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Update all draft-task references to draft-task project-wide using tracking list
  * Work through draft-task-references.txt systematically
  * Update each file in the list
  * Mark off completed updates
> TEST: Reference Update Validation Type: Post-update Check Assert: No draft-task references remain (except historical) Command: grep -r "draft-task"
> dev-handbook/ dev-taskflow/ docs/ --include="\*.md" \| grep -v "done/" \| grep -v "deprecat" \| wc -l
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Delete draft-task.wf.md after all references updated
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Update workflow README with new draft-task entry

## Scope of Work

### Deliverables

#### Create

* dev-handbook/workflow-instructions/draft-task.wf.md

#### Modify

* dev-handbook/workflow-instructions/README.md (update workflow list)
* All files with draft-task references (update to draft-task)

#### Delete

* dev-handbook/workflow-instructions/draft-task.wf.md (after reference updates)

## Acceptance Criteria

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Workflow focuses exclusively on WHAT not HOW
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Clear examples of behavioral specification from task 1 patterns
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Interface contract section is mandatory with CLI/API examples
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Success criteria defined before any other details
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Integration with draft status documented
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />ideas-manager integration documented as optional input
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />All draft-task references updated project-wide
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Embedded test blocks validate all critical operations
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Validation questions and unknowns emphasized

## Example

### Scenario 1: Using ideas-manager Output as Input

**New workflow with ideas-manager:**

# Step 1: Capture idea with ideas-manager
ideas-manager capture "Add user authentication with OAuth support"
# Output: dev-taskflow/backlog/ideas/20250130-1445-oauth-authentication.md

# Step 2: Use enhanced idea as input for draft-task workflow
# For Claude Code: /draft-task dev-taskflow/backlog/ideas/20250130-1445-oauth-authentication.md
# For other agents: Read dev-handbook/workflow-instructions/draft-task.wf.md and follow steps
```

The draft-task workflow reads the enhanced idea which already contains:

* Validated questions and unknowns
* Initial problem statement
* Preliminary solution directions

This provides structured input for creating a behavior-first task specification.

### Scenario 2: Converting Existing Task Creation to Behavior-First Approach

**Current workflow usage:**

```bash
# Old draft-task approach (mixed what/how)
# For Claude Code: /draft-task "Add user authentication system"
# For other agents: Read and follow draft-task.wf.md
```

**New draft-task workflow usage:**

```bash
# New behavior-first approach
# For Claude Code: /draft-task "Add user authentication system"
# For other agents: Read and follow draft-task.wf.md
```

### Step-by-Step Process

1.  **Behavioral Specification Phase**
```markdown
* Define what users experience: "Users can securely log in and access protected features"
* Specify interface contracts: API endpoints, CLI commands, UI components
* Set success criteria: "Users can authenticate within 3 seconds, sessions persist for 24 hours"
2.  **Draft Task Creation**
    ---
    id: v.0.5.0+task.15
    status: draft
    priority: high
    estimate: TBD
    ---
       
    # Add User Authentication System
       
    ## Behavioral Specification
       
    ### User Experience
    - Users see a login form with email/password fields
    - Invalid credentials show clear error messages
    - Successful login redirects to dashboard
    - Sessions automatically expire after 24 hours
       
    ### Interface Contract
    ```bash
    # CLI Interface
    auth-manager login --email user@example.com
    auth-manager logout
    auth-manager status
       
    # API Interface
    POST /api/auth/login
    DELETE /api/auth/logout
    GET /api/auth/status


### Success Criteria

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Users can log in with valid credentials
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Invalid attempts are blocked with helpful messages
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Sessions persist across browser refreshes
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Logout completely clears session data \`\`\`
{: .task-list}

3.  **Handoff to Implementation Planning**
* Task remains in "draft" status
* Implementation details handled in separate replan phase
* Clear interface contract enables parallel development

### Before/After Comparison

**Before (draft-task):**

* Mixed behavioral requirements with implementation details
* Unclear separation between what and how
* Tasks ready for immediate implementation (often incomplete)
* No structured validation questions

**After (draft-task):**

* Pure behavioral specification
* Clear interface contracts with examples
* Draft status indicates need for implementation planning
* Behavior-first approach ensures user value is defined upfront
* Validation questions and unknowns prominently featured
* Optional integration with ideas-manager for structured input
* Embedded test blocks for workflow validation

## Out of Scope

* ❌ Implementation planning details (belongs to plan-task workflow - task 4)
* ❌ Tool selection or file lists
* ❌ Technical architecture decisions
* ❌ Dependency analysis
* ❌ Changes to plan-task workflow (handled in task 4)

## Behavioral Specification Template Update

The task template in `dev-handbook/templates/release-tasks/task.template.md` should be enhanced with:

## Behavioral Specification

### User Experience
- **Input**: [What users provide]
- **Process**: [What users experience during interaction]
- **Output**: [What users receive]

### Expected Behavior
[Describe WHAT the system should do, not HOW]

### Interface Contract
```bash
# CLI Interface (if applicable)
command-name [options] <arguments>

# API Interface (if applicable)
GET/POST/PUT/DELETE /endpoint
```

### Success Criteria

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />\[Measurable outcome 1\]
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />\[Measurable outcome 2\]

### Validation Questions

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Question about unclear requirements?
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Question about edge cases?
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" />Question about user expectations? \`\`\`

## References

* Blueprint Generator concept from research
* Current draft-task.wf.md workflow
* Task template structure
* v.0.4.0+task.1 patterns for behavioral specification
* Reflection: 20250730-113043-task-review-enhancement-session.md
* Reflection: 20250730-180723-task-reopening-and-test-integrity-session.md
* Guide: dev-handbook/guides/documents-embedding.g.md