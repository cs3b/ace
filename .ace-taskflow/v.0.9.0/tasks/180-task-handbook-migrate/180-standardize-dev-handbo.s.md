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

### Phase 1: Workflow-Instructions Migration

**Already migrated to ace-handbook** (6 files):
- [x] manage-agents.wf.md → ace-handbook
- [x] manage-guides.wf.md → ace-handbook
- [x] manage-workflow-instructions.wf.md → ace-handbook
- [x] review-guides.wf.md → ace-handbook
- [x] review-workflows.wf.md → ace-handbook
- [x] update-handbook-docs.wf.md → ace-handbook

**Already migrated to other packages** (10 files):
- [x] update-integration-claude.wf.md → ace-integration-claude
- [x] update-tools-docs.wf.md → ace-docs

**From dev-handbook/workflow-instructions/** (17 files - 14 MIGRATED, 3 remaining):
| File | Status | Location |
|------|--------|----------|
| capture-application-features.wf.md | [x] migrated | ace-taskflow |
| create-adr.wf.md | [x] migrated | ace-docs |
| create-api-docs.wf.md | [x] migrated | ace-docs |
| create-cookbook.wf.md | [x] migrated | ace-docs |
| create-test-cases.wf.md | [x] migrated | ace-taskflow |
| create-user-docs.wf.md | [x] migrated | ace-docs |
| document-unplanned-work.wf.md | [x] migrated | ace-taskflow |
| fix-linting-issue-from.wf.md | [ ] NOT MIGRATED | suggest: ace-lint |
| fix-tests.wf.md | [x] migrated | ace-taskflow |
| improve-code-coverage.wf.md | [x] migrated | ace-taskflow |
| load-project-context.wf.md | [x] migrated | ace-context (as load-context.wf.md) |
| prioritize-align-ideas.wf.md | [x] migrated | ace-taskflow |
| rebase-against.wf.md | [x] migrated | ace-git (as rebase.wf.md) |
| save-session-context.wf.md | [ ] NOT MIGRATED | suggest: skip (obsolete?) |
| synthesize-reviews.wf.md | [ ] NOT MIGRATED | suggest: ace-review |
| update-blueprint.wf.md | [x] migrated | ace-docs |
| update-context-docs.wf.md | [x] migrated | ace-docs |

**From dev-handbook/.integrations/wfi/** (1 file - NOT MIGRATED):
| File | Status | Location |
|------|--------|----------|
| initialize-project-structure.wf.md | [ ] NOT MIGRATED | suggest: ace-handbook |

**Summary**: 22/26 workflows migrated (85%), 4 remaining

### Phase 2: Guides Migration

**Already migrated to ace-handbook** (1 file):
- [x] workflow-context-embedding.g.md → ace-handbook

**From dev-handbook/guides/** (26 files - 0 MIGRATED, all remaining):
| File | Status | Suggested Target |
|------|--------|------------------|
| ai-agent-integration.g.md | [ ] NOT MIGRATED | ace-handbook |
| atom-pattern.g.md | [ ] NOT MIGRATED | ace-handbook |
| changelog.g.md | [ ] NOT MIGRATED | ace-handbook |
| code-review-process.g.md | [ ] NOT MIGRATED | ace-review |
| coding-standards.g.md | [ ] NOT MIGRATED | ace-handbook |
| debug-troubleshooting.g.md | [ ] NOT MIGRATED | ace-handbook |
| documentation.g.md | [ ] NOT MIGRATED | ace-docs |
| documents-embedded-sync.g.md | [ ] NOT MIGRATED | ace-docs |
| documents-embedding.g.md | [ ] NOT MIGRATED | ace-docs |
| embedded-testing-guide.g.md | [ ] NOT MIGRATED | ace-docs |
| error-handling.g.md | [ ] NOT MIGRATED | ace-handbook |
| llm-query-tool-reference.g.md | [ ] NOT MIGRATED | ace-llm |
| performance.g.md | [ ] NOT MIGRATED | ace-handbook |
| project-management.g.md | [ ] NOT MIGRATED | ace-taskflow |
| quality-assurance.g.md | [ ] NOT MIGRATED | ace-handbook |
| release-codenames.g.md | [ ] NOT MIGRATED | ace-taskflow |
| release-publish.g.md | [ ] NOT MIGRATED | ace-taskflow |
| roadmap-definition.g.md | [ ] NOT MIGRATED | ace-taskflow |
| security.g.md | [ ] NOT MIGRATED | ace-git-secrets |
| strategic-planning.g.md | [ ] NOT MIGRATED | ace-handbook |
| task-definition.g.md | [ ] NOT MIGRATED | ace-taskflow |
| temporary-file-management.g.md | [ ] NOT MIGRATED | skip (obsolete?) |
| testing-tdd-cycle.g.md | [ ] NOT MIGRATED | ace-test-runner |
| testing.g.md | [ ] NOT MIGRATED | ace-test-runner |
| version-control-system-git.g.md | [ ] NOT MIGRATED | ace-git |
| version-control-system-message.g.md | [ ] NOT MIGRATED | ace-git-commit |

**From dev-handbook/.meta/gds/** (5 meta-guides - definition files):
| File | Status | Notes |
|------|--------|-------|
| agents-definition.g.md | [ ] NOT MIGRATED | meta: ace-handbook |
| guides-definition.g.md | [ ] NOT MIGRATED | meta: ace-handbook |
| markdown-definition.g.md | [ ] NOT MIGRATED | meta: ace-handbook |
| tools-definition.g.md | [ ] NOT MIGRATED | meta: ace-handbook |
| workflow-instructions-definition.g.md | [ ] NOT MIGRATED | meta: ace-handbook |

**Summary**: 1/32 guides migrated (3%), 31 remaining

### Phase 3: Agents Migration

**Already migrated to ace-* packages** (5 agents across packages):
- [x] search.ag.md → ace-search
- [x] research.ag.md → ace-search
- [x] security-audit.ag.md → ace-git-secrets
- [x] worktree.ag.md → ace-git-worktree
- [x] timestamp.ag.md → ace-timestamp

**From dev-handbook/.integrations/claude/agents/** (12 files - 1 migrated, 5 skip, 6 remaining):
| File | Status | Suggested Target |
|------|--------|------------------|
| cms-componentizer.ag.md | [x] skip | project-specific (CMS) |
| cms-field-verifier.ag.md | [x] skip | project-specific (CMS) |
| cms-page-designer.ag.md | [x] skip | project-specific (CMS) |
| cms-page-populator.ag.md | [x] skip | project-specific (CMS) |
| create-path.ag.md | [x] skip | legacy/obsolete |
| feature-research.ag.md | [ ] NOT MIGRATED | ace-search (merge with research.ag.md?) |
| git-commit.ag.md | [ ] NOT MIGRATED | ace-git-commit |
| lint-files.ag.md | [ ] NOT MIGRATED | ace-lint |
| release-navigator.ag.md | [ ] NOT MIGRATED | ace-taskflow |
| search.ag.md | [x] migrated | ace-search (already done) |
| task-creator.ag.md | [ ] NOT MIGRATED | ace-taskflow |
| task-finder.ag.md | [ ] NOT MIGRATED | ace-taskflow |

**.claude/agents/ symlinks** (integration layer):
- [x] search.ag.md → ace-search/handbook/agents/search.ag.md
- [x] research.ag.md → ace-search/handbook/agents/research.ag.md

**Summary**: 6/12 dev-handbook agents handled (1 migrated, 5 skip), 6 remaining for migration

### Phase 4: Templates Migration

**Already migrated to ace-* packages** (partial):
- [x] ace-git/handbook/templates/commit/squash.template.md
- [x] ace-git/handbook/templates/pr/default.template.md
- [x] ace-git/handbook/templates/pr/bugfix.template.md
- [x] ace-git/handbook/templates/pr/feature.template.md
- [x] ace-prompt/handbook/templates/the-prompt-base.template.md
- [x] ace-prompt/handbook/templates/the-prompt-bug.template.md
- [x] ace-taskflow/templates/idea_enhancement.system.md

**From dev-handbook/templates/** (25 directories - mostly NOT MIGRATED):
| Directory | Status | Suggested Target |
|-----------|--------|------------------|
| binstubs/ | [ ] NOT MIGRATED | skip (mono-repo specific) |
| code-docs/ | [ ] NOT MIGRATED | ace-docs |
| commit/ | [x] partial | ace-git (squash done) |
| completed-work-documentation.md | [ ] NOT MIGRATED | ace-taskflow |
| context/ | [ ] NOT MIGRATED | ace-context |
| cookbooks/ | [ ] NOT MIGRATED | ace-docs |
| idea-manager/ | [ ] NOT MIGRATED | ace-taskflow |
| project-docs/ | [ ] NOT MIGRATED | ace-docs |
| prompts/ | [x] partial | ace-prompt (base, bug done) |
| release-codemods/ | [ ] NOT MIGRATED | ace-taskflow |
| release-docs/ | [ ] NOT MIGRATED | ace-taskflow |
| release-management/ | [ ] NOT MIGRATED | ace-taskflow |
| release-planning/ | [ ] NOT MIGRATED | ace-taskflow |
| release-reflections/ | [ ] NOT MIGRATED | ace-taskflow |
| release-research/ | [ ] NOT MIGRATED | ace-taskflow |
| release-tasks/ | [ ] NOT MIGRATED | ace-taskflow |
| release-testing/ | [ ] NOT MIGRATED | ace-taskflow |
| release-ux/ | [ ] NOT MIGRATED | ace-taskflow |
| review-agents/ | [ ] NOT MIGRATED | ace-review |
| review-modules/ | [ ] NOT MIGRATED | ace-review |
| review-tasks/ | [ ] NOT MIGRATED | ace-review |
| session-management/ | [ ] NOT MIGRATED | skip (obsolete?) |
| task-management/ | [ ] NOT MIGRATED | ace-taskflow |
| tasks/ | [ ] NOT MIGRATED | ace-taskflow |
| user-docs/ | [ ] NOT MIGRATED | ace-docs |

**Summary**: 2/25 template dirs partially migrated, 23 remaining

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
