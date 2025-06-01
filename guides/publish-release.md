# Publish Release Guide

## Goal

This guide provides comprehensive explanations, rationale, and policies for the final deployment phase of project releases. It distinguishes "publish release" (final deployment and archival) from "ship release" (preparation and validation), establishing a clear process for completing the release lifecycle and transitioning projects from active development to archived state.

## Release Process Philosophy

### Distinction: Draft vs. Publish Release

The release process consists of two distinct phases:

1. **Draft/Ship Release** (Preparation Phase):
   - Feature completion and testing
   - Documentation finalization
   - Version preparation and validation
   - Pre-release checks and approvals
   - Initial tagging and package publishing

2. **Publish Release** (Deployment/Archival Phase):
   - Final release validation
   - Documentation archival from `current/` to `done/`
   - Release announcement and communication
   - Post-release monitoring setup
   - Project state transition to "released"

This separation ensures that release preparation can be iterative and collaborative, while the final publish step is decisive and irreversible.

## Versioning Philosophy

### Semantic Versioning Scheme

The project uses semantic versioning with the format `v<major>.<minor>.<patch>`:

- **`<major>.<minor>`**: Extracted directly from the release folder name
  - Example: Folder `v.0.3.0-feedback-after-meta.v.0.2` → Version `0.3`
  - No dependency on task completion counts or other metrics
- **`<patch>`**: Defaults to `0` for initial release publication
  - Incremented only for hotfixes or patch releases
  - Example: `v0.3.0` for initial release, `v0.3.1` for first patch

### Version Determination Process

1. **From Release Folder**: Extract `<major>.<minor>` from folder name pattern `v.<major>.<minor>.<additional>`
2. **Patch Defaulting**: Use `0` for initial publication
3. **Consistency Check**: Ensure version matches all project files and documentation
4. **Validation**: Verify version doesn't conflict with existing releases

## Archival Process

### Documentation Archival Philosophy

Release documentation archival serves multiple purposes:

- **Historical Record**: Preserves complete development context and decisions
- **State Transition**: Clearly marks the end of active development for a release
- **Knowledge Management**: Maintains accessible archive of project evolution
- **Process Validation**: Enables retrospective analysis and process improvement

### Archival Structure

Documentation moves from `docs-project/current/` to `docs-project/done/` following this pattern:

```
Before Archival:
docs-project/current/v.0.3.0-feedback-after-meta.v.0.2/
├── tasks/
├── researches/
├── decisions/
└── v.0.3.0-feedback-after-meta.v.0.2.md

After Archival:
docs-project/done/v.0.3.0-feedback-after-meta.v.0.2/
├── tasks/
├── researches/
├── decisions/
└── v.0.3.0-feedback-after-meta.v.0.2.md
```

### Archival Timing

Documentation archival occurs **after** successful:

- Package publication (if applicable)
- Git tagging and pushing
- Release validation
- Initial monitoring confirmation

This ensures the release is truly complete before archiving its development context.

## Build Process Integration

### Technology-Agnostic Approach

The publish release process accommodates diverse project types:

#### Projects with Build Steps

- Execute `bin/build` as pre-release validation
- Verify build artifacts are current and functional
- Include build status in release validation checklist

#### Documentation-Only Projects

- Skip build execution (graceful handling of no-op builds)
- Focus on content validation and formatting checks
- Ensure all documentation is properly formatted and linked

#### Mixed Projects

- Execute applicable build steps for relevant components
- Validate both code and documentation components
- Coordinate build timing with release dependencies

### Build Integration Points

1. **Pre-Release Validation**: Execute `bin/build` to verify project integrity
2. **Dependency Verification**: Ensure all build dependencies are satisfied
3. **Artifact Validation**: Confirm build outputs match expected standards
4. **Error Handling**: Provide clear feedback for build failures and resolution steps

## Changelog Integration

### Changelog as Release Communication

The changelog serves as the primary communication vehicle for release changes:

- **User-Facing**: Written for end users, not just developers
- **Comprehensive**: Covers all significant changes affecting users
- **Structured**: Follows Keep a Changelog format for consistency
- **Linked**: References issues, tasks, and pull requests where applicable

### Changelog Generation Process

1. **Collection Phase**: Gather changes from task documentation, commit messages, and feature tracking
2. **Categorization**: Organize changes by type (Added, Changed, Fixed, etc.)
3. **Prioritization**: Order items by user impact and importance
4. **Review Phase**: Validate completeness and accuracy with stakeholders
5. **Finalization**: Integrate into overall release documentation

### Integration with Task Management

Changelog entries should reference:

- Task IDs for traceability (e.g., "Task v.0.3.0+task.14")
- GitHub issues/PRs when applicable
- Decision documents (ADRs) for architectural changes
- User feedback that drove specific changes

## Release Validation

### Multi-Level Validation Approach

Release validation occurs at multiple levels:

#### Technical Validation

- All tests pass (`bin/test`)
- Code quality standards met (`bin/lint`)
- Build process completes successfully (`bin/build`)
- Dependencies are current and secure

#### Process Validation

- All planned tasks completed or explicitly deferred
- Documentation is complete and accurate
- Version numbers are consistent across all files
- Changelog accurately reflects changes

#### Content Validation

- Release documentation follows naming conventions
- All acceptance criteria met for included features
- Breaking changes are clearly documented
- Migration guides provided where necessary

### Validation Checkpoints

1. **Pre-Archive Validation**: Before moving documentation
2. **Pre-Tag Validation**: Before creating Git tags
3. **Pre-Publish Validation**: Before package publication
4. **Post-Release Validation**: After all release steps complete

## Communication Strategy

### Multi-Channel Communication

Release announcements should reach appropriate audiences through relevant channels:

#### Internal Communication

- Development team notifications
- Project stakeholder updates
- Internal documentation updates
- Process improvement feedback collection

#### External Communication (if applicable)

- User-facing release notes
- API documentation updates
- Community announcements
- Social media or blog posts

### Communication Timing

1. **Pre-Release**: Stakeholder notifications of impending release
2. **At Release**: Immediate notifications to primary users
3. **Post-Release**: Comprehensive documentation and guides
4. **Follow-up**: Feedback collection and issue monitoring

## Monitoring and Post-Release Activities

### Release Monitoring

Post-release monitoring ensures release quality and identifies issues early:

#### Immediate Monitoring (0-24 hours)

- Error rate monitoring
- Performance metrics validation
- User feedback collection
- Critical issue identification

#### Short-term Monitoring (1-7 days)

- Usage pattern analysis
- Feature adoption tracking
- Support request monitoring
- Community feedback analysis

#### Long-term Monitoring (ongoing)

- Release impact assessment
- Process improvement identification
- User satisfaction measurement
- Next release planning input

### Issue Response Process

1. **Issue Identification**: Through monitoring or user reports
2. **Severity Assessment**: Critical, high, medium, or low priority
3. **Response Coordination**: Team notification and assignment
4. **Resolution Tracking**: Progress monitoring and communication
5. **Post-Mortem**: Process improvement for future releases

## Technology Considerations

### Language/Framework Agnostic

The publish release process is designed to work across different technology stacks:

#### Configuration Management

- Version files (package.json, Cargo.toml, etc.)
- Build configuration updates
- Dependency management
- Environment-specific settings

#### Package Publication

- Registry-specific publishing (npm, RubyGems, PyPI, etc.)
- Authentication and credentials management
- Publication verification
- Rollback procedures if needed

#### Documentation Integration

- API documentation generation
- User guide updates
- Technical reference updates
- Integration guide maintenance

## Process Governance

### Role Responsibilities

#### Release Manager

- Coordinates overall release process
- Validates all release criteria are met
- Executes final publication steps
- Manages communication and announcements

#### Development Team

- Completes feature development and testing
- Updates documentation and changelogs
- Provides technical validation
- Supports post-release monitoring

#### Quality Assurance

- Validates release criteria
- Conducts final testing
- Reviews documentation accuracy
- Monitors post-release quality metrics

### Process Compliance

1. **Checklist Adherence**: All workflow steps must be completed
2. **Documentation Standards**: All artifacts must meet quality standards
3. **Review Requirements**: Appropriate reviews must be completed
4. **Approval Gates**: Required approvals must be obtained
5. **Audit Trail**: Complete record of release process execution

## Risk Management

### Common Release Risks

#### Technical Risks

- Build failures or compilation errors
- Test failures or quality regressions
- Dependency conflicts or version issues
- Performance degradation or resource issues

#### Process Risks

- Incomplete documentation or missing information
- Communication failures or stakeholder misalignment
- Timeline pressures or resource constraints
- Coordination issues across teams or projects

### Risk Mitigation Strategies

1. **Early Validation**: Identify issues before final release steps
2. **Rollback Plans**: Prepare procedures for release reversal if needed
3. **Communication Protocols**: Clear escalation and notification procedures
4. **Quality Gates**: Mandatory validation points throughout the process
5. **Learning Integration**: Continuous improvement based on release outcomes

## Integration with Project Management

### Task Management Integration

The publish release process integrates with overall task management:

- **Task Completion Validation**: Verify all release tasks are done or deferred
- **Dependency Resolution**: Ensure all task dependencies are satisfied
- **Status Updates**: Update task and project status throughout release
- **Documentation Links**: Maintain traceability between tasks and release artifacts

### Release Planning Integration

- **Scope Management**: Clear definition of what's included/excluded
- **Timeline Coordination**: Integration with project schedules
- **Resource Allocation**: Appropriate staffing for release activities
- **Stakeholder Management**: Regular communication and expectation setting

## Continuous Improvement

### Process Metrics

Track key metrics to improve the release process:

- **Release Cycle Time**: Time from feature complete to published
- **Defect Escape Rate**: Issues discovered after release
- **Process Compliance**: Adherence to defined workflows
- **Stakeholder Satisfaction**: Feedback on process effectiveness

### Feedback Integration

1. **Post-Release Retrospectives**: Regular process review sessions
2. **Stakeholder Feedback**: Input from users and team members
3. **Metrics Analysis**: Data-driven process improvement
4. **Best Practice Sharing**: Knowledge transfer across teams
5. **Process Evolution**: Iterative improvement of release procedures

## Related Documentation

- [Prepare Release Workflow](../workflow-instructions/prepare-release.md) (Release preparation and validation)
- [Changelog Guide](./changelog-guide.md) (Changelog writing standards)
- [Version Control Guide](./version-control.md) (Git workflow and tagging)
- [Project Management Guide](./project-management.md) (Task and release coordination)
- [Publish Release Workflow](../workflow-instructions/publish-release.md) (Step-by-step execution)
- [Quality Assurance Guide](./quality-assurance.md) (Release validation standards)
