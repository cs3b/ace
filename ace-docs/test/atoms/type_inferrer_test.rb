# frozen_string_literal: true

require "test_helper"
require "ace/docs/atoms/type_inferrer"

module Ace
  module Docs
    module Atoms
      class TypeInferrerTest < Minitest::Test
        def test_pattern_type_beats_readme_basename
          result = TypeInferrer.resolve(
            "ace-docs/README.md",
            pattern_type: "workflow",
            frontmatter_type: nil
          )

          assert_equal "workflow", result
        end

        def test_readme_defaults_to_user_without_pattern
          result = TypeInferrer.resolve(
            "ace-docs/README.md",
            pattern_type: nil,
            frontmatter_type: nil
          )

          assert_equal "user", result
        end
      end
    end
  end
end
