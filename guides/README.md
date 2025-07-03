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

- **[Project Management Guide](./project-management.g.md)**: Details task management, directory structure, and core workflow.
- **[Write Actionable Task Guide](./task-definition.g.md)**: Guide for creating clear, actionable development tasks.
- **[Strategic Planning Guide](./strategic-planning.g.md)**: High-level strategic planning and roadmap management.
- **[Changelog Guide](./changelog.g.md)**: Standards for maintaining project changelogs.
- **[Picking Codenames Guide](./release-codenames.g.md)**: Guidelines for selecting project codenames.
- **[Document Synchronization Guide](./document-synchronization.md)**: Comprehensive guide for document sync system operation and maintenance.
- **[Document Sync Operations](./document-sync-operations.md)**: Quick reference for document synchronization workflows and commands.
- **[Template Embedding Standards](../.meta/gds/template-embedding.g.md)**: XML format standards for embedding templates in workflow instructions.
- **[Embedding Tests in Workflows](./embedded-testing-guide.g.md)**: Standard for incorporating tests in workflow instructions.
- **[Test-Driven Development Cycle](./testing-tdd-cycle.g.md)**: Core TDD practices and implementation cycle.
  - [Meta Documentation TDD](./test-driven-development-cycle/meta-documentation.md)
  - [Ruby Application TDD](./test-driven-development-cycle/ruby-application.md)
  - [Ruby Gem TDD](./test-driven-development-cycle/ruby-gem.md)
  - [Rust CLI TDD](./test-driven-development-cycle/rust-cli.md)
  - [Rust WASM Zed TDD](./test-driven-development-cycle/rust-wasm-zed.md)
  - [TypeScript Nuxt TDD](./test-driven-development-cycle/typescript-nuxt.md)
  - [TypeScript Vue TDD](./test-driven-development-cycle/typescript-vue.md)

### Technical & Language Guides

- **[Code Review: Diff-Based Documentation Updates](./code-review-diff-for-docs-update.g.md)** - Systematic approach for reviewing code diffs and updating related documentation.
- **[Coding Standards](./coding-standards.g.md)** - Code style and general best practices.
  - [Ruby Coding Standards](./coding-standards/ruby.md)
  - [Rust Coding Standards](./coding-standards/rust.md)
  - [TypeScript Coding Standards](./coding-standards/typescript.md)
- **[Documentation Standards](./documentation.g.md)** - Documentation requirements and structure.
  - [Ruby Documentation Standards](./documentation/ruby.md)
  - [Rust Documentation Standards](./documentation/rust.md)
  - [TypeScript Documentation Standards](./documentation/typescript.md)
- **[Error Handling](./error-handling.g.md)** - Error handling patterns and strategies.
  - [Ruby Error Handling](./error-handling/ruby.md)
  - [Rust Error Handling](./error-handling/rust.md)
  - [TypeScript Error Handling](./error-handling/typescript.md)
- **[Performance](./performance.g.md)** - Performance optimization guidelines.
  - [Ruby Performance](./performance/ruby.md)
  - [Rust Performance](./performance/rust.md)
  - [TypeScript Performance](./performance/typescript.md)
- **[Quality Assurance](./quality-assurance.g.md)** - Quality control processes and standards.
  - [Ruby Quality Assurance](./quality-assurance/ruby.md)
  - [Rust Quality Assurance](./quality-assurance/rust.md)
  - [TypeScript Quality Assurance](./quality-assurance/typescript.md)
- **[Security](./security.g.md)** - Security best practices and considerations.
  - [Ruby Security](./security/ruby.md)
  - [Rust Security](./security/rust.md)
  - [TypeScript Security](./security/typescript.md)
- **[Testing Guidelines](./testing.g.md)** - General testing approach and philosophy.
  - [Ruby RSpec Guide](./testing/ruby-rspec.md)
  - [Ruby RSpec Config Examples](./testing/ruby-rspec-config-examples.md)
  - [Rust Testing Guide](./testing/rust.md)
  - [TypeScript (Bun) Guide](./testing/typescript-bun.md)
- **[Troubleshooting Workflow](./debug-troubleshooting.g.md)** - High-level workflow for debugging and problem-solving.
  - [Ruby Troubleshooting](./troubleshooting/ruby.md)
  - [Rust Troubleshooting](./troubleshooting/rust.md)
  - [TypeScript Troubleshooting](./troubleshooting/typescript.md)
- **[Version Control](./version-control-system.g.md)** - Git workflow and commit standards.
  - [Ruby Version Control](./version-control/ruby.md)
  - [Rust Version Control](./version-control/rust.md)
  - [TypeScript Version Control](./version-control/typescript.md)
- **[Temporary File Management Guidelines](./temporary-file-management.g.md)** - Guidelines for AI agent temporary file usage.

### Draft Release Management

- **[Draft Release Templates](./draft-release/README.md)** - Templates and guides for creating new releases in backlog.

### Publish Release Management

- **[Publish Release Process](./release-publish.g.md)** - Release workflow, versioning, and publication checklists.
  - [Ruby Publish Release](./release-publish/ruby.md)
  - [Rust Publish Release](./release-publish/rust.md)
  - [TypeScript Publish Release](./release-publish/typescript.md)

### Project Initialization

Templates for initializing new projects are available in the templates directory:

- [Architecture Template](../templates/project-docs/architecture.template.md)
- [Blueprint Template](../templates/project-docs/blueprint.template.md)
- [PRD Template](../templates/project-docs/prd.template.md)
- [What Do We Build Template](../templates/project-docs/vision.template.md)

## Task & Release Management

Project tasks and release planning are managed within the `dev-taskflow` directory using a simple Kanban-style flow (`backlog/`, `current/`, `done/`) with structured Markdown task files.

Key guides for this process:

- **[Project Management Guide](./project-management.g.md)**: Details the directory structure, task format, and core workflow.
- **[Publish Release Process](./release-publish.g.md)**: Covers the steps for finalizing and publishing a release.

The specific documentation artifacts required for a release (e.g., ADRs, test cases, user examples) are determined during the specification phase, guided by the draft release templates based on the release type and scope.
