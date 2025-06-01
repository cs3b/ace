<!-- ← Back to docs-dev root -->

# Development Guides

This directory contains comprehensive development guidelines and standards for the project.

## Core Development Process

Our development workflow centers around:

- Iterative, task-based development
- Clear documentation and knowledge preservation
- Transparent progress tracking
- Quality-driven releases

## Guide Organization

### Meta & Process Guides

- **[Project Management Guide](./project-management.md)**: Details task management, directory structure, and core workflow.
- **[Write Actionable Task Guide](./write-actionable-task.md)**: Guide for creating clear, actionable development tasks.
- **[Strategic Planning Guide](./strategic-planning-guide.md)**: High-level strategic planning and roadmap management.
- **[Changelog Guide](./changelog-guide.md)**: Standards for maintaining project changelogs.
- **[Picking Codenames Guide](./picking-codenames.md)**: Guidelines for selecting project codenames.
- **[Embedding Tests in Workflows](./embedding-tests-in-workflows.md)**: Standard for incorporating tests in workflow instructions.
- **[Test-Driven Development Cycle](./test-driven-development-cycle.md)**: Core TDD practices and implementation cycle.
  - [Meta Documentation TDD](./test-driven-development-cycle/meta-documentation.md)
  - [Ruby Application TDD](./test-driven-development-cycle/ruby-application.md)
  - [Ruby Gem TDD](./test-driven-development-cycle/ruby-gem.md)
  - [Rust CLI TDD](./test-driven-development-cycle/rust-cli.md)
  - [Rust WASM Zed TDD](./test-driven-development-cycle/rust-wasm-zed.md)
  - [TypeScript Nuxt TDD](./test-driven-development-cycle/typescript-nuxt.md)
  - [TypeScript Vue TDD](./test-driven-development-cycle/typescript-vue.md)

### Technical & Language Guides

- **[Coding Standards](./coding-standards.md)** - Code style and general best practices.
  - [Ruby Coding Standards](./coding-standards/ruby.md)
  - [Rust Coding Standards](./coding-standards/rust.md)
  - [TypeScript Coding Standards](./coding-standards/typescript.md)
- **[Documentation Standards](./documentation.md)** - Documentation requirements and structure.
  - [Ruby Documentation Standards](./documentation/ruby.md)
  - [Rust Documentation Standards](./documentation/rust.md)
  - [TypeScript Documentation Standards](./documentation/typescript.md)
- **[Error Handling](./error-handling.md)** - Error handling patterns and strategies.
  - [Ruby Error Handling](./error-handling/ruby.md)
  - [Rust Error Handling](./error-handling/rust.md)
  - [TypeScript Error Handling](./error-handling/typescript.md)
- **[Performance](./performance.md)** - Performance optimization guidelines.
  - [Ruby Performance](./performance/ruby.md)
  - [Rust Performance](./performance/rust.md)
  - [TypeScript Performance](./performance/typescript.md)
- **[Quality Assurance](./quality-assurance.md)** - Quality control processes and standards.
  - [Ruby Quality Assurance](./quality-assurance/ruby.md)
  - [Rust Quality Assurance](./quality-assurance/rust.md)
  - [TypeScript Quality Assurance](./quality-assurance/typescript.md)
- **[Security](./security.md)** - Security best practices and considerations.
  - [Ruby Security](./security/ruby.md)
  - [Rust Security](./security/rust.md)
  - [TypeScript Security](./security/typescript.md)
- **[Testing Guidelines](./testing.md)** - General testing approach and philosophy.
  - [Ruby RSpec Guide](./testing/ruby-rspec.md)
  - [Ruby RSpec Config Examples](./testing/ruby-rspec-config-examples.md)
  - [Rust Testing Guide](./testing/rust.md)
  - [TypeScript (Bun) Guide](./testing/typescript-bun.md)
- **[Troubleshooting Workflow](./troubleshooting-workflow.md)** - High-level workflow for debugging and problem-solving.
  - [Ruby Troubleshooting](./troubleshooting/ruby.md)
  - [Rust Troubleshooting](./troubleshooting/rust.md)
  - [TypeScript Troubleshooting](./troubleshooting/typescript.md)
- **[Version Control](./version-control.md)** - Git workflow and commit standards.
  - [Ruby Version Control](./version-control/ruby.md)
  - [Rust Version Control](./version-control/rust.md)
  - [TypeScript Version Control](./version-control/typescript.md)
- **[Temporary File Management Guidelines](./temporary-file-management.md)** - Guidelines for AI agent temporary file usage.

### Draft Release Management

- **[Draft Release Templates](./draft-release/README.md)** - Templates and guides for creating new releases in backlog.

### Publish Release Management

- **[Publish Release Process](./publish-release.md)** - Release workflow, versioning, and publication checklists.
  - [Ruby Publish Release](./publish-release/ruby.md)
  - [Rust Publish Release](./publish-release/rust.md)
  - [TypeScript Publish Release](./publish-release/typescript.md)

### Project Initialization

- **[Initialize Project Templates](./initialize-project-templates/README.md)** - Templates for initializing new projects.
  - [Architecture Template](./initialize-project-templates/architecture.md)
  - [Blueprint Template](./initialize-project-templates/blueprint.md)
  - [PRD Template](./initialize-project-templates/PRD.md)
  - [What Do We Build Template](./initialize-project-templates/what-do-we-build.md)

## Task & Release Management

Project tasks and release planning are managed within the `docs-project` directory using a simple Kanban-style flow (`backlog/`, `current/`, `done/`) with structured Markdown task files.

Key guides for this process:

- **[Project Management Guide](./project-management.md)**: Details the directory structure, task format, and core workflow.
- **[Publish Release Process](./publish-release.md)**: Covers the steps for finalizing and publishing a release.

The specific documentation artifacts required for a release (e.g., ADRs, test cases, user examples) are determined during the specification phase, guided by the draft release templates based on the release type and scope.
