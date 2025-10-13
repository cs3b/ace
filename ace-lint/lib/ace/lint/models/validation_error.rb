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
      end
    end
  end
end
