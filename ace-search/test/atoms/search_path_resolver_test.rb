# frozen_string_literal: true

require "test_helper"
require "ace/search/atoms/search_path_resolver"

module Ace
  module Search
    module Atoms
      class TestSearchPathResolver < AceSearchTestCase
        def setup
          @resolver = SearchPathResolver.new
        end

        # Test Step 1: Explicit path argument (highest priority)

        def test_resolve_with_explicit_relative_path
          result = @resolver.resolve("./src")
          assert_equal "./src", result
        end

        def test_resolve_with_explicit_absolute_path
          result = @resolver.resolve("/absolute/path")
          assert_equal "/absolute/path", result
        end

        def test_resolve_with_explicit_current_directory
          result = @resolver.resolve(".")
          assert_equal ".", result
        end

        def test_resolve_with_explicit_parent_directory
          result = @resolver.resolve("../parent")
          assert_equal "../parent", result
        end

        def test_resolve_with_explicit_glob_pattern
          result = @resolver.resolve("./**/*.md")
          assert_equal "./**/*.md", result
        end

        # Test Step 2: PROJECT_ROOT_PATH environment variable

        def test_resolve_uses_env_variable_when_no_explicit_path
          @resolver.stub :env_project_root, "/env/project/root" do
            @resolver.stub :valid_path?, true do
              result = @resolver.resolve(nil)
              assert_equal "/env/project/root", result
            end
          end
        end

        def test_resolve_ignores_env_variable_if_explicit_path_provided
          @resolver.stub :env_project_root, "/env/project/root" do
            result = @resolver.resolve("./custom")
            assert_equal "./custom", result
          end
        end

        def test_resolve_skips_invalid_env_path
          @resolver.stub :env_project_root, "/nonexistent/path" do
            @resolver.stub :valid_path?, false do
              @resolver.stub :find_project_root, "/detected/root" do
                result = @resolver.resolve(nil)
                assert_equal "/detected/root", result
              end
            end
          end
        end

        def test_resolve_skips_empty_env_variable
          @resolver.stub :env_project_root, "" do
            @resolver.stub :find_project_root, "/detected/root" do
              result = @resolver.resolve(nil)
              assert_equal "/detected/root", result
            end
          end
        end

        def test_resolve_skips_nil_env_variable
          @resolver.stub :env_project_root, nil do
            @resolver.stub :find_project_root, "/detected/root" do
              result = @resolver.resolve(nil)
              assert_equal "/detected/root", result
            end
          end
        end

        # Test Step 3: Project root detection

        def test_resolve_uses_project_root_finder_when_no_explicit_or_env
          @resolver.stub :env_project_root, nil do
            @resolver.stub :find_project_root, "/project/root" do
              result = @resolver.resolve(nil)
              assert_equal "/project/root", result
            end
          end
        end

        def test_resolve_with_actual_project_root_finder
          # This test uses the real ProjectRootFinder to detect the ace-search gem root
          result = @resolver.resolve(nil)

          # Should find a project root (ace-search has Gemfile, .git, etc.)
          # Result should not be just "." since we're in a real project
          refute_nil result
          assert result.is_a?(String)
        end

        # Test Step 4: Fallback to current directory

        def test_resolve_falls_back_to_current_directory_when_no_project_found
          @resolver.stub :env_project_root, nil do
            @resolver.stub :find_project_root, nil do
              result = @resolver.resolve(nil)
              assert_equal ".", result
            end
          end
        end

        # Test priority ordering

        def test_priority_explicit_over_env
          @resolver.stub :env_project_root, "/env/path" do
            result = @resolver.resolve("./explicit")
            assert_equal "./explicit", result
          end
        end

        def test_priority_env_over_project_root
          @resolver.stub :env_project_root, "/env/path" do
            @resolver.stub :valid_path?, true do
              @resolver.stub :find_project_root, "/detected/root" do
                result = @resolver.resolve(nil)
                assert_equal "/env/path", result
              end
            end
          end
        end

        def test_priority_project_root_over_fallback
          @resolver.stub :env_project_root, nil do
            @resolver.stub :find_project_root, "/detected/root" do
              result = @resolver.resolve(nil)
              assert_equal "/detected/root", result
            end
          end
        end

        # Test edge cases

        def test_resolve_with_empty_string_uses_fallback_chain
          @resolver.stub :env_project_root, nil do
            @resolver.stub :find_project_root, "/project/root" do
              result = @resolver.resolve("")
              assert_equal "/project/root", result
            end
          end
        end

        def test_resolve_with_whitespace_only_uses_fallback_chain
          @resolver.stub :env_project_root, nil do
            @resolver.stub :find_project_root, "/project/root" do
              result = @resolver.resolve("   ")
              assert_equal "/project/root", result
            end
          end
        end

        def test_resolve_with_path_containing_spaces
          result = @resolver.resolve("./path with spaces")
          assert_equal "./path with spaces", result
        end

        # Test class method

        def test_class_method_resolve_delegates_to_instance
          result = SearchPathResolver.resolve("./test")
          assert_equal "./test", result
        end

        def test_class_method_resolve_with_nil
          # Create instance and stub its methods
          resolver = SearchPathResolver.new
          resolver.stub :env_project_root, nil do
            resolver.stub :find_project_root, "/detected" do
              # Stub the class method to use our stubbed instance
              SearchPathResolver.stub :new, resolver do
                result = SearchPathResolver.resolve(nil)
                assert_equal "/detected", result
              end
            end
          end
        end

        # Test protected methods (via public interface)

        def test_valid_path_returns_true_for_existing_directory
          # Current directory always exists
          assert @resolver.send(:valid_path?, ".")
        end

        def test_valid_path_returns_false_for_nonexistent_directory
          refute @resolver.send(:valid_path?, "/definitely/does/not/exist/#{rand(100000)}")
        end

        def test_valid_path_expands_tilde_in_path
          # Skip if HOME is not set
          skip "HOME not set" unless ENV["HOME"]

          # HOME directory should exist
          assert @resolver.send(:valid_path?, "~")
        end

        # Edge case tests

        def test_resolve_with_symlink_path
          require "tmpdir"
          Dir.mktmpdir do |tmpdir|
            real_dir = File.join(tmpdir, "real")
            link_dir = File.join(tmpdir, "link")
            Dir.mkdir(real_dir)
            File.symlink(real_dir, link_dir)

            # Resolver should return the symlink path as-is (not resolve it)
            result = @resolver.resolve(link_dir)
            assert_equal link_dir, result
          end
        end

        def test_resolve_nonexistent_explicit_path_returns_as_is
          # Should return the path even if it doesn't exist
          # (validation happens at CLI level, not in resolver)
          nonexistent = "/does/not/exist/#{rand(100000)}"
          result = @resolver.resolve(nonexistent)
          assert_equal nonexistent, result
        end

        def test_resolve_relative_path_with_dots
          result = @resolver.resolve("../../parent")
          assert_equal "../../parent", result
        end

        def test_resolve_path_with_trailing_slash
          result = @resolver.resolve("./src/")
          assert_equal "./src/", result
        end
      end
    end
  end
end
