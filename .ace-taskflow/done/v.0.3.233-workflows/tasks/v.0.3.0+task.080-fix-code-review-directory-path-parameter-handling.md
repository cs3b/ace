---
id: v.0.3.0+task.80
status: done
priority: high
estimate: 4h
dependencies: []
---

# Fix code-review directory path parameter handling

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 .ace/tools/lib | sed 's/^/    /'
```

_Result excerpt:_

```
.ace/tools/lib
├── coding_agent_tools
│   ├── atoms
│   ├── cli.rb
│   ├── cost_tracker.rb
│   ├── ecosystems
│   ├── error.rb
│   ├── error_reporter.rb
│   ├── models.rb
│   ├── molecules
│   ├── notifications.rb
│   ├── organisms
│   ├── pricing_fetcher.rb
│   └── version.rb
└── coding_agent_tools.rb
```

## Objective

Fix the code-review command parameter handling so that directory paths (e.g., `.ace/tools/lib`) and directory glob patterns (e.g., `.ace/tools/lib/**/*`) work equivalently to explicit file glob patterns (e.g., `.ace/tools/lib/**/*.rb`). Currently, directory paths fail with "undefined method 'find_files_with_pattern'" error in the FileSystemScanner class.

## Scope of Work

- Fix the missing `find_files_with_pattern` method in `CodingAgentTools::Atoms::TaskflowManagement::FileSystemScanner`
- Ensure directory paths automatically expand to include all files within the directory tree
- Maintain compatibility with existing glob pattern functionality
- Add proper error handling for invalid paths

### Deliverables

#### Create

- None (fixing existing functionality)

#### Modify

- `.ace/tools/lib/coding_agent_tools/atoms/taskflow_management/file_system_scanner.rb` (implement missing method)
- Any related file system scanning logic that handles path resolution

#### Delete

- None

## Phases

1. Investigate the error source in FileSystemScanner class
2. Implement the missing `find_files_with_pattern` method
3. Add directory-to-glob expansion logic
4. Test with various path formats

## Implementation Plan

### Planning Steps

- [x] Locate the FileSystemScanner class and analyze its current implementation
  > TEST: Class Analysis Complete
  > Type: Pre-condition Check
  > Assert: FileSystemScanner class structure and existing methods are identified
  > Command: grep -r "class.*FileSystemScanner" .ace/tools/lib/
- [x] Identify how path parameters are processed in the code-review command
- [x] Research existing file pattern matching implementations in the codebase

### Execution Steps

- [x] Implement the missing `find_files_with_pattern` method in FileSystemScanner
- [x] Add logic to convert directory paths to appropriate glob patterns (e.g., `dir` → `dir/**/*`)
  > TEST: Directory Path Expansion
  > Type: Action Validation
  > Assert: Directory paths are properly expanded to include all files
  > Command: code-review code .ace/tools/lib --dry-run
- [x] Ensure backward compatibility with existing glob pattern functionality
- [x] Add error handling for non-existent paths and invalid patterns
  > TEST: Error Handling Validation
  > Type: Action Validation
  > Assert: Non-existent paths produce helpful error messages instead of method errors
  > Command: code-review code nonexistent/path 2>&1 | grep -v "find_files_with_pattern"

## Acceptance Criteria

- [x] AC 1: `code-review code .ace/tools/lib` works without errors
- [x] AC 2: `code-review code .ace/tools/lib/**/*` works equivalently to explicit patterns
- [x] AC 3: Both directory paths and glob patterns produce the same file selection results
- [x] AC 4: Existing glob pattern functionality (`.ace/tools/lib/**/*.rb`) continues to work unchanged
- [x] AC 5: Helpful error messages for invalid paths (no undefined method errors)

## Out of Scope

- ❌ Changing the overall code-review command interface or workflow
- ❌ Performance optimizations for file scanning
- ❌ Adding new file filtering or exclusion features

## References

Error example:
```
michalczyz  …/handbook-meta   master ✘!⇡   v24.3.0
 ♥ 18:14 ➜ code-review code .ace/tools/lib
Error: undefined method 'find_files_with_pattern' for class CodingAgentTools::Atoms::TaskflowManagement::FileSystemScanner
```

Working example:
```
michalczyz  …/handbook-meta   master ✘!⇡   v24.3.0
 ♥ 18:14 ➜ code-review code .ace/tools/lib/**/*.rb
✅ Created review session: code-.ace/tools-lib-coding_agent_tools.rb-20250724-181435
```