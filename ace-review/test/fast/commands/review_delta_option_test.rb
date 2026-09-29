# frozen_string_literal: true

require "test_helper"

module Ace
  module Review
    module CLI
      module Commands
        # Regression guard: a full PR review round must never be mistaken for a
        # delta round. dry-cli yields nil for an absent --delta AND for a bare
        # valueless --delta; only an explicit value requests delta resolution.
        class ReviewDeltaOptionTest < AceReviewTest
          ReviewCommand = Ace::Review::CLI::Commands::Review
          ReviewOptions = Ace::Review::Models::ReviewOptions

          def test_absent_delta_stays_a_full_round
            options = build_options(delta: :absent)

            assert_nil options[:delta]
            refute ReviewOptions.new(options).delta_requested?
          end

          def test_bare_delta_flag_stays_a_full_round
            options = build_options(delta: nil)

            assert_nil options[:delta]
            refute ReviewOptions.new(options).delta_requested?
          end

          def test_delta_auto_keyword_requests_auto_resolution
            options = build_options(delta: "auto")

            assert_equal :auto, options[:delta]
            assert ReviewOptions.new(options).delta_requested?
          end

          def test_delta_explicit_head_is_preserved
            options = build_options(delta: "abc123")

            assert_equal "abc123", options[:delta]
          end

          private

          def build_options(delta:)
            command = ReviewCommand.new
            options = {preset: "code-valid"}
            options[:delta] = delta unless delta == :absent
            command.send(:build_review_options, options)
          end
        end
      end
    end
  end
end
