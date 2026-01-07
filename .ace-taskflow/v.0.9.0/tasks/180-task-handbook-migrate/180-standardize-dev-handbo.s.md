---
id: v.0.9.0+task.180
status: draft
priority: medium
estimate: 8-16h
dependencies: []
---

# Migrate and Standardize dev-handbook Content to ace-handbook Gem

## Behavioral Specification

### User Experience
- **Input**: All dev-handbook content (workflows, guides, agents, templates)
- **Process**: Systematic migration with path updates and ace-nav registration
- **Output**: Complete ace-handbook gem with all content discoverable via protocols

### Expected Behavior

After migration, all dev-handbook content becomes available through the ace-handbook gem:
- Workflows discoverable via `wfi://` protocol
- Guides discoverable via `guide://` protocol
- Agents discoverable via `agent://` protocol (new)
- Templates available in gem distribution

The dev-handbook directory is archived to `_legacy/` and all references updated.

### Interface Contract

```bash
# After migration, all content discoverable via ace-nav
ace-nav wfi://create-adr --list     # finds ace-handbook/handbook/workflow-instructions/
ace-nav guide://testing --list       # finds ace-handbook/handbook/guides/
ace-nav agent://search --list        # finds ace-handbook/handbook/agents/

# gem install behavior
gem install ace-handbook
# Includes: all workflows, guides, agents, templates for AI-assisted development
```

### Success Criteria

- [ ] All approved workflows migrated to ace-handbook
- [ ] All approved guides migrated to ace-handbook
- [ ] All approved agents migrated to ace-handbook
- [ ] All approved templates migrated to ace-handbook
- [ ] ace-nav discovery works for all migrated content
- [ ] .claude/ symlinks updated to point to ace-handbook
- [ ] docs/blueprint.md and architecture.md updated
- [ ] ace-handbook version bumped to 0.5.0
- [ ] dev-handbook archived to _legacy/

## Objective

Finalize the ace-handbook gem by migrating all remaining content from dev-handbook, enabling `gem install ace-handbook` to provide complete AI-assisted development capabilities. This eliminates the legacy dev-handbook directory and centralizes all workflows, guides, agents, and templates in a distributable gem.

## Scope of Work

### Phase 1: Workflow-Instructions Migration (17 files)

**Already in ace-handbook** (6 files - no action needed):
- [x] manage-agents.wf.md
- [x] manage-guides.wf.md
- [x] manage-workflow-instructions.wf.md
- [x] review-guides.wf.md
- [x] review-workflows.wf.md
- [x] update-handbook-docs.wf.md

**To migrate from dev-handbook** (17 files):
| File | Decision | Notes |
|------|----------|-------|
| capture-application-features.wf.md | [ ] migrate / skip / move-to: | Feature discovery |
| create-adr.wf.md | [ ] migrate / skip / move-to: | ADR creation |
| create-api-docs.wf.md | [ ] migrate / skip / move-to: | API documentation |
| create-cookbook.wf.md | [ ] migrate / skip / move-to: | Cookbook creation |
| create-test-cases.wf.md | [ ] migrate / skip / move-to: | Test case generation |
| create-user-docs.wf.md | [ ] migrate / skip / move-to: | User documentation |
| document-unplanned-work.wf.md | [ ] migrate / skip / move-to: | Unplanned work tracking |
| fix-linting-issue-from.wf.md | [ ] migrate / skip / move-to: | Lint fix workflow |
| fix-tests.wf.md | [ ] migrate / skip / move-to: | Test fix workflow |
| improve-code-coverage.wf.md | [ ] migrate / skip / move-to: | Coverage improvement |
| load-project-context.wf.md | [ ] migrate / skip / move-to: | Context loading |
| prioritize-align-ideas.wf.md | [ ] migrate / skip / move-to: | Idea prioritization |
| rebase-against.wf.md | [ ] migrate / skip / move-to: | Git rebase workflow |
| save-session-context.wf.md | [ ] migrate / skip / move-to: | Session management |
| synthesize-reviews.wf.md | [ ] migrate / skip / move-to: | Review synthesis |
| update-blueprint.wf.md | [ ] migrate / skip / move-to: | Blueprint updates |
| update-context-docs.wf.md | [ ] migrate / skip / move-to: | Context doc updates |

### Phase 2: Guides Migration (26 files)

**Already in ace-handbook** (1 file - no action needed):
- [x] workflow-context-embedding.g.md

**To migrate from dev-handbook** (26 files):
| File | Decision | Notes |
|------|----------|-------|
| ai-agent-integration.g.md | [ ] migrate / skip / move-to: | AI integration patterns |
| atom-pattern.g.md | [ ] migrate / skip / move-to: | ATOM architecture |
| changelog.g.md | [ ] migrate / skip / move-to: | Changelog format |
| code-review-process.g.md | [ ] migrate / skip / move-to: | Code review |
| coding-standards.g.md | [ ] migrate / skip / move-to: | Coding standards |
| debug-troubleshooting.g.md | [ ] migrate / skip / move-to: | Debugging |
| documentation.g.md | [ ] migrate / skip / move-to: | Documentation standards |
| documents-embedded-sync.g.md | [ ] migrate / skip / move-to: | Doc sync |
| documents-embedding.g.md | [ ] migrate / skip / move-to: | Doc embedding |
| embedded-testing-guide.g.md | [ ] migrate / skip / move-to: | Testing embedded docs |
| error-handling.g.md | [ ] migrate / skip / move-to: | Error handling |
| llm-query-tool-reference.g.md | [ ] migrate / skip / move-to: | LLM tool reference |
| performance.g.md | [ ] migrate / skip / move-to: | Performance |
| project-management.g.md | [ ] migrate / skip / move-to: | Project mgmt |
| quality-assurance.g.md | [ ] migrate / skip / move-to: | QA |
| release-codenames.g.md | [ ] migrate / skip / move-to: | Release codenames |
| release-publish.g.md | [ ] migrate / skip / move-to: | Release publishing |
| roadmap-definition.g.md | [ ] migrate / skip / move-to: | Roadmap |
| security.g.md | [ ] migrate / skip / move-to: | Security |
| strategic-planning.g.md | [ ] migrate / skip / move-to: | Strategic planning |
| task-definition.g.md | [ ] migrate / skip / move-to: | Task definition |
| temporary-file-management.g.md | [ ] migrate / skip / move-to: | Temp files |
| testing-tdd-cycle.g.md | [ ] migrate / skip / move-to: | TDD cycle |
| testing.g.md | [ ] migrate / skip / move-to: | Testing |
| version-control-system-git.g.md | [ ] migrate / skip / move-to: | Git VCS |
| version-control-system-message.g.md | [ ] migrate / skip / move-to: | Commit messages |

### Phase 3: Agents Migration (12 files)

**To migrate from dev-handbook/.integrations/claude/agents/**:
| File | Decision | Notes |
|------|----------|-------|
| cms-componentizer.ag.md | [ ] migrate / skip / move-to: | CMS component |
| cms-field-verifier.ag.md | [ ] migrate / skip / move-to: | CMS fields |
| cms-page-designer.ag.md | [ ] migrate / skip / move-to: | CMS pages |
| cms-page-populator.ag.md | [ ] migrate / skip / move-to: | CMS population |
| create-path.ag.md | [ ] migrate / skip / move-to: | Path creation |
| feature-research.ag.md | [ ] migrate / skip / move-to: | Feature research |
| git-commit.ag.md | [ ] migrate / skip / move-to: | Git commits |
| lint-files.ag.md | [ ] migrate / skip / move-to: | Linting |
| release-navigator.ag.md | [ ] migrate / skip / move-to: | Release navigation |
| search.ag.md | [ ] migrate / skip / move-to: | Search |
| task-creator.ag.md | [ ] migrate / skip / move-to: | Task creation |
| task-finder.ag.md | [ ] migrate / skip / move-to: | Task finding |

### Phase 4: Templates Migration (25 directories)

**To migrate from dev-handbook/templates/**:
| Directory | Decision | Notes |
|-----------|----------|-------|
| binstubs/ | [ ] migrate / skip / move-to: | Binstub templates |
| code-docs/ | [ ] migrate / skip / move-to: | Code documentation |
| commit/ | [ ] migrate / skip / move-to: | Commit templates |
| completed-work-documentation.md | [ ] migrate / skip / move-to: | Completion docs |
| context/ | [ ] migrate / skip / move-to: | Context templates |
| cookbooks/ | [ ] migrate / skip / move-to: | Cookbook templates |
| idea-manager/ | [ ] migrate / skip / move-to: | Idea management |
| project-docs/ | [ ] migrate / skip / move-to: | Project docs |
| prompts/ | [ ] migrate / skip / move-to: | Prompt templates |
| release-codemods/ | [ ] migrate / skip / move-to: | Release codemods |
| release-docs/ | [ ] migrate / skip / move-to: | Release docs |
| release-management/ | [ ] migrate / skip / move-to: | Release mgmt |
| release-planning/ | [ ] migrate / skip / move-to: | Release planning |
| release-reflections/ | [ ] migrate / skip / move-to: | Retrospectives |
| release-research/ | [ ] migrate / skip / move-to: | Release research |
| release-tasks/ | [ ] migrate / skip / move-to: | Release tasks |
| release-testing/ | [ ] migrate / skip / move-to: | Release testing |
| release-ux/ | [ ] migrate / skip / move-to: | Release UX |
| review-agents/ | [ ] migrate / skip / move-to: | Review agents |
| review-modules/ | [ ] migrate / skip / move-to: | Review modules |
| review-tasks/ | [ ] migrate / skip / move-to: | Review tasks |
| session-management/ | [ ] migrate / skip / move-to: | Session mgmt |
| task-management/ | [ ] migrate / skip / move-to: | Task mgmt |
| tasks/ | [ ] migrate / skip / move-to: | Task templates |
| user-docs/ | [ ] migrate / skip / move-to: | User docs |

### Phase 5: Integration Updates

- [ ] Add agent-sources protocol config to ace-handbook/.ace-defaults/
- [ ] Update .claude/ symlinks to point to ace-handbook
- [ ] Update docs/blueprint.md (deprecate dev-handbook)
- [ ] Update docs/architecture.md (ace-handbook as source)
- [ ] Update ace-handbook/ace-handbook.gemspec (include new dirs)
- [ ] Bump ace-handbook version to 0.5.0
- [ ] Update ace-handbook/CHANGELOG.md

### Phase 6: Archive & Cleanup

- [ ] Move dev-handbook/ to _legacy/dev-handbook/
- [ ] Verify all wfi://, guide://, agent:// protocols work
- [ ] Run tests to ensure no breakage

## Out of Scope

- Modifying content of workflows/guides (only path changes)
- Creating new workflows or guides
- Changes to other ace-* gems

## References

- Source idea: `.ace-taskflow/v.0.9.0/ideas/_archive/8o2utp-handbook-chore/`
- ace-handbook gem: `ace-handbook/`
- dev-handbook source: `dev-handbook/`
- ADR-001: Workflow Self-Containment Principle
- docs/ace-gems.g.md: ace-integration-* pattern
