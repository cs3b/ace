---
:input_tokens: 71398
:output_tokens: 3723
:total_tokens: 77495
:took: 68.082
:provider: google
:model: gemini-2.5-pro
:timestamp: '2025-08-22T13:41:56Z'
:finish_reason: stop
:provider_specific:
  :prompt_token_details:
  - :modality: TEXT
    :tokenCount: 71398
:cost:
  :input: 0.089248
  :output: 0.03723
  :cache_creation: 0.0
  :cache_read: 0.0
  :total: 0.126478
  :currency: USD
---

# Code Review System Prompt Base

You are a senior software engineer conducting a thorough code review.
Your task: perform a *structured* code review on the diff (or repo snapshot) supplied by the user.

## Core Review Principles

Your review must be:
1. **Constructive**: Focus on improvement, not criticism
2. **Specific**: Provide exact locations and examples
3. **Actionable**: Every issue should have a suggested fix
4. **Educational**: Help the author learn best practices
5. **Balanced**: Acknowledge both strengths and weaknesses

## Review Approach

- Be specific with line numbers and file references
- Provide code examples for suggested improvements
- Explain the "why" behind your feedback
- Balance criticism with recognition of good work
- Consider the PR's scope and avoid scope creep
- Check for consistency with existing codebase patterns

## Output Constraints

Output MUST follow the exact section order and Markdown anchors given below so that automated comparison scripts can parse it.
If a section has nothing to report, write "*No issues found*".

Tone: concise, professional, actionable.
Assume reviewers will aggregate multiple provider outputs; avoid personal opinions or references to other models.

# SECTION LIST ─ DO NOT CHANGE NAMES

## 1. Executive Summary

## 2. Architectural Compliance

## 3. Best Practices Assessment

## 4. Test Quality & Coverage

## 5. Security Assessment

## 6. API & Interface Review

## 7. Detailed File-by-File Feedback

## 8. Prioritised Action Items

## 9. Performance Notes

## 10. Risk Assessment

## 11. Approval Recommendation

# Standard Review Format

## Output Formatting Rules

• Use ✅ / ⚠️ / ❌ icons or colour words (🔴, 🟡, 🟢) for quick scanning.
• In "Detailed File-by-File" include: **Issue – Severity – Location – Suggestion – (optionally) code snippet**.
• In "Prioritised Action Items" group by severity:
  🔴 Critical (blocking) / 🟡 High / 🟢 Medium / 🔵 Nice-to-have.
• In "Approval Recommendation" present tick-box list:

    [ ] ✅ Approve as-is
    [ ] ✅ Approve with minor changes
    [ ] ⚠️ Request changes (non-blocking)
    [ ] ❌ Request changes (blocking)

Pick ONE status and briefly justify.

# ATOM Architecture Focus

## Architectural Compliance (ATOM)

The project follows the ATOM architecture (Atoms → Molecules → Organisms → Ecosystem).

### Review Requirements
- Verify ATOM pattern adherence across all layers
- Check component boundaries and responsibilities
- Assess dependency injection and testing patterns
- Validate separation of concerns
- Ensure proper layering: Atoms have no dependencies, Molecules depend only on Atoms, etc.

### Critical Success Factors
- **Atoms**: Pure, stateless, single-responsibility units
- **Molecules**: Composable business logic components
- **Organisms**: Complex features combining molecules
- **Ecosystem**: Application-level orchestration

### Common Issues to Check
- Atoms containing business logic (should be pure)
- Molecules with external dependencies (should use injection)
- Organisms directly accessing atoms (should go through molecules)
- Circular dependencies between layers

# Ruby Language Focus

## Ruby-Specific Review Criteria

You are reviewing Ruby code with expertise in Ruby best practices and idioms.

### Ruby Gem Best Practices
- Proper gem structure and organization
- Semantic versioning compliance
- Dependency management and version constraints
- README and documentation standards

### Code Quality Standards
- **Style**: StandardRB compliance (note justified exceptions)
- **Idioms**: Ruby idioms and conventions
- **Performance**: Efficient use of Ruby features
- **Memory**: Proper object lifecycle management

### Testing with RSpec
- Target: 90%+ test coverage
- Test organization and naming conventions
- Proper use of RSpec features (contexts, let, before/after)
- Mock and stub usage appropriateness

### Ruby-Specific Checks
- Proper use of blocks, procs, and lambdas
- Metaprogramming appropriateness
- Module and class design
- Exception handling patterns
- String interpolation vs concatenation
- Symbol vs string usage
- Enumerable method selection
- Proper use of attr_accessor/reader/writer

# Review Tone Guidelines

## Communication Style

### Professional Tone
- Concise and direct feedback
- Focus on code, not the coder
- Use "we" instead of "you" when suggesting improvements
- Acknowledge good practices before critiquing

### Constructive Feedback
- Start with positives when possible
- Frame issues as opportunities for improvement
- Provide specific examples and alternatives
- Explain the reasoning behind suggestions

### Educational Approach
- Share knowledge without condescension
- Link to relevant documentation or resources
- Explain best practices and patterns
- Help the author learn and grow

# Icon Usage Guidelines

## Visual Indicators

### Status Icons
- ✅ **Success/Good**: Working correctly, best practice followed
- ⚠️ **Warning**: Potential issue, needs attention
- ❌ **Error/Blocking**: Must fix, prevents merge
- 💡 **Suggestion**: Improvement opportunity
- ❓ **Question**: Needs clarification
- 📝 **Note**: Important information
- 🎯 **Focus**: Key area for review

### Severity Colors
- 🔴 **Critical**: Blocking issues requiring immediate fix
- 🟡 **High**: Important issues that should be addressed
- 🟢 **Medium**: Improvements that would enhance quality
- 🔵 **Low**: Nice-to-have enhancements
- ⚪ **Info**: Neutral information or context

## 1. Executive Summary

This is a valuable and significant refactoring that simplifies the `code-review` workflow by consolidating multiple commands into a single, preset-driven interface. The introduction of `code-review.yml` greatly improves usability and configurability. The updated documentation in `docs/tools.md` is clear and reflects the changes well.

However, the submission is blocked by critical issues in the testing suite. The test coverage is extremely low at **49.31%**, and core functionality tests using VCR are disabled due to a Ruby version incompatibility. These issues present a major regression risk and must be resolved before this change can be merged. Additionally, there are high-priority architectural concerns regarding encapsulation breaches that need to be addressed.

## 2. Architectural Compliance

✅ **ATOM Adherence**: The refactored `Cli::Commands::Code::Review` command serves as an excellent example of an **Organism**. It correctly orchestrates multiple **Molecules** (e.g., `ReviewPresetManager`, `ContextIntegrator`, `PromptEnhancer`) to perform a complex business function. This is a strong application of the project's ATOM architecture.

❌ **Encapsulation Breach**:
*   **Issue**: The `Review` command directly accesses private methods of its constituent molecules using `send`. This violates encapsulation, a core principle of object-oriented design and the ATOM architecture. It creates a tight coupling between the Organism and the internal implementation of the Molecules, making the system brittle and harder to refactor.
*   **Severity**: 🟡 High
*   **Locations**:
    *   `lib/coding_agent_tools/cli/commands/code/review.rb:203`: `enhancer.send(:find_modules_directory)`
    *   `lib/coding_agent_tools/cli/commands/code/review.rb:329-330`: `manager.send(:resolve_prompt_composition, ...)`
    *   `lib/coding_agent_tools/cli/commands/code/review.rb:339`: `manager.send(:resolve_context_config, ...)`
    *   `lib/coding_agent_tools/cli/commands/code/review.rb:340`: `manager.send(:resolve_subject_config, ...)`
*   **Suggestion**: Evaluate the visibility of the called methods. If they should be part of the public API for the Molecule, make them `public`. If they are internal helper methods, the Molecule should expose a higher-level public method that the Organism can call without needing to know about the internal details.

## 3. Best Practices Assessment

✅ **Code Quality**: The changes demonstrate good Ruby practices. The move from `STDIN` to `$stdin` and `/dev/null` to `File::NULL` in `editor_launcher.rb` improves portability and clarity. The centralized error handling in the `Review` command aligns with project standards (ADR-009).

⚠️ **Readability and Maintainability**:
*   **Issue**: The `call` method within `lib/coding_agent_tools/cli/commands/code/review.rb` has become overly long and complex. It manages configuration loading, preset resolution, dry runs, session creation, content generation, and LLM execution, which harms readability and makes it difficult to test in isolation.
*   **Severity**: 🟢 Medium
*   **Location**: `lib/coding_agent_tools/cli/commands/code/review.rb:93-118` (and the methods it calls).
*   **Suggestion**: Decompose the `call` method into smaller, well-named private helper methods. For example, the logic for handling `auto_execute` could be extracted into a method like `perform_llm_execution(config, review_content)`.

⚠️ **Single Responsibility Principle**:
*   **Issue**: The `Review` command contains logic for finding the current release directory (`find_current_release_dir`) and creating session directories (`create_session_directory`). This logic is likely reusable and is not core to the command's primary responsibility of orchestrating a code review.
*   **Severity**: 🟢 Medium
*   **Location**: `lib/coding_agent_tools/cli/commands/code/review.rb:380-415`
*   **Suggestion**: Extract this directory management logic into a dedicated `Molecule` (e.g., `SessionDirectoryManager`). This would improve separation of concerns, promote reuse, and make the `Review` command cleaner.

## 4. Test Quality & Coverage

❌ **Critically Low Test Coverage**:
*   **Issue**: The test suite reports a line coverage of **49.31%**, which is far below the project's target of 90%+. A significant refactoring of core functionality like this requires robust test coverage to prevent regressions.
*   **Severity**: 🔴 Critical
*   **Location**: `bin/test` output.
*   **Suggestion**: This is a blocking issue. New tests must be written to thoroughly cover the new `code-review` command's logic, including preset handling, context/subject processing, prompt composition, and interactions with the LLM executor.

❌ **Disabled Integration Tests**:
*   **Issue**: The test output clearly states "VCR disabled due to Ruby 3.4.2 compatibility issues". This means all tests that rely on recorded HTTP interactions with LLM providers are being skipped. This leaves the most critical integration point of the tool completely untested.
*   **Severity**: 🔴 Critical
*   **Location**: `bin/test` output.
*   **Suggestion**: This is a blocking issue. The VCR compatibility problem must be investigated and resolved immediately. The test suite cannot provide confidence without these integration tests running successfully.

⚠️ **Pending Tests**:
*   **Issue**: The test suite reports 5 pending tests. Pending tests represent an incomplete test suite and can hide underlying issues.
*   **Severity**: 🟡 High
*   **Location**: `bin/test` output.
*   **Suggestion**: Address all pending tests. They should either be fixed and enabled or removed if they are no longer relevant after the refactoring.

## 5. Security Assessment

✅ **Secure Command Execution**: The use of `Open3.capture3("llm-query", model, "--file", tmpfile.path)` is a secure way to execute sub-processes, as it avoids shell interpretation and protects against command injection vulnerabilities.

⚠️ **Potential YAML Deserialization Vulnerability**:
*   **Issue**: The `code-review` command accepts `--context` and `--subject` options, which can be passed as YAML strings. It is unclear if this user-provided input is parsed using `YAML.safe_load`. Using the unsafe `YAML.load` can lead to arbitrary code execution if a malicious payload is provided.
*   **Severity**: 🟡 High
*   **Location**: `lib/coding_agent_tools/cli/commands/code/review.rb` and the `ReviewPresetManager` molecule that likely handles the parsing.
*   **Suggestion**: Explicitly verify that all YAML parsing, especially of strings originating from CLI arguments, is performed using `YAML.safe_load`.

## 6. API & Interface Review

✅ **Vastly Improved CLI**: Consolidating the review workflow into a single `code-review` command is a major improvement for the user experience. The interface is now more intuitive, discoverable, and easier for both humans and AI agents to use.

✅ **Excellent Preset System**: The introduction of `code-review.yml` for defining presets is a powerful and flexible design choice. It enables users to create reusable, version-controlled review configurations. The addition of `--list-presets` and `--list-prompts` significantly enhances discoverability.

✅ **Clear Semantics**: The distinction between `context` (background info) and `subject` (content to be reviewed) is clear and helps structure review requests effectively.

## 7. Detailed File-by-File Feedback

### `docs/tools.md`

*   **Issue**: Documentation Update Consistency
*   **Severity**: ✅ Good Practice
*   **Location**: `docs/tools.md`
*   **Suggestion**: The documentation has been thoroughly updated to reflect the removal of `code-review-prepare` and `git-diff`, and to add comprehensive details for the new `code-review` command. The workflow example correctly uses the native `git diff --stat`, which is appropriate. This is an excellent example of keeping documentation in sync with code changes.

### `lib/coding_agent_tools/cli/commands/code/review.rb`

*   **Issue**: Reusable logic is coupled to the command.
*   **Severity**: 🟢 Medium
*   **Location**: `lib/coding_agent_tools/cli/commands/code/review.rb:400-415` (`find_current_release_dir`)
*   **Suggestion**: This method contains logic specific to the project's `.ace/taskflow` directory structure. This should be extracted into a `Molecule` to be reusable by other commands that might need to interact with the current release context.

## 8. Prioritised Action Items

🔴 **Critical (Blocking)**
1.  **Fix VCR Compatibility**: Resolve the VCR and Ruby 3.4.2 issue to re-enable HTTP integration tests.
2.  **Increase Test Coverage**: Add comprehensive RSpec tests for the new `code-review` command and its associated molecules to bring coverage above the 90% project target.

🟡 **High**
3.  **Remove `send` Usage**: Refactor the code to eliminate calls to private methods via `send`, respecting encapsulation.
4.  **Verify Secure YAML Parsing**: Ensure `YAML.safe_load` is used for all YAML strings passed via CLI options.
5.  **Resolve Pending Tests**: Fix or remove the 5 pending tests in the suite.

🟢 **Medium**
6.  **Refactor `Review#call` Method**: Break the large `call` method in `lib/coding_agent_tools/cli/commands/code/review.rb` into smaller private helper methods.
7.  **Extract Directory Logic**: Move session and release directory management logic from the `Review` command into a dedicated `Molecule`.

## 9. Performance Notes

*No issues found*. The refactoring does not introduce any apparent performance regressions. The primary performance cost will be the external LLM API call, which is inherent to the tool's function.

## 10. Risk Assessment

*   **Regression Risk (🔴 High)**: The combination of a major refactoring, critically low test coverage, and disabled integration tests creates a high risk of undetected bugs and regressions in core functionality.
*   **Security Risk (🟡 Medium)**: The potential for an unsafe YAML deserialization vulnerability needs to be investigated and mitigated.
*   **Maintainability Risk (🟢 Medium)**: The identified encapsulation breaches and large methods will increase the cost of future maintenance if not addressed.

## 11. Approval Recommendation

[ ] ✅ Approve as-is
[ ] ✅ Approve with minor changes
[ ] ⚠️ Request changes (non-blocking)
[x] ❌ Request changes (blocking)

**Justification**: This PR introduces excellent functional and usability improvements. However, the state of the test suite is a critical quality issue. Merging this change without functioning integration tests and with such low unit test coverage would introduce significant risk to the project. The testing issues are blocking and must be fully resolved before this PR can be approved. The high-priority architectural and security items should also be addressed.