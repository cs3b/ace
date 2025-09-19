# Enhanced Reflection Prompting Guide

This guide provides specific questions and prompts to elicit actionable insights when creating reflection notes with the enhanced template sections.

## Automation Insights Prompts

### Identifying Automation Opportunities

**Process Analysis Questions:**
- Which steps in this workflow required repetitive manual actions?
- What patterns did you notice that could be scripted or automated?
- Were there any multi-step processes that could be combined into a single command?
- What manual validations could be replaced with automated checks?
- Did you perform any text transformations that could be codified?

**Time and Effort Assessment:**
- Which parts of the workflow took the most time?
- What tasks required multiple attempts or iterations?
- Where did you experience friction or delays?
- What would have made this workflow 10x faster?

**Automation Feasibility:**
- What prerequisites would the automation require?
- Is the process deterministic enough to automate?
- What edge cases would need handling?
- Would partial automation still provide value?

### Example High-Quality Response:
```markdown
- **File Structure Validation**: Checking task file metadata compliance
  - Current approach: Manually reviewing YAML frontmatter in each task file
  - Automation proposal: Create `task-validate` command to check all task files
  - Expected time savings: 15 minutes per release (from 20 min to 5 min)
  - Implementation complexity: Low
```

### Example Low-Quality Response (Avoid):
```markdown
- **Various improvements**: Things could be faster
  - Current approach: Manual work
  - Automation proposal: Make it automatic
```

## Tool Proposals Prompts

### Missing Tools Discovery

**Gap Analysis Questions:**
- What command did you wish existed during this workflow?
- Which existing tool almost met your needs but was missing a key feature?
- What repetitive command sequences could be wrapped in a single tool?
- Were there any complex bash pipelines that deserve their own command?
- What information was hard to discover or required multiple steps to find?

**Tool Design Considerations:**
- What would be the primary purpose of this tool?
- What arguments or options would it need?
- How would it integrate with existing tools?
- What output format would be most useful?
- Should it be interactive or fully automated?

### Example High-Quality Tool Proposal:
```markdown
- **Tool Name**: `reflection-analyze`
  - Purpose: Analyze reflection notes for common patterns and generate insights report
  - Expected usage: `reflection-analyze --release v.0.5.0 --output-format markdown`
  - Key features: Pattern detection, frequency analysis, trend identification, actionable recommendations
  - Similar to: Extends `reflection-synthesize` with deeper analysis capabilities
```

## Workflow Proposals Prompts

### New Workflow Identification

**Process Discovery Questions:**
- What multi-step process did you just complete that others might need to repeat?
- Is there a common sequence of actions that deserves its own workflow?
- What knowledge would have been helpful to have documented as a workflow?
- Did you create an ad-hoc process that worked well and should be formalized?
- What workflows from other projects would be valuable here?

**Workflow Design Questions:**
- What would trigger this workflow?
- Who is the target user (human, AI agent, both)?
- What are the key decision points?
- What validations or checks are needed?
- How would this workflow integrate with existing ones?

### Example High-Quality Workflow Proposal:
```markdown
- **Workflow Name**: `migrate-task-format.wf.md`
  - Purpose: Systematically update all task files to new metadata format
  - Trigger: When task format changes are introduced in new release
  - Key steps: 1) Backup existing tasks, 2) Validate current format, 3) Apply transformation, 4) Verify changes, 5) Update indices
  - Expected frequency: Once per major version upgrade
```

## Cookbook Opportunities Prompts

### Pattern Recognition

**Pattern Discovery Questions:**
- What solution did you develop that could be reused in other contexts?
- Did you solve a complex problem that others might face?
- What setup or configuration process would benefit from step-by-step documentation?
- Is there a technique you used that isn't well documented elsewhere?
- What gotchas or pitfalls did you encounter that others should know about?

**Cookbook Value Assessment:**
- How often might this pattern be needed?
- How much time would a cookbook save future developers?
- Is the pattern stable enough to document?
- What skill level would the cookbook target?
- What makes this pattern cookbook-worthy vs. just documentation?

### Example High-Quality Cookbook Proposal:
```markdown
- **Cookbook Title**: `integrating-llm-providers.cookbook.md`
  - Problem it solves: How to add new LLM provider support to the dynamic provider system
  - Target audience: Developers adding AI capabilities or new model support
  - Prerequisites: Understanding of Ruby, API integration, and the provider architecture
  - Key sections: Provider interface, configuration setup, error handling, testing approach, deployment considerations
```

## Pattern Identification Prompts

### Code Pattern Discovery

**Reusability Questions:**
- What code did you write that could become a helper function or module?
- Did you create any data transformations that appear in multiple places?
- What validation logic could be extracted and reused?
- Are there any algorithms or calculations worth preserving?
- What error handling patterns proved effective?

**Template Identification:**
- What file structures did you create that follow a consistent pattern?
- Are there configuration templates that could be standardized?
- What boilerplate code could be templated?
- Did you create any documents with a reusable structure?

### Example High-Quality Pattern:
```markdown
- **Snippet Purpose**: Task file frontmatter validation
  ```ruby
  def validate_task_frontmatter(content)
    frontmatter = YAML.load(content.split('---')[1])
    required = %w[id status priority estimate dependencies]
    missing = required - frontmatter.keys
    raise "Missing fields: #{missing.join(', ')}" unless missing.empty?
    
    # Validate status enum
    valid_statuses = %w[pending in-progress done blocked]
    unless valid_statuses.include?(frontmatter['status'])
      raise "Invalid status: #{frontmatter['status']}"
    end
    
    frontmatter
  end
  ```
  - Use cases: Task creation, task validation, bulk task processing
  - Variations: Could be adapted for different metadata schemas
```

## Quality Indicators

### High-Quality Insights Have:
- Specific, concrete examples
- Clear problem statements
- Measurable benefits or time savings
- Actionable next steps
- Realistic complexity assessments
- Connection to actual work performed

### Low-Quality Insights to Avoid:
- Vague or generic suggestions
- Missing context or rationale
- No clear benefit articulated
- Overly ambitious without feasibility consideration
- Disconnected from actual workflow experience
- Lacking specific examples or use cases

## Using These Prompts

1. **During Workflow Execution**: Keep these questions in mind as you work
2. **Immediately After Completion**: Review the prompts while the experience is fresh
3. **Reflection Creation**: Use relevant prompts to populate each enhanced section
4. **Quality Check**: Compare your responses to the quality indicators
5. **Iterative Improvement**: Refine insights based on the examples provided

Remember: The goal is to capture actionable insights that will improve future work, not to fill every section. Quality over quantity - a few well-articulated insights are more valuable than many vague suggestions.