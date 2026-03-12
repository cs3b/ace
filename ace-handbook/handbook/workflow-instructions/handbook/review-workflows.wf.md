# Review Workflows

## Goal

Systematically review multiple workflow instruction files for compliance with standards, consistency, and quality. This
meta-workflow provides batch review capabilities for handbook maintainers to ensure workflow instructions follow
established patterns and maintain high quality across the entire collection.

## Prerequisites

* Understanding of workflow instruction standards and principles
* Access to handbook guides and workflow standards
* Knowledge of existing workflow patterns
* List of workflow files to review (or intent to review all)

## Project Context Loading

* Load workflow standards: `ace-handbook/handbook/guides/meta/workflow-instructions-definition.g.md`
* Load markdown standards as needed from `ace-handbook/handbook/guides/meta/markdown-definition.g.md`
* Load a current workflow example via `ace-bundle wfi://handbook/manage-workflows`
* Load a current maintenance example via `ace-bundle wfi://handbook/update-docs`

## Process Steps

1.  **Define Review Scope:**
    * Determine which workflows to review:
      * All workflows in `handbook/workflow-instructions/`
      * Specific subset based on criteria (new, recently modified, specific category)
      * Individual workflows provided by user
    * Identify review objectives:
      * Standards compliance check
      * Consistency review across workflows
      * Quality assessment and improvement
      * Template synchronization validation
2.  **Gather Workflow Inventory:**
    * List all workflow files to review:
      
          find workflow-instructions -name "*.wf.md" -type f
      {: .language-bash}
    
    * Group workflows by category or type for systematic review
    * Note file modification dates and sizes for context
    * Create review tracking structure
3.  **Initialize Review Process:**
    * Create review session directory:
      
          mkdir -p dev-taskflow/current/v.X.Y.Z-release/workflow-review/$(date +%Y%m%d)
      {: .language-bash}
    
    * Create review summary template:
      
          # Workflow Review Session - [Date]
               
          ## Review Scope
          * Total workflows reviewed: [N]
          * Review criteria: [Standards compliance, consistency, quality]
               
          ## Summary Results
          * ✅ Compliant workflows: [N]
          * ⚠️ Workflows needing minor fixes: [N]
          * ❌ Workflows needing major fixes: [N]
               
          ## Detailed Findings
          [Individual workflow assessments]
               
          ## Recommended Actions
          [Prioritized improvement tasks]
      {: .language-markdown}
4.  **Review Each Workflow Systematically:**
    
    For each workflow file, assess the following areas:
    
    **Structure Compliance:**
    
    * ✅ Contains required sections: Goal, Prerequisites, Project Context Loading, Process Steps
    * ✅ Uses proper markdown structure and formatting
    * ✅ Follows verb-first naming convention (.wf.md)
    * ✅ Has clear, single-sentence goal statement
    **Self-Containment:**
    
    * ✅ No external dependencies or broken references
    * ✅ Embedded templates use proper format
    * ✅ All necessary examples and patterns included
    * ✅ Context loading section complete and accurate
    **Content Quality:**
    
    * ✅ Instructions are clear and actionable
    * ✅ Process steps are logically ordered
    * ✅ Examples and commands are accurate
    * ✅ Error handling guidance provided
    **Consistency:**
    
    * ✅ Terminology matches project standards
    * ✅ Structure follows established patterns
    * ✅ Cross-references are accurate
    * ✅ Template embedding follows standards
5.  **Document Review Findings:**
    
    For each workflow, create a standardized assessment:
    
        ### [Workflow Name] - [filename.wf.md]
           
        **Overall Status:** ✅ Compliant | ⚠️ Minor Issues | ❌ Major Issues
           
        **Structure Assessment:**
        * Required sections: ✅/❌
        * Naming convention: ✅/❌
        * Markdown formatting: ✅/❌
           
        **Self-Containment Assessment:**
        * External dependencies: ✅ None | ⚠️ Some | ❌ Many
        * Template embedding: ✅ Correct | ⚠️ Minor issues | ❌ Incorrect
        * Context loading: ✅ Complete | ⚠️ Partial | ❌ Missing
           
        **Content Quality Assessment:**
        * Clarity: ✅ Clear | ⚠️ Some issues | ❌ Unclear
        * Completeness: ✅ Complete | ⚠️ Minor gaps | ❌ Major gaps
        * Accuracy: ✅ Accurate | ⚠️ Minor errors | ❌ Major errors
           
        **Issues Identified:**
        * [Specific issue 1]
        * [Specific issue 2]
           
        **Recommended Actions:**
        * [Priority level] [Specific action needed]
    {: .language-markdown}

6.  **Analyze Cross-Workflow Consistency:**
    * Compare terminology usage across workflows
    * Identify inconsistent patterns or structures
    * Check for duplicate content that could be consolidated
    * Verify cross-references between workflows are accurate
    * Assess overall cohesion of workflow collection
7.  **Prioritize Improvement Actions:**
    
    **Critical Issues (Fix Immediately):**
    
    * Broken references or dependencies
    * Missing required sections
    * Incorrect or dangerous commands
    * Major structural problems
    **High Priority Issues (Fix Soon):**
    
    * Inconsistent terminology
    * Minor structural issues
    * Outdated examples or patterns
    * Missing error handling
    **Medium Priority Issues (Plan for Fix):**
    
    * Clarity improvements
    * Better examples or explanations
    * Enhanced self-containment
    * Template synchronization needs
    **Low Priority Issues (Nice to Have):**
    
    * Minor formatting improvements
    * Additional examples
    * Enhanced cross-references
8.  **Create Action Plan:**
    * Group related issues for efficient fixing
    * Estimate effort required for each improvement
    * Assign priority levels and target timelines
    * Consider impact on other workflows or guides
    * Plan for validation after fixes are implemented
9.  **Generate Review Report:**
    * Compile comprehensive review summary
    * Include statistical overview of compliance
    * List all identified issues with priorities
    * Provide actionable improvement plan
    * Document review methodology for future sessions

## Review Criteria and Standards

### Required Workflow Sections

1.  **Goal**: Clear, single-sentence objective
2.  **Prerequisites**: Specific conditions and requirements
3.  **Project Context Loading**: Files to load for context
4.  **Process Steps**: Detailed, actionable instructions
5.  **Success Criteria** or similar validation section

### Self-Containment Requirements

* No references to external workflow files
* All templates embedded using proper format
* Complete context loading section
* All necessary examples included inline
* No broken links or dependencies

### Quality Standards

* Instructions are specific and actionable
* Examples are accurate and current
* Error handling is provided
* Technology-agnostic where possible
* Consistent with project terminology

### Template Embedding Standards

    <templates>
    <template path="relative/path/to/template.md">
    [Template content]
    </template>
    </templates>
{: .language-xml}

## Batch Processing Patterns

### Automated Checks

Use shell commands to quickly identify common issues:

    # Check for missing required sections
    for file in workflow-instructions/*.wf.md; do
      if ! grep -q "## Goal" "$file"; then
        echo "Missing Goal section: $file"
      fi
    done
    
    # Check for external workflow references
    grep -r "workflow-instructions/" workflow-instructions/ --include="*.wf.md"
    
    # Check for broken template embedding
    grep -r "<template" workflow-instructions/ --include="*.wf.md" | grep -v "path="
{: .language-bash}

### Progress Tracking

* Maintain checklist of workflows reviewed
* Track time spent on each workflow assessment
* Document patterns found across multiple workflows
* Note common issues for systematic addressing

## Success Criteria

* All targeted workflows systematically reviewed
* Standardized assessment completed for each workflow
* Issues categorized by priority and type
* Cross-workflow consistency analysis complete
* Actionable improvement plan created with timelines
* Review session documented for future reference
* Critical issues identified for immediate action

## Common Review Patterns

### New Workflow Review

* Focus on structure compliance and self-containment
* Verify all required sections present
* Check examples and commands for accuracy
* Ensure proper template embedding format

### Existing Workflow Maintenance

* Compare against current standards
* Check for outdated examples or patterns
* Verify cross-references still accurate
* Update for consistency with newer workflows

### Comprehensive Collection Review

* Analyze patterns across all workflows
* Identify opportunities for standardization
* Look for content that could be consolidated
* Plan systematic improvements

## Error Handling

**Large number of workflows to review:**

* Break into manageable batches (5-10 workflows per session)
* Use automated checks to identify obvious issues first
* Focus on critical issues before minor improvements

**Inconsistent standards found:**

* Document current state before making changes
* Plan systematic updates to maintain consistency
* Consider updating standards if patterns have evolved

**Time constraints for comprehensive review:**

* Prioritize critical and high-priority issues
* Use sampling approach for large collections
* Focus on workflows used most frequently

## Usage Example

> "Review all workflow instructions in workflow-instructions/ for compliance with current standards and identify any
> inconsistencies or improvement opportunities"
