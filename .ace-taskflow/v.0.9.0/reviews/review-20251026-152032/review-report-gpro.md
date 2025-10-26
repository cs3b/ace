---
:provider: google
:model: gemini-2.5-pro
:finish_reason: STOP
:safety_ratings:
:input_tokens: 17454
:output_tokens: 18364
:total_tokens: 38882
---

# Standard Review Format

## Output Formatting Rules

• Use ✅ / ⚠️ / ❌ icons or colour words (🔴, 🟡, 🟢) for quick scanning.
• In "Detailed File-by-File" include: **Issue – Severity – Location – Suggestion – (optionally) code snippet**.
• In "Prioritised Action Items" group by severity:
  🔴 Critical (blocking) / 🟡 High / 🟢 Medium / 🔵 Nice-to-have.
• In "Approval Recommendation" present tick-box list:

    [ ] ✅ Approve as-is
    [ ] ✅ Approve with minor changes
    [ ] ⚠️ Request changes (non-blocking)
    [ ] ❌ Request changes (blocking)

Pick ONE status and briefly justify.


## Guidelines

# Review Tone Guidelines

## Communication Style

### Professional Tone
- Concise and direct feedback
- Focus on code, not the coder
- Use "we" instead of "you" when suggesting improvements
- Acknowledge good practices before critiquing

### Constructive Feedback
- Start with positives when possible
- Frame issues as opportunities for improvement
- Provide specific examples and alternatives
- Explain the reasoning behind suggestions

### Educational Approach
- Share knowledge without condescension
- Link to relevant documentation or resources
- Explain best practices and patterns
- Help the author learn and grow

# Icon Usage Guidelines

## Visual Indicators

### Status Icons
- ✅ **Success/Good**: Working correctly, best practice followed
- ⚠️ **Warning**: Potential issue, needs attention
- ❌ **Error/Blocking**: Must fix, prevents merge
- 💡 **Suggestion**: Improvement opportunity
- ❓ **Question**: Needs clarification
- 📝 **Note**: Important information
- 🎯 **Focus**: Key area for review

### Severity Colors
- 🔴 **Critical**: Blocking issues requiring immediate fix
- 🟡 **High**: Important issues that should be addressed
- 🟢 **Medium**: Improvements that would enhance quality
- 🔵 **Low**: Nice-to-have enhancements
- ⚪ **Info**: Neutral information or context


## Project Context

# Context

## Metadata


## Code to Review

# Context

## Metadata


## Git Diffs

### Diff: `origin/main...HEAD`

```diff
diff --git a/CHANGELOG.md b/CHANGELOG.md
index ba68fb2b..db8b933a 100644
--- a/CHANGELOG.md
+++ b/CHANGELOG.md
@@ -4,6 +4,16 @@ All notable changes to this project will be documented in this file.
 
 ## [Unreleased]
 
+## [0.9.99] - 2025-10-26
+
+### Added
+- **ace-core v0.10.0**: Unified path resolution system with instance-based PathExpander API
+  - Factory methods for automatic context inference (`for_file`, `for_cli`)
+  - Instance-based `resolve()` method supporting all path types
+  - Protocol URI support (wfi://, guide://, tmpl://, task://, prompt://) via plugin system
+  - 76 comprehensive tests ensuring backward compatibility and new functionality
+  - Updated documentation with usage examples and path resolution rules
+
 ## [0.9.98] - 2025-10-25
 
 ### Fixed
diff --git a/Gemfile.lock b/Gemfile.lock
index 394b079e..caf2d574 100644
--- a/Gemfile.lock
+++ b/Gemfile.lock
@@ -2,13 +2,13 @@ PATH
   remote: ace-context
   specs:
     ace-context (0.16.0)
-      ace-core (~> 0.9.0)
+      ace-core (~> 0.10.0)
       ace-git-diff (~> 0.1.0)
 
 PATH
   remote: ace-core
   specs:
-    ace-core (0.9.3)
+    ace-core (0.10.0)
 
 PATH
   remote: ace-docs
@@ -28,7 +28,7 @@ PATH
   remote: ace-git-commit
   specs:
     ace-git-commit (0.11.0)
-      ace-core (~> 0.9.0)
+      ace-core (~> 0.10.0)
       ace-git-diff (~> 0.1.0)
       ace-llm (~> 0.9.0)
 
@@ -59,7 +59,7 @@ PATH
   remote: ace-llm
   specs:
     ace-llm (0.9.4)
-      ace-core (~> 0.9.0)
+      ace-core (~> 0.10.0)
       addressable (~> 2.8)
       faraday (~> 2.0)
       kramdown (~> 2.0)
@@ -103,7 +103,7 @@ PATH
   remote: ace-taskflow
   specs:
     ace-taskflow (0.13.2)
-      ace-core (~> 0.9.0)
+      ace-core (~> 0.10.0)
       ace-support-mac-clipboard (~> 0.1.0)
       ace-support-markdown (~> 0.1)
       clipboard (~> 1.3)
diff --git a/ace-context/ace-context.gemspec b/ace-context/ace-context.gemspec
index 57564758..176b9e61 100644
--- a/ace-context/ace-context.gemspec
+++ b/ace-context/ace-context.gemspec
@@ -36,7 +36,7 @@ Gem::Specification.new do |spec|
   spec.require_paths = ['lib']
 
   # Runtime dependencies
-  spec.add_dependency 'ace-core', '~> 0.9.0'
+  spec.add_dependency 'ace-core', '~> 0.10.0'
   spec.add_dependency 'ace-git-diff', '~> 0.1.0'
 
   # Development dependencies managed in root Gemfile
diff --git a/ace-core/CHANGELOG.md b/ace-core/CHANGELOG.md
index f66dc8c9..e4050846 100644
--- a/ace-core/CHANGELOG.md
+++ b/ace-core/CHANGELOG.md
@@ -5,6 +5,25 @@ All notable changes to ace-core will be documented in this file.
 The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
 and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
 
+## [0.10.0] - 2025-10-26
+
+### Added
+
+- **Unified Path Resolution System**: PathExpander converted from module to class with instance-based API
+  - Factory methods: `PathExpander.for_file(source_file)` and `PathExpander.for_cli()` with automatic context inference
+  - Instance method: `resolve(path)` supporting source-relative, project-relative, absolute, env vars, and protocol URIs
+  - Protocol URI support via plugin system: `register_protocol_resolver(resolver)` for ace-nav integration
+  - Comprehensive test suite: 76 new tests covering all path resolution scenarios
+  - Full backward compatibility: All existing class methods (expand, join, dirname, basename, absolute?, relative, normalize) preserved
+  - Updated README with usage examples and documentation
+
+### Changed
+
+- **PathExpander Architecture**: Converted from module to class for context-aware path resolution
+  - Enables efficient resolution of multiple paths from single source with inferred context
+  - Provides consistent path handling across all ACE tools
+  - Supports wfi://, guide://, tmpl://, task://, prompt:// protocol URIs
+
 ## [0.9.3] - 2025-10-08
 
 ### Changed
diff --git a/ace-core/README.md b/ace-core/README.md
index 753c86ba..38efabce 100644
--- a/ace-core/README.md
+++ b/ace-core/README.md
@@ -78,6 +78,57 @@ config = resolver.resolve
 Ace::Core.create_default_config('./.ace/core/config.yml')
 ```
 
+### Path Resolution with PathExpander
+
+PathExpander provides unified path resolution across ACE tools with automatic context inference:
+
+```ruby
+require 'ace/core/atoms/path_expander'
+
+# For config files, workflows, templates, prompts
+config_file = ".ace/nav/config.yml"
+expander = Ace::Core::Atoms::PathExpander.for_file(config_file)
+
+# Resolve multiple paths - context inferred once!
+expander.resolve("./local/file.md")        # Source-relative (from config dir)
+expander.resolve("docs/architecture.md")   # Project-relative (from project root)
+expander.resolve("$HOME/.ace/custom.yml")  # Environment variable expansion
+expander.resolve("/absolute/path.md")      # Absolute paths
+
+# For CLI arguments
+expander = Ace::Core::Atoms::PathExpander.for_cli
+resolved = expander.resolve(ARGV[0])  # Uses current directory as context
+```
+
+**Protocol URI Support** (with ace-nav integration):
+
+```ruby
+# Register protocol resolver (e.g., ace-nav)
+Ace::Core::Atoms::PathExpander.register_protocol_resolver(resolver)
+
+# Now protocol URIs work automatically
+expander.resolve("wfi://workflow-name")    # Resolves via ace-nav
+expander.resolve("guide://testing")        # Workflow instructions
+expander.resolve("tmpl://task-draft")      # Templates
+```
+
+**Path Resolution Rules**:
+- Paths starting with `./` or `../`: Resolved relative to source document directory
+- Paths without prefix: Resolved relative to project root
+- Paths with `$VAR` or `${VAR}`: Environment variables expanded
+- Protocol URIs (`protocol://`): Delegated to registered resolver
+- Absolute paths: Used as-is
+
+**Backward Compatible Class Methods**:
+
+```ruby
+# Legacy stateless methods still work
+Ace::Core::Atoms::PathExpander.expand("~/docs")     # Expand tilde and env vars
+Ace::Core::Atoms::PathExpander.join("a", "b", "c")  # Join path components
+Ace::Core::Atoms::PathExpander.absolute?("/path")   # Check if absolute
+Ace::Core::Atoms::PathExpander.protocol?("wfi://")  # Check if protocol URI
+```
+
 ## Configuration Structure
 
 Configuration files are YAML with the following structure:
@@ -112,8 +163,8 @@ ace:
 
 This gem follows the ATOM (Atoms, Molecules, Organisms, Models) architecture:
 
-- **Atoms**: Pure functions with no side effects (`yaml_parser`, `env_parser`, `deep_merger`)
-- **Molecules**: Composed operations using Atoms (`yaml_loader`, `env_loader`, `config_finder`)
+- **Atoms**: Pure functions with no side effects (`yaml_parser`, `env_parser`, `deep_merger`, `path_expander`)
+- **Molecules**: Composed operations using Atoms (`yaml_loader`, `env_loader`, `config_finder`, `project_root_finder`)
 - **Organisms**: Business logic orchestration (`config_resolver`, `environment_manager`)
 - **Models**: Data structures with no behavior (`config`, `cascade_path`)
 
diff --git a/ace-core/lib/ace/core/atoms/path_expander.rb b/ace-core/lib/ace/core/atoms/path_expander.rb
index 0e520cdd..1bd15dd1 100644
--- a/ace-core/lib/ace/core/atoms/path_expander.rb
+++ b/ace-core/lib/ace/core/atoms/path_expander.rb
@@ -5,14 +5,125 @@ require 'pathname'
 module Ace
   module Core
     module Atoms
-      # Pure path expansion and manipulation functions
-      module PathExpander
-        module_function
+      # Path expansion and resolution with automatic context inference
+      #
+      # Supports:
+      # - Instance-based API for context-aware resolution
+      # - Protocol URIs (wfi://, guide://, tmpl://, task://, prompt://)
+      # - Source-relative paths (./, ../)
+      # - Project-relative paths (no prefix)
+      # - Environment variables ($VAR, ${VAR})
+      # - Backward compatible class methods for utilities
+      class PathExpander
+        # Protocol pattern for URI detection
+        PROTOCOL_PATTERN = %r{^[a-z][a-z0-9+.-]*://}.freeze
+
+        # Instance attributes
+        attr_reader :source_dir, :project_root
+
+        # Protocol resolver registry
+        @@protocol_resolver = nil
+
+        # === Factory Methods ===
+
+        # Create expander for a source file (config, workflow, template, prompt)
+        # Automatically infers source_dir and project_root
+        #
+        # @param source_file [String] Path to source file
+        # @return [PathExpander] Instance with inferred context
+        def self.for_file(source_file)
+          require_relative '../molecules/project_root_finder'
+
+          expanded_source = File.expand_path(source_file)
+          source_dir = File.dirname(expanded_source)
+          project_root = Molecules::ProjectRootFinder.new.find || Dir.pwd
+
+          new(source_dir: source_dir, project_root: project_root)
+        end
+
+        # Create expander for CLI context (no source file)
+        # Uses current directory as source_dir
+        #
+        # @return [PathExpander] Instance with CLI context
+        def self.for_cli
+          require_relative '../molecules/project_root_finder'
+
+          new(
+            source_dir: Dir.pwd,
+            project_root: Molecules::ProjectRootFinder.new.find || Dir.pwd
+          )
+        end
+
+        # === Instance Methods ===
+
+        # Initialize with explicit context
+        #
+        # @param source_dir [String] Source document directory (REQUIRED)
+        # @param project_root [String] Project root directory (REQUIRED)
+        # @raise [ArgumentError] if either parameter is nil
+        def initialize(source_dir:, project_root:)
+          if source_dir.nil? || project_root.nil?
+            raise ArgumentError, "PathExpander requires both 'source_dir' and 'project_root' (got source_dir: #{source_dir.inspect}, project_root: #{project_root.inspect})"
+          end
+
+          @source_dir = source_dir
+          @project_root = project_root
+        end
+
+        # Resolve path using instance context
+        # Handles: protocols, source-relative (./), project-relative, env vars, absolute
+        #
+        # @param path [String] Path to resolve
+        # @return [String, Hash] Resolved absolute path, or Hash with error for protocols
+        def resolve(path)
+          return nil if path.nil? || path.empty?
+
+          path_str = path.to_s
+
+          # Check for protocol URIs first
+          if self.class.protocol?(path_str)
+            return resolve_protocol(path_str)
+          end
+
+          # Expand environment variables
+          expanded = expand_env_vars(path_str)
+
+          # Handle absolute paths
+          return File.expand_path(expanded) if Pathname.new(expanded).absolute?
+
+          # Handle source-relative paths (./ or ../)
+          if expanded.start_with?('./') || expanded.start_with?('../')
+            return File.expand_path(expanded, @source_dir)
+          end
+
+          # Default: project-relative paths
+          File.expand_path(expanded, @project_root)
+        end
+
+        # === Class Methods (Utilities and Backward Compatibility) ===
+
+        # Check if path is a protocol URI
+        #
+        # @param path [String] Path to check
+        # @return [Boolean] true if protocol format detected
+        def self.protocol?(path)
+          return false if path.nil? || path.empty?
+          !!(path.to_s =~ PROTOCOL_PATTERN)
+        end
+
+        # Register a protocol resolver (e.g., ace-nav)
+        #
+        # @param resolver [Object] Resolver responding to #resolve(uri)
+        def self.register_protocol_resolver(resolver)
+          @@protocol_resolver = resolver
+        end
 
         # Expand path with tilde and environment variables
+        # Legacy stateless method for backward compatibility
+        #
         # @param path [String] Path to expand
         # @return [String] Expanded absolute path
-        def expand(path)
+        def self.expand(path)
           return nil if path.nil?
 
           expanded = path.to_s.dup
@@ -27,9 +138,10 @@ module Ace
         end
 
         # Join path components safely
+        #
         # @param parts [Array<String>] Path parts to join
         # @return [String] Joined path
-        def join(*parts)
+        def self.join(*parts)
           parts = parts.flatten.compact.map(&:to_s)
           return '' if parts.empty?
 
@@ -37,18 +149,20 @@ module Ace
         end
 
         # Get directory name from path
+        #
         # @param path [String] File path
         # @return [String] Directory path
-        def dirname(path)
+        def self.dirname(path)
           return nil if path.nil?
 
           File.dirname(path.to_s)
         end
 
         # Get base name from path
+        #
         # @param path [String] File path
         # @return [String] Base name
-        def basename(path, suffix = nil)
+        def self.basename(path, suffix = nil)
           return nil if path.nil?
 
           if suffix
@@ -59,19 +173,21 @@ module Ace
         end
 
         # Check if path is absolute
+        #
         # @param path [String] Path to check
         # @return [Boolean] true if absolute path
-        def absolute?(path)
+        def self.absolute?(path)
           return false if path.nil?
 
           Pathname.new(path.to_s).absolute?
         end
 
         # Make path relative to base
+        #
         # @param path [String] Path to make relative
         # @param base [String] Base path
         # @return [String] Relative path
-        def relative(path, base)
+        def self.relative(path, base)
           return nil if path.nil? || base.nil?
 
           path_obj = Pathname.new(expand(path))
@@ -84,13 +200,52 @@ module Ace
         end
 
         # Normalize path (remove .., ., duplicates slashes)
+        #
         # @param path [String] Path to normalize
         # @return [String] Normalized path
-        def normalize(path)
+        def self.normalize(path)
           return nil if path.nil?
 
           Pathname.new(path.to_s).cleanpath.to_s
         end
+
+        private
+
+        # Resolve protocol URI
+        def resolve_protocol(uri)
+          if @@protocol_resolver && @@protocol_resolver.respond_to?(:resolve)
+            result = @@protocol_resolver.resolve(uri)
+            # If resolver returns a Resource with path, extract it
+            return result.path if result.respond_to?(:path)
+            # Otherwise return the result as-is
+            return result
+          end
+
+          # No resolver registered - return error hash
+          {
+            error: "Protocol resolver not available",
+            uri: uri,
+            message: "Protocol '#{uri}' could not be resolved. Register a protocol resolver with PathExpander.register_protocol_resolver(resolver)"
+          }
+        end
+
+        # Expand environment variables in path
+        def expand_env_vars(path)
+          expanded = path.dup
+
+          # Handle ${VAR} format
+          expanded.gsub!(/\$\{([A-Z_][A-Z0-9_]*)\}/i) do |match|
+            var_name = match[2..-2]  # Remove ${ and }
+            ENV[var_name] || match
+          end
+
+          # Handle $VAR format
+          expanded.gsub!(/\$([A-Z_][A-Z0-9_]*)/i) do |match|
+            ENV[match[1..-1]] || match
+          end
+
+          expanded
+        end
       end
     end
   end
diff --git a/ace-core/lib/ace/core/version.rb b/ace-core/lib/ace/core/version.rb
index 5d349828..806414a4 100644
--- a/ace-core/lib/ace/core/version.rb
+++ b/ace-core/lib/ace/core/version.rb
@@ -2,6 +2,6 @@
 
 module Ace
   module Core
-    VERSION = "0.9.3"
+    VERSION = "0.10.0"
   end
 end
diff --git a/ace-core/test/atoms/path_expander_backward_compat_test.rb b/ace-core/test/atoms/path_expander_backward_compat_test.rb
new file mode 100644
index 00000000..7fc5722a
--- /dev/null
+++ b/ace-core/test/atoms/path_expander_backward_compat_test.rb
@@ -0,0 +1,260 @@
+# frozen_string_literal: true
+
+require "test_helper"
+require "ace/core/atoms/path_expander"
+
+class PathExpanderBackwardCompatTest < Minitest::Test
+  # This test suite ensures backward compatibility with the original module API
+  # All existing class methods should work exactly as before
+
+  def setup
+    @original_home = ENV['HOME']
+  end
+
+  def teardown
+    ENV['HOME'] = @original_home if @original_home
+  end
+
+  # === expand() method ===
+
+  def test_expand_expands_tilde
+    ENV['HOME'] = '/home/user'
+
+    result = Ace::Core::Atoms::PathExpander.expand("~/documents")
+
+    assert_equal "/home/user/documents", result
+  end
+
+  def test_expand_expands_environment_variables
+    ENV['TEST_VAR'] = '/test/path'
+
+    result = Ace::Core::Atoms::PathExpander.expand("$TEST_VAR/file.txt")
+
+    assert_equal "/test/path/file.txt", result
+  ensure
+    ENV.delete('TEST_VAR')
+  end
+
+  def test_expand_handles_nil
+    assert_nil Ace::Core::Atoms::PathExpander.expand(nil)
+  end
+
+  def test_expand_returns_absolute_path
+    result = Ace::Core::Atoms::PathExpander.expand("relative/path")
+
+    assert Pathname.new(result).absolute?
+  end
+
+  # === join() method ===
+
+  def test_join_combines_path_parts
+    result = Ace::Core::Atoms::PathExpander.join("path", "to", "file.txt")
+
+    assert_equal "path/to/file.txt", result
+  end
+
+  def test_join_handles_empty_array
+    result = Ace::Core::Atoms::PathExpander.join()
+
+    assert_equal '', result
+  end
+
+  def test_join_handles_nil_elements
+    result = Ace::Core::Atoms::PathExpander.join("path", nil, "file.txt")
+
+    assert_equal "path/file.txt", result
+  end
+
+  def test_join_handles_nested_arrays
+    result = Ace::Core::Atoms::PathExpander.join(["path", "to"], "file.txt")
+
+    assert_equal "path/to/file.txt", result
+  end
+
+  # === dirname() method ===
+
+  def test_dirname_returns_directory_path
+    result = Ace::Core::Atoms::PathExpander.dirname("/path/to/file.txt")
+
+    assert_equal "/path/to", result
+  end
+
+  def test_dirname_handles_nil
+    assert_nil Ace::Core::Atoms::PathExpander.dirname(nil)
+  end
+
+  def test_dirname_handles_root_path
+    result = Ace::Core::Atoms::PathExpander.dirname("/file.txt")
+
+    assert_equal "/", result
+  end
+
+  # === basename() method ===
+
+  def test_basename_returns_file_name
+    result = Ace::Core::Atoms::PathExpander.basename("/path/to/file.txt")
+
+    assert_equal "file.txt", result
+  end
+
+  def test_basename_handles_suffix
+    result = Ace::Core::Atoms::PathExpander.basename("/path/to/file.txt", ".txt")
+
+    assert_equal "file", result
+  end
+
+  def test_basename_handles_nil
+    assert_nil Ace::Core::Atoms::PathExpander.basename(nil)
+  end
+
+  def test_basename_without_extension
+    result = Ace::Core::Atoms::PathExpander.basename("/path/to/file")
+
+    assert_equal "file", result
+  end
+
+  # === absolute?() method ===
+
+  def test_absolute_detects_absolute_paths
+    assert Ace::Core::Atoms::PathExpander.absolute?("/absolute/path")
+    assert Ace::Core::Atoms::PathExpander.absolute?("/")
+  end
+
+  def test_absolute_detects_relative_paths
+    refute Ace::Core::Atoms::PathExpander.absolute?("relative/path")
+    refute Ace::Core::Atoms::PathExpander.absolute?("./path")
+    refute Ace::Core::Atoms::PathExpander.absolute?("../path")
+  end
+
+  def test_absolute_handles_nil
+    refute Ace::Core::Atoms::PathExpander.absolute?(nil)
+  end
+
+  # === relative() method ===
+
+  def test_relative_makes_path_relative_to_base
+    result = Ace::Core::Atoms::PathExpander.relative(
+      "/home/user/project/docs/file.md",
+      "/home/user/project"
+    )
+
+    assert_equal "docs/file.md", result
+  end
+
+  def test_relative_handles_same_path
+    result = Ace::Core::Atoms::PathExpander.relative(
+      "/home/user/project",
+      "/home/user/project"
+    )
+
+    assert_equal ".", result
+  end
+
+  def test_relative_handles_nil_path
+    assert_nil Ace::Core::Atoms::PathExpander.relative(nil, "/base")
+  end
+
+  def test_relative_handles_nil_base
+    assert_nil Ace::Core::Atoms::PathExpander.relative("/path", nil)
+  end
+
+  def test_relative_handles_different_drives_gracefully
+    # On systems with different drives, should return original path
+    # This is hard to test portably, but we can test the fallback behavior
+    path = "/path/to/file"
+    result = Ace::Core::Atoms::PathExpander.relative(path, "/other/base")
+
+    # Should return a valid result (either relative path or original)
+    assert result
+  end
+
+  # === normalize() method ===
+
+  def test_normalize_removes_dot_segments
+    result = Ace::Core::Atoms::PathExpander.normalize("/path/./to/./file.txt")
+
+    assert_equal "/path/to/file.txt", result
+  end
+
+  def test_normalize_removes_double_dot_segments
+    result = Ace::Core::Atoms::PathExpander.normalize("/path/to/../file.txt")
+
+    assert_equal "/path/file.txt", result
+  end
+
+  def test_normalize_removes_duplicate_slashes
+    result = Ace::Core::Atoms::PathExpander.normalize("/path//to///file.txt")
+
+    assert_equal "/path/to/file.txt", result
+  end
+
+  def test_normalize_handles_nil
+    assert_nil Ace::Core::Atoms::PathExpander.normalize(nil)
+  end
+
+  def test_normalize_handles_complex_paths
+    result = Ace::Core::Atoms::PathExpander.normalize("/path/./to/../other/./file.txt")
+
+    assert_equal "/path/other/file.txt", result
+  end
+
+  # === Integration: Methods work together ===
+
+  def test_expand_and_normalize_work_together
+    ENV['TEST_PATH'] = 'test/path'
+
+    expanded = Ace::Core::Atoms::PathExpander.expand("$TEST_PATH/./file.txt")
+    normalized = Ace::Core::Atoms::PathExpander.normalize(expanded)
+
+    assert normalized.end_with?("test/path/file.txt")
+    refute normalized.include?("./")
+  ensure
+    ENV.delete('TEST_PATH')
+  end
+
+  def test_join_and_dirname_work_together
+    joined = Ace::Core::Atoms::PathExpander.join("path", "to", "file.txt")
+    dir = Ace::Core::Atoms::PathExpander.dirname(joined)
+
+    assert_equal "path/to", dir
+  end
+
+  def test_join_and_basename_work_together
+    joined = Ace::Core::Atoms::PathExpander.join("path", "to", "file.txt")
+    base = Ace::Core::Atoms::PathExpander.basename(joined)
+
+    assert_equal "file.txt", base
+  end
+
+  # === Class method API unchanged ===
+
+  def test_class_methods_callable_without_instance
+    # All these should work without creating an instance
+    # (No exception should be raised)
+    Ace::Core::Atoms::PathExpander.expand("~/path")
+    Ace::Core::Atoms::PathExpander.join("a", "b")
+    Ace::Core::Atoms::PathExpander.dirname("/path/file")
+    Ace::Core::Atoms::PathExpander.basename("/path/file")
+    Ace::Core::Atoms::PathExpander.absolute?("/path")
+    Ace::Core::Atoms::PathExpander.relative("/a", "/b")
+    Ace::Core::Atoms::PathExpander.normalize("/path/./file")
+    Ace::Core::Atoms::PathExpander.protocol?("wfi://test")
+
+    # If we got here, all methods were callable
+    assert true
+  end
+
+  def test_old_module_usage_pattern_still_works
+    # Test that the old pattern of calling methods still works
+    expander = Ace::Core::Atoms::PathExpander
+
+    result = expander.expand("~/docs")
+    assert result.end_with?("/docs")
+
+    result = expander.join("a", "b", "c")
+    assert_equal "a/b/c", result
+
+    result = expander.absolute?("/absolute")
+    assert result
+  end
+end
diff --git a/ace-core/test/atoms/path_expander_protocol_test.rb b/ace-core/test/atoms/path_expander_protocol_test.rb
new file mode 100644
index 00000000..f2f545cf
--- /dev/null
+++ b/ace-core/test/atoms/path_expander_protocol_test.rb
@@ -0,0 +1,238 @@
+# frozen_string_literal: true
+
+require "test_helper"
+require "ace/core/atoms/path_expander"
+require "tmpdir"
+require "fileutils"
+
+class PathExpanderProtocolTest < Minitest::Test
+  def setup
+    @tmpdir = Dir.mktmpdir
+    @project_root = File.join(@tmpdir, "project")
+    @source_dir = File.join(@project_root, ".ace")
+
+    FileUtils.mkdir_p(@source_dir)
+    FileUtils.mkdir_p(File.join(@project_root, ".git"))
+
+    # Clear any registered protocol resolver
+    Ace::Core::Atoms::PathExpander.register_protocol_resolver(nil)
+  end
+
+  def teardown
+    FileUtils.rm_rf(@tmpdir) if @tmpdir && File.exist?(@tmpdir)
+    Ace::Core::Atoms::PathExpander.register_protocol_resolver(nil)
+  end
+
+  # === Protocol Detection Tests ===
+
+  def test_protocol_detects_standard_protocols
+    assert Ace::Core::Atoms::PathExpander.protocol?("wfi://setup")
+    assert Ace::Core::Atoms::PathExpander.protocol?("guide://testing")
+    assert Ace::Core::Atoms::PathExpander.protocol?("tmpl://task-draft")
+    assert Ace::Core::Atoms::PathExpander.protocol?("task://083")
+    assert Ace::Core::Atoms::PathExpander.protocol?("prompt://context")
+  end
+
+  def test_protocol_detects_http_protocols
+    assert Ace::Core::Atoms::PathExpander.protocol?("http://example.com")
+    assert Ace::Core::Atoms::PathExpander.protocol?("https://example.com")
+    assert Ace::Core::Atoms::PathExpander.protocol?("ftp://server.com")
+  end
+
+  def test_protocol_detects_complex_protocol_names
+    assert Ace::Core::Atoms::PathExpander.protocol?("custom-proto://resource")
+    assert Ace::Core::Atoms::PathExpander.protocol?("proto+ext://resource")
+    assert Ace::Core::Atoms::PathExpander.protocol?("proto.v2://resource")
+  end
+
+  def test_protocol_rejects_non_protocols
+    refute Ace::Core::Atoms::PathExpander.protocol?("./relative/path")
+    refute Ace::Core::Atoms::PathExpander.protocol?("../parent/path")
+    refute Ace::Core::Atoms::PathExpander.protocol?("docs/file.md")
+    refute Ace::Core::Atoms::PathExpander.protocol?("/absolute/path")
+    refute Ace::Core::Atoms::PathExpander.protocol?("$HOME/path")
+  end
+
+  def test_protocol_handles_edge_cases
+    refute Ace::Core::Atoms::PathExpander.protocol?(nil)
+    refute Ace::Core::Atoms::PathExpander.protocol?("")
+    refute Ace::Core::Atoms::PathExpander.protocol?("   ")
+    refute Ace::Core::Atoms::PathExpander.protocol?("no-colon-slash")
+    refute Ace::Core::Atoms::PathExpander.protocol?("://no-protocol")
+  end
+
+  def test_protocol_case_sensitive
+    assert Ace::Core::Atoms::PathExpander.protocol?("wfi://test")
+    refute Ace::Core::Atoms::PathExpander.protocol?("WFI://test")
+    refute Ace::Core::Atoms::PathExpander.protocol?("Wfi://test")
+  end
+
+  # === Protocol Resolver Registration Tests ===
+
+  def test_register_protocol_resolver
+    resolver = Object.new
+
+    Ace::Core::Atoms::PathExpander.register_protocol_resolver(resolver)
+
+    # We can't directly test the class variable, but we can test behavior
+    # This is verified in resolve tests below
+    assert true  # If we get here, registration didn't error
+  end
+
+  def test_register_nil_resolver_clears_registration
+    resolver = Object.new
+    Ace::Core::Atoms::PathExpander.register_protocol_resolver(resolver)
+
+    # Clear it
+    Ace::Core::Atoms::PathExpander.register_protocol_resolver(nil)
+
+    # Verify by testing resolve behavior (should return error hash)
+    expander = Ace::Core::Atoms::PathExpander.new(
+      source_dir: @source_dir,
+      project_root: @project_root
+    )
+
+    result = expander.resolve("wfi://test")
+    assert_kind_of Hash, result
+    assert result.key?(:error)
+  end
+
+  # === Protocol Resolution Tests ===
+
+  def test_resolve_returns_error_hash_when_no_resolver_registered
+    expander = Ace::Core::Atoms::PathExpander.new(
+      source_dir: @source_dir,
+      project_root: @project_root
+    )
+
+    result = expander.resolve("wfi://workflow")
+
+    assert_kind_of Hash, result
+    assert_equal "Protocol resolver not available", result[:error]
+    assert_equal "wfi://workflow", result[:uri]
+    assert_match(/Protocol 'wfi:\/\/workflow' could not be resolved/, result[:message])
+    assert_match(/PathExpander.register_protocol_resolver/, result[:message])
+  end
+
+  def test_resolve_delegates_to_registered_resolver
+    # Create a mock resolver
+    resolved_path = "/resolved/path/to/workflow.wf.md"
+    mock_resource = Struct.new(:path).new(resolved_path)
+    resolver = Minitest::Mock.new
+    resolver.expect(:resolve, mock_resource, ["wfi://workflow"])
+
+    Ace::Core::Atoms::PathExpander.register_protocol_resolver(resolver)
+
+    expander = Ace::Core::Atoms::PathExpander.new(
+      source_dir: @source_dir,
+      project_root: @project_root
+    )
+
+    result = expander.resolve("wfi://workflow")
+
+    assert_equal resolved_path, result
+    resolver.verify
+  end
+
+  def test_resolve_handles_resolver_returning_plain_string
+    # Some resolvers might return plain strings
+    resolved_path = "/resolved/path.md"
+    resolver = Minitest::Mock.new
+    resolver.expect(:resolve, resolved_path, ["guide://testing"])
+
+    Ace::Core::Atoms::PathExpander.register_protocol_resolver(resolver)
+
+    expander = Ace::Core::Atoms::PathExpander.new(
+      source_dir: @source_dir,
+      project_root: @project_root
+    )
+
+    result = expander.resolve("guide://testing")
+
+    assert_equal resolved_path, result
+    resolver.verify
+  end
+
+  def test_resolve_handles_resolver_returning_nil
+    # Resolver might return nil if resource not found
+    resolver = Minitest::Mock.new
+    resolver.expect(:resolve, nil, ["wfi://missing"])
+
+    Ace::Core::Atoms::PathExpander.register_protocol_resolver(resolver)
+
+    expander = Ace::Core::Atoms::PathExpander.new(
+      source_dir: @source_dir,
+      project_root: @project_root
+    )
+
+    result = expander.resolve("wfi://missing")
+
+    assert_nil result
+    resolver.verify
+  end
+
+  def test_resolve_skips_resolver_if_not_respond_to_resolve
+    # Register something that doesn't respond to :resolve
+    invalid_resolver = Object.new
+
+    Ace::Core::Atoms::PathExpander.register_protocol_resolver(invalid_resolver)
+
+    expander = Ace::Core::Atoms::PathExpander.new(
+      source_dir: @source_dir,
+      project_root: @project_root
+    )
+
+    result = expander.resolve("wfi://test")
+
+    # Should return error hash since resolver doesn't respond to :resolve
+    assert_kind_of Hash, result
+    assert_equal "Protocol resolver not available", result[:error]
+  end
+
+  # === Mixed Resolution Tests ===
+
+  def test_resolve_regular_paths_unaffected_by_resolver_registration
+    # Register a resolver
+    mock_resource = Struct.new(:path).new("/resolved/protocol.md")
+    resolver = Minitest::Mock.new
+    resolver.expect(:resolve, mock_resource, ["wfi://test"])
+
+    Ace::Core::Atoms::PathExpander.register_protocol_resolver(resolver)
+
+    expander = Ace::Core::Atoms::PathExpander.new(
+      source_dir: @source_dir,
+      project_root: @project_root
+    )
+
+    # Regular paths should still work normally
+    assert_equal File.join(@source_dir, "local.yml"), expander.resolve("./local.yml")
+    assert_equal File.join(@project_root, "docs/file.md"), expander.resolve("docs/file.md")
+    assert_equal "/absolute/path", expander.resolve("/absolute/path")
+
+    # Protocol should use resolver
+    result = expander.resolve("wfi://test")
+    assert_equal "/resolved/protocol.md", result
+
+    resolver.verify
+  end
+
+  def test_protocol_resolution_prioritized_over_regular_paths
+    # Even if there's a file literally named "wfi://something",
+    # it should be treated as protocol first
+    resolver = Minitest::Mock.new
+    resolver.expect(:resolve, "/protocol/result.md", ["wfi://file"])
+
+    Ace::Core::Atoms::PathExpander.register_protocol_resolver(resolver)
+
+    expander = Ace::Core::Atoms::PathExpander.new(
+      source_dir: @source_dir,
+      project_root: @project_root
+    )
+
+    result = expander.resolve("wfi://file")
+
+    # Should use protocol resolver, not treat as filename
+    assert_equal "/protocol/result.md", result
+    resolver.verify
+  end
+end
diff --git a/ace-core/test/atoms/path_expander_test.rb b/ace-core/test/atoms/path_expander_test.rb
new file mode 100644
index 00000000..aebfca33
--- /dev/null
+++ b/ace-core/test/atoms/path_expander_test.rb
@@ -0,0 +1,309 @@
+# frozen_string_literal: true
+
+require "test_helper"
+require "ace/core/atoms/path_expander"
+require "tmpdir"
+require "fileutils"
+
+class PathExpanderTest < Minitest::Test
+  def setup
+    @tmpdir = Dir.mktmpdir
+    @project_root = File.join(@tmpdir, "project")
+    @config_dir = File.join(@project_root, ".ace", "config")
+    @docs_dir = File.join(@project_root, "docs")
+
+    # Create directory structure
+    FileUtils.mkdir_p(@config_dir)
+    FileUtils.mkdir_p(@docs_dir)
+
+    # Create a .git marker for project root detection
+    FileUtils.mkdir_p(File.join(@project_root, ".git"))
+
+    # Create some test files
+    @config_file = File.join(@config_dir, "test.yml")
+    @doc_file = File.join(@docs_dir, "readme.md")
+    FileUtils.touch(@config_file)
+    FileUtils.touch(@doc_file)
+
+    # Store original directory and environment
+    @original_dir = Dir.pwd
+    @original_project_root = ENV['PROJECT_ROOT_PATH']
+
+    # Set test project root for ProjectRootFinder
+    ENV['PROJECT_ROOT_PATH'] = @project_root
+  end
+
+  def teardown
+    Dir.chdir(@original_dir) if @original_dir
+    FileUtils.rm_rf(@tmpdir) if @tmpdir && File.exist?(@tmpdir)
+
+    # Restore environment
+    if @original_project_root
+      ENV['PROJECT_ROOT_PATH'] = @original_project_root
+    else
+      ENV.delete('PROJECT_ROOT_PATH')
+    end
+  end
+
+  # === Factory Method Tests ===
+
+  def test_for_file_creates_instance_with_inferred_context
+    Dir.chdir(@project_root) do
+      expander = Ace::Core::Atoms::PathExpander.for_file(@config_file)
+
+      assert_instance_of Ace::Core::Atoms::PathExpander, expander
+      assert_equal @config_dir, expander.source_dir
+      # Project root should be the test tmp directory (has .git marker)
+      assert_equal File.realpath(@project_root), File.realpath(expander.project_root)
+    end
+  end
+
+  def test_for_file_handles_relative_source_file
+    Dir.chdir(@project_root) do
+      relative_path = ".ace/config/test.yml"
+      expander = Ace::Core::Atoms::PathExpander.for_file(relative_path)
+
+      assert_equal File.realpath(@config_dir), File.realpath(expander.source_dir)
+      assert_equal File.realpath(@project_root), File.realpath(expander.project_root)
+    end
+  end
+
+  def test_for_cli_uses_current_directory_as_source_dir
+    Dir.chdir(@docs_dir) do
+      expander = Ace::Core::Atoms::PathExpander.for_cli
+
+      assert_instance_of Ace::Core::Atoms::PathExpander, expander
+      assert_equal File.realpath(@docs_dir), File.realpath(expander.source_dir)
+      assert_equal File.realpath(@project_root), File.realpath(expander.project_root)
+    end
+  end
+
+  # === Context Validation Tests ===
+
+  def test_initialize_raises_error_when_source_dir_nil
+    error = assert_raises(ArgumentError) do
+      Ace::Core::Atoms::PathExpander.new(source_dir: nil, project_root: "/project")
+    end
+
+    assert_match(/requires both 'source_dir' and 'project_root'/, error.message)
+    assert_match(/source_dir: nil/, error.message)
+  end
+
+  def test_initialize_raises_error_when_project_root_nil
+    error = assert_raises(ArgumentError) do
+      Ace::Core::Atoms::PathExpander.new(source_dir: "/source", project_root: nil)
+    end
+
+    assert_match(/requires both 'source_dir' and 'project_root'/, error.message)
+    assert_match(/project_root: nil/, error.message)
+  end
+
+  def test_initialize_raises_error_when_both_nil
+    error = assert_raises(ArgumentError) do
+      Ace::Core::Atoms::PathExpander.new(source_dir: nil, project_root: nil)
+    end
+
+    assert_match(/requires both 'source_dir' and 'project_root'/, error.message)
+  end
+
+  def test_initialize_succeeds_with_valid_parameters
+    expander = Ace::Core::Atoms::PathExpander.new(
+      source_dir: @config_dir,
+      project_root: @project_root
+    )
+
+    assert_equal @config_dir, expander.source_dir
+    assert_equal @project_root, expander.project_root
+  end
+
+  # === Resolution Tests: Source-Relative Paths ===
+
+  def test_resolve_source_relative_path_with_dot_slash
+    expander = Ace::Core::Atoms::PathExpander.new(
+      source_dir: @config_dir,
+      project_root: @project_root
+    )
+
+    result = expander.resolve("./local.yml")
+    expected = File.join(@config_dir, "local.yml")
+
+    assert_equal expected, result
+  end
+
+  def test_resolve_source_relative_path_with_parent
+    expander = Ace::Core::Atoms::PathExpander.new(
+      source_dir: @config_dir,
+      project_root: @project_root
+    )
+
+    result = expander.resolve("../other/file.md")
+    expected = File.expand_path("../other/file.md", @config_dir)
+
+    assert_equal expected, result
+  end
+
+  # === Resolution Tests: Project-Relative Paths ===
+
+  def test_resolve_project_relative_path
+    expander = Ace::Core::Atoms::PathExpander.new(
+      source_dir: @config_dir,
+      project_root: @project_root
+    )
+
+    result = expander.resolve("docs/readme.md")
+    expected = File.join(@project_root, "docs/readme.md")
+
+    assert_equal expected, result
+  end
+
+  def test_resolve_project_relative_path_with_subdirs
+    expander = Ace::Core::Atoms::PathExpander.new(
+      source_dir: @config_dir,
+      project_root: @project_root
+    )
+
+    result = expander.resolve("ace-core/lib/ace/core.rb")
+    expected = File.join(@project_root, "ace-core/lib/ace/core.rb")
+
+    assert_equal expected, result
+  end
+
+  # === Resolution Tests: Absolute Paths ===
+
+  def test_resolve_absolute_path
+    expander = Ace::Core::Atoms::PathExpander.new(
+      source_dir: @config_dir,
+      project_root: @project_root
+    )
+
+    absolute = "/opt/custom/path.txt"
+    result = expander.resolve(absolute)
+
+    assert_equal absolute, result
+  end
+
+  # === Resolution Tests: Environment Variables ===
+
+  def test_resolve_expands_env_var_dollar_format
+    ENV['TEST_VAR'] = '/test/path'
+
+    expander = Ace::Core::Atoms::PathExpander.new(
+      source_dir: @config_dir,
+      project_root: @project_root
+    )
+
+    result = expander.resolve("$TEST_VAR/file.txt")
+    expected = "/test/path/file.txt"
+
+    assert_equal expected, result
+  ensure
+    ENV.delete('TEST_VAR')
+  end
+
+  def test_resolve_expands_env_var_brace_format
+    ENV['TEST_VAR'] = '/test/path'
+
+    expander = Ace::Core::Atoms::PathExpander.new(
+      source_dir: @config_dir,
+      project_root: @project_root
+    )
+
+    result = expander.resolve("${TEST_VAR}/file.txt")
+    expected = "/test/path/file.txt"
+
+    assert_equal expected, result
+  ensure
+    ENV.delete('TEST_VAR')
+  end
+
+  def test_resolve_keeps_undefined_env_var
+    expander = Ace::Core::Atoms::PathExpander.new(
+      source_dir: @config_dir,
+      project_root: @project_root
+    )
+
+    # Undefined variable should be left as-is and treated as project-relative
+    result = expander.resolve("$UNDEFINED_VAR/file.txt")
+
+    # Should be expanded from project root since $UNDEFINED_VAR stays literal
+    assert result.include?(@project_root)
+    assert result.include?("$UNDEFINED_VAR/file.txt")
+  end
+
+  # === Resolution Tests: Edge Cases ===
+
+  def test_resolve_returns_nil_for_nil_path
+    expander = Ace::Core::Atoms::PathExpander.new(
+      source_dir: @config_dir,
+      project_root: @project_root
+    )
+
+    assert_nil expander.resolve(nil)
+  end
+
+  def test_resolve_returns_nil_for_empty_path
+    expander = Ace::Core::Atoms::PathExpander.new(
+      source_dir: @config_dir,
+      project_root: @project_root
+    )
+
+    assert_nil expander.resolve("")
+  end
+
+  def test_resolve_handles_whitespace_in_path
+    expander = Ace::Core::Atoms::PathExpander.new(
+      source_dir: @config_dir,
+      project_root: @project_root
+    )
+
+    result = expander.resolve("docs/file with spaces.md")
+    expected = File.join(@project_root, "docs/file with spaces.md")
+
+    assert_equal expected, result
+  end
+
+  # === Multiple Resolutions with Same Instance ===
+
+  def test_resolve_multiple_paths_with_same_instance
+    expander = Ace::Core::Atoms::PathExpander.new(
+      source_dir: @config_dir,
+      project_root: @project_root
+    )
+
+    # Source-relative
+    result1 = expander.resolve("./local.yml")
+    assert result1.start_with?(@config_dir)
+
+    # Project-relative
+    result2 = expander.resolve("docs/readme.md")
+    assert result2.start_with?(@project_root)
+
+    # Absolute
+    result3 = expander.resolve("/absolute/path")
+    assert_equal "/absolute/path", result3
+
+    # All should be resolved correctly
+    assert_equal File.join(@config_dir, "local.yml"), result1
+    assert_equal File.join(@project_root, "docs/readme.md"), result2
+  end
+
+  # === Attribute Readers ===
+
+  def test_source_dir_reader
+    expander = Ace::Core::Atoms::PathExpander.new(
+      source_dir: @config_dir,
+      project_root: @project_root
+    )
+
+    assert_equal @config_dir, expander.source_dir
+  end
+
+  def test_project_root_reader
+    expander = Ace::Core::Atoms::PathExpander.new(
+      source_dir: @config_dir,
+      project_root: @project_root
+    )
+
+    assert_equal @project_root, expander.project_root
+  end
+end
diff --git a/ace-core/test/integration/path_expander_nav_integration_test.rb b/ace-core/test/integration/path_expander_nav_integration_test.rb
new file mode 100644
index 00000000..41ddea50
--- /dev/null
+++ b/ace-core/test/integration/path_expander_nav_integration_test.rb
@@ -0,0 +1,205 @@
+# frozen_string_literal: true
+
+require "test_helper"
+require "ace/core/atoms/path_expander"
+require "tmpdir"
+require "fileutils"
+
+class PathExpanderNavIntegrationTest < Minitest::Test
+  def setup
+    @tmpdir = Dir.mktmpdir
+    @project_root = File.join(@tmpdir, "project")
+    @source_dir = File.join(@project_root, ".ace")
+    @workflows_dir = File.join(@project_root, "handbook", "workflow-instructions")
+
+    FileUtils.mkdir_p(@source_dir)
+    FileUtils.mkdir_p(@workflows_dir)
+    FileUtils.mkdir_p(File.join(@project_root, ".git"))
+
+    # Create a test workflow file
+    @workflow_file = File.join(@workflows_dir, "test-workflow.wf.md")
+    File.write(@workflow_file, "# Test Workflow\nContent here")
+
+    # Clear any registered protocol resolver
+    Ace::Core::Atoms::PathExpander.register_protocol_resolver(nil)
+  end
+
+  def teardown
+    FileUtils.rm_rf(@tmpdir) if @tmpdir && File.exist?(@tmpdir)
+    Ace::Core::Atoms::PathExpander.register_protocol_resolver(nil)
+  end
+
+  # === Integration Tests ===
+
+  def test_integration_with_ace_nav_resolver
+    # Skip if ace-nav is not available
+    begin
+      require 'ace/nav'
+    rescue LoadError
+      skip "ace-nav not available for integration test"
+    end
+
+    # Create a simple mock that simulates ace-nav behavior
+    mock_resolver = create_mock_nav_resolver
+
+    Ace::Core::Atoms::PathExpander.register_protocol_resolver(mock_resolver)
+
+    expander = Ace::Core::Atoms::PathExpander.new(
+      source_dir: @source_dir,
+      project_root: @project_root
+    )
+
+    result = expander.resolve("wfi://test-workflow")
+
+    assert_equal @workflow_file, result
+  end
+
+  def test_integration_mixed_path_types_with_resolver
+    mock_resolver = create_mock_nav_resolver
+
+    Ace::Core::Atoms::PathExpander.register_protocol_resolver(mock_resolver)
+
+    expander = Ace::Core::Atoms::PathExpander.new(
+      source_dir: @source_dir,
+      project_root: @project_root
+    )
+
+    # Protocol resolution
+    protocol_result = expander.resolve("wfi://test-workflow")
+    assert_equal @workflow_file, protocol_result
+
+    # Source-relative still works
+    source_result = expander.resolve("./config.yml")
+    assert_equal File.join(@source_dir, "config.yml"), source_result
+
+    # Project-relative still works
+    project_result = expander.resolve("docs/readme.md")
+    assert_equal File.join(@project_root, "docs/readme.md"), project_result
+  end
+
+  def test_integration_resolver_returns_nil_for_missing_resource
+    mock_resolver = Minitest::Mock.new
+    mock_resolver.expect(:resolve, nil, ["wfi://missing"])
+
+    Ace::Core::Atoms::PathExpander.register_protocol_resolver(mock_resolver)
+
+    expander = Ace::Core::Atoms::PathExpander.new(
+      source_dir: @source_dir,
+      project_root: @project_root
+    )
+
+    result = expander.resolve("wfi://missing")
+
+    assert_nil result
+    mock_resolver.verify
+  end
+
+  def test_integration_resolver_registration_affects_all_instances
+    # Create a mock that expects two calls
+    mock_resource = Struct.new(:path).new(@workflow_file)
+    mock_resolver = Minitest::Mock.new
+    mock_resolver.expect(:resolve, mock_resource, ["wfi://test-workflow"])
+    mock_resolver.expect(:resolve, mock_resource, ["wfi://test-workflow"])
+
+    Ace::Core::Atoms::PathExpander.register_protocol_resolver(mock_resolver)
+
+    # Create multiple instances
+    expander1 = Ace::Core::Atoms::PathExpander.new(
+      source_dir: @source_dir,
+      project_root: @project_root
+    )
+
+    expander2 = Ace::Core::Atoms::PathExpander.new(
+      source_dir: @workflows_dir,
+      project_root: @project_root
+    )
+
+    # Both should use the registered resolver
+    result1 = expander1.resolve("wfi://test-workflow")
+    result2 = expander2.resolve("wfi://test-workflow")
+
+    assert_equal @workflow_file, result1
+    assert_equal @workflow_file, result2
+
+    mock_resolver.verify
+  end
+
+  def test_integration_unregister_resolver_stops_protocol_resolution
+    mock_resolver = create_mock_nav_resolver
+
+    # Register resolver
+    Ace::Core::Atoms::PathExpander.register_protocol_resolver(mock_resolver)
+
+    expander = Ace::Core::Atoms::PathExpander.new(
+      source_dir: @source_dir,
+      project_root: @project_root
+    )
+
+    # Should work with resolver
+    result = expander.resolve("wfi://test-workflow")
+    assert_equal @workflow_file, result
+
+    # Unregister resolver
+    Ace::Core::Atoms::PathExpander.register_protocol_resolver(nil)
+
+    # Should return error hash now
+    result = expander.resolve("wfi://test-workflow")
+    assert_kind_of Hash, result
+    assert_equal "Protocol resolver not available", result[:error]
+  end
+
+  def test_integration_realistic_config_file_scenario
+    # Simulate a real config file scenario
+    config_file = File.join(@source_dir, "nav", "config.yml")
+    FileUtils.mkdir_p(File.dirname(config_file))
+    File.write(config_file, <<~YAML)
+      sources:
+        - path: wfi://test-workflow
+        - path: ./local/workflows
+        - path: handbook/shared
+    YAML
+
+    mock_resolver = create_mock_nav_resolver
+    Ace::Core::Atoms::PathExpander.register_protocol_resolver(mock_resolver)
+
+    # Create expander for this config file
+    expander = Ace::Core::Atoms::PathExpander.for_file(config_file)
+
+    # Resolve the three different path types
+    result1 = expander.resolve("wfi://test-workflow")
+    result2 = expander.resolve("./local/workflows")
+    result3 = expander.resolve("handbook/shared")
+
+    # Protocol should resolve via ace-nav
+    assert_equal @workflow_file, result1
+
+    # Source-relative should resolve from config file directory
+    assert result2.end_with?(".ace/nav/local/workflows"), "Expected #{result2} to end with .ace/nav/local/workflows"
+
+    # Project-relative should resolve from project root
+    assert result3.end_with?("handbook/shared"), "Expected #{result3} to end with handbook/shared"
+  end
+
+  def test_integration_factory_method_with_protocol_resolution
+    mock_resolver = create_mock_nav_resolver
+    Ace::Core::Atoms::PathExpander.register_protocol_resolver(mock_resolver)
+
+    # Use factory method
+    Dir.chdir(@project_root) do
+      expander = Ace::Core::Atoms::PathExpander.for_cli
+
+      result = expander.resolve("wfi://test-workflow")
+      assert_equal @workflow_file, result
+    end
+  end
+
+  private
+
+  # Create a simple mock that simulates ace-nav ResourceResolver behavior
+  def create_mock_nav_resolver
+    mock_resource = Struct.new(:path).new(@workflow_file)
+    resolver = Minitest::Mock.new
+    resolver.expect(:resolve, mock_resource, ["wfi://test-workflow"])
+    resolver
+  end
+end
diff --git a/ace-git-commit/ace-git-commit.gemspec b/ace-git-commit/ace-git-commit.gemspec
index c73242f0..599ebf27 100644
--- a/ace-git-commit/ace-git-commit.gemspec
+++ b/ace-git-commit/ace-git-commit.gemspec
@@ -29,7 +29,7 @@ Gem::Specification.new do |spec|
   spec.require_paths = ['lib']
 
   # Runtime dependencies
-  spec.add_dependency 'ace-core', '~> 0.9.0'
+  spec.add_dependency 'ace-core', '~> 0.10.0'
   spec.add_dependency 'ace-git-diff', '~> 0.1.0'
   spec.add_dependency 'ace-llm', '~> 0.9.0'
 
diff --git a/ace-llm/ace-llm.gemspec b/ace-llm/ace-llm.gemspec
index 72503d73..57c05878 100644
--- a/ace-llm/ace-llm.gemspec
+++ b/ace-llm/ace-llm.gemspec
@@ -31,7 +31,7 @@ Gem::Specification.new do |spec|
   spec.require_paths = ["lib"]
 
   # Runtime dependencies
-  spec.add_dependency "ace-core", "~> 0.9.0"
+  spec.add_dependency "ace-core", "~> 0.10.0"
   spec.add_dependency "faraday", "~> 2.0"
   spec.add_dependency "addressable", "~> 2.8"
   spec.add_dependency "kramdown", "~> 2.0"
diff --git a/ace-taskflow/ace-taskflow.gemspec b/ace-taskflow/ace-taskflow.gemspec
index ae218dd8..a662abd8 100644
--- a/ace-taskflow/ace-taskflow.gemspec
+++ b/ace-taskflow/ace-taskflow.gemspec
@@ -31,7 +31,7 @@ Gem::Specification.new do |spec|
   spec.require_paths = ["lib"]
 
   # Runtime dependencies
-  spec.add_dependency "ace-core", "~> 0.9.0"
+  spec.add_dependency "ace-core", "~> 0.10.0"
   spec.add_dependency "clipboard", "~> 1.3"
   spec.add_dependency "ace-support-mac-clipboard", "~> 0.1.0"
   spec.add_dependency "ace-support-markdown", "~> 0.1"

```


## Review Request

Please review the provided code according to the guidelines and format specified above.

Provide actionable feedback with specific suggestions for improvement. Reference line numbers or file locations where applicable.
# Standard Review Format

## High-Level Summary

This is an excellent and well-executed refactoring of the `PathExpander`. The transition from a stateless module to a context-aware class provides a much cleaner and more powerful API for path resolution. The change is supported by an outstanding test suite that covers the new functionality, backward compatibility, and integration points. The documentation updates are clear and comprehensive.

The core logic is sound, and the new features like protocol resolution are implemented robustly. The few suggestions below are minor points related to code style and potential future optimizations.

## Strengths & Noteworthy

✅ **Excellent API Design**: The new instance-based API with `for_file` and `for_cli` factory methods is intuitive and effectively solves the problem of context-aware path resolution.

✅ **Exceptional Test Coverage**: The addition of four new test files (`path_expander_test`, `path_expander_protocol_test`, `path_expander_backward_compat_test`, `path_expander_nav_integration_test`) demonstrates a commitment to quality. The coverage is comprehensive and inspires confidence in the change.

✅ **Backward Compatibility**: Great care was taken to preserve the old module-based API by converting the methods to class methods. The dedicated backward compatibility test suite is a model for this type of refactoring.

✅ **Robust Protocol Handling**: The protocol resolver is implemented as a flexible plugin system, and the fallback behavior (returning an informative error hash) is well-designed for debugging.

✅ **Clear Documentation**: The `README.md` and `CHANGELOG.md` files have been updated thoroughly with clear explanations and examples, which is crucial for a core API change like this.

## Detailed File-by-File

### `ace-core/lib/ace/core/atoms/path_expander.rb`

*   **Issue:** In-method `require_relative` calls.
*   **Severity:** 🟢 Medium
*   **Location:**
    *   `ace-core/lib/ace/core/atoms/path_expander.rb:32`
    *   `ace-core/lib/ace/core/atoms/path_expander.rb:46`
*   **Suggestion:** For better dependency clarity and to follow common Ruby conventions, it's generally preferred to place `require` statements at the top of the file. While lazy-loading can help with startup time or circular dependencies, it can also hide a file's dependencies. If there isn't a specific reason for the current placement, consider moving them.

    ```ruby
    # Suggestion:
    # ace-core/lib/ace/core/atoms/path_expander.rb
    
    require 'pathname'
    require_relative '../molecules/project_root_finder' # Move here
    
    module Ace
      module Core
        module Atoms
          class PathExpander
            # ...
    
            def self.for_file(source_file)
              # require_relative '../molecules/project_root_finder' # Remove from here
              # ...
            end
    
            def self.for_cli
              # require_relative '../molecules/project_root_finder' # Remove from here
              # ...
            end
          end
        end
      end
    end
    ```

*   **Issue:** Potential performance consideration for `ProjectRootFinder`.
*   **Severity:** 🔵 Nice-to-have
*   **Location:**
    *   `ace-core/lib/ace/core/atoms/path_expander.rb:36`
    *   `ace-core/lib/ace/core/atoms/path_expander.rb:50`
*   **Suggestion:** The `ProjectRootFinder` is instantiated and its `find` method is called every time a factory method (`for_file`, `for_cli`) is invoked. Since the project root is unlikely to change during the application's lifecycle, this could be a candidate for memoization or caching at a higher level to avoid repeatedly walking up the file system. This is not a required change for this PR but a thought for future optimization.

    ```ruby
    # No code change suggested now, just an informational note.
    # A potential future improvement could involve a singleton or cached ProjectRootFinder.
    ```

### Other Files

*No issues found*. The test files are exemplary, and all documentation and dependency updates are correct.

## Prioritised Action Items

### 🟢 Medium

1.  **`ace-core/lib/ace/core/atoms/path_expander.rb`**: Consider moving the `require_relative` statements to the top of the file for better clarity and adherence to convention, unless there's a strong reason for lazy-loading (e.g., avoiding circular dependencies).

### 🔵 Nice-to-have

1.  **Performance Note**: Keep in mind the potential for optimizing `ProjectRootFinder` calls in the future if `PathExpander` instances are created frequently in performance-sensitive code paths.

## Approval Recommendation

[x] ✅ Approve with minor changes

This is a high-quality, well-tested, and well-documented feature. The suggested changes are non-blocking and relate to style and future considerations. The core implementation is solid and ready for merging after addressing the minor point on dependency loading.