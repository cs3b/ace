# Self-Reflect Command

This command guides reflection on coding sessions, commit history, and release artifacts.

## Process Steps

1. Session Analysis:
   - Review coding session artifacts in tmp/
   - Check recent commit history
   - Assess release progress in prepare-release/

2. Review Areas:

   A. Coding Session Review:
      - AI interaction effectiveness
      - Solution quality assessment
      - Knowledge preservation
      - Pattern recognition

   B. Commit Analysis:
      - Commit message clarity
      - Change atomicity
      - Documentation updates
      - Test coverage

   C. Architecture Impact:
      - Design principles alignment
      - Component relationships
      - Interface contracts
      - Technical debt assessment

   D. Collaboration Workflow Analysis:
      - Task breakdown effectiveness
      - Communication clarity
      - Decision-making process
      - Knowledge sharing practices
      - Testing and validation approach
      - Implementation planning quality
      - Progress tracking methods

   E. Release Progress:
      - Feature completeness
      - Documentation status
      - Test coverage
      - Release readiness

3. Knowledge Capture:
   - Document key decisions in `decisions/`
   - Update best practices in `guides/`
   - Record challenges in `researches/`
   - Add test patterns to `test-cases/`
   - Update architecture in `project/11-architecture.md`
   - Create/update ADRs for significant changes

## Documentation Updates

1. Session Artifacts:
   ```bash
   docs-dev/
   ├── guides/           # Update learned practices
   ├── project/
   │   ├── current-work.md         # Update progress
   │   ├── architecture.md         # Architecture documentation
   │   └── current/               # Current tasks
   ├── decisions/       # Architecture Decision Records
   └── prepare-release/
       └── v.x.x.x/     # Update release docs
   ```

2. Focus Areas:
   - Technical documentation improvements
   - Process optimization insights
   - Quality assurance enhancements
   - Release preparation updates

## Success Criteria

1. Session Review Complete:
   - AI interactions analyzed
   - Solutions validated
   - Patterns documented
   - Improvements identified

2. Commit Quality Verified:
   - Clear messages
   - Proper scoping
   - Documentation updated
   - Tests included

3. Architecture Maintained:
   - Design principles followed
   - Changes documented
   - ADRs created/updated
   - Technical debt tracked

4. Collaboration Workflow Assessed:
   - Strengths identified
   - Improvement areas documented
   - Process enhancement suggestions captured
   - Implementation planning evaluated
   - Knowledge sharing effectiveness measured

5. Release Progress Assessed:
   - Features tracked
   - Docs maintained
   - Tests validated
   - Blockers identified

## Reflection Changelog

1. Session Entry Format:
   ```markdown
   ### YYYY-MM-DD Session Reflection

   #### AI Interaction Review
   - Successful patterns:
     - [Pattern] Description and context
   - Challenges faced:
     - [Challenge] Description and resolution
   - Improvements identified:
     - [Action Item] Specific improvement task

   #### Code Evolution
   - Architecture changes:
     - [Component] Change description and rationale
   - New patterns:
     - [Pattern] Implementation details and use case
   - Technical debt:
     - [Area] Description and mitigation plan

   #### Collaboration Workflow Analysis
   - Strengths:
     - [Area] Description of effective practice with examples
   - Areas for improvement:
     - [Process] Description of improvement opportunity with context
   - Process enhancement suggestions:
     - [Suggestion] Specific actionable process improvement with expected benefits
   - Implementation planning insights:
     - [Planning Method] Effectiveness assessment and recommendations
   - Knowledge sharing practices:
     - [Practice] Evaluation of effectiveness and suggestions for enhancement

   #### Documentation Updates
   - Updated files:
     - [Path] Change description
   - New documentation:
     - [Path] Content purpose
   - Process improvements:
     - [Area] Enhancement details

   #### Next Steps
   - Immediate tasks:
     - [Task] Description and priority
   - Future considerations:
     - [Topic] Details for future planning
   ```

2. Location:
   ```bash
   docs-dev/
   └── reflections/
       ├── YYYY-MM/             # Monthly reflection directory
       │   ├── DD-summary.md    # Daily reflection entries
       │   └── monthly.md       # Monthly summary
       └── changelog.md         # Running changelog of key insights
   ```

3. Usage:
   - Daily entries capture immediate insights
   - Monthly summaries identify patterns
   - Changelog tracks significant learnings
   - Used for:
     - Sprint planning
     - Feature refinement
     - Process improvement
     - Knowledge sharing

## Success Metrics

1. Changelog Quality:
   - Clear context provided
   - Actionable insights
   - Linked to artifacts
   - Traceable outcomes

2. Knowledge Impact:
   - Referenced in planning
   - Influences design
   - Improves processes
   - Reduces mistakes

## Reference Documentation

- [Documentation Guide](../guides/documentation.md)
- [Version Control](../guides/version-control.md)
- [Release Process](../guides/ship-release.md)
- [Quality Assurance](../guides/quality-assurance.md)
- [Architecture](../project/11-architecture.md)
- [Generate ADR](docs/generate-adr.md)
- [Retrospective Template](../guides/prepare-release/v.x.x.x/reflections/_template.md)

## Collaboration Workflow Reflection Guide

When analyzing collaboration workflows, focus on these key dimensions:

1. **Task Management**
   - How effectively were tasks broken down?
   - Was progress tracked transparently?
   - Were dependencies and blockers identified early?

2. **Communication Patterns**
   - Was knowledge shared clearly and proactively?
   - Were questions answered comprehensively?
   - Was contextual information provided with changes?

3. **Decision-Making Process**
   - Were options explored before committing to solutions?
   - Was rationale documented for key decisions?
   - Were tradeoffs clearly articulated?

4. **Implementation Approach**
   - Was planning conducted before implementation?
   - Were checkpoint reviews performed?
   - Was the approach adjusted based on emerging information?

5. **Testing and Validation**
   - Were tests written/updated appropriately?
   - Was validation conducted at key milestones?
   - Were edge cases considered?

6. **Knowledge Capture**
   - Were insights documented during the process?
   - Were reusable patterns identified?
   - Was documentation updated to reflect new knowledge?

For each dimension, identify:
- What worked well (continue)
- What could be improved (change)
- What new practices to try (start)
- What practices to eliminate (stop)

This analysis should produce specific, actionable insights that can be applied to future collaboration sessions.
