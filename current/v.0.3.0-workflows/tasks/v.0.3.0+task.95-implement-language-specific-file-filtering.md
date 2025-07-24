---
id: v.0.3.0+task.95
status: pending
priority: high
estimate: 4h
dependencies: [v.0.3.0+task.93]
---

# Implement Language-Specific File Filtering

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 dev-handbook/guides | sed 's/^/    /'
```

_Result excerpt:_

```
    dev-handbook/guides
    ├── ai-agent-integration.g.md
    ├── atom-pattern.g.md
    ├── changelog.g.md
    ├── code-review-process.g.md
    ├── coding-standards
    │   ├── ruby.md
    │   ├── rust.md
    │   └── typescript.md
    ├── coding-standards.g.md
    ├── debug-troubleshooting.g.md
    ├── documentation
    │   ├── ruby.md
    │   ├── rust.md
    │   └── typescript.md
    ├── documentation.g.md
    ├── documents-embedded-sync.g.md
    ├── documents-embedding.g.md
    ├── draft-release
    │   └── README.md
    ├── embedded-testing-guide.g.md
    ├── error-handling
    │   ├── ruby.md
    │   ├── rust.md
    │   └── typescript.md
    ├── error-handling.g.md
    ├── llm-query-tool-reference.g.md
    ├── migration
    ├── performance
    │   ├── ruby.md
    │   ├── rust.md
    │   └── typescript.md
    ├── performance.g.md
    ├── project-management
    │   ├── README.md
    │   └── release-codenames.g.md
    ├── project-management.g.md
    ├── quality-assurance
    │   ├── ruby.md
    │   ├── rust.md
    │   └── typescript.md
    ├── quality-assurance.g.md
    ├── README.md
    ├── release-codenames.g.md
    ├── release-publish
    │   ├── ruby.md
    │   ├── rust.md
    │   └── typescript.md
    ├── release-publish.g.md
    ├── roadmap-definition.g.md
    ├── security
    │   ├── ruby.md
    │   ├── rust.md
    │   └── typescript.md
    ├── security.g.md
    ├── strategic-planning.g.md
    ├── task-definition.g.md
    ├── temporary-file-management.g.md
    ├── test-driven-development-cycle
    │   ├── meta-documentation.md
    │   ├── ruby-application.md
    │   ├── ruby-gem.md
    │   ├── rust-cli.md
    │   ├── rust-wasm-zed.md
    │   ├── typescript-nuxt.md
    │   └── typescript-vue.md
    ├── testing
    │   ├── ruby-rspec-config-examples.md
    │   ├── ruby-rspec.md
    │   ├── rust.md
    │   ├── typescript-bun.md
    │   ├── vue-firebase-auth.md
    │   └── vue-vitest.md
    ├── testing-tdd-cycle.g.md
    ├── testing.g.md
    ├── troubleshooting
    │   ├── ruby.md
    │   ├── rust.md
    │   └── typescript.md
    ├── version-control
    │   ├── ruby.md
    │   ├── rust.md
    │   └── typescript.md
    ├── version-control-system-git.g.md
    └── version-control-system-message.g.md
```

## Objective

Implement robust language-specific file filtering to ensure that even when glob patterns return mixed file types, Ruby linters only process Ruby files, Markdown linters only process Markdown files, etc. This prevents cross-language linting errors and improves performance by avoiding unnecessary processing. File detection should be based on explicit patterns defined in .coding-agent/lint.yml rather than content analysis.

## Scope of Work

- Create a file type detection system based on explicit file patterns from configuration
- Implement filtering logic for each language runner using configured patterns
- Ensure glob patterns are properly filtered before passing to linters
- Handle special Ruby files without extensions (Gemfile, exe/* scripts) via configuration
- Update .coding-agent/lint.yml to include explicit file pattern definitions

### Deliverables

#### Create

- dev-tools/lib/coding_agent_tools/atoms/code_quality/file_type_detector.rb
- dev-tools/lib/coding_agent_tools/atoms/code_quality/language_file_filter.rb

#### Modify

- dev-tools/lib/coding_agent_tools/organisms/code_quality/ruby_runner.rb (from task 93)
- dev-tools/lib/coding_agent_tools/organisms/code_quality/markdown_runner.rb (from task 93)
- dev-tools/lib/coding_agent_tools/atoms/code_quality/configuration_loader.rb (add file pattern config)

#### Delete

- None expected

## Phases

1. Audit current file detection and filtering mechanisms
2. Design file type detection system with extension and content-based detection
3. Implement language-specific file filtering
4. Integrate filtering into language runners
5. Test with mixed file type scenarios

## Implementation Plan

### Planning Steps

- [ ] Analyze current file discovery patterns in Ruby and Markdown pipelines
  > TEST: Current File Discovery
  > Type: Understanding Check
  > Assert: Current file discovery methods and patterns are documented
  > Command: nav-path file ruby_linting_pipeline
- [ ] Design configuration-based file pattern matching for Ruby files (.rb, .gemspec, Gemfile, exe/*)
- [ ] Design configuration-based file pattern matching for Markdown files (.md, .markdown)

### Execution Steps

- [ ] Create FileTypeDetector class that uses configuration-based pattern matching
- [ ] Implement pattern-based detection using .coding-agent/lint.yml file patterns
  > TEST: Pattern Detection
  > Type: Feature Validation
  > Assert: FileTypeDetector correctly identifies file types using configured patterns
  > Command: ruby -r ./lib/coding_agent_tools -e "puts CodingAgentTools::Atoms::CodeQuality::FileTypeDetector.detect_type('test.rb')"
- [ ] Update .coding-agent/lint.yml to include explicit file patterns for Ruby (*.rb, *.gemspec, Gemfile, exe/*) and Markdown (*.md, *.markdown)
- [ ] Update dev-handbook/.meta/tpl/dotfiles template with new file pattern configuration
- [ ] Create LanguageFileFilter class that filters file lists by language
- [ ] Integrate file filtering into RubyRunner to only process Ruby files
  > TEST: Ruby File Filtering
  > Type: Integration Validation
  > Assert: RubyRunner only processes Ruby files when given mixed file list
  > Command: code-lint ruby docs/ lib/ --dry-run | grep -c "\.md files"
- [ ] Integrate file filtering into MarkdownRunner to only process Markdown files
- [ ] Add configuration options for custom file patterns in .coding-agent/lint.yml
- [ ] Handle edge cases: symlinks, files without extensions, case sensitivity

## Acceptance Criteria

- [ ] AC 1: Ruby runner ignores non-Ruby files even when they are in provided paths
- [ ] AC 2: Markdown runner ignores non-Markdown files even when they are in provided paths
- [ ] AC 3: File type detection works for configured Ruby file patterns (*.rb, *.gemspec, Gemfile, exe/*)
- [ ] AC 4: File type detection works for configured Markdown file patterns (*.md, *.markdown)
- [ ] AC 5: Custom file patterns can be configured via .coding-agent/lint.yml

## Out of Scope

- ❌ Adding support for new file types beyond Ruby and Markdown
- ❌ Content-based language detection (using configuration-based patterns only)
- ❌ Performance optimization for large file sets
- ❌ Integration with external file type detection libraries

## References

```
Current Ruby patterns: StandardRB's built-in file discovery
Current Markdown patterns: Dir.glob(File.join(path, "**", "*.md"))
Configuration: .coding-agent/lint.yml for explicit file patterns
Ruby patterns: *.rb, *.gemspec, Gemfile, exe/* (no content-based detection)
Markdown patterns: *.md, *.markdown (explicit patterns only)
```