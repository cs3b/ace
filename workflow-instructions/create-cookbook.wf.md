# Create Cookbook Workflow Instruction

**Goal:** Transform identified patterns and insights into reusable, high-quality cookbooks that accelerate future development work through systematic documentation of proven procedures.

## Prerequisites

* Understanding of cookbook purpose and target audience
* Source material (reflection note, direct observation, or synthesis report)
* Access to create files in project structure using `create-path` tool

## Project Context Loading

- Read and follow: `dev-handbook/workflow-instructions/load-project-context.wf.md`

## High-Level Execution Plan

### Planning Steps

- [ ] Identify cookbook source material and extract core patterns
- [ ] Determine appropriate cookbook category and target audience
- [ ] Define cookbook scope and validation criteria

### Execution Steps

- [ ] Create cookbook file using embedded template and `create-path` tool
- [ ] Populate cookbook sections with structured content
- [ ] Validate cookbook completeness and actionability
- [ ] Save cookbook in appropriate location with standard naming

## Process Steps

1. **Identify Source Material:**
   - **From Reflection Note:** Extract reusable patterns and procedures
   - **From Direct Input:** Document observed complex procedures
   - **From Synthesis Report:** Capture common workflows and best practices
   - **From User Input:** Accept pattern description and context details

2. **Select Cookbook Category:**
   Choose the primary category that best fits the pattern:
   - **integration:** Connecting systems, services, or tools
   - **setup:** Environment configuration and initialization
   - **migration:** Moving between systems, versions, or structures  
   - **debugging:** Troubleshooting and problem resolution procedures
   - **automation:** Streamlining repetitive tasks and workflows
   - **pattern:** General development patterns and best practices

3. **Determine Target Audience:**
   - **beginner:** Basic concepts, detailed explanations, minimal assumptions
   - **intermediate:** Moderate complexity, some background knowledge assumed
   - **advanced:** Complex procedures, expert-level understanding expected

4. **Define Cookbook Scope:**
   - **Single Pattern:** Focus on one specific procedure or technique
   - **Composite Pattern:** Multiple related procedures in logical sequence
   - **Cross-Category Pattern:** Procedures spanning multiple areas (use primary + secondary categories)

5. **Generate Cookbook File:**
   ```bash
   # Create cookbook using create-path tool with template
   create-path file "dev-handbook/cookbooks/[category]-[descriptive-name].cookbook.md" \
     --template "dev-handbook/templates/cookbooks/cookbook.template.md" \
     --title "[Category] Cookbook: [Descriptive Name]"
   ```

6. **Populate Cookbook Content:**
   Using the embedded template structure, fill in:
   - **Purpose**: Clear statement of what the cookbook accomplishes
   - **Prerequisites**: System, knowledge, and tool requirements
   - **Steps**: Detailed, actionable procedures with validation
   - **Examples**: Concrete use cases and implementations
   - **Troubleshooting**: Common issues and their solutions
   - **Validation**: Success criteria and testing procedures

7. **Review and Validate:**
   - Ensure all sections have meaningful content
   - Verify steps are actionable and complete
   - Test examples and validation procedures
   - Confirm naming follows convention: `[category]-[descriptive-name].cookbook.md`

## Cookbook Categories & Naming Examples

### Category: integration
- `integration-oauth-provider.cookbook.md` - OAuth provider setup and configuration
- `integration-api-gateway.cookbook.md` - API gateway implementation patterns
- `integration-webhook-handling.cookbook.md` - Webhook endpoint design and testing

### Category: setup
- `setup-development-environment.cookbook.md` - Complete dev environment configuration
- `setup-ci-cd-pipeline.cookbook.md` - Continuous integration/deployment setup
- `setup-monitoring-stack.cookbook.md` - Observability and monitoring configuration

### Category: migration
- `migration-database-schema.cookbook.md` - Database schema migration procedures
- `migration-legacy-api.cookbook.md` - Legacy API modernization approach
- `migration-cloud-infrastructure.cookbook.md` - Infrastructure migration patterns

### Category: debugging
- `debugging-performance-issues.cookbook.md` - Performance bottleneck investigation
- `debugging-memory-leaks.cookbook.md` - Memory leak detection and resolution
- `debugging-distributed-systems.cookbook.md` - Multi-service debugging techniques

### Category: automation
- `automation-test-data-generation.cookbook.md` - Automated test data creation
- `automation-deployment-rollback.cookbook.md` - Automated rollback procedures
- `automation-code-quality-gates.cookbook.md` - Automated quality assurance

### Category: pattern
- `pattern-error-handling.cookbook.md` - Consistent error handling approaches
- `pattern-caching-strategy.cookbook.md` - Caching implementation patterns
- `pattern-service-communication.cookbook.md` - Inter-service communication patterns

## Error Handling

### Missing Source Material
**Symptoms:** No clear pattern or procedure identified
**Recovery:** 
1. Prompt user for pattern details and context
2. Ask clarifying questions about the procedure
3. Guide through pattern identification process

### Duplicate Cookbook Name  
**Symptoms:** File already exists with same name
**Recovery:**
1. Check existing cookbook content for overlap
2. Suggest alternative naming with version or specialization
3. Consider merging patterns if highly related
4. Use `--force` flag only if intentional replacement

### Invalid Category
**Symptoms:** Category doesn't match standard list
**Recovery:**
1. Show available categories with descriptions
2. Help user select most appropriate primary category
3. Note secondary category in cookbook metadata if cross-category

### Incomplete Pattern Documentation
**Symptoms:** Pattern lacks sufficient detail for actionable cookbook
**Recovery:**
1. Request additional context and examples
2. Break down complex pattern into smaller, manageable steps
3. Identify missing prerequisites or validation steps

<documents>
    <template path="dev-handbook/templates/cookbooks/cookbook.template.md"># [Category] Cookbook: [Descriptive Name]

**Created**: YYYY-MM-DD
**Last Updated**: YYYY-MM-DD
**Category**: [integration | setup | migration | debugging | automation | pattern]
**Audience**: [beginner | intermediate | advanced]
**Estimated Time**: [X hours/minutes]

## Purpose

Brief description of what this cookbook accomplishes and why it's valuable.

## Prerequisites

**System Requirements:**
- Requirement 1
- Requirement 2

**Knowledge Requirements:**
- Knowledge area 1
- Knowledge area 2

**Tools & Dependencies:**
- Tool/dependency 1
- Tool/dependency 2

## Overview

High-level summary of the approach and main steps involved.

## Steps

### Step 1: [Step Title]

**Objective**: What this step accomplishes

**Commands/Actions:**
```bash
# Command examples with explanation
command --option value
```

**Expected Output:**
```
Sample output that confirms success
```

**Validation:**
```bash
# Commands to verify this step completed successfully
verification-command
```

**Troubleshooting:**
- Common issue 1: Solution
- Common issue 2: Solution

### Step 2: [Step Title]

**Objective**: What this step accomplishes

**Commands/Actions:**
```bash
# Additional commands
```

**Expected Output:**
```
Expected results
```

**Validation:**
```bash
# Verification commands
```

**Troubleshooting:**
- Issue: Solution

## Validation & Testing

### Final Validation Steps

1. **System Check:**
   ```bash
   # Commands to verify overall system state
   ```

2. **Functional Test:**
   ```bash
   # Commands to test functionality end-to-end
   ```

3. **Performance Check** (if applicable):
   ```bash
   # Commands to verify performance expectations
   ```

### Success Criteria

- [ ] Criterion 1: Description of what should be working
- [ ] Criterion 2: Another measurable outcome
- [ ] Criterion 3: Final validation point

## Examples

### Example 1: [Scenario Name]

**Context**: Specific use case or scenario

**Implementation:**
```bash
# Specific commands for this example
```

**Result**: What the outcome looks like

### Example 2: [Another Scenario]

**Context**: Different use case

**Implementation:**
```bash
# Alternative approach or configuration
```

**Result**: Expected outcome

## Templates & Code Snippets

### Configuration Template

```yaml
# Sample configuration file
key: value
section:
  nested_key: nested_value
```

### Code Template

```ruby
# Sample code implementation
class ExampleClass
  def example_method
    # Implementation
  end
end
```

## Common Patterns

### Pattern 1: [Pattern Name]

**When to use**: Specific conditions or scenarios
**How to implement**: Brief implementation guide
**Example**: Quick code or command example

### Pattern 2: [Another Pattern]

**When to use**: Different scenario
**How to implement**: Implementation approach
**Example**: Sample usage

## Troubleshooting

### Error: [Common Error Message]

**Symptoms**: How this error manifests
**Cause**: Root cause of the issue
**Solution**: Step-by-step fix
**Prevention**: How to avoid in the future

### Issue: [Common Problem]

**Symptoms**: Observable behavior
**Diagnosis**: How to confirm this is the issue
**Resolution**: Solution steps
**Verification**: How to confirm it's fixed

## Related Resources

### Documentation Links

- [Official docs link](url)
- [API reference](url)
- [Community guide](url)

### Other Cookbooks

- [Related cookbook 1](link)
- [Related cookbook 2](link)

### External Tools & Resources

- [Tool name](url): Description of how it helps
- [Resource name](url): What it provides

## Version History

### v1.0 (YYYY-MM-DD)
- Initial version
- Core steps documented

### v1.1 (YYYY-MM-DD)
- Added troubleshooting section
- Updated validation steps

## Feedback & Improvements

**Known Limitations:**
- Limitation 1: Description and potential workaround
- Limitation 2: Impact and mitigation

**Future Enhancements:**
- Enhancement idea 1
- Enhancement idea 2

**Contributing:**
If you find issues or improvements for this cookbook, please:
1. Document the specific issue or enhancement
2. Test any proposed changes
3. Update relevant sections
4. Increment version number

---

*This cookbook is part of the development workflow documentation. For more cookbooks, see `dev-handbook/cookbooks/`.*
    </template>
</documents>

## Input

* Source material (reflection note path, synthesis report, or direct pattern description)
* Cookbook category selection
* Target audience level
* Pattern scope and context

## Output / Success Criteria

* Cookbook file created in `dev-handbook/cookbooks/` directory
* File follows naming convention: `[category]-[descriptive-name].cookbook.md`
* All template sections populated with meaningful content
* Cookbook is actionable and self-contained
* Validation procedures included and tested
* Related resources and cross-references updated

## Common Patterns

### Template-Driven Creation
1. Use `create-path` tool with cookbook template
2. Fill template sections systematically
3. Validate completeness against checklist
4. Test examples and procedures

### Pattern Extraction
1. Analyze source material for recurring procedures
2. Identify decision points and alternatives
3. Document assumptions and prerequisites
4. Create concrete examples and test cases

## Related Workflows

- `dev-handbook/workflow-instructions/create-reflection-note.wf.md` - Source material creation
- `dev-handbook/workflow-instructions/synthesize-reflection-notes.wf.md` - Pattern synthesis
- Integration with `create-path` tool for file generation

---

This workflow systematically transforms development insights into reusable cookbooks, building a knowledge base that improves team efficiency and consistency across projects.