# Enhanced Synthesis Analytics Template

This template provides structured formats for analytical synthesis outputs with priority rankings and strategic insights.

## Automation Opportunity Analysis Template

```markdown
# Automation Opportunity Analysis

## Ranked Automation Opportunities

| Priority | Automation Opportunity | Frequency | Impact | Effort | ROI Score |
|----------|----------------------|-----------|--------|--------|-----------|
| Critical | [Process name] | [X reflections] | High | [H/M/L] | [Score] |
| High | [Process name] | [X reflections] | High/Med | [H/M/L] | [Score] |
| Medium | [Process name] | [X reflections] | Med | [H/M/L] | [Score] |

### Scoring Methodology
- **Frequency**: Number of reflections mentioning this pattern
- **Impact**: Time saved per occurrence (High: >30min, Med: 15-30min, Low: <15min) 
- **Effort**: Implementation complexity (H: >1 week, M: 2-5 days, L: <2 days)
- **ROI Score**: (Frequency × Impact Weight × Complexity Factor) / Effort Weight

### Impact Weights
- High Impact: 3 points
- Medium Impact: 2 points  
- Low Impact: 1 point

### Effort Weights  
- Low Effort: 1 point
- Medium Effort: 2 points
- High Effort: 3 points

## Detailed Automation Opportunities

### Critical Priority Automations

#### [Automation Name 1]
- **Process Description**: [What gets automated]
- **Current Manual Steps**: 
  1. [Step 1]
  2. [Step 2]
  3. [Step 3]
- **Automation Approach**: [Technical implementation strategy]
- **Expected Time Savings**: [Quantified benefit per occurrence]
- **Implementation Effort**: [Estimated development time]
- **Dependencies**: [Required components or prerequisites]

### High Priority Automations

#### [Automation Name 2]
- **Process Description**: [What gets automated]
- **Current Manual Steps**: [Step-by-step breakdown]
- **Automation Approach**: [Technical implementation strategy]
- **Expected Time Savings**: [Quantified benefit]
```

## Tool Proposal Consolidation Template

```markdown
# Tool Proposal Consolidation

## Merged Tool Proposals

### [Tool Category 1]: [Consolidated Tool Name]

**Priority**: [Critical/High/Medium/Low]
**Consolidation Score**: [Based on frequency + overlap analysis]

**Merged from proposals:**
- **[Reflection A]**: [Original proposal description]
- **[Reflection B]**: [Similar proposal description]  
- **[Reflection C]**: [Related need]

**Consolidated Requirements:**
- **Core functionality**: [Primary features needed]
- **Integration points**: [How it fits into CAT architecture]
- **Usage patterns**: [Expected interaction patterns]
- **Success criteria**: [How to measure tool effectiveness]

**Technical Approach:**
```ruby
# Conceptual implementation structure
# Following CAT architecture patterns
module CodingAgentTools
  module [Category]
    class [ToolName]
      # Implementation approach
    end
  end
end
```

**Implementation Plan:**
1. **Phase 1**: [Core functionality - estimated effort]
2. **Phase 2**: [Integration features - estimated effort]  
3. **Phase 3**: [Advanced features - estimated effort]

**Priority Justification**: [Rationale based on frequency + impact assessment]
```

## Cookbook Pattern Template

```markdown
# Cookbook Pattern Identification

## Patterns Worth Documenting

| Pattern | Reusability | Complexity | Target Audience | Frequency | Documentation Priority |
|---------|-------------|------------|-----------------|-----------|----------------------|
| [Pattern name] | [High/Med/Low] | [Simple/Complex] | [Dev/User/Both] | [X occurrences] | [Critical/High/Med] |

## Detailed Pattern Analysis

### Critical Priority Patterns

#### [Pattern Name 1]
- **Pattern Description**: [What this solves and when to use it]
- **Reusability Assessment**: [Why this is broadly applicable]
- **Target Users**: [Who would benefit from this documentation]
- **Complexity Level**: [Simple/Moderate/Complex]
- **Prerequisites**: [What users need to know first]

**Proposed Documentation Structure:**
1. **Problem Statement**: [Clear description of the challenge]
2. **Solution Overview**: [High-level approach]
3. **Step-by-Step Guide**: [Detailed implementation]
4. **Code Examples**: [Practical code snippets]
5. **Troubleshooting**: [Common issues and solutions]
6. **Variations**: [Different approaches for different contexts]

**Success Criteria**: [How users know they've implemented correctly]
**Maintenance Needs**: [How often this needs updating]

### High Priority Patterns

#### [Pattern Name 2]
[Similar structure, more condensed]
```

## Priority Matrix Template

```markdown
# Priority Assessment Matrix

## Impact vs Effort Analysis

| Initiative | Impact Score | Effort Score | Priority Quadrant | Recommended Timeline |
|------------|--------------|--------------|-------------------|---------------------|
| [Initiative 1] | [1-5] | [1-5] | [High Impact, Low Effort] | [Immediate] |
| [Initiative 2] | [1-5] | [1-5] | [High Impact, High Effort] | [Plan & Resource] |
| [Initiative 3] | [1-5] | [1-5] | [Low Impact, Low Effort] | [Quick Win] |
| [Initiative 4] | [1-5] | [1-5] | [Low Impact, High Effort] | [Avoid/Defer] |

## Scoring Criteria

### Impact Scoring (1-5)
- **5 - Critical**: Addresses major workflow blocker affecting entire team
- **4 - High**: Significant efficiency gain or quality improvement
- **3 - Medium**: Moderate improvement with noticeable benefits
- **2 - Low**: Minor improvement with limited scope
- **1 - Minimal**: Negligible improvement or very narrow use case

### Effort Scoring (1-5)  
- **5 - Very High**: >1 month development time, major architectural changes
- **4 - High**: 2-4 weeks development, significant new components
- **3 - Medium**: 1-2 weeks development, moderate complexity
- **2 - Low**: 2-5 days development, straightforward implementation
- **1 - Very Low**: <2 days development, simple changes

## Strategic Recommendations

### Immediate Actions (High Impact, Low Effort)
- [Action 1]: [Brief description and timeline]
- [Action 2]: [Brief description and timeline]

### Strategic Projects (High Impact, High Effort)
- [Project 1]: [Description and resource planning approach]
- [Project 2]: [Description and resource planning approach]

### Quick Wins (Low Impact, Low Effort)
- [Win 1]: [Description and when to tackle]
- [Win 2]: [Description and when to tackle]
```

## Usage Guidelines

### When to Use Each Template

1. **Automation Opportunity Analysis**: When synthesis identifies 3+ similar manual processes
2. **Tool Proposal Consolidation**: When multiple reflections suggest similar tool needs
3. **Cookbook Pattern Template**: When common solutions appear across different contexts
4. **Priority Matrix**: For all synthesis reports to guide implementation decisions

### Integration with Synthesis Reports

These templates should be embedded within the main synthesis report structure, not used as standalone documents. They provide the detailed analytical framework that supports the strategic recommendations in the main synthesis output.

### Customization Notes

- Adjust scoring weights based on project context and team priorities
- Modify effort estimates based on team capacity and technical constraints
- Update priority criteria to reflect current strategic objectives
- Include project-specific technical considerations in implementation approaches