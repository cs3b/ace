# frozen_string_literal: true

require "test_helper"
require "ace/core"
require "ace/taskflow/cli/commands/task/create"

module Ace
  module Taskflow
    module Commands
      module Task
        class CreateTest < Minitest::Test
          def setup
            @command = Ace::Taskflow::CLI::Commands::TaskSubcommands::Create.new
          end

          # Test: Title precedence: --title wins over positional when both provided
          def test_title_precedence_flag_over_positional
            args = call_build_args("Positional title", title: "Flag title")
            assert_equal ["Flag title"], args
          end

          # Test: Positional title only (no --title flag)
          def test_positional_title_only
            args = call_build_args("Positional only", title: nil)
            assert_equal ["Positional only"], args
          end

          # Test: --title flag only (no positional)
          def test_title_flag_only
            args = call_build_args(nil, title: "Flag only")
            assert_equal ["Flag only"], args
          end

          # Test: Dependencies parsing: --dependencies 041,042 passed through
          def test_dependencies_parsing
            args = call_build_args(nil, dependencies: "041,042")

            assert_includes args, "--dependencies"
            assert_includes args, "041,042"
          end

          # Test: Subtask creation: --child-of 121
          def test_subtask_creation_with_parent
            args = call_build_args("Test subtask", :"child-of" => "121")

            assert_includes args, "--child-of"
            assert_includes args, "121"
          end

          # Test: Dry-run flag included when true
          def test_dry_run_mode
            args = call_build_args("Dry run task", :"dry-run" => true)

            assert_includes args, "--dry-run"
          end

          # Test: Missing title produces empty args
          def test_missing_title_produces_empty_args
            args = call_build_args(nil, title: nil)
            assert_empty args
          end

          # Test: All options combined
          def test_all_options_combined
            args = call_build_args(
              "Combined test",
              title: "Combined test",
              status: "draft",
              estimate: "2h",
              dependencies: "041,042",
              :"child-of" => "121",
              backlog: true,
              release: "v.1.0.0",
              :"dry-run" => false
            )

            assert_includes args, "Combined test"
            assert_includes args, "--status"
            assert_includes args, "draft"
            assert_includes args, "--estimate"
            assert_includes args, "2h"
            assert_includes args, "--dependencies"
            assert_includes args, "041,042"
            assert_includes args, "--child-of"
            assert_includes args, "121"
            assert_includes args, "--backlog"
            assert_includes args, "--release"
            assert_includes args, "v.1.0.0"
            refute_includes args, "--dry-run" # dry_run is false
          end

          # Test: Standard options (quiet, verbose, debug) not in args array
          def test_standard_options_not_in_args
            args = call_build_args(
              "Test",
              quiet: true,
              verbose: false,
              debug: false
            )

            # Standard options are handled separately by dry-cli, not in args
            assert_equal ["Test"], args
            refute_includes args, "--quiet"
            refute_includes args, "--verbose"
            refute_includes args, "--debug"
          end

          # Test: Backlog flag (boolean)
          def test_backlog_flag
            args = call_build_args("Backlog task", backlog: true)

            assert_includes args, "--backlog"
            assert_includes args, "Backlog task"
          end

          # Test: Release option
          def test_release_option
            args = call_build_args("Release task", release: "v.2.0.0")

            assert_includes args, "--release"
            assert_includes args, "v.2.0.0"
          end

          # Test: Status option
          def test_status_option
            args = call_build_args("Status task", status: "in-progress")

            assert_includes args, "--status"
            assert_includes args, "in-progress"
          end

          # Test: Estimate option
          def test_estimate_option
            args = call_build_args("Estimated task", estimate: "4h")

            assert_includes args, "--estimate"
            assert_includes args, "4h"
          end

          private

          # Call the actual production build_args_for_create method
          # @param positional_title [String, nil] Positional title argument
          # @param options [Hash] Options hash (as dry-cli would provide)
          # @return [Array<String>] Args array built by production code
          def call_build_args(positional_title, **options)
            @command.send(:build_args_for_create, positional_title, options)
          end
        end
      end
    end
  end
end
