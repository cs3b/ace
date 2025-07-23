---
id: v.0.3.0+task.34
status: done
priority: high
estimate: 25h
dependencies: []
---

# Implement Code Review Module with ATOM Architecture

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 dev-tools/lib | sed 's/^/    /'
```

_Result excerpt:_

```
    dev-tools/lib
    ├── coding_agent_tools
    │   ├── atoms
    │   ├── cli
    │   ├── models
    │   ├── molecules
    │   └── organisms
    └── coding_agent_tools.rb
```

## Objective

Implement a complete code review module following the established ATOM architecture and taskflow_management pattern, creating `code-review` and `code-review-prepare` executables that extract and utilize reusable shell logic from the review-code workflow. This establishes a foundation for automated code review workflows with modular, testable components.

## Scope of Work

* Create code review executables following taskflow_management pattern
* Implement complete ATOM architecture stack (atoms → molecules → organisms → CLI)
* Extract shell logic from review-code.wf.md (~100 lines) into bash modules
* Establish session management, content extraction, and context loading
* Create bash module structure with module-loader system
* Integrate with existing LLM query infrastructure

### Deliverables

#### Create (Executables)

* dev-tools/exe/code-review
* dev-tools/exe/code-review-prepare

#### Create (CLI Commands)

* lib/coding_agent_tools/cli/commands/code/review.rb
* lib/coding_agent_tools/cli/commands/code/review_prepare.rb

#### Create (Organisms)

* lib/coding_agent_tools/organisms/code/review_manager.rb
* lib/coding_agent_tools/organisms/code/session_manager.rb
* lib/coding_agent_tools/organisms/code/content_extractor.rb
* lib/coding_agent_tools/organisms/code/context_loader.rb
* lib/coding_agent_tools/organisms/code/prompt_builder.rb

#### Create (Molecules)

* lib/coding_agent_tools/molecules/code/session_directory_builder.rb
* lib/coding_agent_tools/molecules/code/git_diff_extractor.rb
* lib/coding_agent_tools/molecules/code/file_pattern_extractor.rb
* lib/coding_agent_tools/molecules/code/project_context_loader.rb
* lib/coding_agent_tools/molecules/code/prompt_combiner.rb

#### Create (Atoms)

* lib/coding_agent_tools/atoms/code/session_timestamp_generator.rb
* lib/coding_agent_tools/atoms/code/session_name_builder.rb
* lib/coding_agent_tools/atoms/code/git_command_executor.rb
* lib/coding_agent_tools/atoms/code/file_content_reader.rb
* lib/coding_agent_tools/atoms/code/directory_creator.rb

#### Create (Models)

* lib/coding_agent_tools/models/code/review_session.rb
* lib/coding_agent_tools/models/code/review_target.rb
* lib/coding_agent_tools/models/code/review_context.rb
* lib/coding_agent_tools/models/code/review_prompt.rb

#### Create (Bash Modules)

* dev-tools/lib/bash/module-loader.sh
* dev-tools/lib/bash/modules/code/session-management.sh
* dev-tools/lib/bash/modules/code/content-extraction.sh
* dev-tools/lib/bash/modules/code/context-loading.sh

#### Modify

* lib/coding_agent_tools/cli.rb (register code commands)
* lib/coding_agent_tools/organisms.rb (autoload code module)
* lib/coding_agent_tools/molecules.rb (autoload code module)
* lib/coding_agent_tools/atoms.rb (autoload code module)
* lib/coding_agent_tools/models.rb (autoload code module)

## Phases

1. Design ATOM architecture and data flow
2. Create foundational models and bash modules
3. Implement atoms for basic operations
4. Build molecules for composed operations
5. Create organisms for business logic
6. Implement CLI commands and executables
7. Extract shell logic from review-code.wf.md
8. Integration testing and validation

## Implementation Plan

### Planning Steps

* [x] Analyze review-code.wf.md workflow for shell logic extraction points
  > TEST: Shell Logic Analysis
  > Type: Pre-condition Check
  > Assert: 33 bash code blocks identified and categorized by function
  > Command: rg -c '\`\`\`bash' dev-handbook/workflow-instructions/review-code.wf.md
* [x] Design ATOM component hierarchy and data flow patterns
* [x] Map workflow parameters to command-line interface design
* [x] Plan bash module loading and organization structure
  > TEST: Module Architecture Planning
  > Type: Pre-condition Check
  > Assert: Module structure documented with clear dependencies
  > Command: echo "Planned modules: session-management, content-extraction, context-loading" | wc -w

### Execution Steps

- [x] Create Models layer with data structures for review components
- [x] Create bash module-loader.sh and directory structure
  > TEST: Module Loader Functionality
  > Type: Shell Test
  > Assert: Module loader can source and validate bash modules
  > Command: source dev-tools/lib/bash/module-loader.sh && load_module code session-management && type -t create_session_directory
- [x] Implement Atoms layer for basic file, git, and directory operations
- [x] Extract session management logic from review-code.wf.md lines 78-95
- [x] Create Molecules layer for composed operations (diff extraction, context loading)
- [x] Extract content resolution logic from review-code.wf.md lines 134-200
- [x] Implement Organisms layer for business logic orchestration
- [x] Create CLI command classes with parameter validation and help
- [x] Build code-review executable with focus-based system prompt selection
  > TEST: Code Review Command Integration
  > Type: CLI Test
  > Assert: code-review command accepts parameters and creates session
  > Command: dev-tools/exe/code-review --focus code --target HEAD~1..HEAD --dry-run
- [x] Build code-review-prepare executable with sub-command structure
- [x] Register commands in CLI autoloader and update module autoloaders
- [x] Test complete workflow with session creation, content extraction, and prompt building
  > TEST: End-to-End Workflow
  > Type: Integration Test
  > Assert: Complete review session created with all components
  > Command: dev-tools/exe/code-review-prepare session-dir --focus tests --target staged

## Acceptance Criteria

* [x] All ATOM components follow established architecture patterns
* [x] Shell logic extracted from review-code.wf.md (~100 lines) into reusable modules
* [x] code-review command supports all workflow parameters with validation
* [x] code-review-prepare supports 4 sub-commands: session-dir, project-context, project-target, prompt
* [x] Bash modules can be loaded and functions called independently
* [ ] Integration with existing LLM query infrastructure works correctly
* [ ] All components have appropriate test coverage following project standards
* [x] Commands follow naming conventions: target.diff, context.md, prompt.md
* [x] Focus parameter drives automatic system prompt selection
* [x] Session management creates structured directories with metadata

## Out of Scope

* ❌ Implementation of actual LLM review analysis (uses existing llm-query)
* ❌ GUI or web interface for code review
* ❌ Integration with external code review platforms (GitHub, GitLab)
* ❌ Advanced diff visualization or formatting
* ❌ Automated code suggestion or fixing capabilities
* ❌ Support for non-git version control systems

## References

* Source workflow: dev-handbook/workflow-instructions/review-code.wf.md
* Architecture pattern: docs/architecture.md (ATOM hierarchy)
* Command pattern: lib/coding_agent_tools/organisms/taskflow_management/
* Shell logic: review-code.wf.md lines 78-95 (session), 134-200 (content)
* Total new files: 2 executables + 25 Ruby components + 4 bash modules = 31 files