# frozen_string_literal: true

require "test_helper"
require "ace/docs/atoms/frontmatter_free_matcher"

module Ace
  module Docs
    module Atoms
      class FrontmatterFreeMatcherTest < Minitest::Test
        def test_match_with_default_readme_pattern
          assert FrontmatterFreeMatcher.match?(
            "ace-docs/README.md",
            patterns: ["**/README.md"],
            project_root: Dir.pwd
          )
        end

        def test_non_matching_file_returns_false
          refute FrontmatterFreeMatcher.match?(
            "ace-docs/docs/usage.md",
            patterns: ["**/README.md"],
            project_root: Dir.pwd
          )
        end

        def test_custom_pattern_match
          assert FrontmatterFreeMatcher.match?(
            "ace-docs/CONTRIBUTING.md",
            patterns: ["**/CONTRIBUTING.md"],
            project_root: Dir.pwd
          )
        end
      end
    end
  end
end
