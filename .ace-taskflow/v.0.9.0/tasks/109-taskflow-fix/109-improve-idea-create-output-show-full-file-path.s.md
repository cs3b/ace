---
id: v.0.9.0+task.109
status: pending
priority: low
estimate: 30min
dependencies: []
---

# Improve ace-taskflow idea create output to show full file path

## Behavioral Specification

### User Experience
- **Input**: User runs `ace-taskflow idea create` command
- **Process**: Command creates idea in folder structure as expected
- **Output**: Currently shows only folder path, should show full file path

### Current vs Expected Behavior

**Current Output:**
```bash
$ ace-taskflow idea create -gc -llm "test creation of the idea"
Idea captured: .ace-taskflow/v.0.9.0/ideas/20251113-105651-taskflow-test
```

**Expected Output:**
```bash
$ ace-taskflow idea create -gc -llm "test creation of the idea"
Idea captured: .ace-taskflow/v.0.9.0/ideas/20251113-105651-taskflow-test/test-creation-of-the-idea.s.md
```

### Success Criteria
- [x] **Folder Creation**: Ideas are already being created in proper folder structure ✅ (ALREADY WORKING)
- [x] **File Creation**: .s.md files are created inside folders ✅ (ALREADY WORKING)
- [ ] **Output Message**: Show full path to the .s.md file, not just the folder

## Objective

Improve the user feedback when creating ideas to show the complete path to the created .s.md file, making it easier for users to know exactly what file was created.

## Scope of Work

- **User Experience Scope**: Improve output message only
- **System Behavior Scope**: No changes to actual idea creation logic (already working correctly)
- **Interface Scope**: Update the printed output message

## Technical Research

### Current Implementation
Looking at `ace-taskflow/lib/ace/taskflow/commands/idea_command.rb` lines 195-200:
```ruby
writer = Organisms::IdeaWriter.new(config)
path = writer.write(options[:content], options)  # Returns folder path
root_path = Dir.pwd
relative_path = Atoms::PathFormatter.format_relative_path(path, root_path)
puts "Idea captured: #{relative_path}"  # Only shows folder!
```

The `IdeaWriter.write()` method (line 118 in `idea_writer.rb`) returns the folder path, not the file path.

## Implementation Plan

### Planning Steps
* [x] Identify that folder-based idea creation is already working ✅
* [x] Confirm the only issue is output message ✅
* [ ] Determine best approach to get file path

### Execution Steps

- [ ] Update output to show full file path
  **Option A**: Modify `IdeaWriter.write()` to return file path instead of folder path
  ```ruby
  # In idea_writer.rb line 118, instead of:
  path  # Returns folder
  # Return:
  file_path  # Returns full path to .s.md file
  ```

  **Option B**: Update `IdeaCommand.create_idea()` to construct full path
  ```ruby
  # In idea_command.rb after line 197:
  # Get the actual file that was created
  idea_files = Dir.glob(File.join(path, "*.s.md"))
  file_path = idea_files.first || path
  relative_path = Atoms::PathFormatter.format_relative_path(file_path, root_path)
  ```

- [ ] Test the output shows full file path
  > TEST: Output shows file path
  > Type: Manual Test
  > Assert: Running `ace-taskflow idea create` shows path to .s.md file
  > Command: ace-taskflow idea create -gc "test" and verify output

## File Modifications

### Modify Files
Either:
- `ace-taskflow/lib/ace/taskflow/organisms/idea_writer.rb` - Return file path from write(), OR
- `ace-taskflow/lib/ace/taskflow/commands/idea_command.rb` - Construct file path for display

## Risk Analysis

### Technical Risks
- **Breaking changes**: Minimal - only changes output message
- **Compatibility**: No impact on existing functionality

## Notes

**IMPORTANT**: Most of the originally planned work for task 109 (fixing idea done command, reference matching, etc.) was based on a misunderstanding. The folder-based idea creation is ALREADY WORKING. The problematic files mentioned were created BEFORE the fixes were implemented. This task has been reduced to just improving the output message to be more helpful to users.