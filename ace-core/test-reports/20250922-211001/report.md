# Test Report

**Generated:** 2025-09-22 21:10:01
**Status:** ❌ Failed

## Summary

| Metric | Value |
|--------|-------|
| Total Tests | 143 |
| Passed | 125 |
| Failed | 17 |
| Errors | 1 |
| Skipped | 0 |
| Pass Rate | 87.41% |
| Duration | 0.20412s |

## Failures

### 1. test_mergeable_check

- **Type:** failure
- **Location:** `/Users/mc/Ps/ace-meta/ace-core/test/molecules/directory_traverser_test.rb:92`
- **Message:** Expected: 3
Actual: 11

### 2. test_build_cascade_priorities

- **Type:** failure
- **Location:** `/Users/mc/Ps/ace-meta/ace-core/test/molecules/project_root_finder_test.rb:60`
- **Message:** --- expected
+++ actual
@@ -1 +1 @@
-"/private/var/folders/hf/knhxwtnx76gcdps2hxb3bp2r0000gr/T/ace-test-20250922-6295-qn478/ruby_project"
+"/Users/mc/Ps/ace-meta"

### 3. test_find_or_current_returns_current_when_not_found

- **Type:** failure
- **Location:** `/Users/mc/Ps/ace-meta/ace-core/test/molecules/project_root_finder_test.rb:82`
- **Message:** --- expected
+++ actual
@@ -1 +1 @@
-"/private/var/folders/hf/knhxwtnx76gcdps2hxb3bp2r0000gr/T/ace-test-20250922-6295-vm4hjz/no_project"
+"/Users/mc/Ps/ace-meta"

### 4. test_returns_nil_when_no_markers_found

- **Type:** failure
- **Location:** `/Users/mc/Ps/ace-meta/ace-core/test/molecules/project_root_finder_test.rb:71`
- **Message:** Expected "/Users/mc/Ps/ace-meta" to be nil.

### 5. test_in_project_returns_true_when_found

- **Type:** failure
- **Location:** `/Users/mc/Ps/ace-meta/ace-core/test/molecules/project_root_finder_test.rb:189`
- **Message:** --- expected
+++ actual
@@ -1 +1 @@
-"/private/var/folders/hf/knhxwtnx76gcdps2hxb3bp2r0000gr/T/ace-test-20250922-6295-tgxw8n/outer/inner"
+"/Users/mc/Ps/ace-meta"

### 6. test_custom_markers

- **Type:** failure
- **Location:** `/Users/mc/Ps/ace-meta/ace-core/test/molecules/project_root_finder_test.rb:138`
- **Message:** --- expected
+++ actual
@@ -1 +1 @@
-"/private/var/folders/hf/knhxwtnx76gcdps2hxb3bp2r0000gr/T/ace-test-20250922-6295-xir5x1/custom_project"
+"/Users/mc/Ps/ace-meta"

### 7. test_in_project_returns_false_when_not_found

- **Type:** failure
- **Location:** `/Users/mc/Ps/ace-meta/ace-core/test/molecules/project_root_finder_test.rb:103`
- **Message:** Expected true to not be truthy.

### 8. test_relative_path_returns_nil_when_not_in_project

- **Type:** failure
- **Location:** `/Users/mc/Ps/ace-meta/ace-core/test/molecules/project_root_finder_test.rb:148`
- **Message:** --- expected
+++ actual
@@ -1 +1 @@
-"/private/var/folders/hf/knhxwtnx76gcdps2hxb3bp2r0000gr/T/ace-test-20250922-6295-lniupx/project"
+"/Users/mc/Ps/ace-meta"

### 9. test_start_path_option

- **Type:** failure
- **Location:** `/Users/mc/Ps/ace-meta/ace-core/test/molecules/project_root_finder_test.rb:170`
- **Message:** --- expected
+++ actual
@@ -1 +1 @@
-"/private/var/folders/hf/knhxwtnx76gcdps2hxb3bp2r0000gr/T/ace-test-20250922-6295-1r21hm/project"
+"/Users/mc/Ps/ace-meta"

### 10. test_relative_path_from_project_root

- **Type:** failure
- **Location:** `/Users/mc/Ps/ace-meta/ace-core/test/molecules/project_root_finder_test.rb:116`
- **Message:** Expected: "lib/nested/file.rb"
Actual: nil

### 11. test_class_method_find_or_current

- **Type:** failure
- **Location:** `/Users/mc/Ps/ace-meta/ace-core/test/molecules/project_root_finder_test.rb:157`
- **Message:** --- expected
+++ actual
@@ -1 +1 @@
-"/private/var/folders/hf/knhxwtnx76gcdps2hxb3bp2r0000gr/T/ace-test-20250922-6295-man93w/no_project"
+"/Users/mc/Ps/ace-meta"

### 12. test_finds_rakefile_root

- **Type:** failure
- **Location:** `/Users/mc/Ps/ace-meta/ace-core/test/molecules/project_root_finder_test.rb:47`
- **Message:** --- expected
+++ actual
@@ -1 +1 @@
-"/private/var/folders/hf/knhxwtnx76gcdps2hxb3bp2r0000gr/T/ace-test-20250922-6295-u1dj45/project"
+"/Users/mc/Ps/ace-meta"

### 13. test_caching

- **Type:** failure
- **Location:** `/Users/mc/Ps/ace-meta/ace-core/test/molecules/project_root_finder_test.rb:214`
- **Message:** Expected "/Users/mc/Ps/ace-meta" to be nil.

### 14. test_finds_git_root

- **Type:** failure
- **Location:** `/Users/mc/Ps/ace-meta/ace-core/test/molecules/project_root_finder_test.rb:34`
- **Message:** --- expected
+++ actual
@@ -1 +1 @@
-"/private/var/folders/hf/knhxwtnx76gcdps2hxb3bp2r0000gr/T/ace-test-20250922-6295-awh4he/project"
+"/Users/mc/Ps/ace-meta"

### 15. test_preserves_non_relative_paths

- **Type:** failure
- **Location:** `/Users/mc/Ps/ace-meta/ace-core/test/config_discovery_path_resolution_test.rb:112`
- **Message:** --- expected
+++ actual
@@ -1 +1 @@
-"/var/folders/hf/knhxwtnx76gcdps2hxb3bp2r0000gr/T/ace-test-20250922-6295-om50s8/project/relative"
+"/private/var/folders/hf/knhxwtnx76gcdps2hxb3bp2r0000gr/T/ace-test-20250922-6295-om50s8/project/.ace/relative"

### 16. test_resolves_paths_in_nested_ace_directory

- **Type:** failure
- **Location:** `/Users/mc/Ps/ace-meta/ace-core/test/config_discovery_path_resolution_test.rb:50`
- **Message:** --- expected
+++ actual
@@ -1 +1 @@
-"/var/folders/hf/knhxwtnx76gcdps2hxb3bp2r0000gr/T/ace-test-20250922-6295-t6e7cr/project/subdir1"
+"/private/var/folders/hf/knhxwtnx76gcdps2hxb3bp2r0000gr/T/ace-test-20250922-6295-t6e7cr/project/.ace/subdir1"

### 17. test_resolves_paths_in_arrays

- **Type:** failure
- **Location:** `/Users/mc/Ps/ace-meta/ace-core/test/config_discovery_path_resolution_test.rb:140`
- **Message:** --- expected
+++ actual
@@ -1 +1 @@
-"/var/folders/hf/knhxwtnx76gcdps2hxb3bp2r0000gr/T/ace-test-20250922-6295-5r2q3f/project/include1"
+"/private/var/folders/hf/knhxwtnx76gcdps2hxb3bp2r0000gr/T/ace-test-20250922-6295-5r2q3f/project/.ace/include1"

### 18. test_mergeable_check

- **Type:** error
- **Location:** ``
- **Message:** 

## Files Tested

- test/ace/core_test.rb
- test/atoms/command_executor_test.rb
- test/atoms/deep_merger_test.rb
- test/atoms/env_parser_test.rb
- test/atoms/file_reader_test.rb
- test/atoms/yaml_parser_test.rb
- test/config_discovery_path_resolution_test.rb
- test/integration/config_cascade_custom_paths_test.rb
- test/integration/config_cascade_test.rb
- test/integration/multi_source_test.rb
- test/molecules/directory_traverser_test.rb
- test/molecules/env_loader_test.rb
- test/molecules/project_root_finder_test.rb
- test/molecules/yaml_loader_test.rb
- test/organisms/config_resolver_test.rb
- test/organisms/environment_manager_test.rb
