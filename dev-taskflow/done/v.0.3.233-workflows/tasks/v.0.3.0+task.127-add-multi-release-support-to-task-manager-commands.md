---
id: v.0.3.0+task.127
status: done
priority: medium
estimate: 6h
dependencies: []
---

# Add multi-release support to task-manager commands

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 .ace/handbook/guides | sed 's/^/    /'
```

_Result excerpt:_

```
<insert tree here>
```

## Objective

Enable task-manager commands to work across different releases by adding `--release` flag support, allowing users to specify which release to work with using various identification formats (version, codename, fullname, or path).

## Scope of Work

- Add `--release` flag to all task-manager commands (next, all, recent, reschedule, generate-id)
- Support multiple release identification formats: version (v.0.3.0), codename (workflows), fullname (v.0.3.0-workflows), path (.ace/taskflow/current/v.0.3.0-workflows)
- Implement release resolution logic
- Maintain backward compatibility (default to current release)
- Update commands to work with specified release context

### Deliverables

#### Create

- .ace/tools/lib/coding_agent_tools/molecules/taskflow_management/release_resolver.rb

#### Modify

- .ace/tools/lib/coding_agent_tools/cli/commands/task/next.rb
- .ace/tools/lib/coding_agent_tools/cli/commands/task/all.rb
- .ace/tools/lib/coding_agent_tools/cli/commands/task/recent.rb
- .ace/tools/lib/coding_agent_tools/cli/commands/task/reschedule.rb
- .ace/tools/lib/coding_agent_tools/cli/commands/task/generate_id.rb

#### Delete

- N/A

## Phases

1. Design release identification and resolution system
2. Implement release resolver molecule
3. Add `--release` flag to all task commands
4. Test release resolution with various formats

## Implementation Plan

*This section details the specific steps required to complete the task. It is divided into two subsections to distinguish between planning/analysis activities and actual implementation work._

### Planning Steps

*Optional but recommended for complex tasks. Use asterisk markers (`* [ ]`) for research, analysis, and design activities that help clarify the approach before implementation begins._

- [ ] Analyze current release detection logic in task-manager commands
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: Current release detection mechanisms are documented
  > Command: grep -r "current.*release\|release.*current" .ace/tools/lib/coding_agent_tools/cli/commands/task/
- [ ] Design release identification formats and resolution strategy
- [ ] Plan `--release` flag API and backward compatibility approach

### Execution Steps

*Required section. Use hyphen markers (`- [ ]`) for concrete implementation actions that modify code, create files, or change the system state._

- [ ] Create release resolver molecule with format support
  > TEST: Verify Release Resolver Creation
  > Type: Action Validation
  > Assert: Release resolver handles all specified formats
  > Command: grep -E "class.*ReleaseResolver" .ace/tools/lib/coding_agent_tools/molecules/taskflow_management/release_resolver.rb
- [ ] Add `--release` flag to all task-manager commands
- [ ] Update commands to use release resolver for context
  > TEST: Verify Multi-Release Support
  > Type: Action Validation
  > Assert: Commands accept --release flag with different formats
  > Command: task-manager next --release v.0.3.0 --help | grep "\-\-release"
- [ ] Test release resolution with all supported formats (version, codename, fullname, path)
- [ ] Verify backward compatibility (default behavior unchanged)

## Acceptance Criteria

*Define the conditions that signify the task is complete. These can be manual checks or high-level statements whose details are verified by embedded tests in the Implementation Plan._

- [ ] AC 1: All task-manager commands accept `--release` flag
- [ ] AC 2: Release resolution works with version (v.0.3.0), codename (workflows), fullname (v.0.3.0-workflows), and path formats
- [ ] AC 3: Commands operate on specified release when `--release` flag is used
- [ ] AC 4: Backward compatibility maintained (default to current release)
- [ ] AC 5: Appropriate error messages for invalid release specifications

## Out of Scope

- ❌ Cross-release dependency management
- ❌ Release creation or deletion functionality
- ❌ Complex release validation beyond basic format checking
- ❌ GUI or interactive release selection

## References

Based on feedback from: .ace/taskflow/backlog/ideas/exe-task-manager-improvements.md
- Item #1: Multi-release support with `--release` flag
- Supported formats: version (v.0.3.0), codename (workflows), fullname (v.0.3.0-workflows), path (.ace/taskflow/current/v.0.3.0-workflows)
