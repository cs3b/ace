---
id: 8vt.t.tqm
status: pending
priority: medium
created_at: "2026-08-30 19:49:35"
estimate: 2h
dependencies: []
tags: [ace-support-test-helpers, ace-support-config, ace-git-worktree, testing, containers, permissions]
bundle:
  presets: [project]
  files: [ace-support-test-helpers/lib/ace/test_support/test_helper.rb, ace-support-test-helpers/test/fast/atoms/test_helper_test.rb, ace-support-config/test/test_helper.rb, ace-support-config/test/feat/config_cascade_edge_test.rb, ace-support-config/test/fast/molecules/project_config_scanner_test.rb, ace-git-worktree/test/fast/atoms/path_expander_test.rb]
  commands: [bundle exec ace-test ace-support-test-helpers all, bundle exec ace-test ace-support-config all, bundle exec ace-test ace-git-worktree all]
needs_review: false
---

# Promote permission_denial_enforced? probe into ace-support-test-helpers

## Objective

Extract the empirical `permission_denial_enforced?` probe (added in PR #9 / commit 75a338742 for task `8vt.t.rtr.2`) from `ace-support-config/test/feat/config_cascade_edge_test.rb` into `Ace::TestSupport::TestHelper` in `ace-support-test-helpers`, and adopt it everywhere chmod-based permission tests exist across the monorepo.

## Background

Clean-context review of `8vt.t.rtr.2` (W404) observed that `ace-support-config/test/fast/molecules/project_config_scanner_test.rb` and `ace-git-worktree/test/fast/atoms/path_expander_test.rb` still guard permission tests with weaker `Process.uid.zero?` or `Process.uid == 0` checks. UID-only checks miss non-root processes granted `CAP_DAC_OVERRIDE` (common in containerized CI environments) and vacuously pass or fail where DAC permission denial cannot be produced. The empirical probe (temporary file, `chmod 0000`, attempt read, with `NotImplementedError`/`SystemCallError` treated as untestable, and permissions restored in `ensure` for clean teardown) is strictly more correct.

## Behavioral Specification

### User Experience / Test Execution
- **Input:** Test suites in `ace-support-config`, `ace-git-worktree`, and other packages execute permission denial tests in various environments: unprivileged host user (UID != 0, no `CAP_DAC_OVERRIDE`), container root (UID 0 with `CAP_DAC_OVERRIDE`), non-root container with capabilities, or filesystems without chmod support (Windows / WSL virtual mounts).
- **Process:** Tests query `permission_denial_enforced?` provided by `Ace::TestSupport::TestHelper`. If the probe returns `true`, the test proceeds with `chmod`-based assertions. If `false`, the test calls `skip "Permission bits not enforced for this process (root/CAP_DAC_OVERRIDE)"`.
- **Output:** All permission test cases execute and verify expected exceptions in standard environments, and skip deterministically without failures or false positives in containerized or root environments.

### Expected Behavior
1. **Shared Helper Placement**:
   - `permission_denial_enforced?` is implemented as an instance method in `Ace::TestSupport::TestHelper` (`ace-support-test-helpers/lib/ace/test_support/test_helper.rb`).
   - Because `Ace::TestSupport::BaseTestCase` includes `TestHelper`, all test suites inheriting `BaseTestCase` or `AceTestCase` have access to `permission_denial_enforced?`.
   - `Ace::Support::Config::TestCase` in `ace-support-config/test/test_helper.rb` includes `Ace::TestSupport::TestHelper` (requiring `"ace/test_support"`).
2. **Probe Implementation & Lifecycle**:
   - On Windows (`Gem.win_platform?`), returns `false`.
   - Creates a temporary probe file using `Tempfile.create("ace_perm_probe")`.
   - Attempts `File.chmod(0o000, probe.path)`. If `NotImplementedError` or `SystemCallError` is raised, returns `false` (untestable/ignored mode bits).
   - Attempts `File.read(probe.path)`. If read succeeds without error (root/`CAP_DAC_OVERRIDE` bypass), returns `false`. If `SystemCallError` (e.g. `Errno::EACCES`) is raised, returns `true`.
   - In an `ensure` block, restores file mode (`File.chmod(0o600, probe.path)` rescued against `StandardError`) to ensure `Tempfile` cleanup and unlink succeed without permission errors.
3. **Probe Adjudication (Read vs Write Denial)**:
   - Linux kernel DAC bypass via `CAP_DAC_OVERRIDE` bypasses read, write, and execute permissions uniformly.
   - Therefore, a single empirical read-denial probe is canonical and sufficient for all `chmod 0o000`, `0o444`, and `0o555` tests; distinct write probes are unnecessary.
4. **Adoption & Sweep Inventory**:
   - `ace-support-test-helpers`: Add helper in `lib/ace/test_support/test_helper.rb` and unit tests in `test/fast/atoms/test_helper_test.rb`.
   - `ace-support-config`:
     - `test/test_helper.rb`: Add `require "ace/test_support"` and `include Ace::TestSupport::TestHelper` to `Ace::Support::Config::TestCase`.
     - `test/feat/config_cascade_edge_test.rb`: Remove private `permission_denial_enforced?` helper; retain `skip ... unless permission_denial_enforced?` in `test_permission_denied_on_config_file` and `test_permission_denied_on_config_directory`.
     - `test/fast/molecules/project_config_scanner_test.rb`: Replace `skip "Permission tests require non-root" if Process.uid.zero?` with `skip "Permission bits not enforced for this process (root/CAP_DAC_OVERRIDE)" unless permission_denial_enforced?`.
   - `ace-git-worktree`:
     - `test/fast/atoms/path_expander_test.rb`: Replace `skip "Permission tests don't work as root" if Process.uid == 0` with `skip "Permission bits not enforced for this process (root/CAP_DAC_OVERRIDE)" unless permission_denial_enforced?`.
   - `ace-support-core`:
     - `test/fast/molecules/yaml_loader_test.rb`: Preserve structural failure simulation (`blocker` file) which tests write failure deterministically across all environments without depending on chmod.
   - `ace-support-fs`:
     - `test/fast/molecules/directory_traverser_edge_test.rb`: Preserved as-is (graceful error handling without skip).

### Interface Contract

```ruby
module Ace
  module TestSupport
    module TestHelper
      # Returns true when mode-0000/DAC permission bits are actually enforced
      # against the current process. Returns false for root (UID 0), processes
      # with CAP_DAC_OVERRIDE, Windows platforms, or unsupported filesystems.
      #
      # @return [Boolean]
      def permission_denial_enforced?
        return false if Gem.win_platform?

        Tempfile.create("ace_perm_probe") do |probe|
          probe.write("probe")
          probe.flush
          begin
            File.chmod(0o000, probe.path)
          rescue NotImplementedError, SystemCallError
            return false
          end
          begin
            File.read(probe.path)
            false
          rescue SystemCallError
            true
          ensure
            begin
              File.chmod(0o600, probe.path)
            rescue StandardError
              nil
            end
          end
        end
      end
    end
  end
end
```

## Success Criteria

- [ ] `Ace::TestSupport::TestHelper#permission_denial_enforced?` is implemented and unit tested in `ace-support-test-helpers`.
- [ ] `permission_denial_enforced?` properly restores temporary file permissions to `0o600` in an `ensure` block before Tempfile disposal.
- [ ] `ace-support-config` adopts shared `permission_denial_enforced?` and removes private duplicate.
- [ ] `ace-support-config/test/fast/molecules/project_config_scanner_test.rb` replaces `Process.uid.zero?` with `permission_denial_enforced?`.
- [ ] `ace-git-worktree/test/fast/atoms/path_expander_test.rb` replaces `Process.uid == 0` with `permission_denial_enforced?`.
- [ ] All package test suites (`ace-support-test-helpers`, `ace-support-config`, `ace-git-worktree`) pass with 0 failures and 0 errors.
- [ ] Full monorepo deterministic test suite (`bundle exec ace-test-suite --no-color --target all`) passes cleanly.
- [ ] Zero changes to production code in `lib/` (except test support gem `ace-support-test-helpers/lib/ace/test_support/test_helper.rb`).

## Required Package Tests

- `bundle exec ace-test ace-support-test-helpers all`
- `bundle exec ace-test ace-support-config fast`
- `bundle exec ace-test ace-support-config feat`
- `bundle exec ace-test ace-support-config all`
- `bundle exec ace-test ace-git-worktree fast`
- `bundle exec ace-test ace-git-worktree all`
- `ruby .ace-bin/ci_package_inventory.rb`
- `bundle exec ace-test-e2e ace-monorepo-e2e --dry-run`
- `bundle exec ace-test-suite --no-color --target all`

## Clean-Container Verification

- Run all package and suite tests inside a container running as root (UID 0 / `CAP_DAC_OVERRIDE`) and verify all permission tests skip cleanly with 0 failures and 0 errors.
- Run tests in an unprivileged user environment and verify all permission tests run and assert expected behavior.

## Deliverables

1. **Implementation Files**:
   - `ace-support-test-helpers/lib/ace/test_support/test_helper.rb`
   - `ace-support-test-helpers/test/fast/atoms/test_helper_test.rb`
   - `ace-support-config/test/test_helper.rb`
   - `ace-support-config/test/feat/config_cascade_edge_test.rb`
   - `ace-support-config/test/fast/molecules/project_config_scanner_test.rb`
   - `ace-git-worktree/test/fast/atoms/path_expander_test.rb`
2. **Validation Artifacts**:
   - Test execution logs confirming clean execution in both unprivileged and container root environments.

## Out of Scope / Negative Boundaries

- No modifications to production (`lib/`) code in any runtime packages.
- No changes to error taxonomy, configuration schemas, or cascade precedence.
- No modifications to `ace-support-core/test/fast/molecules/yaml_loader_test.rb` (structural blocker preserved) or `ace-support-fs/test/fast/molecules/directory_traverser_edge_test.rb`.
- No new gem dependencies or bundle changes.
