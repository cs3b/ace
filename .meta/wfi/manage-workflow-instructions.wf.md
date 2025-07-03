# Manage Workflow Instructions

## Goal

Create, update, and maintain workflow instruction files following established standards and patterns. This meta-workflow guides handbook maintainers through the systematic creation of self-contained, well-structured workflow instructions that leverage embedded templates and comply with project conventions.

## Prerequisites

* Understanding of workflow instruction principles and standards
* Access to dev-handbook/.meta/gds/ definition files
* Knowledge of existing workflow patterns
* Access to template embedding system

## Project Context Loading

* Load workflow standards: `dev-handbook/.meta/gds/workflow-instructions-definition.g.md`
* Load template embedding guide: `dev-handbook/.meta/gds/template-embedding.g.md`
* Load project structure: `docs/blueprint.md`
* Load example workflows: `dev-handbook/workflow-instructions/review-task.wf.md`
* Load batch processing example: `dev-handbook/workflow-instructions/draft-release.wf.md`

## Process Steps

1. **Define Workflow Scope and Purpose:**
   * Identify the specific process or goal the workflow will address
   * Determine the target audience (human developers, AI agents, or both)
   * Define clear boundaries: what the workflow includes and excludes
   * Gather requirements from users or project needs

2. **Design Workflow Structure:**
   * Plan the workflow sections following the standard format:
     - `## Goal` - Clear, single-sentence objective
     - `## Prerequisites` - Required conditions and knowledge
     - `## Project Context Loading` - Files to load for context
     - `## Process Steps` - Detailed step-by-step instructions
     - `## Success Criteria` - Validation and completion checks
   * Design embedded content strategy (templates, examples, commands)
   * Plan for self-containment without external dependencies

3. **Gather and Prepare Content:**
   * Collect relevant templates from `dev-handbook/templates/` if applicable
   * Prepare example commands and patterns
   * Identify common error scenarios and solutions
   * Gather technology-specific examples if needed

4. **Create Workflow File:**
   * Create file in `dev-handbook/workflow-instructions/` with `.wf.md` extension
   * Use verb-first naming convention (e.g., `create-api-docs.wf.md`)
   * Implement standard workflow structure:

     ```markdown
     # Workflow Title
     
     ## Goal
     [Single sentence describing the objective]
     
     ## Prerequisites
     * [Required condition 1]
     * [Required condition 2]
     
     ## Project Context Loading
     * Load [context file 1]: `path/to/file`
     * Load [context file 2]: `path/to/file`
     
     ## Process Steps
     
     1. **Step Name:**
        * [Detailed instruction]
        * [Example or command]
     
     ## Success Criteria
     * [Completion check 1]
     * [Completion check 2]
     ```

5. **Embed Templates and Content:**
   * Use the template embedding format for reusable content:

     ```markdown
     <templates>
     <template path="path/to/template.md">
     [Template content here]
     </template>
     </templates>
     ```

   * Embed common commands and examples directly in process steps
   * Include technology-agnostic patterns with specific examples
   * Provide error handling and troubleshooting guidance

6. **Validate Workflow Standards Compliance:**
   * Verify all required sections are present and complete
   * Check for self-containment (no external dependencies)
   * Ensure clear, actionable instructions
   * Validate embedded templates follow proper format
   * Test that examples and commands are accurate

7. **Test and Refine:**
   * Review workflow with intended users
   * Test instructions by following them step-by-step
   * Verify embedded templates and examples work correctly
   * Refine language for clarity and conciseness
   * Ensure consistency with existing workflow patterns

8. **Integration and Documentation:**
   * Update workflow instructions README.md if needed
   * Add workflow to appropriate category in documentation
   * Consider cross-references with related guides or workflows
   * Run template synchronization if embedded templates are used

## Embedded Templates and Examples

### Basic Workflow Template Structure

```markdown
# [Action Verb] [Object/Target]

## Goal

[Single sentence describing what this workflow achieves]

## Prerequisites

* [Specific requirement 1]
* [Specific requirement 2]
* [Knowledge or access requirement]

## Project Context Loading

* Load [description]: `path/to/relevant/file`
* Load [description]: `path/to/other/file`

## Process Steps

1. **[Action Step Name]:**
   * [Specific instruction with details]
   * [Example command or pattern]
   
   **Validation:**
   * [How to verify this step succeeded]

2. **[Next Step Name]:**
   * [Continue with logical progression]

## Success Criteria

* [Measurable outcome 1]
* [Measurable outcome 2]
* [Quality check]

## Error Handling

**[Common Error Scenario]:**
* **Symptoms:** [What the user sees]
* **Solution:** [How to resolve]

## Usage Example

> "[Example user request or scenario]"
```

### Technology-Agnostic Command Examples

When including commands that vary by technology stack:

```markdown
### Run Tests
- Ruby: `bundle exec rspec`
- Node.js: `npm test`
- Python: `pytest`
- Rust: `cargo test`

### Install Dependencies
- Ruby: `bundle install`
- Node.js: `npm install`
- Python: `pip install -r requirements.txt`
- Rust: `cargo build`
```

### Embedded Test Pattern

For workflows that include validation steps:

```markdown
* [Action step]
  > TEST: [Test Name]
  > Type: [Pre-condition Check | Action Validation | Post-condition Check]
  > Assert: [What should be true]
  > Command: [Command to verify] || [Alternative command]
```

## Quality Standards

### Content Quality
* **Clarity:** Use simple, direct language
* **Completeness:** Include all necessary steps and context
* **Accuracy:** Verify all commands and examples work
* **Consistency:** Follow established patterns and terminology

### Structure Quality
* **Self-contained:** No external dependencies required
* **Logical flow:** Steps build upon each other naturally
* **Modular:** Clear separation between different phases
* **Actionable:** Each step produces a measurable outcome

### Technical Quality
* **Template compliance:** Follow embedding standards
* **File naming:** Use verb-first .wf.md convention
* **Cross-references:** Accurate links to related content
* **Version control:** Proper git handling for new files

## Success Criteria

* Workflow file created with proper naming and structure
* All required sections present and complete
* Embedded content follows template standards
* Instructions are clear, actionable, and self-contained
* No external dependencies or broken references
* Quality review completed and issues addressed
* Integration with existing documentation complete

## Common Patterns

### Planning-Heavy Workflows
For complex processes requiring significant upfront analysis:
1. Include substantial planning steps
2. Use embedded tests for validation
3. Break execution into clear phases
4. Provide rollback or error recovery

### Batch Processing Workflows
For operations on multiple items:
1. Include item selection/filtering logic
2. Provide progress tracking mechanisms
3. Handle partial failures gracefully
4. Include summary and reporting steps

### Creation Workflows
For generating new content:
1. Embed relevant templates directly
2. Include file naming conventions
3. Provide directory structure guidance
4. Include validation and quality checks

## Usage Example

> "Create a workflow instruction for automating database migrations in our Ruby on Rails application"