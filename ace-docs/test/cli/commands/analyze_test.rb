# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/docs/cli/commands/analyze"
require "ace/docs/molecules/change_detector"

module Ace
  module Docs
    module CLI
      module Commands
        class AnalyzeTest < Minitest::Test
          def setup
            @command = Analyze.new
          end

          # Tests for CLI option propagation (PR #92 review feedback)
          # Verifies --exclude-renames/--exclude-moves flags propagate to DiffOrchestrator

          def test_build_diff_options_passes_exclude_renames_true
            options = @command.send(:build_diff_options, {exclude_renames: true})

            assert_equal true, options[:exclude_renames],
              "Should pass exclude_renames: true when CLI flag is set"
          end

          def test_build_diff_options_passes_exclude_moves_true
            options = @command.send(:build_diff_options, {exclude_moves: true})

            assert_equal true, options[:exclude_moves],
              "Should pass exclude_moves: true when CLI flag is set"
          end

          def test_build_diff_options_defaults_exclude_renames_to_false
            options = @command.send(:build_diff_options, {})

            assert_equal false, options[:exclude_renames],
              "Should default exclude_renames to false (include renames by default)"
          end

          def test_build_diff_options_defaults_exclude_moves_to_false
            options = @command.send(:build_diff_options, {})

            assert_equal false, options[:exclude_moves],
              "Should default exclude_moves to false (include moves by default)"
          end

          def test_build_diff_options_uses_new_exclude_keys_not_legacy_include_keys
            options = @command.send(:build_diff_options, {exclude_renames: true, exclude_moves: true})

            # Must use exclude_* keys (ace-git API)
            assert options.key?(:exclude_renames), "Should use exclude_renames key"
            assert options.key?(:exclude_moves), "Should use exclude_moves key"

            # Must NOT use legacy include_* keys
            refute options.key?(:include_renames), "Should NOT use legacy include_renames key"
            refute options.key?(:include_moves), "Should NOT use legacy include_moves key"
          end
        end
      end
    end
  end
end
