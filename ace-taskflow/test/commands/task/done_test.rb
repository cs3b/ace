# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/core"
require "ace/taskflow/cli/commands/task/done"

module Ace
  module Taskflow
    module Commands
      module Task
        class DoneTest < AceTaskflowTestCase
          def setup
            super
            @command = Ace::Taskflow::CLI::Commands::TaskSubcommands::Done.new
          end

          def test_passes_allow_incomplete_flag_to_task_manager
            called_allow_incomplete = nil
            manager = Object.new
            manager.define_singleton_method(:complete_task) do |_ref, allow_incomplete: false|
              called_allow_incomplete = allow_incomplete
              {
                success: true,
                message: "Task 123 marked as done",
                warning: "Bypassed completion gate"
              }
            end

            output = nil
            Ace::Taskflow::Organisms::TaskManager.stub :new, manager do
              output = capture_stdout do
                @command.call(task_ref: "123", allow_incomplete: true, quiet: true, verbose: false, debug: false)
              end
            end

            assert_equal true, called_allow_incomplete
            assert_includes output, "Warning: Bypassed completion gate"
            assert_includes output, "Task 123 marked as done"
          end

          def test_defaults_allow_incomplete_to_false
            called_allow_incomplete = nil
            manager = Object.new
            manager.define_singleton_method(:complete_task) do |_ref, allow_incomplete: false|
              called_allow_incomplete = allow_incomplete
              { success: true, message: "ok" }
            end

            Ace::Taskflow::Organisms::TaskManager.stub :new, manager do
              capture_stdout do
                @command.call(task_ref: "123", quiet: true, verbose: false, debug: false)
              end
            end

            assert_equal false, called_allow_incomplete
          end

          def test_raises_cli_error_when_completion_is_blocked
            manager = Object.new
            manager.define_singleton_method(:complete_task) do |_ref, allow_incomplete: false|
              { success: false, message: "Completion blocked" }
            end

            Ace::Taskflow::Organisms::TaskManager.stub :new, manager do
              error = assert_raises(Ace::Core::CLI::Error) do
                @command.call(task_ref: "123", quiet: true, verbose: false, debug: false)
              end
              assert_includes error.message, "Completion blocked"
            end
          end
        end
      end
    end
  end
end
