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

      # Raised when ace-context fails to process context
      class ContextProcessingError < Error
        attr_reader :details

        def initialize(message, details = nil)
          @details = details
          super(message)
        end
      end
    end
  end
end
