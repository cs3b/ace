---
id: v.0.2.0+task.23
status: pending
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

Collection of code quality improvements to enhance maintainability, consistency, and reduce technical debt across CLI components and related functionality. These improvements include extracting common CLI functionality, improving URL construction, centralizing constants, and organizing fallback configurations.

## Scope of Work

- Extract shared patterns from CLI commands into reusable components
- Improve URL construction in GeminiClient using proper URI handling
- Extract hardcoded string values to well-named constants
- Centralize fallback model lists for better maintainability
- Improve overall code consistency and reduce duplication

### Deliverables

#### Create

- lib/coding_agent_tools/cli/shared_behavior.rb
- lib/coding_agent_tools/constants/cli_constants.rb
- lib/coding_agent_tools/constants/model_constants.rb
- lib/coding_agent_tools/config/fallback_models.yml

#### Modify

- lib/coding_agent_tools/organisms/gemini_client.rb
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

* [ ] Analyze CLI commands to identify shared patterns and duplicated code
  > TEST: Pattern Analysis Complete
  > Type: Pre-condition Check
  > Assert: Common CLI patterns are documented and shared functionality identified
  > Command: diff -u lib/coding_agent_tools/cli/commands/llm/models.rb lib/coding_agent_tools/cli/commands/lms/models.rb
* [ ] Identify all hardcoded strings that should be constants
  > TEST: Hardcoded Strings Catalogued
  > Type: Pre-condition Check
  > Assert: All hardcoded strings are documented with suggested constant names
  > Command: grep -r "\"[A-Z_]*\"" lib/coding_agent_tools/ --include="*.rb" | head -20
* [ ] Research current URL construction patterns in GeminiClient
* [ ] Document all fallback model lists across command classes

### Execution Steps

- [ ] Create shared CLI behavior module with common functionality
  > TEST: Shared Behavior Module Created
  > Type: Action Validation
  > Assert: Shared CLI behavior module is properly defined and includes common patterns
  > Command: ruby -r "./lib/coding_agent_tools/cli/shared_behavior" -e "puts CodingAgentTools::Cli::SharedBehavior"
- [ ] Extract common CLI functionality (error handling, output formatting, etc.)
- [ ] Update CLI commands to use shared behavior module
- [ ] Create CLI constants file with role names and formatting constants
  > TEST: CLI Constants Defined
  > Type: Action Validation
  > Assert: CLI constants are properly defined and accessible
  > Command: ruby -r "./lib/coding_agent_tools/constants/cli_constants" -e "puts CodingAgentTools::Constants::CliConstants::ROLE_USER"
- [ ] Replace hardcoded strings with constant references throughout codebase
- [ ] Improve URL construction in GeminiClient using Addressable::URI
  > TEST: URL Construction Improved
  > Type: Action Validation
  > Assert: GeminiClient uses proper URI handling methods
  > Command: grep -n "Addressable::URI" lib/coding_agent_tools/organisms/gemini_client.rb
- [ ] Add addressable gem dependency if not already present
- [ ] Create centralized fallback model configuration
- [ ] Update command classes to use centralized fallback models
  > TEST: Fallback Models Centralized
  > Type: Action Validation
  > Assert: Command classes use centralized fallback model configuration
  > Command: grep -L "fallback.*model" lib/coding_agent_tools/cli/commands/**/*.rb
- [ ] Run full test suite to verify no regressions
- [ ] Update documentation to reflect new shared components

## Acceptance Criteria

- [ ] CLI commands use shared behavior module for common functionality
- [ ] Code duplication is reduced between similar CLI commands
- [ ] All hardcoded strings are replaced with appropriately named constants
- [ ] GeminiClient uses proper URI handling instead of manual string concatenation
- [ ] Fallback model lists are centralized and easily configurable
- [ ] All existing functionality is preserved
- [ ] Test suite passes completely with no regressions
- [ ] Code follows established patterns and conventions
- [ ] Documentation is updated to reflect new shared components

## Out of Scope

- ❌ Adding new CLI commands or features
- ❌ Changing CLI command interfaces or behavior
- ❌ Major architectural changes to CLI framework
- ❌ Refactoring non-CLI code beyond specific improvements mentioned

## References

- [DRY principle documentation](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself)
- [Ruby constants best practices](https://ruby-doc.org/docs/ruby-doc-bundle/UsersGuide/rg/constants.html)
- [Addressable gem documentation](https://github.com/sporkmonger/addressable)
- [YAML configuration patterns](https://yaml.org/spec/1.2/spec.html)
- [CLI design patterns](https://clig.dev/)
- [Project coding standards](docs-dev/guides/coding-standards.md)
- [Refactoring best practices](docs-dev/guides/refactoring.md)