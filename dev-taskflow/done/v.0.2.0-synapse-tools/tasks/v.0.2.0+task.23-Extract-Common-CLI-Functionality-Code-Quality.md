---
id: v.0.2.0+task.23
status: done
priority: low
estimate: 4h
dependencies: []
---

# Extract Common CLI Functionality Code Quality

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 3 lib/coding_agent_tools/ | grep -E "(cli|organisms)" && find . -name "*.rb" -path "*/cli/*" | head -10
```

_Result excerpt:_

```
lib/coding_agent_tools/
├── cli/
│   ├── commands/
│   │   ├── llm/
│   │   │   └── models.rb
│   │   └── lms/
│   │       └── models.rb
│   └── base.rb
├── organisms/
│   ├── gemini_client.rb
│   ├── lm_studio_client.rb
│   └── base_client.rb

./lib/coding_agent_tools/cli/commands/llm/models.rb
./lib/coding_agent_tools/cli/commands/lms/models.rb
```

## Objective

Collection of remaining code quality improvements to enhance maintainability, consistency, and reduce technical debt across CLI components. Focus on extracting shared patterns from CLI command classes, refactoring repetitive URL construction in GeminiClient, centralizing constants, and organizing fallback configurations.

**Note**: ExecutableWrapper molecule has already been implemented (commit 2c27340), eliminating 400+ lines of duplicated code across exe/* scripts. This task focuses on the remaining CLI command-level improvements.

## Scope of Work

- Extract shared patterns from CLI command classes into reusable components
- Refactor repetitive URL construction pattern in GeminiClient (3 instances of duplicate logic)
- Extract hardcoded string values to well-named constants
- Centralize fallback model lists for better maintainability
- Improve overall code consistency and reduce duplication in CLI commands

### Deliverables

#### Create

- lib/coding_agent_tools/cli/shared_behavior.rb
- lib/coding_agent_tools/constants/cli_constants.rb
- lib/coding_agent_tools/constants/model_constants.rb
- lib/coding_agent_tools/config/fallback_models.yml

#### Modify

- lib/coding_agent_tools/organisms/gemini_client.rb (refactor URL construction duplication)
- lib/coding_agent_tools/cli/commands/llm/models.rb
- lib/coding_agent_tools/cli/commands/lms/models.rb
- Various files with hardcoded strings and model lists

## Phases

1. Audit - Identify improvement opportunities across the codebase
2. Extract - Create shared components and constants
3. Refactor - Apply improvements to existing code
4. Verify - Ensure all changes maintain functionality

## Implementation Plan

### Planning Steps

* [x] Analyze CLI command classes to identify shared patterns and duplicated code
  > TEST: Pattern Analysis Complete
  > Type: Pre-condition Check
  > Assert: Common CLI patterns are documented and shared functionality identified (methods like filter_models, output_models, handle_error are duplicated)
  > Command: diff -u lib/coding_agent_tools/cli/commands/llm/models.rb lib/coding_agent_tools/cli/commands/lms/models.rb
* [x] Identify all hardcoded strings that should be constants
  > TEST: Hardcoded Strings Catalogued
  > Type: Pre-condition Check
  > Assert: All hardcoded strings are documented with suggested constant names
  > Command: grep -r "\"[A-Z_]*\"" lib/coding_agent_tools/ --include="*.rb" | head -20
* [x] Research repetitive URL construction patterns in GeminiClient (3 instances of duplicate base_path logic)
  > TEST: URL Construction Patterns Identified
  > Type: Pre-condition Check  
  > Assert: Repetitive URL construction logic is documented (list_models, model_info, build_api_url methods)
  > Command: grep -n "base_path.*=.*url_obj\.path" lib/coding_agent_tools/organisms/gemini_client.rb
* [x] Document all fallback model lists across command classes

### Execution Steps

- [x] Create shared CLI behavior module with common functionality
  > TEST: Shared Behavior Module Created
  > Type: Action Validation
  > Assert: Shared CLI behavior module is properly defined and includes common patterns
  > Command: ruby -r "./lib/coding_agent_tools/cli/shared_behavior" -e "puts CodingAgentTools::Cli::SharedBehavior"
- [x] Extract common CLI functionality (error handling, output formatting, etc.)
- [x] Update CLI commands to use shared behavior module
- [x] Create CLI constants file with role names and formatting constants
  > TEST: CLI Constants Defined
  > Type: Action Validation
  > Assert: CLI constants are properly defined and accessible
  > Command: ruby -r "./lib/coding_agent_tools/constants/cli_constants" -e "puts CodingAgentTools::Constants::CliConstants::ROLE_USER"
- [x] Replace hardcoded strings with constant references throughout codebase
- [x] Extract repetitive URL construction logic in GeminiClient into a private helper method
  > TEST: URL Construction Refactored
  > Type: Action Validation
  > Assert: GeminiClient has single URL construction method instead of 3 duplicated patterns
  > Command: grep -c "base_path.*=.*url_obj\.path" lib/coding_agent_tools/organisms/gemini_client.rb | test "$(cat)" -eq 1
- [x] Create centralized fallback model configuration
- [x] Update command classes to use centralized fallback models
  > TEST: Fallback Models Centralized
  > Type: Action Validation
  > Assert: Command classes use centralized fallback model configuration
  > Command: grep -L "fallback.*model" lib/coding_agent_tools/cli/commands/**/*.rb
- [x] Run full test suite to verify no regressions
- [x] Update documentation to reflect new shared components

## Acceptance Criteria

- [x] CLI command classes use shared behavior module for common functionality (filter_models, output_models, handle_error methods)
- [x] Code duplication is reduced between llm/models.rb and lms/models.rb commands
- [x] All hardcoded strings in CLI commands are replaced with appropriately named constants
- [x] GeminiClient URL construction logic is extracted into a single private helper method (eliminating 3 instances of duplicate base_path logic)
- [x] Fallback model lists are centralized in YAML configuration and easily configurable
- [x] All existing functionality is preserved (no behavior changes to CLI commands)
- [x] Test suite passes completely with no regressions
- [x] Code follows established ATOM architecture patterns and conventions
- [x] Documentation is updated to reflect new shared CLI components
- [x] ExecutableWrapper functionality remains intact (already implemented and working)

## Out of Scope

- ❌ Adding new CLI commands or features
- ❌ Changing CLI command interfaces or behavior
- ❌ Major architectural changes to CLI framework
- ❌ Refactoring non-CLI code beyond specific improvements mentioned
- ❌ Reworking ExecutableWrapper (already completed in commit 2c27340)
- ❌ Major changes to Addressable::URI usage (already properly implemented)

## References

- [DRY principle documentation](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself)
- [Ruby constants best practices](https://ruby-doc.org/docs/ruby-doc-bundle/UsersGuide/rg/constants.html)
- [Addressable gem documentation](https://github.com/sporkmonger/addressable)
- [YAML configuration patterns](https://yaml.org/spec/1.2/spec.html)
- [CLI design patterns](https://clig.dev/)
- [Project coding standards](docs-dev/guides/coding-standards.md)
- [Refactoring best practices](docs-dev/guides/refactoring.md)