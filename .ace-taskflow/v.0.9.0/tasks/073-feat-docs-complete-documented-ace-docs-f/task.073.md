---
id: v.0.9.0+task.073
status: pending
priority: high
estimate: 4-6h
dependencies: []
---

# Complete documented ace-docs features (focus paths, semantic validation)

## Behavioral Specification

### User Experience

- **Input**: Document frontmatter with `update.focus.paths` array specifying files/directories to track, plus `--semantic` flag for validation
- **Process**: Users configure which codebase paths are relevant to each document, then run `ace-docs diff` to see only changes in those paths, or `ace-docs validate --semantic` for LLM-powered content validation
- **Output**: Filtered git diffs showing only relevant changes, semantic validation results with accuracy/consistency feedback, updated documentation reflecting correct frontmatter structure

### Expected Behavior

**Focus Path Filtering (Primary Feature):**

When a user adds `update.focus.paths` to document frontmatter (e.g., `paths: ["ace-docs/", "CHANGELOG.md"]`), running `ace-docs diff` on that document should:
- Generate git diff filtered to only the specified paths
- Use git's native path filtering (efficient, accurate)
- Show changes only in ace-docs/ directory and CHANGELOG.md file
- Reduce noise by excluding unrelated codebase changes
- Work with existing `--since`, `--exclude-renames`, `--exclude-moves` flags

**Semantic Validation:**

When a user runs `ace-docs validate docs/file.md --semantic`:
- Delegate to ace-llm-query subprocess for LLM analysis
- Check if content matches stated document purpose
- Identify contradictions, inaccuracies, or inconsistencies
- Validate appropriate depth for document type
- Return clear validation results with specific issues listed

**Documentation Corrections:**

- Update usage.md to show correct frontmatter structure with `focus.keywords` and `focus.paths`
- Fix README.md to list both fields separately
- Provide clear examples of path filtering use cases
- Remove outdated TODO comments from codebase

### Interface Contract

```bash
# Document frontmatter configuration
---
update:
  last-updated: '2025-10-14'
  focus:
    keywords:                    # LLM relevance hints (existing, for future use)
      - implementation
      - architecture
    paths:                       # Git diff path filters (NEW - being connected)
      - "ace-docs/"              # Include directory
      - "CHANGELOG.md"           # Include specific file
      - "dev-handbook/guides/"   # Include another directory
---

# CLI Commands

# Diff with path filtering (behavior changes - now actually filters!)
ace-docs diff README.md
# Expected: Shows only changes in paths specified in README.md frontmatter
# Current behavior: Ignores focus.paths, shows all changes
# NEW behavior: Uses git diff -- path1 path2 to filter

# Semantic validation (stub → real implementation)
ace-docs validate docs/architecture.md --semantic
# Expected output:
# ✓ Semantic validation passed
# Or:
# ✗ Semantic validation failed:
#   - Content contradicts stated purpose in section "Tools Overview"
#   - Missing depth for architecture document type
#   - Outdated information about ace-lint integration

# Error cases
ace-docs validate --semantic
# When ace-llm-query unavailable:
# Error: Semantic validation unavailable (ace-llm-query not found)
# Install ace-llm gem to enable semantic validation

# Existing commands remain unchanged
ace-docs diff --all                    # Still works
ace-docs diff --since "1 week ago"    # Still works
ace-docs validate --syntax            # Still works (delegates to ace-lint)
```

**Error Handling:**

- Missing ace-llm-query: Clear error with installation instructions
- Invalid paths in focus.paths: Git handles gracefully (no matches = empty diff)
- LLM API failures: Report timeout/rate limit with retry suggestion
- Document without focus.paths: Defaults to full repository diff (backward compatible)

**Edge Cases:**

- Empty focus.paths array: Treated same as missing (full repo diff)
- Paths that don't exist: Git returns empty diff (not an error)
- Multiple documents with different paths: Each filters independently
- Path patterns (wildcards): Supported by git natively (e.g., "*.md")

### Success Criteria

- [ ] **Focus Path Filtering Works**: `ace-docs diff` on document with `focus.paths` shows only changes in specified paths
- [ ] **Backward Compatible**: Documents without `focus.paths` still get full repository diffs
- [ ] **Git Native Filtering**: Uses `git diff <since>..HEAD -- path1 path2` for efficiency
- [ ] **Semantic Validation Functional**: `--semantic` flag calls ace-llm-query and returns validation results
- [ ] **Documentation Accurate**: usage.md and README.md show correct frontmatter structure with examples
- [ ] **Clean Codebase**: Stale TODO comments removed, code matches documentation

### Validation Questions

- [ ] **Scope Clarity**: Should focus.keywords also be implemented for LLM analysis, or just document the structure?
- [ ] **Model Selection**: Which LLM model for semantic validation (gflash for speed vs stronger model for accuracy)?
- [ ] **Temperature**: What temperature for semantic validation (0.3 deterministic vs 0.7 creative)?
- [ ] **Batch Validation**: Should semantic validation work with multiple files, or one at a time?

## Objective

Complete the documented-but-unimplemented features from task.071 that users expect based on current documentation. The primary need is focus path filtering to reduce diff noise by showing only changes in files/directories relevant to each document (e.g., README.md only cares about ace-docs/ and CHANGELOG.md changes, not test file changes).

## Scope of Work

### User Experience Scope

- **Focus Path Filtering**: Configure and use path-based diff filtering via frontmatter
- **Semantic Validation**: Run LLM-powered validation on document content
- **Documentation Accuracy**: Correct examples and explanations in usage.md and README.md
- **Code Quality**: Remove misleading TODOs and connect existing infrastructure

### System Behavior Scope

- Connect existing `document.focus_hints["paths"]` to git diff path filtering
- Implement semantic validation by calling ace-llm-query subprocess
- Update frontmatter documentation structure (split focus into keywords/paths)
- Clean up 4 TODO comments identified in codebase scan

### Interface Scope

- `ace-docs diff` command behavior (filtered output when focus.paths present)
- `ace-docs validate --semantic` command behavior (LLM validation results)
- Frontmatter schema documentation (focus.keywords and focus.paths)
- Error messages and edge case handling

### Deliverables

#### Behavioral Specifications

- Focus path filtering user flow and examples
- Semantic validation request/response flow
- Updated frontmatter structure with both fields documented
- Error handling and edge case behaviors

#### Validation Artifacts

- Test examples showing path filtering working
- Semantic validation examples with pass/fail cases
- Documentation verification (examples match implementation)

#### Workflow Components

- `ux/usage.md` with updated frontmatter examples
- Focus path filtering usage patterns
- Semantic validation workflow examples

## Out of Scope

- ❌ **Focus Keywords Implementation**: Document structure but don't connect to LLM (future enhancement)
- ❌ **Comprehensive Test Suite**: Task 071 deferred testing, this continues that pattern
- ❌ **Advanced Path Patterns**: Beyond git's native glob support (e.g., regex)
- ❌ **Semantic Auto-Fix**: Validation only, no content modification suggestions
- ❌ **Batch Semantic Validation**: One file at a time (performance consideration)

## References

- Parent Task: .ace-taskflow/v.0.9.0/tasks/done/071-docs-docs-complete-ace-docs-batch-analys/task.071.md
- Code with TODO: ace-docs/lib/ace/docs/molecules/change_detector.rb:252
- Code with TODO: ace-docs/lib/ace/docs/organisms/validator.rb:82,87
- Code with TODO: ace-docs/lib/ace/docs/commands/update_command.rb:40
- Documentation: ace-docs/docs/usage.md:359-361 (incorrect structure)
- Documentation: ace-docs/README.md:166 (incomplete description)

## Technical Approach

### Architecture Pattern

The implementation connects existing infrastructure that was built but never wired together:
- **Document model** already reads `focus_hints["paths"]` (document.rb:134-136)
- **Git diff filtering** already supports `options[:paths]` (change_detector.rb:202-205)
- **Connection missing**: `get_diff_for_document` never merges focus paths into options

Pattern: Extend existing molecules (ChangeDetector, Validator) following ATOM architecture without introducing new layers.

### Technology Stack

**No New Dependencies Required:**
- Uses existing Open3 for subprocess calls (already in use)
- Uses existing ace-llm-query gem (already available in workspace)
- Uses git's native path filtering (--  path1 path2 syntax)
- All required gems already in gemspec

**LLM Configuration:**
- Model: gflash (fast, cost-effective for validation)
- Temperature: 0.3 (deterministic validation results)
- Subprocess call pattern: Follow existing DiffAnalyzer approach

### Implementation Strategy

**Phase 1: Focus Path Filtering (2h)**
1. Modify `get_diff_for_document()` to extract and merge focus paths
2. Remove obsolete `filter_relevant_changes()` method
3. Test with real document containing focus.paths

**Phase 2: Semantic Validation (1.5h)**
1. Implement `validate_semantic()` in Validator organism
2. Build LLM prompt for semantic validation
3. Parse LLM response for VALID/INVALID and issues
4. Handle errors gracefully (missing ace-llm-query, API failures)

**Phase 3: Documentation (1h)**
1. Update usage.md frontmatter structure examples
2. Update README.md to list both focus fields
3. Create ux/usage.md with path filtering examples
4. Clean up TODO comments

**Phase 4: Testing (0.5h)**
1. Manual test with ace-docs/README.md
2. Verify backward compatibility
3. Test semantic validation with sample document

## File Modifications

### Create

- `.ace-taskflow/v.0.9.0/tasks/073-feat-docs-complete-documented-ace-docs-f/ux/usage.md`
  - Purpose: User-facing documentation for focus path filtering feature
  - Key components: Frontmatter examples, diff command usage, troubleshooting
  - Dependencies: None

### Modify

- `ace-docs/lib/ace/docs/molecules/change_detector.rb`
  - Changes:
    - Line 18-28: Add focus path extraction and merge into options
    - Line 247-259: Remove `filter_relevant_changes()` method (obsolete)
  - Impact: Enables path filtering, simplifies code
  - Integration points: Called by DiffCommand, AnalyzeCommand

- `ace-docs/lib/ace/docs/organisms/validator.rb`
  - Changes:
    - Line 86-89: Replace stub with LLM subprocess call
    - Add prompt building logic (30-40 lines)
    - Add response parsing logic (15-20 lines)
  - Impact: Makes --semantic flag functional
  - Integration points: Called by ValidateCommand

- `ace-docs/lib/ace/docs/commands/update_command.rb`
  - Changes:
    - Line 40: Remove stale TODO comment
  - Impact: Code quality cleanup
  - Integration points: None

- `ace-docs/docs/usage.md`
  - Changes:
    - Line 359-361: Replace incorrect focus structure with keywords+paths
    - Add explanation of focus.paths feature (20-30 lines)
    - Add path filtering examples (3-5 scenarios)
  - Impact: Documentation accuracy
  - Integration points: User documentation

- `ace-docs/README.md`
  - Changes:
    - Line 166: Split into two separate field descriptions
  - Impact: Documentation accuracy
  - Integration points: User documentation

### Delete

**No files to delete** - all changes are modifications

## Test Case Planning

### Test Scenarios

**Happy Path Scenarios:**

1. **Focus path filtering with multiple paths**
   - Input: Document with `focus.paths: ["ace-docs/", "CHANGELOG.md"]`
   - Expected: Diff shows only changes in those paths
   - Test: Create test document, run ace-docs diff, verify output

2. **Semantic validation pass**
   - Input: Well-written document matching its purpose
   - Expected: ✓ Semantic validation passed
   - Test: Mock ace-llm-query to return VALID

3. **Semantic validation fail with issues**
   - Input: Document with contradictions
   - Expected: ✗ Semantic validation failed with issue list
   - Test: Mock ace-llm-query to return INVALID with issues

**Edge Case Scenarios:**

1. **Document without focus.paths**
   - Input: Document with no focus.paths field
   - Expected: Full repository diff (backward compatible)
   - Test: Verify default behavior unchanged

2. **Empty focus.paths array**
   - Input: `focus.paths: []`
   - Expected: Full repository diff
   - Test: Verify treated same as missing

3. **Non-existent paths in focus.paths**
   - Input: `focus.paths: ["nonexistent/"]`
   - Expected: Empty diff (git handles gracefully)
   - Test: Verify no error thrown

4. **Path patterns with wildcards**
   - Input: `focus.paths: ["*.md"]`
   - Expected: Git expands wildcards, shows matching files
   - Test: Verify git's glob support works

**Error Condition Scenarios:**

1. **ace-llm-query not found**
   - Input: Run semantic validation without ace-llm-query
   - Expected: Clear error message with installation instructions
   - Test: Mock command not found (Errno::ENOENT)

2. **LLM API timeout**
   - Input: Semantic validation with API timeout
   - Expected: Error message suggesting retry
   - Test: Mock subprocess failure with timeout

3. **Invalid focus.paths structure**
   - Input: `focus.paths: "string instead of array"`
   - Expected: Graceful handling or clear error
   - Test: Verify type checking

**Integration Point Scenarios:**

1. **Focus paths with --since flag**
   - Input: Document with focus.paths + --since "1 week ago"
   - Expected: Filtered diff for specified time range
   - Test: Verify flags combine correctly

2. **Focus paths with --exclude-renames**
   - Input: Document with focus.paths + --exclude-renames
   - Expected: Both filters apply
   - Test: Verify options merge correctly

### Test Type Categorization

**Unit Tests (High Priority):**
- ChangeDetector.get_diff_for_document with focus.paths present/absent
- Validator.validate_semantic with mocked subprocess
- Path extraction from document.focus_hints["paths"]

**Integration Tests (Medium Priority):**
- Full diff command with path filtering end-to-end
- Full validate command with semantic flag end-to-end
- Multiple option flags combining correctly

**Manual Tests (This Task):**
- Test on real ace-docs/README.md with actual paths
- Verify backward compatibility with existing documents
- Check documentation examples actually work

### Test Coverage Expectations

This task continues the pattern from task 071 of **deferring comprehensive test suite**:
- Manual testing: 100% (required before completion)
- Automated tests: 0% (deferred to future task)
- Code coverage: Not measured (consistent with parent task)

## Implementation Plan

### Planning Steps

* [ ] Review existing code structure to confirm understanding
  - Read change_detector.rb:18-28, 247-259, 182-211
  - Read validator.rb:86-89
  - Read document.rb:134-136
  - Confirm infrastructure is ready to connect

### Execution Steps

- [ ] **Step 1: Implement focus path filtering in ChangeDetector**
  - Modify `get_diff_for_document()` method (line 18):
    ```ruby
    def self.get_diff_for_document(document, since: nil, options: {})
      return empty_diff_result unless document.path

      # Extract focus paths from document and merge into options
      focus_paths = document.focus_hints["paths"]
      if focus_paths && !focus_paths.empty?
        options = options.merge(paths: focus_paths)
      end

      # Determine the since parameter
      since_param = determine_since(document, since)

      # Get the git diff (now with path filtering)
      diff_content = generate_git_diff(since_param, options)

      # Return results directly (no filter_relevant_changes)
      {
        document_path: document.path,
        document_type: document.doc_type,
        since: since_param,
        diff: diff_content,
        has_changes: !diff_content.strip.empty?,
        timestamp: Time.now.iso8601,
        options: options
      }
    end
    ```
  > TEST: Path Filtering Works
  > Type: Integration Validation
  > Assert: Diff filtered to specified paths
  > Command: ace-docs diff ace-docs/README.md (after adding focus.paths)

- [ ] **Step 2: Remove obsolete filter_relevant_changes method**
  - Delete lines 247-259 in change_detector.rb
  - Method is no longer needed (git does the filtering)

- [ ] **Step 3: Implement semantic validation in Validator**
  - Replace stub at validator.rb:86-89 with full implementation:
    ```ruby
    def validate_semantic(document)
      require "open3"

      # Build semantic validation prompt
      prompt = <<~PROMPT
        Validate this documentation for semantic accuracy and relevance.

        Document Type: #{document.doc_type}
        Purpose: #{document.purpose}

        Content:
        #{document.content}

        Check for:
        - Content matches stated purpose
        - Information is accurate and up-to-date
        - No contradictions or inconsistencies
        - Appropriate depth for document type

        Respond with:
        - VALID or INVALID
        - List of issues (if any) as bullet points starting with "-"
      PROMPT

      # Call ace-llm-query
      stdout, stderr, status = Open3.capture3(
        "ace-llm-query",
        "--model", "gflash",
        "--temperature", "0.3",
        stdin_data: prompt
      )

      if !status.success?
        return { errors: ["Semantic validation unavailable (ace-llm-query error: #{stderr})"], warnings: [] }
      end

      # Parse LLM response
      errors = []
      warnings = []

      if stdout.match(/INVALID/i)
        # Extract issues from response
        issues = stdout.scan(/^- (.+)$/).flatten
        errors.concat(issues)
      end

      { errors: errors, warnings: warnings }
    rescue Errno::ENOENT
      { errors: ["Semantic validation unavailable (ace-llm-query not found). Install ace-llm gem."], warnings: [] }
    end
    ```
  > TEST: Semantic Validation Functional
  > Type: Integration Validation
  > Assert: Returns validation results
  > Command: ace-docs validate ace-docs/README.md --semantic

- [ ] **Step 4: Clean up stale TODO comments**
  - Remove TODO at update_command.rb:40 (feature already works)
  - Update TODO at validator.rb:82 to note delegation to ace-lint

- [ ] **Step 5: Create ux/usage.md documentation**
  - Create `.ace-taskflow/v.0.9.0/tasks/073-feat-docs-complete-documented-ace-docs-f/ux/usage.md`
  - Document frontmatter structure with focus.keywords and focus.paths
  - Provide 3-5 real-world examples of path filtering
  - Include troubleshooting section

- [ ] **Step 6: Update usage.md frontmatter documentation**
  - Fix lines 359-361 to show correct structure
  - Add explanation of focus.paths feature
  - Provide path filtering examples

- [ ] **Step 7: Update README.md frontmatter reference**
  - Split line 166 into two separate field descriptions:
    - `update.focus.keywords`: LLM relevance keywords
    - `update.focus.paths`: Git diff path filters

- [ ] **Step 8: Manual testing**
  - Test focus path filtering:
    - Update ace-docs/README.md with `focus.paths: ["ace-docs/", "CHANGELOG.md"]`
    - Run `ace-docs diff ace-docs/README.md`
    - Verify only shows changes in those paths
  - Test semantic validation:
    - Run `ace-docs validate ace-docs/README.md --semantic`
    - Verify returns validation results
  - Test backward compatibility:
    - Run diff on document without focus.paths
    - Verify still shows full repository diff
  > TEST: Manual Validation Complete
  > Type: End-to-End Validation
  > Assert: All features working as expected
  > Command: Manual verification checklist

- [ ] **Step 9: Version bump to 0.3.3**
  - Update ace-docs/lib/ace/docs/version.rb: VERSION = "0.3.3"
  - Update ace-docs/CHANGELOG.md with new features
  > TEST: Version Updated
  > Type: Action Validation
  > Assert: Version file and changelog updated
  > Command: grep "0.3.3" ace-docs/lib/ace/docs/version.rb

## Risk Assessment

### Technical Risks

- **Risk**: Focus paths merge might conflict with command-line options
  - **Probability**: Low
  - **Impact**: Medium (unexpected behavior)
  - **Mitigation**: Frontmatter paths only used when no --paths CLI option
  - **Rollback**: Revert change_detector.rb modifications

- **Risk**: LLM response format might vary unpredictably
  - **Probability**: Medium
  - **Impact**: Low (validation fails gracefully)
  - **Mitigation**: Flexible parsing with fallbacks
  - **Rollback**: Validation returns empty errors (stub behavior)

### Integration Risks

- **Risk**: ace-llm-query version incompatibility
  - **Probability**: Low
  - **Impact**: Low (workspace gem is latest)
  - **Mitigation**: Graceful error handling for command not found
  - **Monitoring**: Test semantic validation during manual testing

### Performance Risks

- **Risk**: LLM validation adds 5-30s latency per document
  - **Mitigation**: Document in usage.md, user opts in with --semantic flag
  - **Monitoring**: Log warning if validation takes >60s
  - **Thresholds**: Acceptable for opt-in feature

## Acceptance Criteria

- [ ] **Focus Path Filtering Works**: Document with focus.paths filters git diff correctly
- [ ] **Backward Compatible**: Documents without focus.paths still get full diffs
- [ ] **Semantic Validation Functional**: --semantic flag calls LLM and returns results
- [ ] **Documentation Complete**: usage.md, README.md, and ux/usage.md all accurate
- [ ] **Code Quality**: All TODO comments cleaned up
- [ ] **Manual Testing Passed**: All test scenarios verified working
