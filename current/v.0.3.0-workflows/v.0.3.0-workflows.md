# v.0.3.0 Workflows

## Release Overview

Improve workflow independence and integration capabilities to make workflow instructions easily integrable into coding agents like Claude Code, Windsurf, Zed, and others.

## Release Information

- **Type**: Feature
- **Start Date**: 2025-06-26
- **Target Date**: TBD
- **Release Date**: TBD
- **Status**: Planning

## Goals & Requirements

### Primary Goals

- [ ] Make workflows independent and self-contained
  - Success Metrics: Each workflow can be executed without dependencies on other workflows
  - Acceptance Criteria: Workflows include all necessary context and instructions within the file
  - Implementation Strategy: Refactor existing workflows to include embedded context and remove cross-references
  - Dependencies & Status: Requires analysis of current workflow dependencies
  - Risks & Mitigations: Risk of duplication - mitigate by creating shared reference sections

- [ ] Enhance integration capabilities for coding agents
  - Success Metrics: Workflows can be directly consumed by Claude Code, Windsurf, Zed
  - Acceptance Criteria: Each workflow includes agent-specific integration notes and examples
  - Implementation Strategy: Add standardized agent integration sections to workflow templates
  - Dependencies & Status: Requires research into agent-specific requirements
  - Risks & Mitigations: Risk of agent-specific drift - maintain common core with agent-specific extensions

## Collected Notes

Raw user input:
> We will be improving the workflows, make then independent, so it will be much easier to integrate them into coding agents like: claude code / windsurf / zed / ...

Updated requirements:
> To update all workflow instructions @dev-handbook/workflow-instructions/ (21 files total)
> - ensure they never call / reference other workflow instruction from itself
> - every workflow instruction have high level plan (7-step execution pattern)
> - every workflow instruction ensure we load project context, at bare minimum:
>   * Review project objectives: docs/what-do-we-build.md
>   * Examine high-level architecture: docs/architecture.md  
>   * Check project structure and key files: docs/blueprint.md

## Implementation Plan

### Core Components

1. **Design & Architecture**:
   - [ ] Comprehensive workflow analysis (21 files)
   - [ ] Standardized execution template design
   - [ ] Agent integration interface design
   - [ ] Project context loading template

2. **Dependencies**:
   - [ ] Complete workflow dependency mapping across all 21 files
   - [ ] Agent integration requirements research
   - [ ] Template system for standardized structure

3. **Implementation Phases**:
   - [ ] Phase 1: Analysis & Template Creation
     - Audit all 21 workflow dependencies and cross-references
     - Create standardized execution and context templates
     - Research agent integration patterns
   - [ ] Phase 2: Comprehensive Workflow Refactoring
     - Remove cross-references from all 21 workflows
     - Add high-level execution plans to every workflow
     - Embed project context loading in every workflow
   - [ ] Phase 3: Agent Integration Enhancement
     - Add agent-specific sections to all workflows
     - Create integration examples and compatibility guides
   - [ ] Phase 4: Validation & Documentation
     - Test all workflows with target agents
     - Create comprehensive workflow independence guide
     - Validate compatibility across agent platforms

## Quality Assurance

### Test Coverage

- [ ] Workflow Independence Tests
  - All 21 workflows run without cross-workflow dependencies
  - Each workflow contains high-level execution plan
  - All required context is embedded in each workflow
- [ ] Agent Integration Tests
  - Test all 21 workflows with Claude Code
  - Test all 21 workflows with Windsurf 
  - Test all 21 workflows with Zed
- [ ] Standardization Tests
  - All workflows follow standardized template structure
  - Project context loading consistent across workflows
  - Execution patterns standardized

## Release Checklist

- [ ] All 21 workflows made independent with no cross-references
- [ ] High-level execution plans added to all workflows
- [ ] Project context loading embedded in all workflows
- [ ] Agent integration sections added to all workflows
- [ ] Tests passing for all workflows across all target agents
- [ ] Documentation complete
  - Workflow independence guide
  - Standardized execution templates
  - Agent integration examples
  - Migration notes for users
- [ ] All workflow files validated and tested
- [ ] CHANGELOG updated
- [ ] Release notes prepared