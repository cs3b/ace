# Priority Matrix Template

This template provides a structured approach for evaluating and prioritizing improvements identified through reflection synthesis.

## Priority Assessment Framework

### Impact vs Effort Matrix

```
     HIGH IMPACT    |    HIGH IMPACT
     HIGH EFFORT    |    LOW EFFORT
  __________________|__________________
  Strategic Projects |  Immediate Actions
  Plan & Resource   |  Do First
  __________________|__________________
     LOW IMPACT     |    LOW IMPACT  
     HIGH EFFORT    |    LOW EFFORT
  __________________|__________________
    Avoid/Defer     |   Quick Wins
    Don't Do        |   Do When Time Allows
```

## Scoring System

### Impact Assessment (1-5 scale)

**5 - Critical Impact**
- Addresses major workflow blocker affecting entire team
- Prevents significant rework or eliminates recurring problems
- Enables new capabilities essential for project success
- ROI > 300% within 3 months

**4 - High Impact**  
- Significant efficiency gain (>25% time savings on common tasks)
- Quality improvement that prevents defects or issues
- Improves team productivity or developer experience substantially
- ROI 150-300% within 6 months

**3 - Medium Impact**
- Moderate improvement with noticeable benefits (10-25% efficiency gain)
- Reduces friction in existing workflows  
- Improves maintainability or code quality
- ROI 50-150% within 12 months

**2 - Low Impact**
- Minor improvement with limited scope (<10% efficiency gain)
- Affects only specific use cases or individual workflows
- Incremental improvement to existing functionality
- ROI 10-50% within 12 months

**1 - Minimal Impact**
- Negligible improvement or very narrow use case
- Nice-to-have feature with questionable value
- Benefits unclear or difficult to measure
- ROI <10% or unclear timeline

### Effort Assessment (1-5 scale)

**5 - Very High Effort**
- >1 month full-time development
- Major architectural changes or new system components
- Requires extensive research, design, and planning
- High risk of scope creep or technical challenges
- Requires coordination across multiple systems/teams

**4 - High Effort**
- 2-4 weeks full-time development  
- Significant new components or major modifications
- Moderate architectural impact
- Some research required, complex integration points
- May require external dependencies

**3 - Medium Effort**
- 1-2 weeks full-time development
- Moderate complexity implementation
- Well-understood problem with clear solution approach
- Standard integration patterns and existing infrastructure
- Some testing and documentation overhead

**2 - Low Effort**  
- 2-5 days full-time development
- Straightforward implementation using existing patterns
- Minor modifications to existing components
- Minimal integration complexity
- Standard testing approach

**1 - Very Low Effort**
- <2 days full-time development
- Simple configuration changes or parameter adjustments
- Uses existing functionality with minor modifications
- Trivial integration requirements
- Minimal testing needs

## Priority Calculation

### Formula
```
Priority Score = (Impact Score × Impact Weight) - (Effort Score × Effort Weight)
```

### Default Weights
- **Impact Weight**: 3 (emphasizes value delivery)
- **Effort Weight**: 2 (moderate penalty for complexity)

### Priority Bands
- **Critical (Score ≥ 10)**: Immediate action required
- **High (Score 7-9)**: Next sprint priority  
- **Medium (Score 4-6)**: Future sprint consideration
- **Low (Score 1-3)**: Backlog or defer
- **Negative (Score ≤ 0)**: Avoid or reconsider scope

## Template Usage

### Step 1: List All Improvement Opportunities
Create comprehensive list from synthesis report including:
- Automation opportunities
- Tool proposals  
- Process improvements
- Technical enhancements
- Documentation needs

### Step 2: Score Each Opportunity

| Initiative | Description | Impact | Effort | Score | Priority |
|------------|-------------|--------|--------|-------|----------|
| [Name] | [Brief description] | [1-5] | [1-5] | [Calculated] | [Band] |

### Step 3: Categorize by Quadrant

#### Immediate Actions (High Impact, Low Effort)
**Characteristics**: High value, quick wins that should be prioritized immediately
- [Initiative 1]: [Impact score] / [Effort score] - [Expected timeline]
- [Initiative 2]: [Impact score] / [Effort score] - [Expected timeline]

#### Strategic Projects (High Impact, High Effort)  
**Characteristics**: High value initiatives requiring significant planning and resources
- [Project 1]: [Impact score] / [Effort score] - [Planning approach]
- [Project 2]: [Impact score] / [Effort score] - [Resource requirements]

#### Quick Wins (Low Impact, Low Effort)
**Characteristics**: Easy improvements to tackle during downtime or as warm-up tasks
- [Win 1]: [Impact score] / [Effort score] - [When to implement]
- [Win 2]: [Impact score] / [Effort score] - [Context for implementation]

#### Avoid/Defer (Low Impact, High Effort)
**Characteristics**: Resource-intensive work with questionable value - avoid unless strategic
- [Item 1]: [Why deferred] - [Conditions for reconsideration]
- [Item 2]: [Why deferred] - [Alternative approaches]

### Step 4: Create Implementation Timeline

#### Week 1-2 (Immediate Actions)
- [ ] [High impact, low effort item 1]
- [ ] [High impact, low effort item 2]

#### Month 1-2 (Strategic Planning)
- [ ] Plan and resource [strategic project 1]
- [ ] Design approach for [strategic project 2]  

#### Month 2-3 (Strategic Execution)
- [ ] Execute [planned strategic project]
- [ ] Begin [next strategic priority]

#### Ongoing (Quick Wins)
- [ ] Implement [quick win] when bandwidth available
- [ ] Address [minor improvement] during related work

## Advanced Prioritization Considerations

### Strategic Alignment Multiplier
- **Core Mission**: Multiply impact by 1.5
- **Supporting Capability**: No adjustment
- **Peripheral Feature**: Multiply impact by 0.8

### Risk Assessment
- **High Risk**: Increase effort score by 1
- **Medium Risk**: No adjustment  
- **Low Risk**: Decrease effort score by 1

### Dependency Considerations
- **Blocking Others**: Increase impact by 1
- **Blocked by Others**: Increase effort by 1
- **Independent**: No adjustment

## Template Customization

### Project-Specific Adjustments
- Modify scoring criteria based on team context
- Adjust weights based on current strategic priorities
- Add additional factors (technical debt, security, etc.)
- Include project-specific timeline constraints

### Regular Review Process
- Re-evaluate priorities monthly based on changing conditions
- Update scoring as implementation reveals new information
- Track actual vs estimated impact and effort for calibration
- Adjust framework based on lessons learned