---
id: v.0.9.0+task.088
status: draft
priority: medium
estimate: TBD
dependencies: []
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
