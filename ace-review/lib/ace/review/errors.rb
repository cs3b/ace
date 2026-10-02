# frozen_string_literal: true

module Ace
  module Review
    # Namespace for ace-review errors
    module Errors
      # Base error class for all ace-review errors
      class Error < StandardError; end

      # Raised when a required dependency is missing
      class MissingDependencyError < Error
        attr_reader :dependency_name, :install_command

        def initialize(dependency_name, install_command = nil)
          @dependency_name = dependency_name
          @install_command = install_command || "gem install #{dependency_name}"

          message = "Required gem '#{dependency_name}' not found.\n"
          message += "Install with: #{@install_command}"

          super(message)
        end
      end

      # Raised when ace-bundle fails to process bundle
      class BundleProcessingError < Error
        attr_reader :details

        def initialize(message, details = nil)
          @details = details
          super(message)
        end
      end

      # Raised when ace-task cannot find task
      class TaskNotFoundError < Error
        attr_reader :task_ref

        def initialize(task_ref)
          @task_ref = task_ref
          message = "Task '#{task_ref}' not found.\n"
          message += "Run 'ace-task show #{task_ref}' for details."
          super(message)
        end
      end

      # Raised when task exists but has no path
      class TaskPathNotFoundError < Error
        attr_reader :task_ref

        def initialize(task_ref)
          @task_ref = task_ref
          message = "Task '#{task_ref}' exists but has no path.\n"
          message += "Check task status with: ace-task show #{task_ref}"
          super(message)
        end
      end

      # Raised when a subprocess command times out
      class CommandTimeoutError < Error
        attr_reader :command, :timeout_seconds

        def initialize(command, timeout_seconds)
          @command = command
          @timeout_seconds = timeout_seconds
          message = "Command '#{command}' timed out after #{timeout_seconds} seconds."
          super(message)
        end
      end

      # Raised when context composition fails
      class ContextComposerError < Error; end
    end
  end
end
