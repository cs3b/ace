# frozen_string_literal: true

module Ace
  module Lint
    module Models
      # Represents a single validation error
      # @attr line [Integer, nil] Line number where error occurred
      # @attr message [String] Error message
      # @attr severity [Symbol] Error severity (:error, :warning)
      ValidationError = Struct.new(:line, :message, :severity) do
        def initialize(message:, line: nil, severity: :error)
          super(line, message, severity)
        end

        def to_s
          if line
            "Line #{line}: #{message}"
          else
            message
          end
        end

        # Convert error to hash for JSON serialization
        # @return [Hash] Error as hash
        def to_h
          {line: line, message: message, severity: severity}
        end
      end
    end
  end
end
