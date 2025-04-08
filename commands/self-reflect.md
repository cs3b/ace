# Self-Reflect Command

This command guides reflection on coding sessions, commit history, and release artifacts.

## Process Steps

1. Session Analysis:
   - Review coding session artifacts in tmp/
   - Check recent commit history
   - Assess release progress in release-template/

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
      
   D. Release Progress:
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
   │   ├── 00-current-work.md      # Update progress
   │   ├── 11-architecture.md      # Architecture documentation
   │   └── 1-next/      # Refine upcoming tasks
   ├── decisions/       # Architecture Decision Records
   └── release-template/
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

4. Release Progress Assessed:
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
- [Release Process](../guides/release.md)
- [Quality Assurance](../guides/quality-assurance.md)
- [Architecture](../project/11-architecture.md)
- [Generate ADR](docs/generate-adr.md)