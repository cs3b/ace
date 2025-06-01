# Create Architecture Decision Record Workflow Instruction

## Goal

Create a structured Architecture Decision Record (ADR) document in the `docs-dev/decisions/` directory to
capture a significant architectural decision, its context, rationale, and consequences.

## Prerequisites

- A clear architectural problem or choice needs to be documented.
- The standard ADR template (`dev-docs/guides/draft-release/v.x.x.x/decisions/_template.md`) should be used as
  a base.

## Process Steps

1. **Identify Need:** Determine that a decision warrants an ADR (e.g., choosing a library, defining a core
   interface, changing a major workflow).
2. **Gather Context:** Collect information about the problem, requirements, constraints, and alternatives considered.
3. **Draft ADR:** Create a new file (e.g., `docs-dev/decisions/ADR-XXX-DecisionTitle.md`).
   Use the standard template and fill in the sections:
    - **Status:** (e.g., Proposed, Accepted)
    - **Context:** Describe the problem/issue.
    - **Decision:** Clearly state the chosen approach.
    - **Consequences:** Detail positive, negative, and neutral impacts.
    - **Alternatives Considered:** Briefly describe other options and why they weren't chosen.
    - **Related Decisions:** Link to other relevant ADRs.
    - **References:** Link to external resources.
4. **Review (Optional):** Have the ADR reviewed by team members or the AI for clarity and completeness.
5. **Save:** Save the completed ADR file.

## Input

- Decision context, rationale, and chosen approach.
- Information about alternatives considered.

## Output / Success Criteria

- A new ADR `.md` file is created in `docs-dev/decisions/`.
- The ADR follows the standard template structure.
- The problem, decision, and rationale are clearly documented.
- Consequences and alternatives are considered and recorded.

## Reference Documentation

- [ADR Template](docs-dev/guides/draft-release/v.x.x.x/decisions/_template.md)
- [Documentation Standards Guide](docs-dev/guides/documentation.g.md)
