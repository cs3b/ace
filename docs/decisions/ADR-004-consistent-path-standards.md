# ADR-004: Consistent Path Standards for Document Embedding

## Status

Accepted - Evolved to Gem Handbook Pattern (see ADR-016)
Date: 2025-06-30
Evolution: October 2025

## Context

The current document embedding system uses inconsistent path references across workflow instructions. Analysis reveals:

1. **Template Duplication**: Some templates are referenced 3 times (`task.template.md`) and 2 times (`blueprint.template.md`)
2. **Path Inconsistency**: While most paths are relative to project root, there's no enforced standard
3. **Mixed Path Types**: Some workflows might use absolute paths or inconsistent relative paths
4. **Maintenance Burden**: Path inconsistencies make automation and validation difficult

Current template embedding uses paths like:

- `dev-handbook/templates/release-tasks/task.template.md`
- `dev-handbook/templates/project-docs/blueprint.template.md`

## Decision

We will establish and enforce consistent path standards for all document embedding:

### Path Standards

1. **Always Relative to Project Root**: All document paths must be relative to the project root directory
2. **Consistent Path Format**: Paths must follow the pattern:
   - Templates: `dev-handbook/templates/**/*.template.md`
   - Guides: `dev-handbook/guides/**/*.g.md`
3. **No Absolute Paths**: Absolute paths are prohibited in document embedding
4. **Consistent Separator**: Use forward slashes (`/`) as path separators regardless of operating system

### Validation Rules

1. **Template Validation**: Template paths must start with `dev-handbook/templates/` and end with `.template.md`
2. **Guide Validation**: Guide paths must start with `dev-handbook/guides/` and end with `.g.md`
3. **Path Existence**: All referenced paths must exist in the filesystem
4. **No Duplication**: Each document should be referenced only once across all workflows

### Implementation

1. **Sync Script Updates**: Modify validation logic to enforce these standards
2. **Migration**: Update all existing workflows to use consistent paths
3. **Documentation**: Update developer guidelines to specify path standards
4. **Automation**: Implement linting rules to catch path violations

## Consequences

### Positive

1. **Predictability**: Developers and automation tools can rely on consistent path formats
2. **Maintainability**: Easier to refactor directory structures with consistent paths
3. **Validation**: Automated validation can catch path errors early
4. **Clarity**: Clear distinction between templates and guides based on path patterns

### Negative

1. **Migration Effort**: Existing workflows may need path updates
2. **Breaking Changes**: Workflows with non-standard paths will require updates
3. **Enforcement Overhead**: Need to maintain validation rules and documentation

### Neutral

1. **Learning Curve**: Developers need to learn and follow path standards
2. **Tool Updates**: Sync scripts and validation tools need updates

## Alternatives Considered

### Alternative 1: Maintain Current Inconsistency

- **Pros**: No migration effort required
- **Cons**: Continued maintenance burden, unpredictable behavior

### Alternative 2: Use Absolute Paths

- **Pros**: Unambiguous path references
- **Cons**: Brittle to directory structure changes, not portable

### Alternative 3: Environment-Relative Paths

- **Pros**: Flexible for different environments
- **Cons**: Complex to implement, inconsistent behavior

## Implementation Notes

### Sync Script Changes Required

```ruby
def validate_template_path(path)
  unless path.start_with?("dev-handbook/templates/") && path.end_with?(".template.md")
    raise "Invalid template path: #{path}. Must start with 'dev-handbook/templates/' and end with '.template.md'"
  end
end

def validate_guide_path(path)
  unless path.start_with?("dev-handbook/guides/") && path.end_with?(".g.md")
    raise "Invalid guide path: #{path}. Must start with 'dev-handbook/guides/' and end with '.g.md'"
  end
end
```

### Migration Checklist

1. Audit all existing workflow files for path consistency
2. Update any non-conforming paths
3. Test sync script with updated validation
4. Update documentation and guidelines
5. Implement automated checks in CI/CD pipeline

## References

- [ADR-002: XML Template Embedding Architecture](./ADR-002-xml-template-embedding-architecture.md)
- [ADR-003: Template Directory Separation](./ADR-003-template-directory-separation.md)
- Task 40: Implement Universal Document Embedding System

## Evolution: Gem Handbook Pattern (October 2025)

### Current State

The original path standards focused on `dev-handbook/templates/` and `dev-handbook/guides/` have evolved with the mono-repo migration (ADR-015) into a **gem-specific handbook pattern**:

```
ace-gem/
└── handbook/
    ├── agents/                        # .ag.md files
    │   └── process.ag.md
    └── workflow-instructions/          # .wf.md files
        └── your-workflow.wf.md
```

### Key Path Pattern Changes

1. **From Central to Distributed**:
   - Old: `dev-handbook/templates/**/*.template.md`
   - New: `ace-gem/handbook/workflow-instructions/**/*.wf.md`

2. **From Templates to Workflows**:
   - Old: Simple templates embedded in workflows
   - New: Self-contained workflows with embedded templates (ADR-001)

3. **New Agent Pattern**:
   - Format: `ace-gem/handbook/agents/**/*.ag.md`
   - Purpose: Single-purpose, composable agents

4. **Integration Symlinks**:
   - Pattern: `.claude/agents/` → `gem/handbook/agents/`
   - Purpose: Claude Code integration

### Current Path Standards (October 2025)

**For Gem Development:**
- Workflows: `{gem-name}/handbook/workflow-instructions/*.wf.md`
- Agents: `{gem-name}/handbook/agents/*.ag.md`
- Integration: `.claude/agents/{agent-name}.ag.md` (symlink)

**For Discovery:**
- Protocol: `wfi://{namespace}/{action}` via ace-nav
- Command: `ace-nav wfi://docs/update`

**Path Validation:**
```ruby
# Current validation (per gem)
def validate_workflow_path(path)
  unless path.match?(%r{^[\w-]+/handbook/workflow-instructions/[\w-]+/[\w-]+\.wf\.md$})
    raise "Invalid workflow path: #{path}"
  end
end

def validate_agent_path(path)
  unless path.match?(%r{^[\w-]+/handbook/agents/[\w-]+\.ag\.md$})
    raise "Invalid agent path: #{path}"
  end
end
```

### Relationship to Original Decision

The **principles remain valid**:
- ✅ Always relative to project root
- ✅ Consistent path format per document type
- ✅ No absolute paths
- ✅ Automated validation

The **implementation evolved**:
- From: Central `dev-handbook/templates/` with `.template.md`
- To: Distributed `gem/handbook/` with `.wf.md` and `.ag.md`
- Reason: Better modularity, gem-specific workflows, installable patterns

### Examples in Production

**ace-docs paths:**
```
ace-docs/handbook/workflow-instructions/update-docs.wf.md
.claude/agents/update-docs.ag.md → ace-docs/handbook/agents/update-docs.ag.md
```

**ace-task paths:**
```
ace-task/handbook/workflow-instructions/draft-task.wf.md
ace-task/handbook/agents/task-finder.ag.md
```

See **ADR-016: Handbook Directory Architecture** for complete details of current pattern.
