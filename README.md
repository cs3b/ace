# Development Handbook (`dev-handbook`)

Standardized development guides, workflow instructions, and templates for AI-assisted development systems. Designed to be integrated as a Git submodule.

## Quick Start

```sh
git submodule add <repository-url> dev-handbook
git submodule update --init --recursive
```

## Structure

- **`guides/`** - Development best practices and standards
- **`workflow-instructions/`** - Step-by-step AI agent workflows
- **`templates/`** - Project and documentation templates
- **`.integrations/`** - AI assistant configurations (agents, commands)
- **`dev-taskflow/`** - Task management (backlog → current → done)
- **`dev-tools/`** - CLI utilities for LLM integration and automation

## Development Guides

### Core Process & Meta
- [Project Management](./guides/project-management.g.md) | [Task Definition](./guides/task-definition.g.md) | [Strategic Planning](./guides/strategic-planning.g.md)
- [Roadmap Definition](./guides/roadmap-definition.g.md) | [Changelog](./guides/changelog.g.md) | [Release Codenames](./guides/release-codenames.g.md)
- [Documents Embedding](./guides/documents-embedding.g.md) | [Embedded Sync](./guides/documents-embedded-sync.g.md) | [Embedded Testing](./guides/embedded-testing-guide.g.md)
- [AI Agent Integration](./guides/ai-agent-integration.g.md) | [LLM Query Reference](./guides/llm-query-tool-reference.g.md) | [Temp File Management](./guides/temporary-file-management.g.md)

### Technical Standards
- [ATOM Pattern](./guides/atom-pattern.g.md) | [Code Review Process](./guides/code-review-process.g.md) | [Debug Troubleshooting](./guides/debug-troubleshooting.g.md)
- [Version Control Messages](./guides/version-control-system-message.g.md) | [Git Workflow](./guides/version-control-system-git.g.md)

### Language-Specific Guides
Each guide has Ruby, Rust, and TypeScript variants:
- **[Coding Standards](./guides/coding-standards.g.md)** ([Ruby](./guides/coding-standards/ruby.md) | [Rust](./guides/coding-standards/rust.md) | [TypeScript](./guides/coding-standards/typescript.md))
- **[Documentation](./guides/documentation.g.md)** ([Ruby](./guides/documentation/ruby.md) | [Rust](./guides/documentation/rust.md) | [TypeScript](./guides/documentation/typescript.md))
- **[Error Handling](./guides/error-handling.g.md)** ([Ruby](./guides/error-handling/ruby.md) | [Rust](./guides/error-handling/rust.md) | [TypeScript](./guides/error-handling/typescript.md))
- **[Performance](./guides/performance.g.md)** ([Ruby](./guides/performance/ruby.md) | [Rust](./guides/performance/rust.md) | [TypeScript](./guides/performance/typescript.md))
- **[Quality Assurance](./guides/quality-assurance.g.md)** ([Ruby](./guides/quality-assurance/ruby.md) | [Rust](./guides/quality-assurance/rust.md) | [TypeScript](./guides/quality-assurance/typescript.md))
- **[Security](./guides/security.g.md)** ([Ruby](./guides/security/ruby.md) | [Rust](./guides/security/rust.md) | [TypeScript](./guides/security/typescript.md))
- **[Troubleshooting](./guides/troubleshooting)** ([Ruby](./guides/troubleshooting/ruby.md) | [Rust](./guides/troubleshooting/rust.md) | [TypeScript](./guides/troubleshooting/typescript.md))
- **[Version Control](./guides/version-control)** ([Ruby](./guides/version-control/ruby.md) | [Rust](./guides/version-control/rust.md) | [TypeScript](./guides/version-control/typescript.md))

### Testing & TDD
- **[Testing Guidelines](./guides/testing.g.md)** | **[TDD Cycle](./guides/testing-tdd-cycle.g.md)**
- Platform-specific: [Ruby RSpec](./guides/testing/ruby-rspec.md) | [Rust](./guides/testing/rust.md) | [TypeScript Bun](./guides/testing/typescript-bun.md) | [Vue](./guides/testing/vue-vitest.md)
- TDD Templates: [Meta Docs](./guides/test-driven-development-cycle/meta-documentation.md) | [Ruby App](./guides/test-driven-development-cycle/ruby-application.md) | [Ruby Gem](./guides/test-driven-development-cycle/ruby-gem.md) | [Rust CLI](./guides/test-driven-development-cycle/rust-cli.md) | [TypeScript](./guides/test-driven-development-cycle/typescript-vue.md)

### Release Management
- **[Draft Release Templates](./guides/draft-release/README.md)** | **[Publish Process](./guides/release-publish.g.md)**
- Platform-specific: [Ruby](./guides/release-publish/ruby.md) | [Rust](./guides/release-publish/rust.md) | [TypeScript](./guides/release-publish/typescript.md)

## Workflow Instructions

### By Category

| Category | Key Workflows |
|----------|--------------|
| **Foundation** | [initialize-project-structure](./.integrations/wfi/initialize-project-structure.wf.md), [load-project-context](./workflow-instructions/load-project-context.wf.md) |
| **Tasks** | [capture-idea](./workflow-instructions/capture-idea.wf.md), [draft-task](./workflow-instructions/draft-task.wf.md), [plan-task](./workflow-instructions/plan-task.wf.md), [work-on-task](./workflow-instructions/work-on-task.wf.md) |
| **Quality** | [review-code](./workflow-instructions/review-code.wf.md), [fix-tests](./workflow-instructions/fix-tests.wf.md), [improve-code-coverage](./workflow-instructions/improve-code-coverage.wf.md) |
| **Release** | [draft-release](./workflow-instructions/draft-release.wf.md), [publish-release](./workflow-instructions/publish-release.wf.md), [update-context-docs](./workflow-instructions/update-context-docs.wf.md) |
| **Docs** | [create-adr](./workflow-instructions/create-adr.wf.md), [create-api-docs](./workflow-instructions/create-api-docs.wf.md), [create-user-docs](./workflow-instructions/create-user-docs.wf.md) |
| **Session** | [save-session-context](./workflow-instructions/save-session-context.wf.md), [create-reflection-note](./workflow-instructions/create-reflection-note.wf.md) |

### Common Sequences

| Scenario | Workflow Chain | Time |
|----------|---------------|------|
| New Project | `initialize` → `load-context` → `draft-release` | 2-4h |
| Feature | `draft-task` → `plan-task` → `work-on-task` → `review-code` | 4-16h |
| Bug Fix | `work-on-task` → `fix-tests` | 1-8h |
| Release | `synthesize-reviews` → `publish-release` → `update-context-docs` | 2-6h |

### All Workflows

**Task Management:** [capture-idea](./workflow-instructions/capture-idea.wf.md) | [draft-task](./workflow-instructions/draft-task.wf.md) | [plan-task](./workflow-instructions/plan-task.wf.md) | [work-on-task](./workflow-instructions/work-on-task.wf.md) | [review-task](./workflow-instructions/review-task.wf.md) | [replan-cascade-task](./workflow-instructions/replan-cascade-task.wf.md) | [prioritize-align-ideas](./workflow-instructions/prioritize-align-ideas.wf.md) | [document-unplanned-work](./workflow-instructions/document-unplanned-work.wf.md)

**Code Quality:** [review-code](./workflow-instructions/review-code.wf.md) | [synthesize-reviews](./workflow-instructions/synthesize-reviews.wf.md) | [fix-tests](./workflow-instructions/fix-tests.wf.md) | [fix-linting-issue-from](./workflow-instructions/fix-linting-issue-from.wf.md) | [improve-code-coverage](./workflow-instructions/improve-code-coverage.wf.md) | [rebase-against](./workflow-instructions/rebase-against.wf.md)

**Documentation:** [create-adr](./workflow-instructions/create-adr.wf.md) | [create-api-docs](./workflow-instructions/create-api-docs.wf.md) | [create-user-docs](./workflow-instructions/create-user-docs.wf.md) | [create-test-cases](./workflow-instructions/create-test-cases.wf.md) | [update-blueprint](./workflow-instructions/update-blueprint.wf.md)

**Session:** [save-session-context](./workflow-instructions/save-session-context.wf.md) | [create-reflection-note](./workflow-instructions/create-reflection-note.wf.md) | [synthesize-reflection-notes](./workflow-instructions/synthesize-reflection-notes.wf.md)

## Decision Tree

```
START → What do you need?
├─ New project? → initialize-project-structure
├─ Need context? → load-project-context  
├─ Have idea? → capture-idea → draft-task
├─ Ready to code? → work-on-task
├─ Tests failing? → fix-tests
├─ Need review? → review-code
├─ Ready to ship? → publish-release
└─ Session ending? → save-session-context
```

## Templates

[Architecture](./templates/project-docs/architecture.template.md) | [Blueprint](./templates/project-docs/blueprint.template.md) | [PRD](./templates/project-docs/prd.template.md) | [Vision](./templates/project-docs/vision.template.md)

---

*Updated as workflows evolve and new patterns emerge.*