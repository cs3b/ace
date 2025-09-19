# Reflection: PathResolver Test Random Failures Fix

**Date**: 2025-09-18
**Context**: Debugging and fixing randomly failing test_finds_project_root_when_not_provided test
**Author**: Development Team
**Type**: Problem-Solving

## What Went Well

- Systematic investigation approach identified multiple root causes quickly
- Test failure reports provided clear diagnostic information showing exact path mismatches
- Running the test in isolation helped confirm the fix worked consistently
- The codebase structure made it easy to understand test helpers and path resolution logic

## What Could Be Improved

- Initial assumption about test pollution was only partially correct - missed the symlink issue
- Could have checked for platform-specific issues (macOS symlinks) earlier
- Test suite could benefit from better isolation mechanisms for parallel execution

## Key Learnings

- **Parallel test execution can cause environment variable pollution**: Tests running in parallel can modify shared environment variables, causing race conditions
- **macOS has symlink quirks**: The `/var` directory is actually a symlink to `/private/var`, which can cause path comparison failures
- **File.realpath() is essential for path comparisons**: When comparing paths that might involve symlinks, always resolve them first
- **Test isolation is critical**: Tests should explicitly clear and restore environment state to avoid interference

## Technical Details

### Root Causes Identified

1. **Environment Variable Pollution**
   - The `PROJECT_ROOT_PATH` environment variable was being set by other tests
   - PathResolver's ProjectRootDetector checks this variable with highest priority
   - Tests running in parallel could contaminate the environment

2. **macOS Symlink Resolution**
   - Temporary directories created under `/var/folders/...`
   - macOS resolves this to `/private/var/folders/...`
   - Direct string comparison failed due to different path representations

### Solution Applied

```ruby
def test_finds_project_root_when_not_provided
  with_test_project("git-project", chdir: true) do |project_path|
    # Clear any existing project root environment variables to avoid test pollution
    # from parallel test execution
    original_root_path = ENV.delete("PROJECT_ROOT_PATH")
    original_root = ENV.delete("PROJECT_ROOT")

    begin
      # Don't pass project_root, let it find it
      resolver = AceTools::Atoms::PathResolver.new
      # Resolve symlinks on both sides for macOS /var -> /private/var compatibility
      assert_equal File.realpath(project_path), File.realpath(resolver.project_root)
    ensure
      # Restore original values if they existed
      ENV["PROJECT_ROOT_PATH"] = original_root_path if original_root_path
      ENV["PROJECT_ROOT"] = original_root if original_root
    end
  end
end
```

## Action Items

### Stop Doing

- Assuming path equality without considering symlink resolution
- Running tests that depend on environment variables without proper isolation

### Continue Doing

- Using detailed test failure reports that show actual vs expected values
- Running tests multiple times to verify fixes for random failures
- Investigating both test infrastructure and implementation code

### Start Doing

- Always use `File.realpath()` when comparing filesystem paths in tests
- Document platform-specific behaviors in test comments
- Consider adding a test helper for environment variable isolation

## Additional Context

- Test file: `test/unit/atoms/path_resolver_test.rb:115`
- Related classes: `AceTools::Atoms::PathResolver`, `AceTools::Atoms::ProjectRootDetector`
- This fix is part of the v.0.8.0 minitest migration effort