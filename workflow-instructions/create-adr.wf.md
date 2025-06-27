# Create Architecture Decision Record Workflow Instruction

## Goal

Create a structured Architecture Decision Record (ADR) document in the `docs/decisions/` directory to
capture a significant architectural decision, its context, rationale, and consequences.

## Prerequisites

- A clear architectural problem or choice needs to be documented.
- An understanding of what makes a decision architecturally significant (impacts structure, introduces dependencies, changes patterns, affects scalability, etc.).

## Project Context Loading

- Load project objectives: `docs/what-do-we-build.md`
- Load architecture overview: `docs/architecture.md`
- Load project structure: `docs/blueprint.md`

## High-Level Execution Plan

### Planning Steps

- [ ] Identify and validate the architectural decision needs documentation
- [ ] Gather comprehensive context and alternatives
- [ ] Determine ADR number and file naming

### Execution Steps

- [ ] Draft ADR using embedded template
- [ ] Review and validate ADR content
- [ ] Create ADR file in proper location
- [ ] Update any related documentation

## When to Create an ADR

Create an ADR when:

- Choosing between competing libraries or frameworks
- Defining core interfaces or data structures
- Changing major workflows or processes
- Making decisions that affect system architecture
- Introducing new patterns or technologies
- Making trade-offs between competing quality attributes (performance vs. maintainability, etc.)

## Process Steps

1. **Identify Need:** Determine that a decision warrants an ADR. Ask yourself:
   - Will this decision affect the system's structure or key abstractions?
   - Are there multiple viable alternatives with different trade-offs?
   - Will future developers need to understand why this choice was made?
   - Could this decision be revisited or changed in the future?

2. **Gather Context:** Collect comprehensive information:
   - What problem are we trying to solve?
   - What are the requirements and constraints?
   - Who are the stakeholders affected?
   - What alternatives have been considered?
   - What are the evaluation criteria?

3. **Draft ADR:** Create a new file following this naming convention:
   - File name: `docs/decisions/ADR-XXX-decision-title.md`
   - Where XXX is the next sequential number (e.g., ADR-001, ADR-002)
   - Use kebab-case for the decision title in the filename

4. **Fill in the ADR using this template:**

```markdown
# ADR-XXX: Title of the Decision

## Status

[Proposed | Accepted | Deprecated | Superseded]
Date: YYYY-MM-DD

## Context

What is the issue that we're seeing that is motivating this decision or change?

[Describe the forces at play, including technological, business, and organizational constraints. Include any relevant background information, current state, and why a decision needs to be made now.]

## Decision

What is the change that we're proposing and/or doing?

[State the decision clearly and concisely. Use active voice. Be specific about what will be done.]

## Consequences

What becomes easier or more difficult to do because of this change?

### Positive

- [Benefit 1: Describe specific improvements]
- [Benefit 2: Include measurable outcomes where possible]

### Negative

- [Challenge 1: Be honest about drawbacks]
- [Challenge 2: Include mitigation strategies if applicable]

### Neutral

- [Impact 1: Changes that are neither good nor bad]
- [Impact 2: Side effects that need to be noted]

## Alternatives Considered

- **Alternative 1**: [Brief description]
  - Why it wasn't chosen: [Specific reasons]
- **Alternative 2**: [Brief description]
  - Why it wasn't chosen: [Specific reasons]

## Related Decisions

- [Link to related ADRs using relative paths]
- [Link to related documentation]

## References

- [External references, research papers, blog posts]
- [Links to relevant documentation or discussions]
```

5. **Write Clear Content:** Follow these principles:
   - **Context**: Explain the "why" comprehensively. Future readers should understand the situation without additional context.
   - **Decision**: State what you're doing, not what you're thinking about doing. Be definitive.
   - **Consequences**: Be balanced and honest. Include both immediate and long-term impacts.
   - **Alternatives**: Document viable alternatives seriously considered, not straw men.

6. **Review:** Before finalizing:
   - Is the context clear to someone unfamiliar with current discussions?
   - Is the decision stated unambiguously?
   - Are all significant consequences documented?
   - Would a developer in 2 years understand why this decision was made?

7. **Save and Commit:**
   - Save the ADR in `docs/architecture-decisions/`
   - Commit with a message like: "docs: Add ADR-XXX for [decision topic]"
   - Update any related documentation that references this decision

## ADR Writing Best Practices

### DO

- Write in full sentences with proper grammar
- Use present tense for context and decision
- Be specific about technologies, versions, and constraints
- Include enough detail that the ADR stands alone
- Link to external resources for deep dives
- Number ADRs sequentially (ADR-001, ADR-002, etc.)

### DON'T

- Write novels - be concise but complete
- Use ambiguous language ("might", "could", "should consider")
- Forget to date the decision
- Skip documenting rejected alternatives
- Make the status "Accepted" until actually accepted

## Input

- Decision context, rationale, and chosen approach
- Information about alternatives considered
- Stakeholder concerns and constraints
- Evaluation criteria used

## Output / Success Criteria

- A new ADR `.md` file is created in `docs/decisions/`
- The ADR follows the template structure completely
- The problem, decision, and rationale are clearly documented
- All significant consequences (positive, negative, neutral) are recorded
- Viable alternatives and rejection reasons are documented
- The document is self-contained and understandable without external context

## Examples of Good ADR Titles

- ADR-001-use-react-for-frontend
- ADR-002-adopt-microservices-architecture
- ADR-003-implement-event-sourcing
- ADR-004-choose-postgresql-over-mongodb
- ADR-005-use-jwt-for-authentication
