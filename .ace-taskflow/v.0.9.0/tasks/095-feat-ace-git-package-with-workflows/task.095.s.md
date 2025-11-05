---
id: v.0.9.0+task.095
status: draft
priority: medium
estimate: 2-3 days
dependencies: []
needs_review: true
---

# Create ace-git package with three essential workflows

Create a unified ace-git gem package that consolidates git workflow management with three essential workflows:
- **rebase.wf.md**: Changelog preservation during rebase operations
- **create-pr.wf.md**: Pull request creation with comprehensive templates (new)
- **squash-pr.wf.md**: Smart commit squashing (one per version) for clean history

## Review Questions (Pending Human Input)

### [HIGH] Critical Implementation Questions
- [ ] Should this be named `ace-git` (unified package) or keep separate `ace-git-rebase`, `ace-git-pr` packages?
  - **Research conducted**: Examined existing ace-git-* packages (ace-git-commit, ace-git-diff, ace-git-worktree)
  - **Pattern observed**: Current packages are feature-specific (commit, diff, worktree)
  - **Suggested default**: Create unified `ace-git` package with multiple workflows
  - **Why needs human input**: Architectural decision affecting package organization

- [ ] Should we implement any Ruby helper methods or keep this purely workflow-focused?
  - **Research conducted**: Checked ace-git-commit (has executable), ace-git-diff (has executable)
  - **Pattern observed**: Most git packages include minimal Ruby for CLI integration
  - **Suggested default**: Workflow-only package, no executable
  - **Why needs human input**: Determines if users need programmatic access

### [MEDIUM] Enhancement Questions
- [ ] Should the PR creation workflow integrate with GitHub CLI (`gh`) or provide generic git instructions?
  - **Research conducted**: Found existing `gh pr create` usage in commit workflow instruction
  - **Suggested default**: Use `gh` commands with fallback instructions for generic git
  - **Why needs human input**: Platform-specific vs platform-agnostic approach

- [ ] Should squash workflow support interactive mode selection or automatic detection?
  - **Research conducted**: No existing squash patterns found in current packages
  - **Suggested default**: Automatic detection based on version tags/CHANGELOG entries
  - **Why needs human input**: Balance between automation and user control

## Behavioral Specification

### User Experience

**Input**: Developer needs comprehensive git workflow guidance for rebase, PR creation, and commit management
**Process**: Developer follows workflow instructions provided by the ace-git package
**Output**: Successfully executed git operations with preserved changelog, clean PR creation, and organized commit history

### Expected Behavior

- Developers install the ace-git gem to access all three workflow instructions
- Three separate workflow guides provide step-by-step instructions for:
  - Rebase operations with changelog/version preservation
  - Pull request creation with templates and best practices
  - Commit squashing for clean version-based history
- Clear patterns for resolving conflicts and handling edge cases
- Configuration examples show how to customize each workflow's behavior
- The package integrates with Claude Code through handbook/workflow-instructions/

### Interface Contract

#### Package Structure

```
ace-git/
├── .ace.example/git/
│   ├── config.yml                       # General git configuration
│   ├── rebase.yml                       # Rebase-specific configuration
│   ├── pr.yml                          # PR creation configuration
│   └── squash.yml                      # Squash workflow configuration
├── lib/ace/git/
│   └── version.rb                      # VERSION constant
├── handbook/workflow-instructions/      # All workflow documentation
│   ├── rebase.wf.md                    # Changelog-preserving rebase
│   ├── create-pr.wf.md                 # PR creation with templates
│   └── squash-pr.wf.md                 # Version-based commit squashing
├── ace-git.gemspec                     # Gem specification
├── CHANGELOG.md                        # Keep a Changelog format
├── README.md                           # Package documentation with all workflows
├── Rakefile                            # Basic gem tasks (no tests)
└── LICENSE                             # MIT license
```

**Configuration Interface (.ace/git/config.yml):**

```yaml
git:
  # General git preferences
  default_branch: main
  remote: origin
  verbose: false

  # Rebase configuration
  rebase:
    preserve_files:
      - CHANGELOG.md
      - "**/version.rb"
    auto_resolve: manual

  # PR configuration
  pr:
    template: default      # PR template selection
    draft: false          # Create as draft PR
    reviewers: []         # Auto-assign reviewers

  # Squash configuration
  squash:
    strategy: version     # Squash by version tags
    interactive: false    # Use interactive mode
    preserve_messages: true  # Keep important commit messages
```

**Workflow Access:**

- Via gem installation: `gem install ace-git`
- Via Claude Code: All three workflows available through handbook integration
- No executable binary (workflow-first approach)

### Success Criteria

- [ ] ace-git gem package created with minimal structure
- [ ] Three workflow instructions provide comprehensive guidance:
  - [ ] rebase.wf.md: Complete rebase with changelog preservation
  - [ ] create-pr.wf.md: Pull request creation with templates
  - [ ] squash-pr.wf.md: Smart commit squashing by version
- [ ] Configuration examples demonstrate customization for all workflows
- [ ] Package follows ace-gems.g.md standards (CHANGELOG.md, version.rb, etc.)
- [ ] Handbook integration enables Claude Code workflow access for all three workflows
- [ ] No unnecessary Ruby implementation (workflow-focused)
- [ ] README documents all three workflows clearly

### Validation Questions

- [Moved to Review Questions section with research context]

## Objective

Create a minimal, workflow-first ace-git gem package that consolidates essential git workflows (rebase with changelog preservation, PR creation, and commit squashing) into a single, well-organized package following the ace-gems standard structure.

## Scope of Work

### Package Creation Scope

- Minimal gem structure per ace-gems.g.md
- Three workflow instructions in handbook/workflow-instructions/
- Multiple configuration examples in .ace.example/git/
- Proper versioning and changelog setup
- Unified README covering all workflows

### Workflow Documentation Scope

#### Rebase Workflow (rebase.wf.md)
- Pre-rebase verification steps
- Conflict resolution patterns for CHANGELOG.md
- Version file conflict handling strategies
- Post-rebase validation procedures
- Recovery and rollback guidance

#### PR Creation Workflow (create-pr.wf.md)
- PR template selection and customization
- Branch naming conventions
- Commit message preparation
- Integration with GitHub CLI (`gh`)
- Draft PR vs ready-for-review decisions

#### Squash Workflow (squash-pr.wf.md)
- Version-based commit detection
- CHANGELOG entry preservation
- Interactive vs automatic squashing
- Commit message consolidation
- History cleanup best practices

### Integration Scope

- Claude Code handbook integration for all workflows
- Configuration through ace-core cascade
- References to existing ace-git-* packages
- Coordination with ace-taskflow for version management

## Deliverables

### Package Components

- ace-git.gemspec with minimal dependencies
- lib/ace/git/version.rb with VERSION constant
- handbook/workflow-instructions/
  - rebase.wf.md (changelog-preserving rebase)
  - create-pr.wf.md (pull request creation)
  - squash-pr.wf.md (version-based squashing)
- .ace.example/git/ configuration templates
  - config.yml (general configuration)
  - rebase.yml (rebase-specific)
  - pr.yml (PR creation settings)
  - squash.yml (squash preferences)
- CHANGELOG.md in Keep a Changelog format
- README.md with comprehensive usage for all workflows
- Rakefile for gem tasks (no tests needed)
- LICENSE file (MIT)

### Workflow Content

Each workflow includes:
- Complete step-by-step procedures
- Decision trees for edge cases
- Example scenarios with solutions
- Integration points with git/gh commands
- Recovery procedures for failures
- Configuration customization examples

## Out of Scope

**Implementation Concerns (deferred or not needed):**

- Executable binary (no CLI tool)
- Ruby implementation of rebase logic
- Automated conflict resolution algorithms
- Test suite (workflow-only package)
- Complex ATOM architecture (atoms/, molecules/, organisms/)
- Integration with CI/CD pipelines
- Performance optimization

## References

- Source Idea: `.ace-taskflow/v.0.9.0/ideas/done/20251025-112037-create-rebase-workflow-to-mind-the-changelog-an.md`
- Related: ace-gems.g.md development guide
- Related: ace-git-commit package (commit generation patterns)
- Related: ace-git-diff package (diff command patterns)
- Related: ace-git-worktree package (branch management patterns)
- Related: dev-handbook/workflow-instructions/rebase-against.wf.md (existing rebase workflow)
- Related: Keep a Changelog specification
- Related: Semantic Versioning specification
- Related: GitHub CLI (`gh`) documentation for PR creation

