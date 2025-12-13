# v.0.4.0 Replanning

## Release Overview

This release introduces a comprehensive specification cycle architecture that separates idea capture, behavioral specification (what), and implementation planning (how). It establishes clear phase boundaries to enable more autonomous AI agent execution while maintaining human control over planning and specification.

## Release Information

- **Type**: Feature
- **Start Date**: 2025-01-30
- **Target Date**: 2025-02-28  
- **Status**: Planning

## Collected Notes

From our conversation analysis of the planning agent research and existing workflows:

- Need to separate "what" (behavior/interface) from "how" (implementation) in task specification
- Current draft-task.wf.md jumps directly to implementation details without behavior-first thinking
- Current plan-task.wf.md mixes concerns in a single pass
- Ideas should be captured separately from formal tasks (vague, might not be implemented)
- Task states: ideas → draft → pending → in-progress → done
- Manual cascade review after task completion to update dependent tasks
- All specification phases are manual (no automatic execution)
- Each phase produces distinct artifacts with clear handoffs
- Tools should be flexible and support workflows, not enforce rigid systems
- Concurrent development handled through dependency graphs and git worktrees

## Goals & Requirements

### Primary Goals

- [ ] Establish clear separation between idea capture, behavioral specification, and implementation planning
- [ ] Enable AI agents to execute tasks more autonomously with better specifications
- [ ] Maintain human control over all planning and specification phases

### Dependencies

- Existing task-manager and create-path tools
- Current workflow instruction structure
- Task template format

### Risks & Mitigation

- Complexity explosion from too many states | Keep states minimal and transitions clear
- Context loss between phases | Structure handoff formats between workflows
- Disruption to existing workflows | Implement incrementally with backward compatibility

## Implementation Plan

### Core Components

1. **Design & Architecture**
   - [ ] Design new task template with clear what/how sections
   - [ ] Define handoff formats between specification phases
   - [ ] Document state transitions and graduation criteria

2. **Dependencies**  
   - [ ] Ensure create-path supports draft status
   - [ ] Verify task-manager can handle new states
   - [ ] Plan migration for existing tasks

3. **Implementation Phases**
   - [ ] Phase 1: Enhance existing workflows with behavior focus
   - [ ] Phase 2: Introduce new tools and workflows
   - [ ] Phase 3: Add cascade management capabilities

## Quality Assurance

### Test Coverage

- [ ] Workflow validation for each new specification phase
- [ ] Tool integration tests for new status support
- [ ] End-to-end specification cycle testing
- [ ] Migration testing for existing tasks

### Documentation

- [ ] Updated workflow instructions
- [ ] New workflow creation guides
- [ ] Tool usage documentation updates
- [ ] Migration guide for existing tasks

## Release Checklist

- [ ] All planned features implemented and tested
- [ ] All tests passing (unit, integration, e2e)
- [ ] Documentation complete and reviewed
- [ ] CHANGELOG.md updated with all changes
- [ ] Version numbers updated in relevant files
- [ ] Security review completed
- [ ] Performance benchmarks meet targets
- [ ] Backward compatibility verified
- [ ] Migration guide prepared (if needed)
- [ ] Release notes drafted

## Notes

This release fundamentally changes how we approach task specification, moving from a single-pass approach to a multi-phase specification cycle that better supports both human planning and AI execution.