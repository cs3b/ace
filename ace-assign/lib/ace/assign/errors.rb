# frozen_string_literal: true

require "ace/support/cli/error"

module Ace
  module Assign
    # Base error class for all ace-assign exceptions.
    # Inherits from Ace::Support::Cli::Error to support exception-based
    # exit code pattern (per ADR-023).
    #
    # Subclasses should call super with appropriate exit_code.
    class Error < Ace::Support::Cli::Error
      def initialize(message, exit_code: 1)
        super
      end
    end

    # Assignment-related errors
    module AssignmentErrors
      class NotFound < Error
        def initialize(message = "Assignment not found")
          super(message, exit_code: 2)
        end
      end

      class NoActive < Error
        def initialize(message = "No active assignment")
          super(message, exit_code: 2)
        end
      end
    end

    # Config-related errors
    module ConfigErrors
      class NotFound < Error
        def initialize(message = "Configuration not found")
          super(message, exit_code: 3)
        end
      end
    end

    # Step-related errors
    module StepErrors
      class NotFound < Error
        def initialize(message = "Step not found")
          super(message, exit_code: 4)
        end
      end

      class InvalidState < Error; end
    end

    # Local prune/start exclusion errors (exit code 5).
    module LifecycleErrors
      # The identity was pruned or its exclusion artifacts are unsafe, so a
      # writer must not be started against it.
      class Conflict < Error
        def initialize(message = "Conflicting lifecycle identity")
          super(message, exit_code: 5)
        end
      end

      # Maintenance exclusion is busy or its admission deadline expired.
      class MaintenanceBusy < Error
        def initialize(message = "Maintenance exclusion is busy")
          super(message, exit_code: 5)
        end
      end
    end
  end
end
