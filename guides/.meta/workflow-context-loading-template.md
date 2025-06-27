# Workflow Context Loading Template

This template provides a standardized approach for loading project context at the beginning of AI workflow
instructions. It ensures all workflows have access to essential project information before execution begins.

## Standard Project Context Loading Section

Include this section near the top of your workflow file, after "Prerequisites" and before "Process Steps":

```markdown
## Project Context Loading

### Core Project Documents
* Load project objectives: `docs/what-do-we-build.md`
* Load architecture overview: `docs/architecture.md`
* Load project structure: `docs/blueprint.md`

### Workflow-Specific Context
<!-- Customize this section based on your workflow needs -->

**For Task-Based Workflows:**
* Load current release context: `bin/rc`
* Review task management structure: `dev-taskflow/current/*/`
* Check task dependencies and format requirements

**For Code Implementation Workflows:**
* Review coding standards: `dev-handbook/guides/coding-standards.g.md`
* Load language-specific guidelines: `dev-handbook/guides/coding-standards/{language}.md`
* Check test framework configuration: `spec/` or relevant test directory

**For Documentation Workflows:**
* Review documentation standards: `dev-handbook/guides/documentation.g.md`
* Load documentation guidelines: `dev-handbook/guides/documentation/{language}.md`
* Check existing documentation structure and patterns

**For Release/Deployment Workflows:**
* Review release guidelines: `dev-handbook/guides/release-publish.g.md`
* Load deployment procedures: `dev-handbook/guides/release-publish/{language}.md`
* Check version management and changelog patterns

**For Quality Assurance Workflows:**
* Review QA standards: `dev-handbook/guides/quality-assurance.g.md`
* Load testing guidelines: `dev-handbook/guides/testing.g.md`
* Check project-specific test configurations and patterns
```

## Context Loading Commands

### Discovery Commands

Use these commands to understand the project state before beginning work:

```bash
# Find current release directory
ls -1 dev-taskflow/current/

# View project structure
bin/tree

# Check git status
git status

# Review recent activity
bin/tr

# Get current release info
bin/rc
```

### Validation Commands

Use these commands to ensure the environment is ready:

```bash
# Verify project dependencies
bundle check  # For Ruby projects
npm ci        # For Node.js projects

# Run quick validation
bin/test --quick  # If available

# Check linting status
bin/lint --check  # If available
```

## Customization Guidelines

### For Different Project Types

**Ruby Gem Projects:**

```markdown
### Ruby Gem Context
* Review gem specification: `*.gemspec`
* Check Ruby version requirements: `.ruby-version` or `Gemfile`
* Load gem-specific patterns: `dev-handbook/guides/coding-standards/ruby.md`
* Review test setup: `spec/spec_helper.rb`
```

**Web Application Projects:**

```markdown
### Web Application Context
* Review application configuration: `config/` directory
* Check environment setup: `.env.example` or environment documentation
* Load framework-specific guidelines: `dev-handbook/guides/coding-standards/{framework}.md`
* Review API documentation: `docs/api/` or similar
```

**CLI Tool Projects:**

```markdown
### CLI Tool Context
* Review command structure: `bin/` directory
* Check CLI framework configuration
* Load CLI-specific patterns and conventions
* Review help text and documentation standards
```

### Environment-Specific Context

**Development Environment:**
```markdown
### Development Context
* Verify development dependencies: `Gemfile` (Ruby), `package.json` (Node.js)
* Check local configuration: `.env.development` or similar
* Review development-specific documentation
* Validate development tools setup
```

**Testing Environment:**
```markdown
### Testing Context
* Review test configuration: `spec/`, `test/`, or relevant directory
* Check test data setup: `fixtures/`, `factories/`, or similar
* Load testing guidelines: `dev-handbook/guides/testing/{language}.md`
* Verify test dependencies and setup
```

**Production Environment:**
```markdown
### Production Context
* Review deployment configuration
* Check production-specific documentation
* Load security guidelines: `dev-handbook/guides/security/{language}.md`
* Review monitoring and logging setup
```

## Cross-Workflow References

### Removing Cross-Workflow Dependencies

When creating standalone workflows, ensure they don't rely on other workflows by:

1. **Embedding Required Information**: Instead of referencing other workflows, include essential information directly
2. **Using Direct File References**: Reference specific files or sections rather than other workflow files
3. **Including Self-Contained Instructions**: Provide complete setup and execution instructions within the workflow

**Example - Instead of:**

```markdown
<!-- DON'T DO THIS -->
* Follow the setup from `setup-environment.wf.md`
* Use the validation from `validate-project.wf.md`
```

**Do this:**

```markdown
<!-- DO THIS -->
* Setup environment:

  ```bash
  bundle install
  npm ci
  ```

* Validate project:

  ```bash
  bin/test --validate
  bin/lint --check
  ```
```

### Template Application Example

```markdown
## Project Context Loading

### Core Project Documents
* Load project objectives: `docs/what-do-we-build.md`
* Load architecture overview: `docs/architecture.md`
* Load project structure: `docs/blueprint.md`

### Ruby Gem Context
* Review gem specification: `coding_agent_tools.gemspec`
* Check Ruby version requirements: `.ruby-version`
* Load Ruby coding standards: `dev-handbook/guides/coding-standards/ruby.md`
* Review RSpec configuration: `spec/spec_helper.rb`

### Current Development Context
* Load current release context: `bin/rc`
* Review active tasks: `dev-taskflow/current/*/tasks/`
* Check recent development activity: `bin/tr`
* Validate development environment:
  ```bash
  bundle check
  bin/test --quick
  ```
```

## Quality Checklist

Before using this template:
- [ ] All file paths are valid for your project
- [ ] Commands work in your project environment
- [ ] Context loading is relevant to your workflow type
- [ ] No cross-workflow dependencies are introduced
- [ ] All referenced documentation exists
- [ ] Environment validation commands are appropriate

## Integration with Execution Template

This context loading template should be used together with the workflow execution template:

1. **Add Prerequisites section** (workflow-specific)
2. **Include this Context Loading section**
3. **Follow with the 7-step Process Steps** from the execution template
4. **Complete with workflow-specific sections** (Error Recovery, Usage Examples, etc.)

## References

- Derived from `work-on-task.wf.md` Project Context Loading section
- Aligned with project documentation structure in `docs/blueprint.md`
- Supports the standardized workflow execution pattern
