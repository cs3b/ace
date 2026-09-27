# frozen_string_literal: true

require "test_helper"

module Ace
  module Review
    module Molecules
      class ExemptPathsTest < AceReviewTest
        def test_validate_accepts_nil_and_specific_globs
          assert_nil ExemptPaths.validate!(nil)
          assert_nil ExemptPaths.validate!(["CHANGELOG.md", "**/*.golden", "docs/**"])
        end

        def test_validate_refuses_malformed_values
          assert_equal "exempt_paths must be a list of non-empty glob strings",
            ExemptPaths.validate!(["CHANGELOG.md", ""])
          assert_equal "exempt_paths must be a list of non-empty glob strings",
            ExemptPaths.validate!("CHANGELOG.md")
          assert_equal "exempt_paths must be a list of non-empty glob strings",
            ExemptPaths.validate!([nil])
        end

        def test_validate_refuses_overly_broad_patterns_by_name
          ["**", "**/*", "*"].each do |pattern|
            error = ExemptPaths.validate!([pattern])
            assert_equal "exempt_paths pattern '#{pattern}' matches every path; refusing to exempt the world", error
          end
        end

        def test_classify_partitions_paths
          result = ExemptPaths.classify(["CHANGELOG.md", "lib/a.rb", "docs/x.md"], ["CHANGELOG.md", "docs/**"])

          assert_equal ["CHANGELOG.md", "docs/x.md"], result[:exempt]
          assert_equal ["lib/a.rb"], result[:non_exempt]
        end

        def test_classify_with_no_patterns_leaves_everything_non_exempt
          result = ExemptPaths.classify(["lib/a.rb"], nil)

          assert_empty result[:exempt]
          assert_equal ["lib/a.rb"], result[:non_exempt]
        end

        def test_classify_matches_nested_paths_with_doublestar
          result = ExemptPaths.classify(["a/b/c.txt"], ["**/*.txt"])

          assert_equal ["a/b/c.txt"], result[:exempt]
        end
      end
    end
  end
end
