# Context

## Metadata

- **preset_content**: # Project Context

You are working on the Coding Agent Workflow Toolkit (Meta) - a comprehensive meta-repository that provides documentation and guidance for setting up AI-assisted development workflow systems.
- **preset_name**: project
- **output**: cache

## Files

### docs/ace-gems.g.md

```
# ACE Gem Development Guide

Quick guide for creating ace-* gems that integrate with the ACE framework.

## Available Shared Packages

Before implementing functionality, leverage these existing ace-* gems:

### ace-core
Zero-dependency foundation providing configuration cascade, environment management, and utilities.

```ruby
require 'ace/core'

# Configuration cascade (./.ace → ~/.ace → defaults)
config = Ace::Core.config
value = Ace::Core.get('ace', 'settings', 'key')
Ace::Core.get_env('API_KEY', 'default')  # Env vars without polluting ENV

# Discovery API
discovery = Ace::Core::ConfigDiscovery.new
discovery.project_root
discovery.find_config_file('config.yml')

# Common atoms (require explicitly for tree-shaking)
require 'ace/core/atoms/yaml_parser'
require 'ace/core/atoms/deep_merger'
require 'ace/core/atoms/file_reader'

Ace::Core::Atoms::YamlParser.parse(yaml)
Ace::Core::Atoms::DeepMerger.merge(base, override)
Ace::Core::Atoms::FileReader.read(path)
```
*See ace-core/README.md for complete API documentation.*

### ace-test-support
Testing utilities and base test case:

```ruby
require 'ace/test_support'

class MyTest < AceTestCase
  def test_cli
    result = run_subprocess(['ace-your-gem', 'process'])
    assert_equal 0, result.exit_code
  end
end
```

### Other Useful Gems
- **ace-nav**: Resource navigation (`wfi://` protocol)
- **ace-llm**: Multi-provider LLM integration
- **ace-taskflow**: Task and release management

## Gem Structure

All ace-* gems follow the ATOM architecture pattern - see [architecture.md](../docs/architecture.md) for details.

### Standard Directory Layout

```
ace-your-gem/
├── .ace.example/           # Example configuration
│   └── your-gem/
│       └── config.yml
├── lib/
│   └── ace/
│       └── your_gem/
│           ├── atoms/      # Pure functions, no side effects
│           ├── molecules/  # Composed operations
│           ├── organisms/  # Business orchestration
│           ├── models/     # Data structures
│           └── version.rb
├── test/
│   ├── test_helper.rb
│   └── (test files matching lib structure)
├── exe/
│   └── ace-your-gem       # Executable script
├── ace-your-gem.gemspec
├── Rakefile
└── README.md
```

### Quick Example Structure

```ruby
# lib/ace/your_gem/atoms/parser.rb - Pure function
module Ace::YourGem::Atoms
  module Parser
    module_function
    def parse(input)
      JSON.parse(input)
    end
  end
end

# lib/ace/your_gem/molecules/loader.rb - Composed operation
class Ace::YourGem::Molecules::Loader
  def self.load_file(path)
    content = Ace::Core::Atoms::FileReader.read(path)
    Atoms::Parser.parse(content)
  end
end
```

## Configuration

### Example Configuration (.ace.example)

```yaml
# .ace.example/your-gem/config.yml
ace:
  your_gem:
    features:
      verbose: false
    processing:
      timeout: 30
```

### Loading Configuration

```ruby
# lib/ace/your_gem.rb
module Ace
  module YourGem
    def self.config
      @config ||= begin
        base_config = Ace::Core.config
        base_config.get('ace', 'your_gem') || default_config
      end
    end

    def self.default_config
      { 'features' => { 'verbose' => false }, 'processing' => { 'timeout' => 30 } }
    end
  end
end
```

## CLI Implementation

```ruby
# exe/ace-your-gem
#!/usr/bin/env ruby
require 'ace/your_gem'
require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: ace-your-gem [options]"
  opts.on("-v", "--verbose", "Verbose output") { options[:verbose] = true }
  opts.on("-h", "--help", "Show help") { puts opts; exit }
end.parse!

config = Ace::YourGem.config
verbose = options[:verbose] || config['features']['verbose']

begin
  # Your gem logic here
  result = Ace::YourGem::Organisms::Processor.new.process(ARGV[0])
  puts result
rescue => e
  $stderr.puts "Error: #{e.message}"
  exit 1
end
```

## Claude Code Integration

Create command files in `.claude/commands/`:

```markdown
# .claude/commands/your-gem-process.md
---
description: Process data with ace-your-gem
allowed-tools: Read, Write, Bash
argument-hint: "[file-path]"
---

Process the file using ace-your-gem functionality.
```

## Testing

### Setup

```ruby
# test/test_helper.rb
require 'ace/test_support'
require 'ace/your_gem'

class YourGemTestCase < AceTestCase
end
```

### Essential Testing Patterns

```ruby
# Test atoms (pure functions)
class ParserTest < YourGemTestCase
  def test_parse_valid
    result = Ace::YourGem::Atoms::Parser.parse('{"key": "value"}')
    assert_equal({ "key" => "value" }, result)
  end
end

# Test CLI commands
class CLITest < YourGemTestCase
  def test_command
    result = run_subprocess(['ace-your-gem', 'process', 'file.json'])
    assert_equal 0, result.exit_code
  end
end

# Test with fixtures
def test_with_fixture
  data = fixture_path('sample.json')  # Provided by AceTestCase
  result = process(data)
  assert result.success?
end
```

### Coverage

```ruby
# Rakefile
require 'rake/testtask'
Rake::TestTask.new(:test) do |t|
  t.test_files = FileList['test/**/*_test.rb']
end
```

**Key Principles:**
- Test isolation - each test independent
- Use fixtures from `test/fixtures/`
- Mock external services
- Test edge cases and error paths

## Quick Start

### Create New Gem

```bash
#!/bin/bash
# create-ace-gem.sh
GEM_NAME=$1
bundle gem "ace-$GEM_NAME" --no-exe --no-coc --no-ext --no-mit
cd "ace-$GEM_NAME"

# Create structure
mkdir -p lib/ace/$GEM_NAME/{atoms,molecules,organisms,models}
mkdir -p test/fixtures exe .ace.example/$GEM_NAME

# Create executable
cat > exe/ace-$GEM_NAME << 'EOF'
#!/usr/bin/env ruby
require 'ace/your_gem'
require 'optparse'

OptionParser.new do |opts|
  opts.banner = "Usage: ace-your-gem [options]"
  opts.on("-h", "--help", "Show help") { puts opts; exit }
end.parse!

# Main logic
EOF
chmod +x exe/ace-$GEM_NAME

# Update gemspec dependencies
echo "Add to gemspec: ace-core and ace-test-support"
```

### Minimal Gemspec

```ruby
# ace-your-gem.gemspec
Gem::Specification.new do |spec|
  spec.name = "ace-your-gem"
  spec.version = "0.1.0"
  spec.summary = "Your gem description"
  spec.files = Dir.glob(%w[lib/**/*.rb exe/* README.md])
  spec.bindir = "exe"
  spec.executables = ["ace-your-gem"]
  spec.add_dependency "ace-core", "~> 0.9"
  spec.add_development_dependency "ace-test-support", "~> 0.9"
end
```

## Key Guidelines

- **Reuse existing gems** - Check ace-core, ace-test-support first
- **Follow ATOM pattern** - See [architecture.md](../docs/architecture.md)
- **Test thoroughly** - Use AceTestCase for consistent testing
- **Keep focused** - Single purpose per gem
- **Document clearly** - README with examples

*For existing gem examples, see any ace-* directory in the repository.*
```

### docs/architecture.md

```
# ACE - System Architecture

## Overview

ACE (Agent Coding Environment) is a mono-repo ecosystem of modular Ruby gems that provide a deterministic CLI surface for AI-assisted software development. Both human developers and AI agents use the same tools through consistent interfaces.

## Core Architecture Principles

- **Mono-Repo Structure**: All ace-* gems at repository root with shared dependencies
- **ATOM Pattern**: Consistent architecture across all gems (Atoms, Molecules, Organisms, Models)
- **Configuration Cascade**: Hierarchical .ace/ configuration with nearest-wins resolution
- **Zero-Dependency Core**: ace-core uses only Ruby standard library
- **AI-Native Design**: Deterministic commands designed for autonomous agent execution

## Repository Organization

The mono-repo contains modular ace-* gems and legacy components being migrated. Each gem follows the ATOM architecture pattern with consistent directory structure. For detailed file organization and navigation, see [blueprint.md](blueprint.md).

## ATOM Architecture Pattern

All ace-* gems follow the ATOM pattern for consistent, testable code organization:

### Atoms (Pure Functions)

- No side effects or external dependencies
- Single, well-defined purpose
- Examples: `yaml_parser`, `deep_merger`, `path_expander`

### Molecules (Composed Operations)

- Combine atoms to perform specific operations
- May have controlled side effects (file I/O)
- Examples: `yaml_loader`, `config_finder`, `context_chunker`

### Organisms (Business Logic)

- Orchestrate molecules to implement features
- Handle complex workflows and coordination
- Examples: `config_resolver`, `context_loader`, `test_orchestrator`

### Models (Data Structures)

- Pure data carriers with no business logic
- Immutable value objects preferred
- Examples: `config`, `context_data`, `test_result`

## Component Types

### Tools (ace-* gems)

Modular Ruby gems providing focused CLI functionality:

- **ace-core**: Configuration management foundation
- **ace-context**: Project context loading
- **ace-test-runner**: Test execution and reporting
- **ace-test-support**: Shared testing infrastructure
- **ace-taskflow**: Task, release, and idea management with move-to-done and rescheduling
- **ace-nav**: Resource discovery and navigation with wfi:// protocol support
- **ace-llm**: Multi-provider AI model integration with CLI-based providers support
- **ace-git-commit**: Smart git commit generation with LLM integration

### Workflows (.wf.md)

Self-contained instruction documents for AI agents:

- Migrating to `ace-taskflow/handbook/workflow-instructions/`
- Legacy location: `dev-handbook/workflow-instructions/`
- Include all necessary context and templates
- Follow ADR-001 self-containment principle
- Discoverable via ace-nav wfi:// protocol

### Agents (.ag.md)

Specialized single-purpose agents for focused tasks:

- Located in `dev-handbook/.integrations/claude/agents/`
- Exposed via `.claude/agents/` symlinks
- Designed for delegation and composition

### Guides

Development patterns and best practices:

- Located in `dev-handbook/guides/`
- Reference documentation for humans and agents
- Standards and conventions

## AI Integration Architecture

### Claude Code Integration

- **Commands**: `.claude/commands/` maps workflows to slash commands
- **Agents**: `.claude/agents/` provides agent access via Task tool
- **Deterministic CLI**: All tools provide predictable, parseable output
- **wfi:// Protocol**: Direct workflow access via ace-nav integration

### Platform Compatibility

- Commands work identically for humans and agents
- Platform-agnostic design (Claude Code, Codex, OpenCode)
- Future MCP (Model Context Protocol) support planned

### Agent Delegation Pattern

1. User invokes command or agent
2. Agent analyzes task requirements
3. Delegates to specialized subagents as needed
4. Aggregates results and reports back

## Key Architectural Decisions

### Mono-Repo Migration (ADR-015)

- Migrated from multi-repository submodules to mono-repo
- Each capability packaged as focused ace-* gem
- Simplified dependency management and testing

### ATOM Architecture (ADR-011)

- Enforces clean separation of concerns
- Consistent patterns across all gems
- Testable, maintainable code structure

### Workflow Self-Containment (ADR-001)

- Workflows include all necessary templates
- No external dependencies except core docs
- Enables reliable autonomous execution

### Configuration Cascade

- `.ace/` directories searched from current to home
- Nearest configuration wins (deepest in tree)
- Enables project-specific settings without modification

### Zero-Dependency Core

- ace-core uses only Ruby standard library
- Provides stable foundation for all other gems
- Reduces dependency conflicts and complexity

## Security & Quality Principles

- **Path Validation**: Multi-layer validation for file operations
- **Input Sanitization**: Clean all user inputs before processing
- **Test Coverage**: Comprehensive test suites using ace-test-support
- **CI/CD Integration**: GitHub Actions matrix testing across Ruby versions
- **Deterministic Output**: Consistent, predictable command results

## Future Architecture

### Planned Migrations

- **ace-handbook**: Workflows, guides, and templates as a gem
- **ace-search**: Unified file and content search across codebases
- **ace-review**: Code review automation and synthesis

### Vision

Every development capability becomes an installable Ruby gem. Prompts, agents, and workflows are embedded within thematic gems, making them instantly available through `gem install ace-*`.

---

*For detailed architectural decisions, see [docs/decisions.md](decisions.md)*


```

### docs/blueprint.md

```
# Project Blueprint: ACE (Agent Coding Environment)

## What is a Blueprint?

This document provides navigation guidance for the ACE codebase, highlighting what to modify and what to avoid.

## Repository Structure

```
ace-*/          # Ruby gems following ATOM architecture
dev-handbook/   # Workflows, agents, guides (legacy, migrating to ace-handbook)
.ace-taskflow/  # Task and release management (migrated from dev-taskflow)
dev-tools/      # CLI tools (legacy, being split into ace-* gems)
.claude/        # Claude Code integration (commands and agent symlinks)
.ace/           # Configuration cascade root
docs/           # System documentation and ADRs
.github/        # CI/CD workflows
```

For detailed architecture and ATOM pattern, see [architecture.md](architecture.md).

## Read-Only Paths

AI agents should treat these as read-only unless explicitly instructed to modify:

- `docs/decisions/**/*` # Architecture Decision Records
- `docs/migrations/**/*` # Documentation migration records
- `ace-*/lib/**/*` # Gem source code (modify only for bug fixes)
- `ace-*/test/**/*` # Gem test files (modify only for test updates)
- `.github/workflows/**/*` # CI/CD configuration
- `dev-handbook/guides/**/*` # Development guides
- `dev-handbook/workflow-instructions/**/*` # AI workflow instructions
- `.ace-taskflow/done/**/*` # Completed tasks
- `.ace-taskflow/v.*/retro/**/*` # Development retrospectives
- `Gemfile.lock` # Root workspace lock file

## Ignored Paths

AI agents should ignore these during normal operations:

- `.ace-taskflow/done/**/*` # Completed tasks and releases
- `.cache/ace-*/**/*` # Cached output from ace tools
- `ace-*/coverage/**/*` # Test coverage reports
- `**/test-reports/**/*` # Test report files
- `tmp/**/*` # Temporary files
- `.git/**/*` # Git internals
- `.bundle/**/*` # Bundle cache
- `node_modules/**/*` # Node.js dependencies
- `*.bak` # Backup files
- `docs/context/cached/**/*` # Legacy cached context files


```

### docs/decisions.md

```
# Project Decisions

This document provides actionable decisions from Architecture Decision Records (ADRs) that directly affect how AI agents and developers should work with this codebase.

## Active Decisions

### Workflow Self-Containment
**Decision**: All AI workflows must be completely self-contained with embedded templates and context. Workflows cannot depend on other workflows or external files except the three standard context documents.
**Impact**: When executing workflows, never load external guides or templates. All necessary information must be within the .wf.md file itself. Only load `docs/what-do-we-build.md`, `docs/architecture.md`, and `docs/blueprint.md` for project context.
**Details**: [ADR-001](decisions/ADR-001-workflow-self-containment-principle.md)

### XML Template Embedding
**Decision**: Use XML format `<documents>` and `<template>` tags for embedding templates within workflow files, placed at the end of the document.
**Impact**: When updating workflows, preserve XML template blocks exactly. Use `handbook sync-templates` command to synchronize embedded templates with source files. Never use four-tick markdown blocks for templates.
**Details**: [ADR-002](decisions/ADR-002-xml-template-embedding-architecture.md)

### Template Directory Structure
**Decision**: All templates must be stored in `dev-handbook/templates/` with standardized subdirectories and `.template.md` extension.
**Impact**: When creating new templates, place them in the appropriate subdirectory (project-docs/, release-tasks/, code-review/, reflections/, task-management/). Always use `.template.md` extension.
**Details**: [ADR-003](decisions/ADR-003-template-directory-separation.md)

### Consistent Path Standards
**Decision**: All document paths must be relative to project root, never absolute. Follow standard patterns like `dev-handbook/templates/**/*.template.md`.
**Impact**: When referencing files in documentation or code, always use paths relative to the project root. Never use absolute paths or paths starting with `./` or `../`.
**Details**: [ADR-004](decisions/ADR-004-consistent-path-standards.md)

### Universal Document Embedding
**Decision**: Use the universal `<documents>` container format for embedding any type of document (templates, guides, examples) in workflows.
**Impact**: When embedding documents in workflows, always use the `<documents>` wrapper with appropriate document type tags. This enables automated synchronization and validation.
**Details**: [ADR-005](decisions/ADR-005-universal-document-embedding-system.md)

## Architecture Decisions

### Mono-Repo Migration to ace-* Gems
**Decision**: Migrate from multi-repository submodule architecture to mono-repo with modular ace-* Ruby gems.
**Impact**: When working with the codebase:
- All new functionality goes into appropriate ace-* gems at the repository root
- Follow ATOM architecture (atoms/, molecules/, organisms/, models/) in each gem
- Use the root Gemfile for development dependencies
- Run commands with `bundle exec` during development
- Configuration uses .ace/ cascade with nearest/deepest wins
- Legacy dev-* directories are being migrated incrementally
**Details**: [ADR-015](decisions/ADR-015-mono-repo-ace-gems-migration.md)

## Development Tool Decisions

### CI-Aware VCR Configuration
**Decision**: VCR cassettes must be environment-aware with CI detection and appropriate recording modes.
**Impact**: When writing tests with external API calls, ensure VCR is configured to detect CI environments. Use `new_episodes` mode locally and `none` in CI.
**Details**: [ADR-006](decisions/ADR-006-CI-Aware-VCR-Configuration.t.md)

### Zeitwerk Autoloading
**Decision**: Use Zeitwerk for all Ruby autoloading with proper inflections for acronyms (CLI, HTTP, API, JSON, etc.).
**Impact**: Follow file naming conventions strictly. Use snake_case filenames that match class names. Configure inflections for technical acronyms in the Zeitwerk setup.
**Details**: [ADR-007](decisions/ADR-007-Zeitwerk-for-Autoloading.t.md)

### Observability with dry-monitor
**Decision**: Implement observability using dry-monitor's publish/subscribe pattern with a central Notifications instance.
**Impact**: When adding new features that need monitoring, publish events through the Notifications instance. Subscribe to events for logging, metrics, or debugging.
**Details**: [ADR-008](decisions/ADR-008-Observability-with-dry-monitor.t.md)

### Centralized CLI Error Reporting
**Decision**: Use a centralized ErrorReporter module for all CLI error handling with debug flag support.
**Impact**: Never print errors directly to stdout/stderr in CLI commands. Always route errors through ErrorReporter for consistent formatting and debug support.
**Details**: [ADR-009](decisions/ADR-009-Centralized-CLI-Error-Reporting.t.md)

### HTTP Client Strategy
**Decision**: Use Faraday as the standard HTTP client with retry middleware and observability integration.
**Impact**: For all HTTP requests, use Faraday with the standard middleware stack. Never use Net::HTTP directly. Ensure retry logic and monitoring are configured.
**Details**: [ADR-010](decisions/ADR-010-HTTP-Client-Strategy-with-Faraday.t.md)

### ATOM Architecture Rules
**Decision**: Strictly follow ATOM architecture layers: Models (pure data), Molecules (focused operations), Organisms (business orchestration), Ecosystems (complete workflows).
**Impact**: When creating new components in dev-tools:
- Pure data structures go in `models/` (no behavior)
- Focused operations composing Atoms go in `molecules/` (single responsibility)
- Business logic orchestrating Molecules goes in `organisms/` (complex coordination)
- Never place data carriers in `molecules/` or behavior in `models/`
**Details**: [ADR-011](decisions/ADR-011-ATOM-Architecture-House-Rules.t.md)

### Dynamic Provider System
**Decision**: Implement a dynamic provider system for LLM integrations with standardized interfaces.
**Impact**: When adding new LLM providers, follow the established provider interface pattern. Register providers dynamically through the provider system.
**Details**: [ADR-012](decisions/ADR-012-Dynamic-Provider-System-Architecture.t.md)

### Class Naming Conventions
**Decision**: Preserve established technical acronyms in class names (JSONFormatter, HTTPClient, APICredentials) while using CamelCase for domain terms.
**Impact**: When naming classes, keep technical acronyms uppercase (HTTP, API, JSON, LLM). Use CamelCase for domain-specific terms (LlmModelInfo, not LLMModelInfo).
**Details**: [ADR-013](decisions/ADR-013-Class-Naming-Conventions-and-Zeitwerk-Inflections.t.md)

### LLM Integration Architecture
**Decision**: Use hybrid approach for LLM context sizes: API-first with static fallback mappings.
**Impact**: When integrating with LLM providers, first attempt to get context size from API. Maintain static mappings as fallback for providers without API support.
**Details**: [ADR-014](decisions/ADR-014-LLM-Integration-Architecture.t.md)

## Decision History

For complete decision history and detailed rationale, refer to the individual ADR documents in `docs/decisions/`.
```

### docs/tools.md

```
# ACE Tools Reference

| Tool | Purpose | Key Commands |
|------|---------|--------------|
| **ace-context** | Load project context | `ace-context project`, `ace-context --list` |
| **ace-test** | Run tests | `ace-test test/file.rb`, `ace-test test/file.rb:42` |
| **ace-test-suite** | Run all tests | `ace-test-suite` |
| **ace-taskflow** | Task management | `ace-taskflow task`, `ace-taskflow tasks --preset current` |
| **ace-nav** | Resource navigation | `ace-nav wfi://workflow-name`, `ace-nav --sources` |
| **ace-llm-query** | Query LLM providers | `ace-llm-query "prompt" -m gpt-4` |
| **ace-git-commit** | Generate commits | `ace-git-commit`, `ace-git-commit --staged` |

## Quick Examples

```sh
# Task management
ace-taskflow task done 019              # Mark complete & move to done/
ace-taskflow idea reschedule "feat" --add-next  # Reschedule idea
ace-taskflow release reschedule v.0.9.0 --status active

# Git commits
ace-git-commit                          # Generate commit for all changes
ace-git-commit --staged                 # Commit only staged files

# Navigation and context
ace-context project --output stdio      # Load context to stdout
ace-nav 'wfi://*task*' --list          # Find workflow patterns
```

*Full documentation in each ace-*/docs/usage.md*

```

### docs/what-do-we-build.md

```
# ACE (Agent Coding Environment)

## What We Build

ACE packages development capabilities as Ruby gems for AI coding assistants. Whether it's a tool, a workflow, or a template - ACE turns it into a reusable gem that works seamlessly with Claude Code, Codex, OpenCode, and other AI development environments.

## Current Capabilities

- **ace-core**: Configuration management and shared utilities
- **ace-context**: Project context loading with smart caching
- **ace-test-runner**: Test execution and CI integration
- **ace-test-support**: Testing infrastructure and helpers
- **ace-taskflow**: Task, release, and idea management with move-to-done and rescheduling
- **ace-nav**: Resource discovery and navigation with wfi:// protocol support
- **ace-llm**: Multi-provider AI model integration with CLI-based providers (Claude, Codex, OpenCode)
- **ace-git-commit**: Smart git commit generation with LLM integration

## Coming Soon

- **ace-search**: Unified file and content search across codebases
- **ace-git**: Enhanced git operations and smart commit generation
- **ace-review**: Code review automation and synthesis
- **ace-handbook**: Workflows, guides, and templates as a gem

## The Vision

Every development capability becomes an installable Ruby gem. Prompts, agents, and workflows are embedded within thematic gems rather than generic bundles. Install with `gem install ace-*` and use immediately - whether you're a human developer or an AI agent.

---

*ACE: Making AI-assisted development as simple as `gem install`.*


```

## Commands

### Command: `pwd`

**Output:**
```
/Users/mc/Ps/ace-meta

```

### Command: `date`

**Output:**
```
Tue Sep 30 20:47:54 WEST 2025

```

### Command: `git status --short`

**Output:**
```
 D .ace-taskflow/v.0.9.0/t/001-feat-core-minimal-ace-core-gem/task.001.md
 D .ace-taskflow/v.0.9.0/t/002-feat-root-gemfile-workspace/task.002.md
 D .ace-taskflow/v.0.9.0/t/003-test-core-set-up-minitest-ace-core/task.003.md
 D .ace-taskflow/v.0.9.0/t/004-test-core-integration-tests-ace-core/task.004.md
 D .ace-taskflow/v.0.9.0/t/005-feat-context-ace-context-gem/task.005.md
 D .ace-taskflow/v.0.9.0/t/006-feat-taskflow-ace-taskflow-gem/task.006.md
 D .ace-taskflow/v.0.9.0/t/007-feat-git-ace-git-gem-ace-gc-only/task.007.md
 D .ace-taskflow/v.0.9.0/t/007-feat-git-ace-git-gem-ace-gc-only/ux/usage.md
 D .ace-taskflow/v.0.9.0/t/010-test-test-ace-test-runner-package-execut/task.010.md
 D .ace-taskflow/v.0.9.0/t/011-test-test-redesign-ace-test-runner-perfo/task.011.md
 D .ace-taskflow/v.0.9.0/t/012-test-test-ace-test-runner-progress-repor/task.012.md
 D .ace-taskflow/v.0.9.0/t/013-feat-test-ace-test-runner-rich-developer/task.013.md
 D .ace-taskflow/v.0.9.0/t/014-test-test-enhanced-report-generation-ind/task.014.md
 D .ace-taskflow/v.0.9.0/t/015-test-test-optimize-ace-test-runner-perfo/task.015.md
 D .ace-taskflow/v.0.9.0/t/016-feat-context-smart-caching-ace-context/task.016.md
 D .ace-taskflow/v.0.9.0/t/017-refactor-context-ace-context-markdown-only-pres/task.017.md
 D .ace-taskflow/v.0.9.0/t/018-feat-nav-ace-nav-gem-navigation-handboo/task.018.md
 D .ace-taskflow/v.0.9.0/t/018-feat-nav-ace-nav-gem-navigation-handboo/ux.md
 D .ace-taskflow/v.0.9.0/t/019-feat-taskflow-ace-taskflow-release-managemen/task.019.md
 D .ace-taskflow/v.0.9.0/t/019-feat-taskflow-ace-taskflow-release-managemen/ux.md
 D .ace-taskflow/v.0.9.0/t/020-refactor-nav-ace-nav-follow-standard-config/task.020.md
 D .ace-taskflow/v.0.9.0/t/021-task-llm-extract-llm-query-dev-tools-ac/progress.md
 D .ace-taskflow/v.0.9.0/t/021-task-llm-extract-llm-query-dev-tools-ac/qa/ux.md
 D .ace-taskflow/v.0.9.0/t/021-task-llm-extract-llm-query-dev-tools-ac/task.021.md
 D .ace-taskflow/v.0.9.0/t/022-task-taskflow-migrate-dev-taskflow-ace-taskf/task.022.md
 D .ace-taskflow/v.0.9.0/t/023-feat-llm-ace-llm-providers-cli-gem-cli-/task.023.md
 D .ace-taskflow/v.0.9.0/t/024-task-taskflow-migrate-workflows-ace-taskflow/task.024.md
 D .ace-taskflow/v.0.9.0/t/025-feat-llm-git-commit-llm-enhance-flags-i/qa/usage.md
 D .ace-taskflow/v.0.9.0/t/025-feat-llm-git-commit-llm-enhance-flags-i/task.025.md
 D .ace-taskflow/v.0.9.0/t/026-feat-reschedule-subcommand-tasks-co/qa/usage.md
 D .ace-taskflow/v.0.9.0/t/026-feat-reschedule-subcommand-tasks-co/task.026.md
 D .ace-taskflow/v.0.9.0/t/027-feat-release-command-directory-stru/qa/usage.md
 D .ace-taskflow/v.0.9.0/t/027-feat-release-command-directory-stru/task.027.md
 D .ace-taskflow/v.0.9.0/t/028-test-taskflow-comprehensive-coverage-ace-tas/task.028.md
 D .ace-taskflow/v.0.9.0/t/029-task-taskflow-ace-taskflow-workflow-instruct/task.029.md
 D .ace-taskflow/v.0.9.0/t/030-fix-nav-ace-nav-protocol-path-formatti/task.030.md
 D .ace-taskflow/v.0.9.0/t/031-feat-taskflow-descriptive-paths-ace-taskflow/task.031.md
 D .ace-taskflow/v.0.9.0/t/031-feat-taskflow-descriptive-paths-ace-taskflow/ux/usage.md
 D .ace-taskflow/v.0.9.0/t/032-feat-taskflow-preset-system-ace-taskflow-lis/task.032.md
 D .ace-taskflow/v.0.9.0/t/032-feat-taskflow-preset-system-ace-taskflow-lis/ux/usage.md
 D .ace-taskflow/v.0.9.0/t/033-feat-taskflow-enhanced-stats-summary-display/task.033.md
 D .ace-taskflow/v.0.9.0/t/033-feat-taskflow-enhanced-stats-summary-display/ux/usage.md
 D .ace-taskflow/v.0.9.0/t/034-feat-taskflow-dependency-management-ace-task/task.034.md
 D .ace-taskflow/v.0.9.0/t/034-feat-taskflow-dependency-management-ace-task/ux/usage.md
 D .ace-taskflow/v.0.9.0/t/035-feat-llm-configuration-based-provider-a/task.035.md
 D .ace-taskflow/v.0.9.0/t/036-fix-llm-ace-llm-query-executable-follo/task.036.md
 D .ace-taskflow/v.0.9.0/t/037-feat-llm-env-cascade-loading-support-ac/task.037.md
 D .ace-taskflow/v.0.9.0/t/038-feat-llm-proper-binstub-ace-llm-query/task.038.md
 D .ace-taskflow/v.0.9.0/t/039-task-taskflow-ace-taskflow-display-status-co/task.039.md
 D .ace-taskflow/v.0.9.0/t/040-task-taskflow-implemented-dependency-aware-s/task.040.md
 D .ace-taskflow/v.0.9.0/t/041-feat-taskflow-move-done-and-reschedule/docs/ideas/041-feat-taskflow-move-done-tasks.md
 D .ace-taskflow/v.0.9.0/t/041-feat-taskflow-move-done-and-reschedule/docs/ideas/041-feat-taskflow-reschedule-ideas-releases.md
 D .ace-taskflow/v.0.9.0/t/041-feat-taskflow-move-done-and-reschedule/task.041.md
 D .ace-taskflow/v.0.9.0/t/042-fix-git-ace-git-commit-api-key-loading/task.042.md
 D .ace-taskflow/v.0.9.0/t/043-refactor-core-env-loading-centralize-ace-cor/task.043.md
 D .ace-taskflow/v.0.9.0/t/044-feat-core-ace-core-init-subcommand-confi/task.044.md
 D .ace-taskflow/v.0.9.0/t/045-task-restructurin---title-configuration-namespac/task.045.md
?? .ace-taskflow/v.0.9.0/t/done/001-feat-core-minimal-ace-core-gem/
?? .ace-taskflow/v.0.9.0/t/done/002-feat-root-gemfile-workspace/
?? .ace-taskflow/v.0.9.0/t/done/003-test-core-set-up-minitest-ace-core/
?? .ace-taskflow/v.0.9.0/t/done/004-test-core-integration-tests-ace-core/
?? .ace-taskflow/v.0.9.0/t/done/005-feat-context-ace-context-gem/
?? .ace-taskflow/v.0.9.0/t/done/006-feat-taskflow-ace-taskflow-gem/
?? .ace-taskflow/v.0.9.0/t/done/007-feat-git-ace-git-gem-ace-gc-only/
?? .ace-taskflow/v.0.9.0/t/done/010-test-test-ace-test-runner-package-execut/
?? .ace-taskflow/v.0.9.0/t/done/011-test-test-redesign-ace-test-runner-perfo/
?? .ace-taskflow/v.0.9.0/t/done/012-test-test-ace-test-runner-progress-repor/
?? .ace-taskflow/v.0.9.0/t/done/013-feat-test-ace-test-runner-rich-developer/
?? .ace-taskflow/v.0.9.0/t/done/014-test-test-enhanced-report-generation-ind/
?? .ace-taskflow/v.0.9.0/t/done/015-test-test-optimize-ace-test-runner-perfo/
?? .ace-taskflow/v.0.9.0/t/done/016-feat-context-smart-caching-ace-context/
?? .ace-taskflow/v.0.9.0/t/done/017-refactor-context-ace-context-markdown-only-pres/
?? .ace-taskflow/v.0.9.0/t/done/018-feat-nav-ace-nav-gem-navigation-handboo/
?? .ace-taskflow/v.0.9.0/t/done/019-feat-taskflow-ace-taskflow-release-managemen/
?? .ace-taskflow/v.0.9.0/t/done/020-refactor-nav-ace-nav-follow-standard-config/
?? .ace-taskflow/v.0.9.0/t/done/021-task-llm-extract-llm-query-dev-tools-ac/
?? .ace-taskflow/v.0.9.0/t/done/022-task-taskflow-migrate-dev-taskflow-ace-taskf/
?? .ace-taskflow/v.0.9.0/t/done/023-feat-llm-ace-llm-providers-cli-gem-cli-/
?? .ace-taskflow/v.0.9.0/t/done/024-task-taskflow-migrate-workflows-ace-taskflow/
?? .ace-taskflow/v.0.9.0/t/done/025-feat-llm-git-commit-llm-enhance-flags-i/
?? .ace-taskflow/v.0.9.0/t/done/026-feat-reschedule-subcommand-tasks-co/
?? .ace-taskflow/v.0.9.0/t/done/027-feat-release-command-directory-stru/
?? .ace-taskflow/v.0.9.0/t/done/028-test-taskflow-comprehensive-coverage-ace-tas/
?? .ace-taskflow/v.0.9.0/t/done/029-task-taskflow-ace-taskflow-workflow-instruct/
?? .ace-taskflow/v.0.9.0/t/done/030-fix-nav-ace-nav-protocol-path-formatti/
?? .ace-taskflow/v.0.9.0/t/done/031-feat-taskflow-descriptive-paths-ace-taskflow/
?? .ace-taskflow/v.0.9.0/t/done/032-feat-taskflow-preset-system-ace-taskflow-lis/
?? .ace-taskflow/v.0.9.0/t/done/033-feat-taskflow-enhanced-stats-summary-display/
?? .ace-taskflow/v.0.9.0/t/done/035-feat-llm-configuration-based-provider-a/
?? .ace-taskflow/v.0.9.0/t/done/036-fix-llm-ace-llm-query-executable-follo/
?? .ace-taskflow/v.0.9.0/t/done/037-feat-llm-env-cascade-loading-support-ac/
?? .ace-taskflow/v.0.9.0/t/done/038-feat-llm-proper-binstub-ace-llm-query/
?? .ace-taskflow/v.0.9.0/t/done/039-task-taskflow-ace-taskflow-display-status-co/
?? .ace-taskflow/v.0.9.0/t/done/040-task-taskflow-implemented-dependency-aware-s/
?? .ace-taskflow/v.0.9.0/t/done/041-feat-taskflow-move-done-and-reschedule/
?? .ace-taskflow/v.0.9.0/t/done/042-fix-git-ace-git-commit-api-key-loading/
?? .ace-taskflow/v.0.9.0/t/done/043-refactor-core-env-loading-centralize-ace-cor/
?? .ace-taskflow/v.0.9.0/t/done/044-feat-core-ace-core-init-subcommand-confi/
?? .ace-taskflow/v.0.9.0/t/done/045-task-restructurin---title-configuration-namespac/

```

### Command: `task-manager recent --limit 3`

**Output:**
```
Status: No tasks found
No recent tasks found

```

### Command: `task-manager next --limit 3`

**Output:**
```

```

### Command: `release-manager current`

**Output:**
```

```

### Command: `eza -R -1 -L 2 --git-ignore --absolute $PROJECT_ROOT_PATH`

**Output:**
```
/Users/mc/Ps/ace-meta/ace-context
/Users/mc/Ps/ace-meta/ace-core
/Users/mc/Ps/ace-meta/ace-git-commit
/Users/mc/Ps/ace-meta/ace-llm
/Users/mc/Ps/ace-meta/ace-llm-providers-cli
/Users/mc/Ps/ace-meta/ace-nav
/Users/mc/Ps/ace-meta/ace-taskflow
/Users/mc/Ps/ace-meta/ace-test-runner
/Users/mc/Ps/ace-meta/ace-test-support
/Users/mc/Ps/ace-meta/bin
/Users/mc/Ps/ace-meta/CHANGELOG.md
/Users/mc/Ps/ace-meta/CLAUDE.md
/Users/mc/Ps/ace-meta/dev-handbook
/Users/mc/Ps/ace-meta/dev-local
/Users/mc/Ps/ace-meta/dev-tools
/Users/mc/Ps/ace-meta/docs
/Users/mc/Ps/ace-meta/Gemfile
/Users/mc/Ps/ace-meta/Gemfile.lock
/Users/mc/Ps/ace-meta/migrate-taskflow.sh
/Users/mc/Ps/ace-meta/mise.toml
/Users/mc/Ps/ace-meta/Rakefile
/Users/mc/Ps/ace-meta/README.md
/Users/mc/Ps/ace-meta/reflections

```