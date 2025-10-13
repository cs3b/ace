---
id: v.0.3.0+task.88
status: done
priority: high
estimate: 3h
dependencies: []
---

# Refactor CommitMessageGenerator to use direct Ruby calls

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 .ace/tools/lib/coding_agent_tools/molecules/git | grep commit | sed 's/^/    /'
```

_Result excerpt:_

```
    ├── commit_message_generator.rb
```

## Objective

Replace the current implementation of CommitMessageGenerator that shells out to the `llm-query` executable with direct Ruby calls to the appropriate LLM client organisms. This will improve performance by avoiding process creation overhead, eliminate dependency on PATH, and remove the complexity of temporary files for prompts.

## Scope of Work

- Analyze current shelling out implementation in CommitMessageGenerator
- Identify the appropriate organisms/clients to call directly
- Refactor to use direct Ruby method calls
- Remove temporary file handling logic
- Ensure all functionality is preserved

### Deliverables

#### Create

- None

#### Modify

- .ace/tools/lib/coding_agent_tools/molecules/git/commit_message_generator.rb

#### Delete

- None (possibly remove temporary file handling code)

## Phases

1. Analyze current implementation
2. Identify direct Ruby API to use
3. Refactor the implementation
4. Test the changes

## Implementation Plan

### Planning Steps

- [x] Review current CommitMessageGenerator implementation
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: Current shelling out implementation is understood
  > Command: cd .ace/tools && grep -n "Open3\|llm-query" lib/coding_agent_tools/molecules/git/commit_message_generator.rb
- [x] Identify which LLM organisms/clients are available for direct use
- [x] Understand the prompt format and parameters being passed

### Execution Steps

- [x] Step 1: Identify the LLM client to use directly
  - Look for GoogleClient, AnthropicClient, or a generic LLMQueryOrchestrator
  - Review how llm-query executable determines which provider to use
- [x] Step 2: Replace shell command construction with direct method calls
  > TEST: Verify Direct Call Implementation
  > Type: Action Validation
  > Assert: No more Open3.capture3 or shelling out to llm-query
  > Command: cd .ace/tools && ! grep -q "Open3\|llm-query" lib/coding_agent_tools/molecules/git/commit_message_generator.rb
- [x] Step 3: Remove temporary file handling
  - Replace Tempfile creation with direct string passing
  - Ensure prompt is passed directly to the LLM client
- [x] Step 4: Update error handling
  - Convert from shell command error handling to Ruby exception handling
  - Ensure same error messages are preserved
- [x] Step 5: Test commit message generation
  > TEST: Commit Message Generation Works
  > Type: Functional Test
  > Assert: Commit messages are generated successfully
  > Command: cd .ace/tools && bundle exec rspec spec/coding_agent_tools/molecules/git/commit_message_generator_spec.rb
- [x] Step 6: Integration test with git-commit command
  > TEST: Git Commit Integration
  > Type: Integration Test
  > Assert: git-commit command still works with the refactored generator
  > Command: cd .ace/tools && bundle exec exe/git-commit --dry-run --intention "test commit"
- [x] Step 7: Performance comparison
  - Measure time before and after refactoring
  - Ensure performance improvement is achieved

## Acceptance Criteria

- [x] AC 1: CommitMessageGenerator no longer shells out to llm-query
- [x] AC 2: Direct Ruby calls are used to invoke LLM clients
- [x] AC 3: No temporary files are created for prompts
- [x] AC 4: All existing functionality is preserved
- [x] AC 5: Performance is improved (no process creation overhead)
- [x] AC 6: Error handling works correctly with Ruby exceptions
- [x] AC 7: All tests pass after refactoring

## Out of Scope

- ❌ Changing the commit message format or prompt structure
- ❌ Adding new features to commit message generation
- ❌ Modifying the LLM client implementations
- ❌ Changing the public interface of CommitMessageGenerator

## References

- Code review report: .ace/taskflow/current/v.0.3.0-workflows/code_review/code-.ace/tools-lib-20250724-184702/cr-report-gpro.md (lines 121-125)
- Ruby gem best practices regarding internal method calls vs shelling out
- Performance considerations for subprocess creation