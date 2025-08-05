---
id: v.0.6.0+task.015
status: draft
priority: medium
estimate: TBD
dependencies: []
---

# Remove unnecessary claude-integrate migration documentation

## Behavioral Specification

### User Experience
- **Input**: User reads Claude integration documentation to understand the system
- **Process**: User navigates between README.md and related documentation to learn about the integration
- **Output**: User gains clear understanding of current Claude integration system without confusion from obsolete migration information

### Expected Behavior
<!-- Describe WHAT the system should do from the user's perspective -->
<!-- Focus on observable outcomes, system responses, and user experience -->
<!-- Avoid implementation details - no mention of files, code structure, or technical approaches -->

The documentation system should present a clean, current view of the Claude integration without references to legacy migration processes. Users should experience:

- Clear and focused documentation that explains the current system
- No confusion from outdated migration information about systems that were never released
- Straightforward understanding of how to use the handbook claude commands
- No dead links or references to non-existent migration guides

### Interface Contract
<!-- Define all external interfaces, APIs, and interaction points -->
<!-- Include normal operations, error conditions, and edge cases -->

```bash
# Documentation Navigation Interface
# Users access documentation through standard file paths:
dev-handbook/.integrations/claude/README.md  # Main integration guide
# MIGRATION.md will no longer exist
```

**Error Handling:**
- [Missing migration guide]: Documentation will not reference MIGRATION.md, preventing 404 errors
- [Outdated links]: README.md will contain only valid, current references

**Edge Cases:**
- [User searches for migration info]: They find current setup instructions instead
- [External links to MIGRATION.md]: Will result in 404, but main docs remain accessible

### Success Criteria
<!-- Define measurable, observable criteria that indicate successful completion -->
<!-- Focus on behavioral outcomes and user experience, not implementation artifacts -->

- [ ] **Documentation Clarity**: Users can understand Claude integration without encountering migration references
- [ ] **No Dead Links**: README.md contains no references to MIGRATION.md or migration processes
- [ ] **Focused Content**: Documentation focuses solely on current system usage without historical migration context

### Validation Questions
<!-- Questions to clarify requirements, resolve ambiguities, and validate understanding -->
<!-- Ask about unclear requirements, edge cases, and user expectations -->

- [x] **Requirement Clarity**: Should all references to the legacy claude-integrate script be removed from README.md?
  - Answer: Yes, since it was developed and replaced on the same day, no users ever used the legacy version
- [x] **Edge Case Handling**: What if users have bookmarked the MIGRATION.md file?
  - Answer: Accept this as the cost of cleanup - the file was never needed as no migration occurred
- [x] **User Experience**: Should we add a note explaining why there's no migration guide?
  - Answer: No, this would add unnecessary complexity. The current system should stand on its own
- [x] **Success Definition**: Is complete removal of migration documentation sufficient?
  - Answer: Yes, remove MIGRATION.md and update README.md to remove migration references

## Objective

Remove unnecessary documentation about migrating from a legacy system that was never actually released or used. This cleanup ensures users focus on the current Claude integration system without confusion from obsolete migration instructions.

## Scope of Work
<!-- Define the behavioral scope - what user experiences and system behaviors are included -->

- **User Experience Scope**: Documentation readers experience clean, focused content about current Claude integration
- **System Behavior Scope**: Documentation system presents only relevant, current information
- **Interface Scope**: File system interface provides access to README.md without MIGRATION.md

### Deliverables
<!-- Focus on behavioral and experiential deliverables, not implementation artifacts -->

#### Behavioral Specifications
- Clean documentation experience without migration references
- Clear understanding path for new users learning the system
- Removal of confusion points from obsolete content

#### Validation Artifacts
- Verification that README.md contains no migration references
- Confirmation that MIGRATION.md no longer exists
- Documentation review showing improved clarity

## Out of Scope
<!-- Explicitly exclude implementation concerns to maintain behavioral focus -->

- ❌ **Implementation Details**: File structures, code organization, technical architecture
- ❌ **Technology Decisions**: Tool selections, library choices, framework decisions
- ❌ **Performance Optimization**: Specific performance improvement strategies
- ❌ **Future Enhancements**: Migration guides for future versions or other integration improvements

## References

- User feedback requesting removal of unnecessary migration documentation
- Current Claude integration documentation in dev-handbook/.integrations/claude/
- Project decision that claude-integrate was developed and replaced same day