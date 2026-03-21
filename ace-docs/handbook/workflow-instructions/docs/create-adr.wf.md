---
doc-type: workflow
title: Create Architecture Decision Record
purpose: Create structured Architecture Decision Records for significant decisions
ace-docs:
  last-updated: 2026-02-23
  last-checked: 2026-03-21
---

# Create Architecture Decision Record

## Goal

Create a structured Architecture Decision Record (ADR) document in the `docs/decisions/` directory to capture a
significant architectural decision, its context, rationale, and consequences.

## Prerequisites

* A clear architectural problem or choice needs to be documented
* Understanding of what makes a decision architecturally significant (impacts structure, introduces dependencies,
  changes patterns, affects scalability, etc.)

## Project Context Loading

* Read and follow: `ace-bundle wfi://bundle`

## High-Level Execution Plan

### Planning Steps

* Identify and validate the architectural
  decision needs documentation
* Gather comprehensive context and
  alternatives
* Determine ADR number and file naming


### Execution Steps

* Draft ADR using embedded template
* Review and validate ADR content
* Create ADR file in proper location
* Update docs/decisions.md summary
* Commit changes


## When to Create an ADR

Create an ADR when:

* Choosing between competing libraries or frameworks
* Defining core interfaces or data structures
* Changing major workflows or processes
* Making decisions that affect system architecture
* Introducing new patterns or technologies
* Making trade-offs between competing quality attributes (performance vs. maintainability, etc.)

## Process Steps

### 1. Identify Need

Determine that a decision warrants an ADR. Ask yourself:

* Will this decision affect the system's structure or key abstractions?
* Are there multiple viable alternatives with different trade-offs?
* Will future developers need to understand why this choice was made?
* Could this decision be revisited or changed in the future?

### 2. Gather Context

Collect comprehensive information:

* What problem are we trying to solve?
* What are the requirements and constraints?
* Who are the stakeholders affected?
* What alternatives have been considered?
* What are the evaluation criteria?

### 3. Determine ADR Number

Check existing ADRs and use next sequential number:

    # List existing ADRs to find next number
    ls docs/decisions/ADR-*.md | tail -1
    
    # Check both active and archived
    ls docs/decisions/archive/ADR-*.md 2>/dev/null | tail -1
{: .language-bash}

Next ADR should be: `ADR-XXX` where XXX is one higher than the last used number.

### 4. Draft ADR

Create new file following naming convention:

* **File name**: `docs/decisions/ADR-XXX-decision-title.md`
* **Format**: ADR-001, ADR-002, etc. (zero-padded to 3 digits)
* **Title**: Use kebab-case for the decision title in filename

Use the embedded template below.

### 5. Write Clear Content

Follow these principles:

**Context Section:**

* Explain the "why" comprehensively
* Future readers should understand the situation without additional context
* Include technical background and business drivers

**Decision Section:**

* State what you're doing, not what you're thinking about doing
* Be definitive and unambiguous
* Specify technologies, versions, and approaches

**Consequences Section:**

* Be balanced and honest
* Include both immediate and long-term impacts
* Document trade-offs explicitly
* Group into Positive, Negative, and Neutral

**Alternatives Section:**

* Document viable alternatives seriously considered
* Explain why each alternative was rejected
* Avoid straw man arguments

### 6. Review

Before finalizing, verify:

* Is the context clear to someone unfamiliar with current discussions?
* Is the decision stated unambiguously?
* Are all significant consequences documented?
* Would a developer in 2 years understand why this decision was made?
* Are alternatives documented with fair treatment?

### 7. Validate

Use ace-docs to validate the ADR:

    # Validate syntax and required fields
    ace-docs validate docs/decisions/ADR-XXX-*.md
    
    # Check for common issues
    ace-lint docs/decisions/ADR-XXX-*.md
{: .language-bash}

### 8. Update docs/decisions.md

Add the new ADR to the summary document:

1.  Determine appropriate section (Active Decisions, Gem Architecture, etc.)
2.  Add entry following pattern:
^

    ### Decision Title
    **Decision**: Brief summary of what was decided
    **Impact**: How this affects developers and agents
    **Details**: [ADR-XXX](decisions/ADR-XXX-decision-title.md)
{: .language-markdown}

1.  Maintain alphabetical or logical grouping within section

### 9. Save and Commit

    # Stage changes
    git add docs/decisions/ADR-XXX-*.md docs/decisions.md
    
    # Commit with descriptive message
    git commit -m "docs: Add ADR-XXX for [decision topic]"
{: .language-bash}

Or use ace-git-commit:

    ace-git-commit docs/decisions/ -i "Add ADR for [decision topic]"
{: .language-bash}

## ADR Writing Best Practices

### DO

* Write in full sentences with proper grammar
* Use present tense for context and decision
* Be specific about technologies, versions, and constraints
* Include enough detail that the ADR stands alone
* Link to external resources for deep dives
* Number ADRs sequentially (ADR-001, ADR-002, etc.)
* Date the decision with ISO format (YYYY-MM-DD)

### DON'T

* Write novels - be concise but complete
* Use ambiguous language ("might", "could", "should consider")
* Forget to date the decision
* Skip documenting rejected alternatives
* Make the status "Accepted" until actually accepted
* Include implementation details better suited for code comments

## Examples of Good ADR Titles

* ADR-001-use-react-for-frontend
* ADR-002-adopt-microservices-architecture
* ADR-003-implement-event-sourcing
* ADR-004-choose-postgresql-over-mongodb
* ADR-005-use-jwt-for-authentication
* ADR-015-mono-repo-ace-gems-migration
* ADR-016-handbook-directory-architecture

## After Creation: ADR Lifecycle

ADRs may need maintenance over time as patterns evolve or become obsolete:

* **Evolution**: Patterns change but principles remain valid → add evolution sections
* **Archival**: Patterns no longer used in current codebase → move to archive
* **Scope Updates**: Implementation details change → update scope notes

See `wfi://docs/maintain-adrs` for complete lifecycle management.

## Input

* Decision context, rationale, and chosen approach
* Information about alternatives considered
* Stakeholder concerns and constraints
* Evaluation criteria used

## Output / Success Criteria

* A new ADR `.md` file is created in `docs/decisions/`
* The ADR follows the template structure completely
* The problem, decision, and rationale are clearly documented
* All significant consequences (positive, negative, neutral) are recorded
* Viable alternatives and rejection reasons are documented
* The document is self-contained and understandable without external context
* docs/decisions.md summary is updated
* Changes are committed to version control

## Troubleshooting

**Cannot determine next ADR number:**

* Check both `docs/decisions/ADR-*.md` and `docs/decisions/archive/ADR-*.md`
* Look at the highest number used across both locations
* Use next sequential number

**Validation fails:**

* Check frontmatter is present and valid
* Verify all required sections exist
* Run `ace-docs validate` for specific errors

**Unsure if decision needs ADR:**

* Ask: "Will this be hard to reverse?"
* Ask: "Will future developers wonder why we did this?"
* Ask: "Are there multiple valid alternatives?"
* If yes to any, create the ADR

<documents>
    <template path="tmpl://project-docs/decisions/adr"># ADR-XXX: Title of the Decision

## Status

Proposed | Accepted | Deprecated | Superseded
Date: YYYY-MM-DD

## Context

Describe the architectural problem or opportunity. Include:
- The forces at play (technical, business, regulatory)
- The current situation that led to this decision
- Why this decision is necessary now
- Key stakeholders and their concerns

## Decision

We will [describe the decision in clear, active voice].

Key aspects of this decision:
- [Specific technology, pattern, or approach chosen]
- [Key implementation details or principles]
- [Boundaries and scope of the decision]

## Consequences

### Positive

- [Benefit or advantage gained]
- [Improved capability or reduced complexity]
- [Alignment with other goals or decisions]

### Negative

- [Cost or limitation introduced]
- [Increased complexity or maintenance burden]
- [Trade-off made against other quality attributes]

### Neutral

- [Impact that is neither clearly positive nor negative]
- [Change that shifts rather than eliminates complexity]

## Alternatives Considered

### Alternative 1: [Name]

- **Description**: [Brief description]
- **Pros**: [Advantages]
- **Cons**: [Disadvantages]
- **Why not chosen**: [Specific reasons for rejection]

### Alternative 2: [Name]

- **Description**: [Brief description]
- **Pros**: [Advantages]
- **Cons**: [Disadvantages]
- **Why not chosen**: [Specific reasons for rejection]

## Related Decisions

- [Link to related ADRs]
- [Reference to superseded decisions]
- [Dependencies on other architectural decisions]

## References

- [Link to relevant documentation]
- [Reference to external resources]
- [Related GitHub issues or pull requests]
    </template>
</documents>