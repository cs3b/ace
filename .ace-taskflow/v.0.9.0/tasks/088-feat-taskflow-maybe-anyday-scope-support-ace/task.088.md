---
id: v.0.9.0+task.088
status: pending
priority: medium
estimate: 4h
dependencies: []
sort: 995
---

# Add maybe and anyday scope support to ace-taskflow ideas

## Behavioral Specification

### User Experience
- **Input**:
  - List ideas: `ace-taskflow ideas maybe` or `ace-taskflow ideas anyday`
  - Create ideas: `ace-taskflow idea create "content" --maybe` or `ace-taskflow idea create "content" --anyday`
- **Process**:
  - Listing: System scans the respective subdirectories (ideas/maybe/ or ideas/anyday/) and displays ideas from those locations
  - Creating: System creates idea file in the specified subdirectory
- **Output**:
  - List of ideas from the specified subdirectory with proper statistics
  - Confirmation message showing path to created idea
  - Total idea counts include maybe/anyday ideas in all contexts

### Expected Behavior

**Reading/Listing Ideas:**
- Users can list ideas from maybe/ and anyday/ subdirectories using new presets
- The 'all' preset includes ideas from main directory + maybe/ + anyday/ + done/
- Statistics always show total counts including ideas from all subdirectories
- Help text documents the new maybe and anyday presets

**Creating Ideas:**
- Users can create ideas directly in maybe/ or anyday/ subdirectories using flags
- `--maybe` flag creates idea file in `ideas/maybe/` subdirectory
- `--anyday` flag creates idea file in `ideas/anyday/` subdirectory
- Compatible with existing flags: `--backlog`, `--release`, `--current`, `--git-commit`, `--llm-enhance`
- Subdirectory context applies to whatever release/location is specified
- Subdirectories are auto-created if they don't exist

### Interface Contract

```bash
# List ideas from subdirectories
ace-taskflow ideas maybe          # List ideas in maybe/ subdirectory
ace-taskflow ideas anyday         # List ideas in anyday/ subdirectory
ace-taskflow ideas all            # All ideas including maybe, anyday, and done

# Create ideas in subdirectories
ace-taskflow idea create "Add caching" --maybe
# Creates: .ace-taskflow/v.0.9.0/ideas/maybe/20251024-214530-add-caching.md

ace-taskflow idea create "Refactor auth" --anyday --backlog
# Creates: .ace-taskflow/backlog/ideas/anyday/20251024-214530-refactor-auth.md

ace-taskflow idea create "Fix tests" --maybe --git-commit
# Creates in maybe/ subdirectory and commits

# Expected output format
v.0.9.0: 50 ideas • Mono-Repo Multiple Gems
Ideas: 💡 11 | 🤔 5 maybe | 📅 3 anyday | ✅ 31 done • 50 total
```

**Error Handling:**
- `--maybe` and `--anyday` are mutually exclusive (error if both provided)
- Subdirectory is created if it doesn't exist
- Works across all contexts (current, backlog, specific releases)

**Edge Cases:**
- When no active release exists, --maybe/--anyday creates in backlog/ideas/maybe or backlog/ideas/anyday
- Empty subdirectories show "No ideas found" message
- Statistics correctly count ideas even when subdirectories are empty

### Success Criteria

**Listing:**
- [ ] **List Maybe Ideas**: `ace-taskflow ideas maybe` displays only ideas from `ideas/maybe/` subdirectory
- [ ] **List Anyday Ideas**: `ace-taskflow ideas anyday` displays only ideas from `ideas/anyday/` subdirectory
- [ ] **All Preset Includes Subdirs**: `ace-taskflow ideas all` includes ideas from main + maybe/ + anyday/ + done/
- [ ] **Statistics Include All**: Total idea counts include maybe/ and anyday/ in all contexts
- [ ] **Help Documentation**: Help text documents the new maybe and anyday presets

**Creating:**
- [ ] **Create with --maybe**: `ace-taskflow idea create "content" --maybe` creates idea in ideas/maybe/
- [ ] **Create with --anyday**: `ace-taskflow idea create "content" --anyday` creates idea in ideas/anyday/
- [ ] **Works with --backlog**: Creates in backlog/ideas/maybe/ or backlog/ideas/anyday/
- [ ] **Works with --release**: Creates in specific release's maybe/anyday subdirectories
- [ ] **Auto-create Subdirs**: Subdirectory is auto-created if it doesn't exist
- [ ] **Help Documentation**: Help text documents the new --maybe and --anyday flags
- [ ] **Mutual Exclusivity**: Error when both --maybe and --anyday provided

### Validation Questions

- [ ] **Statistics Format**: Should the statistics show emoji indicators for maybe (🤔) and anyday (📅) scopes, or use text labels?
- [ ] **Default Behavior**: Should the 'next' preset (default) exclude maybe/anyday ideas or include them?
- [ ] **Moving Ideas**: Should there be commands to move existing ideas into maybe/anyday subdirectories (similar to 'done')?
- [ ] **Subdirectory Names**: Are 'maybe' and 'anyday' the final names, or should they be configurable?

## Objective

Enable users to organize ideas into 'maybe' and 'anyday' categories for better idea management. This allows users to separate ideas by priority/timeline:
- **maybe**: Ideas that might be pursued but uncertain
- **anyday**: Ideas that can be done anytime, no specific urgency

Users should be able to both list ideas from these categories and create ideas directly in them, providing a complete idea management workflow.

## Scope of Work

- **User Experience Scope**:
  - List ideas filtered by maybe/anyday subdirectories
  - Create ideas directly in maybe/anyday subdirectories
  - View statistics that include all subdirectories
  - Use help documentation to understand new features

- **System Behavior Scope**:
  - Scan maybe/ and anyday/ subdirectories when listing ideas
  - Create maybe/ and anyday/ subdirectories as needed
  - Count ideas from all subdirectories for statistics
  - Support preset-based filtering for new subdirectories

- **Interface Scope**:
  - New presets: 'maybe', 'anyday'
  - New flags: --maybe, --anyday
  - Updated help text for both listing and creating
  - Updated statistics display format

### Deliverables

#### Behavioral Specifications
- Complete interface contracts for listing and creating
- Clear error handling specifications
- Edge case behavior definitions
- User experience flow descriptions

#### Validation Artifacts
- Success criteria covering all user scenarios
- Validation questions for implementation decisions
- Examples demonstrating expected behavior
- Help text showing new features

## Out of Scope

- ❌ **Implementation Details**: File structures, code organization, specific Ruby classes/methods
- ❌ **Technology Decisions**: Which specific Ruby patterns to use, data structure choices
- ❌ **Performance Optimization**: Caching strategies, scanning optimizations
- ❌ **Future Enhancements**:
  - Custom subdirectory names via configuration
  - Moving existing ideas between subdirectories via CLI
  - Filtering ideas by multiple scopes simultaneously
  - Visual indicators in terminal output beyond basic emoji/text

## References

- Source idea: `.ace-taskflow/v.0.9.0/ideas/done/20251024-213241-ace-taskflow-ideas-should-scan-also-the-maybe-and.md` (marked as done: 2025-10-25)
- Related structures: `.ace-taskflow/v.0.9.0/ideas/maybe/` and `.ace-taskflow/v.0.9.0/ideas/anyday/` subdirectories
- Existing done scope implementation: `ace-taskflow/lib/ace/taskflow/molecules/idea_loader.rb` lines 30-37

## Technical Approach

### Architecture Pattern
The implementation follows the existing "done" subdirectory pattern established in IdeaLoader. The done/ implementation scans a subdirectory within ideas/, and the same pattern will be replicated for maybe/ and anyday/ subdirectories.

**Pattern Analysis:**
- **Existing done/ pattern**: IdeaLoader.load_all() accepts a `scope` parameter (`:next`, `:done`, `:all`) and conditionally scans the `done/` subdirectory
- **New pattern**: Extend scope parameter to include `:maybe` and `:anyday`, and add conditional scanning for those subdirectories
- **Integration**: Minimal changes to existing architecture - purely additive functionality

**Architecture Decision:**
- Extend existing scope-based loading in IdeaLoader rather than creating new loader methods
- Reuse existing directory scanning logic (load_ideas_from_directory)
- Leverage existing preset system for new "maybe" and "anyday" presets
- Follow established pattern: subdirectories under ideas/ directory, same file naming conventions

### Technology Stack
**No new dependencies required.** All functionality can be implemented using existing Ruby standard library and ace-taskflow components:
- File system operations: FileUtils (already in use)
- Directory scanning: Dir.glob (already in use)
- YAML configuration: YAML (already in use for presets)
- Testing: Minitest (existing test framework)

**Compatibility:**
- Ruby version: 2.7+ (existing requirement)
- No breaking changes to existing API
- Backward compatible with existing idea files and directory structures

### Implementation Strategy

**Phase 1: IdeaLoader Extension (Reading)**
1. Add `:maybe` and `:anyday` to scope handling in `load_all()` method
2. Add conditional subdirectory scanning for maybe/ and anyday/ similar to done/
3. Update count_ideas_in_directory() to include maybe and anyday counts

**Phase 2: IdeaArgParser Extension (Writing)**
1. Add `--maybe` and `--anyday` flag parsing to parse_capture_options()
2. Add mutual exclusivity validation (error if both flags provided)
3. Return scope information in parsed options hash

**Phase 3: IdeaCommand Integration**
1. Extract scope from parsed options in create_idea()
2. Append scope subdirectory to config["directory"] path
3. Auto-create subdirectory if it doesn't exist

**Phase 4: Preset Manager Extension**
1. Add "maybe" preset to default_presets hash
2. Add "anyday" preset to default_presets hash
3. Both presets follow "done" preset pattern with scope-specific filters

**Phase 5: Statistics Integration**
1. Update StatsFormatter.get_idea_statistics() to detect maybe/anyday paths
2. Add maybe/anyday status icons to IDEA_STATUS_ICONS constant
3. Update format_ideas_line() to display maybe/anyday counts with emojis

**Phase 6: Help Documentation**
1. Update IdeasCommand.show_help() to document new presets
2. Update IdeaCommand.show_help() to document new flags

**Rollback Strategy:**
- All changes are additive - no existing functionality modified
- If issues arise, simply don't use new flags/presets
- Rollback involves removing new code sections and presets
- Data safety: Subdirectories can remain, ideas won't be lost

**Performance Monitoring:**
- Directory scanning performance should match existing done/ scanning
- Expected: <10ms additional scan time per subdirectory (based on done/ metrics)
- No indexing or caching changes needed

## File Modifications

### Modify

**1. ace-taskflow/lib/ace/taskflow/molecules/idea_loader.rb**
- **Changes**:
  - Extend `load_all()` method to handle `:maybe` and `:anyday` scopes (lines 18-40)
  - Add maybe/ and anyday/ subdirectory scanning in conditional blocks (similar to done/ at lines 30-37)
  - Update `count_ideas_in_directory()` to include maybe and anyday subdirectory counts (lines 266-291)
- **Impact**: Enables reading ideas from maybe/ and anyday/ subdirectories
- **Integration points**:
  - Called by IdeasCommand for listing ideas
  - Called by StatsFormatter for statistics calculation

**2. ace-taskflow/lib/ace/taskflow/molecules/idea_arg_parser.rb**
- **Changes**:
  - Add `--maybe` and `--anyday` flag parsing in `parse_capture_options()` (lines 23-59)
  - Add `:scope` key to returned options hash
  - Add validation logic for mutual exclusivity
- **Impact**: Enables parsing of new creation flags
- **Integration points**: Called by IdeaCommand.create_idea() to parse command arguments

**3. ace-taskflow/lib/ace/taskflow/commands/idea_command.rb**
- **Changes**:
  - Extract scope from options in `create_idea()` method (lines 131-192)
  - Append scope subdirectory to config["directory"] path before calling IdeaWriter
  - Add error handling for mutual exclusivity
- **Impact**: Routes idea creation to correct subdirectory
- **Integration points**: Entry point for `ace-taskflow idea create` command

**4. ace-taskflow/lib/ace/taskflow/molecules/list_preset_manager.rb**
- **Changes**:
  - Add "maybe" preset to `default_presets()` hash (lines 119-192)
  - Add "anyday" preset to `default_presets()` hash (lines 119-192)
- **Impact**: Enables `ace-taskflow ideas maybe` and `ace-taskflow ideas anyday` commands
- **Integration points**: Used by IdeasCommand to apply preset-based filtering

**5. ace-taskflow/lib/ace/taskflow/molecules/stats_formatter.rb**
- **Changes**:
  - Add emoji icons for maybe (🤔) and anyday (📅) to IDEA_STATUS_ICONS constant (lines 23-30)
  - Update `get_idea_statistics()` to detect maybe/anyday from path (lines 209-240)
  - Update `format_ideas_line()` to display maybe/anyday counts (lines 253-279)
- **Impact**: Statistics display includes maybe and anyday counts with emojis
- **Integration points**: Called by IdeasCommand for header display

**6. ace-taskflow/lib/ace/taskflow/commands/ideas_command.rb**
- **Changes**:
  - Update `get_ideas_for_preset()` to handle maybe/anyday preset names (lines 155-184)
  - Add `:maybe` and `:anyday` cases to scope determination logic
  - Update `show_help()` to document new presets (lines 366-402)
- **Impact**: Routes preset names to correct scope values
- **Integration points**: Main entry point for listing ideas with presets

**7. ace-taskflow/lib/ace/taskflow/commands/idea_command.rb**
- **Changes**:
  - Update `show_help()` to document --maybe and --anyday flags (lines 363-411)
- **Impact**: User documentation via help command
- **Integration points**: Displayed when user runs `ace-taskflow idea --help`

### Create

**8. ace-taskflow/test/molecules/idea_loader_maybe_anyday_test.rb**
- **Purpose**: Unit tests for maybe/anyday scope loading in IdeaLoader
- **Key components**:
  - Test loading ideas with scope: :maybe
  - Test loading ideas with scope: :anyday
  - Test loading all ideas includes maybe and anyday
  - Test counting ideas includes maybe and anyday subdirectories
- **Dependencies**: Test fixtures with maybe/ and anyday/ subdirectories

**9. ace-taskflow/test/molecules/idea_arg_parser_scope_test.rb**
- **Purpose**: Unit tests for --maybe and --anyday flag parsing
- **Key components**:
  - Test parsing --maybe flag
  - Test parsing --anyday flag
  - Test mutual exclusivity validation
  - Test combination with other flags
- **Dependencies**: IdeaArgParser class

**10. ace-taskflow/test/commands/idea_command_scope_test.rb**
- **Purpose**: Integration tests for creating ideas in subdirectories
- **Key components**:
  - Test creating idea with --maybe flag
  - Test creating idea with --anyday flag
  - Test creating in backlog with --maybe
  - Test error when both flags provided
- **Dependencies**: Full command execution environment

**11. .ace-taskflow/v.0.9.0/tasks/088-feat-taskflow-maybe-anyday-scope-support-ace/ux/usage.md**
- **Purpose**: Complete usage documentation for new feature
- **Status**: ✅ Already created
- **Key components**: Command syntax, scenarios, examples, migration notes

## Test Case Planning

### Scenario Identification

**Happy Path Scenarios:**
1. **List maybe ideas**: `ace-taskflow ideas maybe` shows only ideas from maybe/ subdirectory
2. **List anyday ideas**: `ace-taskflow ideas anyday` shows only ideas from anyday/ subdirectory
3. **List all ideas**: `ace-taskflow ideas all` includes main + maybe + anyday + done subdirectories
4. **Create with --maybe**: Idea file created in ideas/maybe/ subdirectory
5. **Create with --anyday**: Idea file created in ideas/anyday/ subdirectory
6. **Combine --maybe with --backlog**: Idea created in backlog/ideas/maybe/
7. **Statistics include maybe/anyday**: Counts show 💡 11 | 🤔 5 maybe | 📅 3 anyday | ✅ 31 done

**Edge Case Scenarios:**
1. **Empty maybe subdirectory**: Shows "No ideas found" but statistics still show total counts
2. **Empty anyday subdirectory**: Shows "No ideas found" but statistics still show total counts
3. **No active release with --maybe**: Creates in backlog/ideas/maybe/ automatically
4. **Subdirectory doesn't exist**: Auto-creates maybe/ or anyday/ directory on first use
5. **Mixed directory formats**: Handles both flat files and directory-based ideas in maybe/anyday
6. **Default preset excludes maybe/anyday**: `ace-taskflow ideas` (default) shows only main directory

**Error Condition Scenarios:**
1. **Mutual exclusivity**: Error when both `--maybe` and `--anyday` provided together
2. **Invalid scope in preset**: Gracefully handle unknown scope values

**Integration Point Scenarios:**
1. **Preset system integration**: New presets work with existing --backlog, --release flags
2. **Statistics display integration**: Maybe/anyday counts appear in all contexts (current, backlog, releases)
3. **File naming integration**: Ideas in subdirectories follow same timestamp-title.md naming pattern
4. **Git commit integration**: --git-commit works with --maybe and --anyday flags

### Test Type Categorization

**Unit Tests (High Priority):**
1. **IdeaLoader.load_all()** with scope: :maybe
   - Returns only ideas from maybe/ subdirectory
   - Handles both flat files and directory-based ideas
   - Returns empty array when maybe/ doesn't exist
2. **IdeaLoader.load_all()** with scope: :anyday
   - Returns only ideas from anyday/ subdirectory
   - Handles both flat files and directory-based ideas
   - Returns empty array when anyday/ doesn't exist
3. **IdeaLoader.load_all()** with scope: :all
   - Includes ideas from main + maybe + anyday + done
   - Correctly aggregates counts from all subdirectories
4. **IdeaLoader.count_ideas_in_directory()**
   - Counts ideas in maybe/ subdirectory
   - Counts ideas in anyday/ subdirectory
   - Total includes main + maybe + anyday + done
5. **IdeaArgParser.parse_capture_options()** with --maybe
   - Returns { scope: "maybe" } in options hash
   - Compatible with other flags (--backlog, --git-commit, etc.)
6. **IdeaArgParser.parse_capture_options()** with --anyday
   - Returns { scope: "anyday" } in options hash
   - Compatible with other flags
7. **IdeaArgParser mutual exclusivity**
   - Raises error or returns error indicator when both --maybe and --anyday present
8. **ListPresetManager default_presets()**
   - Contains "maybe" preset with correct configuration
   - Contains "anyday" preset with correct configuration
   - Presets have type: 'ideas' and appropriate scope filters
9. **StatsFormatter.get_idea_statistics()**
   - Detects maybe status from /maybe/ in path
   - Detects anyday status from /anyday/ in path
   - Counts correctly aggregate by status
10. **StatsFormatter.format_ideas_line()**
    - Displays maybe count with 🤔 emoji
    - Displays anyday count with 📅 emoji
    - Format matches: "Ideas: 💡 11 | 🤔 5 maybe | 📅 3 anyday | ✅ 31 done • 50 total"

**Integration Tests (Medium Priority):**
1. **Create idea with --maybe flag**
   - Idea file created at correct path: .ace-taskflow/v.0.9.0/ideas/maybe/[timestamp-title].md
   - File content formatted correctly
   - Subdirectory auto-created if doesn't exist
2. **Create idea with --anyday flag**
   - Idea file created at correct path: .ace-taskflow/v.0.9.0/ideas/anyday/[timestamp-title].md
   - File content formatted correctly
   - Subdirectory auto-created if doesn't exist
3. **Create with --maybe --backlog**
   - Idea created in backlog/ideas/maybe/
   - Path: .ace-taskflow/backlog/ideas/maybe/[timestamp-title].md
4. **Create with --anyday --release v.0.8.0**
   - Idea created in specific release's anyday subdirectory
   - Path: .ace-taskflow/v.0.8.0/ideas/anyday/[timestamp-title].md
5. **List ideas with maybe preset**
   - Command: `ace-taskflow ideas maybe`
   - Shows only ideas from maybe/ subdirectory
   - Statistics show total counts including all scopes
6. **List ideas with anyday preset**
   - Command: `ace-taskflow ideas anyday`
   - Shows only ideas from anyday/ subdirectory
   - Statistics show total counts including all scopes
7. **List ideas with all preset**
   - Command: `ace-taskflow ideas all`
   - Displays ideas from main + maybe + anyday + done
   - Correct ordering and grouping
8. **Statistics display across presets**
   - `ace-taskflow ideas --stats` shows maybe and anyday counts
   - Emoji indicators appear correctly
   - Percentages calculated correctly

**End-to-End Tests (Low Priority):**
1. **Complete workflow**: Create → List → Statistics
   - Create idea with --maybe
   - List with `ideas maybe` shows the new idea
   - Statistics include the new maybe count
2. **Cross-context workflow**: Multiple releases with maybe/anyday
   - Create ideas in different releases with --maybe
   - List all shows ideas from all releases' maybe subdirectories
   - Statistics aggregate correctly
3. **Git integration workflow**
   - Create idea with --maybe --git-commit
   - Verify git commit created
   - Verify idea file in git history

### Test Planning Documentation

**Test Coverage Expectations:**
- **Critical paths**: 100% coverage for IdeaLoader scope handling, IdeaArgParser flag parsing
- **Integration points**: 90% coverage for command execution paths
- **Edge cases**: 80% coverage for error conditions and empty subdirectories

**Test Data Requirements:**
- Fixture directory structure with maybe/ and anyday/ subdirectories
- Sample idea files in each subdirectory (flat files and directory-based)
- Test release structures (v.0.9.0, backlog) with ideas in all subdirectories

**Test Framework and Tooling:**
- Framework: Minitest (existing framework)
- Assertions: Standard minitest assertions (assert_equal, assert_includes, assert_match)
- Fixtures: Temporary test directories with realistic structure
- Helpers: Existing test helpers (with_test_project, capture_stdout)

## Implementation Plan

### Planning Steps

* [ ] Review existing "done" scope implementation in IdeaLoader
  - Understand exact pattern used for done/ subdirectory scanning
  - Identify reusable code patterns and helper methods
  - Document any edge cases or special handling
* [ ] Analyze preset system architecture in ListPresetManager
  - Review how existing presets (done, all, next) are structured
  - Understand preset type filtering and context handling
  - Plan preset configuration for maybe and anyday
* [ ] Design scope parameter extension strategy
  - Map scope symbols (:maybe, :anyday) to directory names
  - Plan conditional logic placement in load_all() method
  - Design backward compatibility approach
* [ ] Plan statistics integration approach
  - Determine how to detect maybe/anyday status from file paths
  - Design emoji icon constants and display format
  - Plan statistics aggregation logic

### Execution Steps

#### Phase 1: IdeaLoader Extension (Reading)

- [ ] Add :maybe and :anyday scope handling to IdeaLoader.load_all()
  - Extend scope conditional logic (lines 24-37) to include :maybe and :anyday cases
  - Add maybe/ subdirectory scanning block parallel to done/ block (lines 30-37)
  - Add anyday/ subdirectory scanning block parallel to done/ block
  - Update :all scope to include maybe and anyday subdirectories
  > TEST: Scope Loading Validation
  > Type: Unit Test
  > Assert: load_all(scope: :maybe) returns only ideas from maybe/ subdirectory
  > Command: cd ace-taskflow && ruby -Ilib:test test/molecules/idea_loader_maybe_anyday_test.rb -n test_load_maybe_scope

- [ ] Update count_ideas_in_directory() to include maybe and anyday counts
  - Add maybe_dir and anyday_dir similar to done_dir (line 280)
  - Count ideas in maybe/ subdirectory
  - Count ideas in anyday/ subdirectory
  - Include in total count calculation (line 290)
  > TEST: Counting Validation
  > Type: Unit Test
  > Assert: count_ideas_in_directory includes maybe and anyday subdirectory counts
  > Command: cd ace-taskflow && ruby -Ilib:test test/molecules/idea_loader_maybe_anyday_test.rb -n test_count_includes_maybe_anyday

#### Phase 2: IdeaArgParser Extension (Writing)

- [ ] Add --maybe and --anyday flag parsing to IdeaArgParser.parse_capture_options()
  - Add case branches for "--maybe" and "--anyday" in parse loop (lines 26-53)
  - Set options[:scope] = "maybe" or "anyday" when flag detected
  - Increment loop counter appropriately
  > TEST: Flag Parsing
  > Type: Unit Test
  > Assert: parse_capture_options(["content", "--maybe"]) returns { scope: "maybe" }
  > Command: cd ace-taskflow && ruby -Ilib:test test/molecules/idea_arg_parser_scope_test.rb -n test_parse_maybe_flag

- [ ] Add mutual exclusivity validation
  - Check if both :scope values are set (would indicate both flags present)
  - Raise ArgumentError or set error flag in options hash
  - Add error message: "Cannot use both --maybe and --anyday flags together"
  > TEST: Mutual Exclusivity
  > Type: Unit Test
  > Assert: Parsing with both flags raises error or returns error indicator
  > Command: cd ace-taskflow && ruby -Ilib:test test/molecules/idea_arg_parser_scope_test.rb -n test_mutual_exclusivity

#### Phase 3: IdeaCommand Integration

- [ ] Extract scope from parsed options in create_idea() method
  - After options = parse_options(args) (line 133), extract scope = options[:scope]
  - Handle error if mutual exclusivity violated
  - Default scope to nil (main directory) if not provided

- [ ] Append scope subdirectory to config directory path
  - After determining location (lines 148-183), check if scope is present
  - If scope == "maybe", append "/maybe" to config["directory"]
  - If scope == "anyday", append "/anyday" to config["directory"]
  - Ensure subdirectory creation happens in IdeaWriter (already auto-creates)
  > TEST: Subdirectory Path Construction
  > Type: Integration Test
  > Assert: Created idea file exists at .ace-taskflow/v.0.9.0/ideas/maybe/[timestamp].md
  > Command: cd ace-taskflow && ruby -Ilib:test test/commands/idea_command_scope_test.rb -n test_create_with_maybe_flag

- [ ] Update show_help() to document new flags
  - Add --maybe and --anyday to flags documentation (lines 371-376)
  - Add examples showing usage with other flags
  - Document mutual exclusivity constraint

#### Phase 4: Preset Manager Extension

- [ ] Add "maybe" preset to ListPresetManager.default_presets()
  - Insert after "done" preset (after line 190)
  - Configuration: name: 'maybe', description: 'Ideas in maybe subdirectory', context: 'current', filters: {}, type: 'ideas', scope: :maybe
  - Set default: false (not a default preset)

- [ ] Add "anyday" preset to ListPresetManager.default_presets()
  - Insert after "maybe" preset
  - Configuration: name: 'anyday', description: 'Ideas in anyday subdirectory', context: 'current', filters: {}, type: 'ideas', scope: :anyday
  - Set default: false
  > TEST: Preset Registration
  > Type: Unit Test
  > Assert: preset_exists?('maybe', :ideas) returns true
  > Command: cd ace-taskflow && ruby -Ilib:test test/molecules/list_preset_manager_test.rb -n test_maybe_preset_exists

#### Phase 5: IdeasCommand Integration

- [ ] Update get_ideas_for_preset() to handle maybe/anyday preset names
  - Add cases for preset_name == 'maybe' → scope = :maybe (line 160)
  - Add cases for preset_name == 'anyday' → scope = :anyday (line 160)
  - Ensure scope is passed to idea_loader.load_all() call
  > TEST: Preset to Scope Mapping
  > Type: Integration Test
  > Assert: ideas command with 'maybe' preset calls load_all with scope: :maybe
  > Command: cd ace-taskflow && ruby -Ilib:test test/commands/ideas_command_test.rb -n test_maybe_preset_execution

- [ ] Update show_help() to document new presets
  - New presets will auto-appear in preset list (lines 372-378)
  - Add examples for maybe and anyday presets (lines 380-384)

#### Phase 6: Statistics Integration

- [ ] Add maybe and anyday status icons to StatsFormatter.IDEA_STATUS_ICONS
  - Add "maybe" => "🤔" to constant hash (line 24)
  - Add "anyday" => "📅" to constant hash (line 24)
  - Update IDEA_STATUS_ORDER if necessary for display ordering

- [ ] Update get_idea_statistics() to detect maybe/anyday from path
  - Extend status detection logic (lines 229-234)
  - If idea[:path].include?("/maybe/"), set status = "maybe"
  - If idea[:path].include?("/anyday/"), set status = "anyday"
  - Maintain existing done/ and new detection
  > TEST: Status Detection
  > Type: Unit Test
  > Assert: Idea with path containing "/maybe/" has status "maybe"
  > Command: cd ace-taskflow && ruby -Ilib:test test/molecules/stats_formatter_test.rb -n test_detect_maybe_status

- [ ] Update format_ideas_line() to display maybe/anyday counts
  - Add maybe_count extraction similar to done_count (line 258)
  - Add anyday_count extraction
  - Insert maybe and anyday display in parts array (lines 260-271)
  - Format: "💡 #{new_count} | 🤔 #{maybe_count} maybe | 📅 #{anyday_count} anyday | ✅ #{done_count}"
  > TEST: Statistics Display Format
  > Type: Integration Test
  > Assert: Output matches "Ideas: 💡 11 | 🤔 5 maybe | 📅 3 anyday | ✅ 31 done • 50 total"
  > Command: cd ace-taskflow && ace-taskflow ideas --stats

#### Phase 7: Test Implementation

- [ ] Create test fixtures with maybe/ and anyday/ subdirectories
  - Add test/fixtures/taskflow/ideas/maybe/ directory
  - Add test/fixtures/taskflow/ideas/anyday/ directory
  - Create sample idea files in each subdirectory
  - Include both flat files (.md) and directory-based ideas

- [ ] Implement IdeaLoader unit tests (test/molecules/idea_loader_maybe_anyday_test.rb)
  - Test load_all with scope: :maybe
  - Test load_all with scope: :anyday
  - Test load_all with scope: :all includes maybe and anyday
  - Test count_ideas_in_directory includes maybe and anyday
  > TEST: Unit Test Suite
  > Type: Unit Test Suite
  > Assert: All IdeaLoader maybe/anyday tests pass
  > Command: cd ace-taskflow && ruby -Ilib:test test/molecules/idea_loader_maybe_anyday_test.rb

- [ ] Implement IdeaArgParser unit tests (test/molecules/idea_arg_parser_scope_test.rb)
  - Test parsing --maybe flag
  - Test parsing --anyday flag
  - Test mutual exclusivity error
  - Test combination with other flags (--backlog, --git-commit)
  > TEST: Argument Parsing Suite
  > Type: Unit Test Suite
  > Assert: All IdeaArgParser scope tests pass
  > Command: cd ace-taskflow && ruby -Ilib:test test/molecules/idea_arg_parser_scope_test.rb

- [ ] Implement IdeaCommand integration tests (test/commands/idea_command_scope_test.rb)
  - Test creating idea with --maybe flag
  - Test creating idea with --anyday flag
  - Test creating in backlog with --maybe
  - Test error when both --maybe and --anyday provided
  > TEST: Command Integration Suite
  > Type: Integration Test Suite
  > Assert: All IdeaCommand scope tests pass
  > Command: cd ace-taskflow && ruby -Ilib:test test/commands/idea_command_scope_test.rb

- [ ] Run full test suite to verify no regressions
  - Execute all existing tests
  - Verify no failures in unrelated tests
  - Check code coverage for new code paths
  > TEST: Regression Check
  > Type: Full Test Suite
  > Assert: All tests pass, no regressions detected
  > Command: cd ace-taskflow && rake test

#### Phase 8: Manual Testing and Validation

- [ ] Test creating ideas with --maybe flag
  - Create idea in current release with --maybe
  - Verify file created at correct path
  - Verify subdirectory auto-created
  > TEST: Manual Creation Test
  > Type: Manual Integration Test
  > Assert: Idea file exists at .ace-taskflow/v.0.9.0/ideas/maybe/[timestamp].md
  > Command: ace-taskflow idea create "Test maybe idea" --maybe && ls .ace-taskflow/v.0.9.0/ideas/maybe/

- [ ] Test listing ideas with new presets
  - Run: ace-taskflow ideas maybe
  - Run: ace-taskflow ideas anyday
  - Run: ace-taskflow ideas all
  - Verify output shows correct ideas and statistics
  > TEST: Manual Listing Test
  > Type: Manual Integration Test
  > Assert: Ideas displayed from correct subdirectories with proper statistics
  > Command: ace-taskflow ideas maybe && ace-taskflow ideas anyday && ace-taskflow ideas all

- [ ] Test statistics display
  - Run: ace-taskflow ideas --stats
  - Verify maybe and anyday counts appear with emoji icons
  - Verify total count includes all subdirectories
  > TEST: Statistics Display
  > Type: Manual Integration Test
  > Assert: Output shows "Ideas: 💡 X | 🤔 Y maybe | 📅 Z anyday | ✅ W done • Total total"
  > Command: ace-taskflow ideas --stats

- [ ] Test edge cases
  - Test with empty maybe/ subdirectory
  - Test with no active release (should fall back to backlog)
  - Test error message for --maybe --anyday together
  > TEST: Edge Case Validation
  > Type: Manual Integration Test
  > Assert: Appropriate messages for edge cases, no crashes
  > Command: ace-taskflow idea create "Test" --maybe --anyday

## Acceptance Criteria

### Listing Functionality
- [ ] `ace-taskflow ideas maybe` displays only ideas from ideas/maybe/ subdirectory
- [ ] `ace-taskflow ideas anyday` displays only ideas from ideas/anyday/ subdirectory
- [ ] `ace-taskflow ideas all` includes ideas from main + maybe/ + anyday/ + done/ subdirectories
- [ ] Statistics always show total counts including ideas from all subdirectories (main, maybe, anyday, done)
- [ ] Help text (`ace-taskflow ideas --help`) documents the new maybe and anyday presets

### Creation Functionality
- [ ] `ace-taskflow idea create "content" --maybe` creates idea in ideas/maybe/ subdirectory
- [ ] `ace-taskflow idea create "content" --anyday` creates idea in ideas/anyday/ subdirectory
- [ ] `--maybe` works with `--backlog` flag (creates in backlog/ideas/maybe/)
- [ ] `--maybe` works with `--release <name>` flag (creates in release/ideas/maybe/)
- [ ] `--anyday` works with `--backlog` flag (creates in backlog/ideas/anyday/)
- [ ] Subdirectories are auto-created if they don't exist
- [ ] Help text (`ace-taskflow idea --help`) documents the new --maybe and --anyday flags
- [ ] Error message displayed when both --maybe and --anyday provided together

### Statistics and Display
- [ ] Statistics display shows maybe count with 🤔 emoji
- [ ] Statistics display shows anyday count with 📅 emoji
- [ ] Format matches: "Ideas: 💡 11 | 🤔 5 maybe | 📅 3 anyday | ✅ 31 done • 50 total"
- [ ] Empty subdirectories show "No ideas found" but statistics still show total counts

### Testing
- [ ] All unit tests pass (IdeaLoader, IdeaArgParser, StatsFormatter, ListPresetManager)
- [ ] All integration tests pass (IdeaCommand, IdeasCommand)
- [ ] No regressions in existing tests
- [ ] Manual testing validates all scenarios in ux/usage.md

## Risk Assessment

### Technical Risks

**Risk:** Existing code relies on specific scope values, breaking with new additions
- **Probability:** Low
- **Impact:** Medium
- **Mitigation:** Thorough testing of existing functionality, use default values and conditional logic
- **Rollback:** Remove new scope cases, revert to original scope handling

**Risk:** Path detection logic for statistics incorrectly categorizes ideas
- **Probability:** Low
- **Impact:** Medium
- **Mitigation:** Use explicit path matching (idea[:path].include?("/maybe/")), test with various path formats
- **Rollback:** Revert statistics detection logic to original implementation

**Risk:** Mutual exclusivity validation not comprehensive enough, allows invalid combinations
- **Probability:** Low
- **Impact:** Low
- **Mitigation:** Add explicit error checking in IdeaArgParser, add integration tests for error cases
- **Rollback:** Remove validation, document manual constraint in help text

### Integration Risks

**Risk:** New presets conflict with custom user presets
- **Probability:** Low
- **Impact:** Low
- **Mitigation:** Check preset system's override behavior, document that built-in presets can be overridden
- **Monitoring:** Test with custom preset files, verify no namespace collisions

**Risk:** Subdirectory auto-creation fails due to permissions or disk space
- **Probability:** Low
- **Impact:** Low
- **Mitigation:** Reuse existing FileUtils.mkdir_p logic (already used for main directory creation)
- **Monitoring:** Add error handling for directory creation failures

### Performance Risks

**Risk:** Scanning additional subdirectories degrades performance
- **Probability:** Low
- **Impact:** Low
- **Mitigation:** Subdirectory scanning is already implemented for done/, performance already acceptable
- **Monitoring:** Compare scan times before/after implementation
- **Thresholds:** <10ms additional time per subdirectory (based on existing done/ metrics)
