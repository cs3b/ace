# frozen_string_literal: true

require "test_helper"

module Ace
  module Config
    module Atoms
      class PathExpanderTest < TestCase
        def test_resolve_absolute_path
          expander = PathExpander.new(source_dir: "/some/dir", project_root: "/project")

          result = expander.resolve("/absolute/path")

          assert_equal "/absolute/path", result
        end

        def test_resolve_source_relative_path
          expander = PathExpander.new(source_dir: "/some/dir", project_root: "/project")

          result = expander.resolve("./relative")

          assert_equal "/some/dir/relative", result
        end

        def test_resolve_parent_relative_path
          expander = PathExpander.new(source_dir: "/some/dir", project_root: "/project")

          result = expander.resolve("../sibling")

          assert_equal "/some/sibling", result
        end

        def test_resolve_project_relative_path
          expander = PathExpander.new(source_dir: "/some/dir", project_root: "/project")

          result = expander.resolve("lib/file.rb")

          assert_equal "/project/lib/file.rb", result
        end

        def test_resolve_nil_returns_nil
          expander = PathExpander.new(source_dir: "/dir", project_root: "/root")

          assert_nil expander.resolve(nil)
          assert_nil expander.resolve("")
        end

        def test_for_file_factory
          expander = PathExpander.for_file("/some/dir/file.rb", project_root: "/project")

          assert_equal "/some/dir", expander.source_dir
          assert_equal "/project", expander.project_root
        end

        def test_for_cli_factory
          expander = PathExpander.for_cli(project_root: "/project")

          assert_equal Dir.pwd, expander.source_dir
          assert_equal "/project", expander.project_root
        end

        def test_requires_both_parameters
          assert_raises(ArgumentError) do
            PathExpander.new(source_dir: nil, project_root: "/root")
          end

          assert_raises(ArgumentError) do
            PathExpander.new(source_dir: "/dir", project_root: nil)
          end
        end

        def test_protocol_detection
          assert PathExpander.protocol?("wfi://something")
          assert PathExpander.protocol?("guide://path")
          assert PathExpander.protocol?("https://example.com")

          refute PathExpander.protocol?("normal/path")
          refute PathExpander.protocol?("./relative")
          refute PathExpander.protocol?("/absolute")
          refute PathExpander.protocol?(nil)
          refute PathExpander.protocol?("")
        end

        def test_expand_class_method
          result = PathExpander.expand("~/test")

          assert_equal File.expand_path("~/test"), result
        end

        def test_join
          assert_equal "a/b/c", PathExpander.join("a", "b", "c")
          assert_equal "", PathExpander.join
        end

        def test_dirname
          assert_equal "/some/dir", PathExpander.dirname("/some/dir/file.rb")
          assert_nil PathExpander.dirname(nil)
        end

        def test_basename
          assert_equal "file.rb", PathExpander.basename("/some/dir/file.rb")
          assert_equal "file", PathExpander.basename("/some/dir/file.rb", ".rb")
          assert_nil PathExpander.basename(nil)
        end

        def test_absolute
          assert PathExpander.absolute?("/absolute/path")
          refute PathExpander.absolute?("relative/path")
          refute PathExpander.absolute?(nil)
        end

        def test_normalize
          assert_equal "a/b/c", PathExpander.normalize("a/./b/../b/c")
          assert_nil PathExpander.normalize(nil)
        end

        def test_resolve_protocol_without_resolver_raises_error
          # Clear any previously registered resolver
          PathExpander.register_protocol_resolver(nil)

          expander = PathExpander.new(source_dir: "/dir", project_root: "/root")

          error = assert_raises(PathError) do
            expander.resolve("wfi://some-workflow")
          end

          assert_match(/Protocol.*could not be resolved/, error.message)
          assert_match(/wfi:\/\/some-workflow/, error.message)
        end

        def test_resolve_protocol_with_resolver
          # Create a mock resolver
          mock_resolver = Object.new
          def mock_resolver.resolve(uri)
            "/resolved/#{uri.split("://").last}"
          end

          PathExpander.register_protocol_resolver(mock_resolver)

          expander = PathExpander.new(source_dir: "/dir", project_root: "/root")
          result = expander.resolve("wfi://workflow-name")

          assert_equal "/resolved/workflow-name", result
        ensure
          # Clean up
          PathExpander.register_protocol_resolver(nil)
        end

        def test_env_expansion_with_stubbed_get_env
          expander = PathExpander.new(source_dir: "/dir", project_root: "/root")

          # Stub get_env to return custom value without modifying global ENV
          expander.stub :get_env, ->(name) { name == "CUSTOM_VAR" ? "/custom/path" : nil } do
            result = expander.resolve("$CUSTOM_VAR/subdir")
            assert_equal "/custom/path/subdir", result
          end
        end

        def test_env_expansion_preserves_undefined_vars
          expander = PathExpander.new(source_dir: "/dir", project_root: "/root")

          # Stub get_env to return nil (simulating undefined ENV var)
          expander.stub :get_env, nil do
            result = expander.resolve("$UNDEFINED_VAR/subdir")
            # Should preserve $UNDEFINED_VAR in the path
            assert_match(/\$UNDEFINED_VAR/, result)
          end
        end

        def test_absolute_with_alt_separator
          # This test only makes sense on Windows where ALT_SEPARATOR is defined
          if File::ALT_SEPARATOR
            assert PathExpander.absolute?("\\absolute\\path")
          else
            # On non-Windows, ALT_SEPARATOR is nil, so backslash paths are not absolute
            refute PathExpander.absolute?("\\relative\\path")
          end
        end
      end
    end
  end
end
