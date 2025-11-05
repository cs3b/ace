---
id: v.0.9.0+task.095
status: draft
priority: medium
estimate: TBD
dependencies: []
---

# Create ace-git package with

- changelog preservation workflow - rebase.wf.md
- creating pr - create-pr.wf.md  (new)
- squash pr - squash-pr.wf.md (auto squash and reduce number of commits, one per version)

## Behavioral Specification

### User Experience

**Input**: Developer needs guidance for rebasing while preserving changelog entries and version files
**Process**: Developer follows workflow instructions provided by the ace-git-rebase package
**Output**: Successfully rebased branch with intact changelog entries and consistent version references

### Expected Behavior

- Developers install the ace-git-rebase gem to access workflow instructions
- The workflow guide provides step-by-step instructions for rebase operations
- Clear patterns for resolving changelog and version file conflicts
- Configuration examples show how to customize rebase behavior
- The package integrates with Claude Code through handbook/workflow-instructions/

### Interface Contract

#### Package Structure

```
ace-git-rebase/
├── .ace.example/git/rebase.yml          # Configuration example
├── lib/ace/git_rebase/version.rb        # VERSION constant
├── handbook/workflow-instructions/      # Workflow documentation
│   └── rebase-preserve-changelog.wf.md  # Main workflow
├── ace-git-rebase.gemspec               # Gem specification
├── CHANGELOG.md                         # Keep a Changelog format
└── README.md                            # Package documentation
```

**Configuration Interface (.ace/git/rebase.yml):**

```yaml
git:
  rebase:
    preserve_files:        # Files to protect during rebase
      - CHANGELOG.md
      - "**/version.rb"
    auto_resolve: manual   # Conflict resolution strategy
    verbose: false         # Output verbosity
```

**Workflow Access:**

- Via gem installation: `gem install ace-git-rebase`
- Via Claude Code: Workflow available through handbook integration
- No executable binary (workflow-first approach)

### Success Criteria

- [ ] ace-git-rebase gem package created with minimal structure
- [ ] Workflow instruction provides comprehensive rebase guidance
- [ ] Configuration example demonstrates customization patterns
- [ ] Package follows ace-gems.g.md standards (CHANGELOG.md, version.rb, etc.)
- [ ] Handbook integration enables Claude Code workflow access
- [ ] No unnecessary Ruby implementation (workflow-focused)

### Validation Questions

- Should the package name be `ace-git-rebase` or just `ace-git`?
- Do we need any Ruby helper methods or pure documentation?
- Should we include multiple workflow variants (interactive, automated)?
- How should the workflow reference existing tools (ace-git-diff, ace-git-commit)?

## Objective

Create a minimal, workflow-first ace-git-rebase gem package that provides comprehensive guidance for rebasing operations while preserving changelog entries and version consistency, following the ace-gems standard structure.

## Scope of Work

### Package Creation Scope

- Minimal gem structure per ace-gems.g.md
- Workflow instruction in handbook/workflow-instructions/
- Configuration examples in .ace.example/
- Proper versioning and changelog setup

### Workflow Documentation Scope

- Pre-rebase verification steps
- Conflict resolution patterns for CHANGELOG.md
- Version file conflict handling strategies
- Post-rebase validation procedures
- Recovery and rollback guidance

### Integration Scope

- Claude Code handbook integration
- Configuration through ace-core cascade
- References to related ace-git-* packages

## Deliverables

### Package Components

- ace-git-rebase.gemspec with minimal dependencies
- lib/ace/git_rebase/version.rb with VERSION constant
- handbook/workflow-instructions/rebase-preserve-changelog.wf.md
- .ace.example/git/rebase.yml configuration template
- CHANGELOG.md in Keep a Changelog format
- README.md with installation and usage guide
- Rakefile for gem tasks (no tests needed)
- LICENSE file (MIT)

### Workflow Content

- Complete rebase procedure with changelog focus
- Conflict resolution decision trees
- Example scenarios and solutions
- Integration points with git commands
- Recovery procedures for failed rebases

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
- Related: ace-git-commit package structure
- Related: ace-git-diff package for command execution patterns
- Related: Keep a Changelog specification
- Related: Semantic Versioning specification

