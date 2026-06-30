# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "tmpdir"
require "ace/core/molecules/frontmatter_free_policy"

module Ace
  module Core
    module Molecules
      class FrontmatterFreePolicyTest < Minitest::Test
        def test_patterns_fall_back_to_defaults
          result = FrontmatterFreePolicy.patterns(config: {})
          assert_equal FrontmatterFreePolicy::DEFAULT_PATTERNS, result
        end

        def test_match_uses_relative_path
          assert FrontmatterFreePolicy.match?(
            "ace-docs/README.md",
            patterns: ["*/README.md"],
            project_root: Dir.pwd
          )
        end

        def test_match_uses_canonical_path_for_symlinked_roots
          Dir.mktmpdir do |tmpdir|
            project_root = File.join(tmpdir, "project")
            docs_dir = File.join(project_root, "ace-docs")
            FileUtils.mkdir_p(docs_dir)
            File.write(File.join(docs_dir, "README.md"), "# README\n")
            linked_root = File.join(tmpdir, "linked-project")
            File.symlink(project_root, linked_root)

            assert FrontmatterFreePolicy.match?(
              File.join(linked_root, "ace-docs", "README.md"),
              patterns: ["*/README.md"],
              project_root: project_root
            )
          end
        end
      end
    end
  end
end
