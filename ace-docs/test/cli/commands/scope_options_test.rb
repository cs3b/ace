# frozen_string_literal: true

require_relative "../../test_helper"
require "tmpdir"
require "fileutils"
require "ace/docs/cli/commands/scope_options"

module Ace
  module Docs
    module CLI
      module Commands
        class ScopeOptionsTest < Minitest::Test
          class ScopeHarness
            include ScopeOptions

            public :normalized_scope_globs, :path_in_scope?
          end

          def setup
            @temp_dir = Dir.mktmpdir("ace-docs-scope-test")
            FileUtils.mkdir_p(File.join(@temp_dir, "ace-assign", "docs"))
            File.write(File.join(@temp_dir, "ace-assign", "docs", "usage.md"), "# usage")
            @harness = ScopeHarness.new
          end

          def teardown
            FileUtils.rm_rf(@temp_dir) if @temp_dir
          end

          def test_normalizes_package_scope
            globs = @harness.normalized_scope_globs(
              { package: ["ace-assign"] },
              project_root: @temp_dir
            )

            assert_equal ["ace-assign/**/*.md"], globs
          end

          def test_normalizes_bare_glob_scope
            globs = @harness.normalized_scope_globs(
              { glob: ["ace-assign"] },
              project_root: @temp_dir
            )

            assert_equal ["ace-assign/**/*.md"], globs
          end

          def test_keeps_explicit_glob_unchanged
            globs = @harness.normalized_scope_globs(
              { glob: ["ace-assign/docs/**/*.md"] },
              project_root: @temp_dir
            )

            assert_equal ["ace-assign/docs/**/*.md"], globs
          end

          def test_unknown_package_raises
            error = assert_raises(ArgumentError) do
              @harness.normalized_scope_globs(
                { package: ["ace-missing"] },
                project_root: @temp_dir
              )
            end

            assert_match(/Unknown package/, error.message)
          end

          def test_path_in_scope_matches_relative_paths
            globs = ["ace-assign/**/*.md"]

            assert_equal true, @harness.path_in_scope?(
              File.join(@temp_dir, "ace-assign", "docs", "usage.md"),
              globs,
              project_root: @temp_dir
            )

            assert_equal false, @harness.path_in_scope?(
              File.join(@temp_dir, "README.md"),
              globs,
              project_root: @temp_dir
            )
          end
        end
      end
    end
  end
end
