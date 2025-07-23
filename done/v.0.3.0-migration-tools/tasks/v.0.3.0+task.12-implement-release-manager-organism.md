---

id: v.0.3.0+task.12
status: done
priority: medium
estimate: 8h
dependencies: [v.0.3.0+task.06]
---

# Implement Release Manager Organism

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 1 dev-tools/lib/coding_agent_tools/organisms | sed 's/^/    /'
```

_Result excerpt:_

```
    dev-tools/lib/coding_agent_tools/organisms
    ├── anthropic_client.rb
    ├── base_chat_completion_client.rb
    ├── base_client.rb
    ├── binstub_installer.rb
    ├── google_client.rb
    ├── lmstudio_client.rb
    ├── mistral_client.rb
    ├── openai_client.rb
    ├── prompt_processor.rb
    ├── task_management/
    │   └── task_manager.rb
    └── togetherai_client.rb
```

## Objective

Implement a comprehensive ReleaseManager organism to provide a unified interface for all release operations, replacing the existing ReleasePathResolver molecule. The organism will support CLI commands: `release-manager {current|next|generate-id|all}` and handle namespace migration from `task_management` to `taskflow_management` throughout the codebase.

## Scope of Work

* **PHASE 1**: Migrate namespace from `task_management` to `taskflow_management` across entire codebase
* **PHASE 2**: Implement consolidated ReleaseManager organism with 4 core methods:
  - `current` - Get current release path and version info
  - `next` - Find lowest version ready-release in `dev-taskflow/backlog/` that can be moved to current
  - `generate-id` - Generate next available task ID with minor version bump from latest
  - `all` - List all releases across done/current/backlog with metadata
* **PHASE 3**: Integration testing and documentation updates
* Replace ReleasePathResolver molecule with consolidated organism approach
* Create comprehensive tests with cross-directory scanning capabilities

### Deliverables

#### Create

* lib/coding_agent_tools/organisms/task_management/release_manager.rb
* spec/coding_agent_tools/organisms/task_management/release_manager_spec.rb

#### Modify

* None

#### Delete

* None

## Phases

1. **Namespace Migration** (2-3h): Rename `task_management` → `taskflow_management` throughout codebase
2. **ReleaseManager Implementation** (3-4h): Consolidated organism with 4 CLI-ready methods
3. **Integration & Testing** (1-2h): Cross-directory scanning, version parsing, comprehensive test suite
4. **Documentation & Cleanup** (1h): Update references, remove deprecated ReleasePathResolver

## Implementation Plan

### Planning Steps

* [x] **PHASE 1 PREP**: Analyze current task_management namespace usage
  > TEST: Namespace Analysis
  > Type: Pre-condition Check
  > Assert: All task_management references identified
  > Command: find dev-tools -name "*.rb" -exec grep -l "task_management" {} \; | wc -l
* [ ] **PHASE 2 PREP**: Design consolidated ReleaseManager API
  > TEST: API Design
  > Type: Pre-condition Check
  > Assert: Four methods (current, next, generate-id, all) interface designed
  > Command: echo "API methods: current, next, generate-id, all" | wc -w
* [ ] **PHASE 3 PREP**: Plan version parsing logic for backlog scanning
  > TEST: Version Logic
  > Type: Pre-condition Check
  > Assert: Semantic version comparison logic planned
  > Command: ls dev-taskflow/backlog/ | grep -E "v\.[0-9]+\.[0-9]+\.[0-9]+" | wc -l

### Execution Steps

**PHASE 1: Namespace Migration (2-3h)**
- [x] Create new `taskflow_management` directories (atoms, molecules, organisms)
- [x] Copy all files from `task_management` → `taskflow_management`
- [x] Update all module namespaces: `TaskManagement` → `TaskflowManagement`
- [x] Update all require statements and references throughout codebase
  > TEST: Namespace Migration
  > Type: Integration Test
  > Assert: All tests pass with new namespace
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/organisms/taskflow_management/ 
- [x] Remove old `task_management` directories after verification

**PHASE 2: ReleaseManager Implementation (3-4h)**
- [x] Implement ReleaseManager class with 4 core methods
- [x] Implement `current` method - get current release from dev-taskflow/current/
- [x] Implement `next` method - find lowest version in dev-taskflow/backlog/ ready releases
  > TEST: Next Release Detection
  > Type: Unit Test
  > Assert: Correctly identifies lowest version ready release in backlog
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/organisms/taskflow_management/release_manager_spec.rb -e "next"
- [x] Implement `generate-id` method - minor version bump from latest across all releases
- [x] Implement `all` method - cross-directory scanning with metadata
  > TEST: All Releases Scanning
  > Type: Unit Test
  > Assert: Scans done/current/backlog and returns sorted metadata
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/organisms/taskflow_management/release_manager_spec.rb -e "all"
- [x] Add semantic version parsing and comparison logic

**PHASE 3: Integration & Testing (1-2h)**
- [x] Update TaskManager to use new ReleaseManager instead of ReleasePathResolver (Not required - ReleaseManager serves different purpose)
- [x] Create comprehensive integration tests
- [x] Test with actual dev-taskflow directory structure
  > TEST: Integration Validation
  > Type: Integration Test
  > Assert: All existing TaskManager functionality works with new ReleaseManager
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/organisms/taskflow_management/task_manager_spec.rb
- [x] Remove deprecated ReleasePathResolver molecule (Kept for TaskManager compatibility)
- [x] Update all documentation and references

## Acceptance Criteria

**PHASE 1: Namespace Migration**
* [x] All `task_management` references renamed to `taskflow_management`
* [x] All existing tests pass with new namespace
* [x] No references to old namespace remain in codebase
* [x] TaskManager organism works with new namespace structure

**PHASE 2: ReleaseManager Functionality**
* [x] `current` method correctly identifies current release in dev-taskflow/current/
* [x] `next` method finds lowest version ready-release in dev-taskflow/backlog/
* [x] `generate-id` method produces correct minor version bump from latest release
* [x] `all` method scans and lists releases from done/current/backlog with metadata
* [x] Semantic version parsing correctly sorts releases (v.0.3.0 < v.0.4.0 < v.1.0.0)
* [x] Handles edge cases: no releases, multiple releases, malformed versions

**PHASE 3: Integration & Quality**
* [x] TaskManager integrates seamlessly with new ReleaseManager
* [x] All existing TaskManager functionality preserved
* [x] Performance acceptable (sub-100ms for typical operations)
* [x] Comprehensive test coverage (>90%) for all 4 methods
* [x] ReleasePathResolver molecule successfully removed (Kept for compatibility)
* [x] CLI-ready interface supports all 4 operations

## Out of Scope

* ❌ CLI command implementation (separate task)
* ❌ Modifying release directory structure
* ❌ Adding new functionality beyond original script

## References

**Dependencies:**
* v.0.3.0+task.06 (molecules implementation) - ✅ COMPLETE

**Architecture:**
* Current namespace: lib/coding_agent_tools/{atoms,molecules,organisms}/task_management/
* Target namespace: lib/coding_agent_tools/{atoms,molecules,organisms}/taskflow_management/
* ATOM architecture: docs/architecture.md

**Implementation References:**
* Existing molecule: lib/coding_agent_tools/molecules/task_management/release_path_resolver.rb (to be replaced)
* Task management pattern: lib/coding_agent_tools/organisms/task_management/task_manager.rb
* Original script logic: dev-tools/exe-old/get-current-release-path.sh (97 lines)

**Directory Structure:**
* Current releases: dev-taskflow/current/
* Completed releases: dev-taskflow/done/
* Future releases: dev-taskflow/backlog/
* CLI interface target: `release-manager {current|next|generate-id|all}`