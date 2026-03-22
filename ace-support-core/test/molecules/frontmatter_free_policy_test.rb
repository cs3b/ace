# frozen_string_literal: true

require "test_helper"
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
      end
    end
  end
end
