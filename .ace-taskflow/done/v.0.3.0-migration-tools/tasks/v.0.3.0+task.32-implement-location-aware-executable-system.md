---
id: v.0.3.0+task.32
status: done
priority: high
estimate: 8h
dependencies: [v.0.3.0+task.31]
---

# Implement Location-Aware Executable System

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 .ace/tools/exe | sed 's/^/    /'
```

_Result excerpt:_

```
    .ace/tools/exe
    ├── coding_agent_tools
    ├── generate-review-prompt
    ├── llm-models
    ├── llm-query
    ├── llm-usage-report
    └── task-manager
```

## Objective

Make all executables in `.ace/tools/exe/*` location-aware so they work predictably regardless of the directory from which they're executed. This resolves the current SecurityError with binstubs trying to access `../.ace/taskflow` from the `.ace/tools` directory and enables flexible usage patterns including PATH-based access.

## Scope of Work

* Create robust project root detection mechanism
* Update task management CLI commands to use absolute paths
* Ensure all executables can find project structure from any location
* Add optional PATH setup for system-wide access
* Test execution from various directory locations

### Deliverables

#### Create

* lib/coding_agent_tools/atoms/project_root_detector.rb
* bin/setup-env (PATH setup script)
* spec/coding_agent_tools/atoms/project_root_detector_spec.rb

#### Modify

* lib/coding_agent_tools/cli/commands/task/next.rb
* lib/coding_agent_tools/cli/commands/task/recent.rb  
* lib/coding_agent_tools/cli/commands/task/all.rb
* lib/coding_agent_tools/cli/commands/task/generate_id.rb
* .ace/tools/exe/task-manager
* .ace/tools/exe/llm-query
* .ace/tools/exe/llm-models
* .ace/tools/exe/llm-usage-report
* .ace/tools/exe/coding_agent_tools

#### Delete

* None

## Phases

1. Create Project Root Detection Foundation
2. Update Task Management Commands
3. Update All Executables for Self-Awareness
4. Create PATH Setup Script
5. Testing and Validation

## Implementation Plan

### Planning Steps

* [x] Analyze current path detection logic and failure points
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: Current path resolution mechanisms and failure modes are documented
  > Command: grep -r "base_path\|Dir.pwd" .ace/tools/lib .ace/tools/exe
* [x] Research project structure markers for reliable root detection
  - Primary markers: `.git` directory (highest priority for development)
  - Secondary markers: `coding_agent_tools.gemspec`, `Gemfile`
  - Tertiary markers: `.ruby-version`, custom `.tools-meta` file
* [x] Design ProjectRootDetector API and fallback strategies
  - Upward directory traversal with marker detection
  - Process-level caching to avoid repeated filesystem operations
  - Clear error handling when root cannot be detected
  - Optional debug mode for troubleshooting

### Execution Steps

- [x] Create ProjectRootDetector atom with robust project root detection
  - Implement marker-based detection (`.git`, `gemspec`, `Gemfile`)
  - Add caching mechanism to store detected root per process
  - Include debug mode for troubleshooting detection issues
  - Handle edge cases: symlinks, nested git repos, permission errors
  > TEST: Project Root Detection
  > Type: Unit Test
  > Assert: ProjectRootDetector finds correct root from various locations
  > Command: cd .ace/tools && bundle exec rspec spec/coding_agent_tools/atoms/project_root_detector_spec.rb
- [x] Update task CLI commands to use ProjectRootDetector instead of brittle path logic
- [x] Update task-manager executable to be location-aware
- [x] Update all LLM executables to be location-aware
- [x] Update main coding_agent_tools executable to be location-aware
- [x] Create bin/setup-env script for PATH-based access
  > TEST: PATH Setup Functionality
  > Type: Integration Test
  > Assert: setup-env script correctly adds exe directory to PATH
  > Command: source bin/setup-env && which task-manager
- [x] Test all executables from various directory locations
  - Test from project root, subdirectories, home directory, /tmp
  - Test with symlinked executables
  - Test with spaces in directory paths
  - Verify proper error messages when run outside project context
  > TEST: Location Independence
  > Type: Integration Test  
  > Assert: All executables work from arbitrary directories
  > Command: cd /tmp && /full/path/to/.ace/tools/exe/task-manager next
- [x] Update binstub configuration to leverage location-aware executables

## Acceptance Criteria

* [x] All executables in .ace/tools/exe/* work correctly when run from any directory
* [x] ProjectRootDetector reliably finds project root from nested subdirectories
* [x] Task management commands resolve correct paths to .ace/taskflow regardless of execution location
* [x] PATH setup script enables system-wide access to executables
* [x] SecurityError with binstubs is resolved
* [x] All existing functionality remains intact
* [x] Comprehensive test coverage for location detection logic

## Out of Scope

* ❌ Modifying the core task management file scanning logic (SecurityError fix is through path resolution)
* ❌ Creating GUI interfaces for PATH setup
* ❌ Adding shell completion scripts
* ❌ Modifying project directory structure

## References

* Current issue: SecurityError in bin/tn when accessing ../.ace/taskflow from .ace/tools directory
* Related: v.0.3.0+task.31 (binstub installation system implementation)
* Path detection logic: lib/coding_agent_tools/cli/commands/task/next.rb:31
* Security validation: lib/coding_agent_tools/atoms/task_management/file_system_scanner.rb:127
* Ruby best practices for executable path resolution: Use `File.expand_path` with `__FILE__`
* Standard gem markers: `.git`, `gemspec`, `Gemfile` for root detection

## Technical Notes

### Root Detection Strategy
1. Start from current executable location (`File.dirname(File.expand_path(__FILE__))`)
2. Traverse upward looking for markers in priority order:
   - `.git` directory (development environment indicator)
   - `coding_agent_tools.gemspec` (gem-specific marker)
   - `Gemfile` (Ruby project marker)
3. Cache detected root in class variable to avoid repeated traversal
4. Fail gracefully with helpful error message if no root found

### Security Considerations
- Validate all resolved paths stay within project boundaries
- Use existing SecurePathValidator for path validation
- Avoid following symlinks that lead outside project root
- Ensure no arbitrary file access through manipulated paths