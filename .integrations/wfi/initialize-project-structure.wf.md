# Initialize Project Structure Workflow Instruction

## Goal

Complete the project initialization started by `coding-agent-tools integrate claude --init-project` by gathering project information, customizing generated files, configuring context, and creating initial release planning to establish a comprehensive foundation for AI-assisted development.

**Prerequisites**: This workflow assumes `coding-agent-tools integrate claude --init-project` has already been run, which creates the basic directory structure, generates core documentation from templates, and installs Claude integration.

**Idempotency**: This workflow is designed to be idempotent. Rerunning it will skip already completed steps or safely update existing files without overwriting customized content.

## Process Steps

1. **Project Documentation Setup**:
    - Create documentation structure (`docs/decisions/`) for Architecture Decision Records if not exists.
    - **Identify Source**: Check if `PRD.md` exists at the project root.
        - If yes: Use this file as the primary source. If the existing `PRD.md` lacks structure, populate it using the PRD template.
        - If no: Check if `README.md` exists at the project root. Use this file as the primary source. If the existing `README.md` lacks project information, enhance it using the README template.
        - If neither exists: Create initial `PRD.md` and `README.md` files using the project templates and prepare to use interactive prompts to populate them.
    - **Extract/Prompt**: Extract core information **including primary technology stack**
      (e.g., Ruby, Rust, TypeScript) from the identified source file (`PRD.md` or `README.md`).
      If no source file or incomplete information, use interactive prompts to gather missing details.
    - **Interactive Prompts**: When using interactive prompts, ask comprehensive questions such as:
        - "What is the project's name and primary purpose?"
        - "What is the main technology stack (e.g., Node.js, Python, Ruby, Rust)?"
        - "What are 2-3 key features this project will provide?"
        - "Who are the primary users or target audience?"
        - "What external APIs or services will this project integrate with?"
        - "What are the main design principles or constraints?"
        - "What are the primary and secondary use cases?"

2. **Update Generated Documentation**:
    - Review the auto-generated files created by `integrate --init-project`:
        - `docs/what-do-we-build.md`
        - `docs/architecture.md`
        - `docs/blueprint.md`
    - Update these files with information gathered from PRD.md/README.md and interactive prompts
    - Replace any placeholder text with actual project information
    - Ensure consistency across all documentation files

3. **Configure Project Context**:
    - Review and customize the context configuration at `.coding-agent/context.yml`
    - Update the project context template at `docs/context/project.md`:
        - Add project-specific sections
        - Include key project decisions and constraints
        - Reference important documentation
    - Configure context presets for your project needs:
        - Modify the `project` preset to capture essential project information
        - Add custom presets if needed for specific development areas
    - Test context loading with `context --preset project` to verify configuration

4. **Verify Dev-Tools Integration**:
    - **Ensure dev-tools availability**:
        - Verify dev-tools commands are accessible from the project
        - Add dev-tools to PATH if not already available
        - Key commands include:
          - `task-manager next` - Find next actionable task
          - `task-manager recent` - Show recent activity
          - `git-commit` - Intelligent commit workflow
          - `code-lint` - Code quality checks
          - `context` - Load project context
          - `release-manager` - Manage releases
    - **Create project-specific scripts (optional)**:
        - Only if the project requires custom wrapper scripts, create them in `bin/`
        - Most functionality is available directly through dev-tools commands

5. **Customize v.0.0.0 Bootstrap Release** (if it was created):
    - If `dev-taskflow/current/v.0.0.0-bootstrap/` exists:
        - **Customize Template Tasks**: Replace template placeholders in task files:
            - Replace `[PLACEHOLDER]` values in the release overview file with actual project information
            - Update task descriptions with project-specific details
            - Update task dependencies to reflect actual workflow
        - **Mark Completed Tasks**: Update the status of tasks that were already completed:
            - Mark the dev-taskflow structure setup task as `done`
            - Mark the core documentation task as `in-progress` or `done` based on completion level
            - Leave PRD completion and roadmap creation tasks as `pending` for user completion
        - **Update Release Status**: Set the v.0.0.0 release overview status to `in-progress` and add the current date as the start date

6. **Draft Initial Release and Roadmap**:
    - **Create v.0.1.0 Release Draft** based on PRD/README:
        - Use `release-manager draft v.0.1.0` to create the first development release
        - Extract initial features from PRD.md's "Must-Have Features (P0)"
        - Create tasks for core functionality implementation
        - Set realistic milestones based on project scope
    - **Generate Initial Roadmap**:
        - Create `docs/roadmap.md` outlining project phases:
            - **Phase 1 (v.0.1.0)**: Core functionality and MVP features
            - **Phase 2 (v.0.2.0)**: Enhanced features from "Should-Have Features (P1)"
            - **Phase 3 (v.0.3.0)**: Polish, optimization, and "Could-Have Features (P2)"
        - Include timeline estimates if available from PRD
        - Define success metrics for each phase
    - **Set up Release Structure**:
        - Move v.0.1.0 draft to `dev-taskflow/backlog/` for planning
        - Create initial task breakdown for the first milestone
        - Document release goals and acceptance criteria

7. **Review and Update Project Source Documentation**:
    - Review the information extracted or gathered through interactive prompts
    - Update the primary source document (PRD.md or README.md) with all gathered project information
    - Ensure alignment with templates while preserving project-specific details
    - Add any missing sections or information discovered during the initialization process
    - Create a checklist of remaining items that need user input or decisions

8. **Provide Next Steps Guidance**:
    - **Display Current Status**:
        - List v.0.0.0 tasks and their status (if bootstrap was created)
        - Show v.0.1.0 draft release overview
        - Display roadmap summary
    - **Immediate Actions**:
        - Complete any remaining PRD.md sections
        - Review and refine the v.0.1.0 release plan
        - Run `task-manager next` to see the next actionable task
    - **Context Management**:
        - Explain how to use `context --preset project` to load project context
        - Guide on updating context templates as the project evolves
    - **Release Workflow**:
        - Explain transition from v.0.0.0 bootstrap to v.0.1.0 development
        - Describe the release cycle: draft → current → done
        - Show how to use `release-manager` commands

## Prerequisites

- `coding-agent-tools integrate claude --init-project` must have been run successfully
- Project root directory must be accessible with write permissions
- Ruby >= 3.2 for running dev-tools commands
- Optional: An existing `PRD.md` or `README.md` (at project root) can provide information for extraction
- Git repository initialized

## Project Context Loading

- Read and follow: `dev-handbook/workflow-instructions/load-project-context.wf.md`

## High-Level Execution Plan

### Planning Steps

- [ ] Assess what was created by `integrate --init-project`
- [ ] Identify missing or incomplete documentation
- [ ] Plan information gathering strategy

### Execution Steps

- [ ] Create/enhance PRD.md and README.md with project information
- [ ] Update auto-generated documentation with gathered details
- [ ] Configure context templates and presets
- [ ] Verify dev-tools command availability
- [ ] Customize bootstrap release tasks (if exists)
- [ ] Draft v.0.1.0 release and create roadmap
- [ ] Review and finalize all documentation

## User Input (if PRD.md or README.md not present or incomplete)

The workflow will prompt for:

1. **Project Overview**:
    - Project name and purpose
    - Key features and goals
    - Target audience/users
    - Success metrics

2. **Technical Information**:
    - **Primary Technology Stack** (e.g., Ruby, Rust, TypeScript)
    - Core libraries/frameworks used
    - External dependencies
    - Integration points
    - Performance requirements
    - Security considerations

3. **Development Planning**:
    - Priority features for v.0.1.0
    - Timeline estimates
    - Team structure (if applicable)
    - Deployment strategy

## Generated/Updated Documentation

### PRD.md
- Complete product requirements with all sections filled
- Clear feature prioritization (P0, P1, P2)
- Technical requirements and constraints
- User stories and acceptance criteria

### docs/roadmap.md
- Phased development plan
- Release milestones
- Feature allocation per release
- Success metrics per phase

### docs/context/project.md
- Customized context template
- Project-specific sections
- Key decisions and constraints
- Important file references

### .coding-agent/context.yml
- Configured presets for the project
- Custom context definitions
- Appropriate chunk limits

## Success Criteria

- [ ] PRD.md exists and is complete with project information
- [ ] README.md provides clear project overview
- [ ] All generated docs updated with actual project details
- [ ] Context configuration tested and working
- [ ] v.0.1.0 release drafted with initial tasks
- [ ] Roadmap created with phased approach
- [ ] Clear next steps provided to user

## Workflow Context

This workflow completes the project initialization by focusing on information gathering, customization, and planning - the aspects that require human input and decision-making that the automated `integrate --init-project` command cannot handle. It transforms a template-based setup into a fully customized, project-specific development environment.

## Behavior

- Preserves all files created by `integrate --init-project`
- Enhances documentation with project-specific information
- Creates comprehensive planning artifacts (releases, roadmap)
- Configures context for optimal AI assistance
- Provides clear guidance for project continuation

## Embedded Templates

### PRD Template

<documents>
<template path="dev-handbook/templates/project-docs/prd.template.md"># Product Requirements Document (PRD) Template

## Project Overview

### Problem Statement
<!-- Describe the core problem this project aims to solve -->

### Proposed Solution
<!-- High-level description of your approach to solving the problem -->

### Success Metrics
<!-- How will you measure success? Include quantifiable goals where possible -->

## Project Details

### Project Name
<!-- The official name of your project -->

### Target Audience
<!-- Who are the primary users/beneficiaries of this project? -->

### Core Value Proposition
<!-- What unique value does this project provide? -->

## Functional Requirements

### Must-Have Features (P0)
<!-- Critical features without which the project cannot succeed -->
- [ ] Feature 1: Description
- [ ] Feature 2: Description

### Should-Have Features (P1)
<!-- Important features that significantly enhance the project -->
- [ ] Feature 1: Description
- [ ] Feature 2: Description

### Could-Have Features (P2)
<!-- Nice-to-have features for future consideration -->
- [ ] Feature 1: Description
- [ ] Feature 2: Description

## Technical Considerations

### Technology Stack
<!-- Preferred programming languages, frameworks, databases, etc. -->
- **Primary Language**:
- **Framework/Runtime**:
- **Database**:
- **Key Libraries**:
- **Deployment**:

### Architecture Requirements
<!-- High-level architectural constraints or preferences -->

### Performance Requirements
<!-- Speed, scalability, and resource constraints -->

### Security Requirements
<!-- Security considerations and compliance needs -->

### Integration Requirements
<!-- External systems or APIs this project needs to work with -->

## User Stories

### Primary User Flows
<!-- Describe the main user journeys through your application -->

#### User Story 1

**As a** [type of user]
**I want** [goal/desire]
**So that** [benefit/value]

**Acceptance Criteria:**
- [ ] Criterion 1
- [ ] Criterion 2

#### User Story 2

**As a** [type of user]
**I want** [goal/desire]
**So that** [benefit/value]

**Acceptance Criteria:**
- [ ] Criterion 1
- [ ] Criterion 2

## Timeline and Milestones

### Development Phases
<!-- Break down the project into manageable phases -->

#### Phase 1: Foundation (v.0.1.0)
- **Duration**: [Estimated time]
- **Goals**: [What will be accomplished]
- **Deliverables**: [Specific outputs]

#### Phase 2: Enhancement (v.0.2.0)
- **Duration**: [Estimated time]
- **Goals**: [What will be accomplished]
- **Deliverables**: [Specific outputs]

#### Phase 3: Polish (v.0.3.0)
- **Duration**: [Estimated time]
- **Goals**: [What will be accomplished]
- **Deliverables**: [Specific outputs]

## Risks and Mitigations

### Technical Risks
<!-- Potential technical challenges and how to address them -->

### Business Risks
<!-- Market, user adoption, or other business-related risks -->

### Dependencies
<!-- External factors that could impact the project -->

## Success Criteria

### MVP Success Metrics
<!-- What defines a successful MVP launch? -->

### Long-term Success Metrics
<!-- What defines long-term project success? -->

## Appendices

### Glossary
<!-- Define project-specific terms -->

### References
<!-- Links to relevant resources, research, or documentation -->

### Assumptions
<!-- List any assumptions made in this PRD -->

### Out of Scope
<!-- Explicitly state what is NOT included in this project -->
</template>

<template path="dev-handbook/templates/project-docs/roadmap.template.md"># Project Roadmap

## Overview

This roadmap outlines the planned development phases for [Project Name], from initial MVP through to full feature completion.

## Development Phases

### Phase 1: Foundation (v.0.1.0)
**Timeline**: [Start Date] - [End Date]
**Status**: Planning

#### Goals
- Establish core architecture
- Implement fundamental features
- Create basic user interface
- Set up development infrastructure

#### Key Features
- [ ] Feature 1
- [ ] Feature 2
- [ ] Feature 3

#### Success Metrics
- Metric 1: Target value
- Metric 2: Target value

---

### Phase 2: Enhancement (v.0.2.0)
**Timeline**: [Start Date] - [End Date]
**Status**: Planned

#### Goals
- Expand functionality
- Improve user experience
- Add integration capabilities
- Enhance performance

#### Key Features
- [ ] Feature 1
- [ ] Feature 2
- [ ] Feature 3

#### Success Metrics
- Metric 1: Target value
- Metric 2: Target value

---

### Phase 3: Polish (v.0.3.0)
**Timeline**: [Start Date] - [End Date]
**Status**: Planned

#### Goals
- Optimize performance
- Polish user interface
- Add advanced features
- Prepare for production

#### Key Features
- [ ] Feature 1
- [ ] Feature 2
- [ ] Feature 3

#### Success Metrics
- Metric 1: Target value
- Metric 2: Target value

## Release Schedule

| Version | Target Date | Type | Focus |
|---------|------------|------|-------|
| v.0.0.0 | [Date] | Bootstrap | Project setup and documentation |
| v.0.1.0 | [Date] | Alpha | Core functionality |
| v.0.2.0 | [Date] | Beta | Enhanced features |
| v.0.3.0 | [Date] | RC | Polish and optimization |
| v.1.0.0 | [Date] | Release | Production ready |

## Dependencies

### External Dependencies
- Dependency 1: Impact and timeline
- Dependency 2: Impact and timeline

### Internal Dependencies
- Team availability
- Infrastructure setup
- Design completion

## Risk Factors

### High Priority Risks
- Risk 1: Mitigation strategy
- Risk 2: Mitigation strategy

### Medium Priority Risks
- Risk 1: Mitigation strategy
- Risk 2: Mitigation strategy

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| [Date] | 1.0 | Initial roadmap | [Author] |
</template>

<template path="dev-handbook/templates/project-docs/context-template.md"># Project Context Template

## Project Overview

### Name
[Project Name]

### Purpose
[Brief description of what this project does and why it exists]

### Status
[Current development phase: Planning/Active/Maintenance]

### Repository
[Repository URL]

## Key Information

### Technology Stack
- **Primary Language**: [Language]
- **Framework**: [Framework]
- **Database**: [Database]
- **Key Dependencies**: [List main dependencies]

### Architecture
[Brief description of system architecture]

### Project Structure
```
project-root/
├── src/           # [Description]
├── tests/         # [Description]
├── docs/          # [Description]
└── ...
```

## Development Workflow

### Key Commands
- `command1` - Description
- `command2` - Description

### Testing Strategy
[How testing is approached in this project]

### Deployment Process
[How the project is deployed]

## Important Decisions

### Decision 1
[Brief description and rationale]

### Decision 2
[Brief description and rationale]

## Current Focus

### Active Development
[What's currently being worked on]

### Known Issues
[Any important issues to be aware of]

### Next Steps
[Planned next actions]

## References

### Documentation
- [Link to important doc 1]
- [Link to important doc 2]

### External Resources
- [Link to external resource 1]
- [Link to external resource 2]

## Team Information

### Maintainers
- [Name/Role]

### Contributing
[How to contribute to this project]
</template>
</documents>

## References

- dev-handbook/.integrations/wfi/initialize-project-structure.wf.md
- dev-handbook/templates/project-docs/ (various templates)
- dev-handbook/guides/project-management.g.md