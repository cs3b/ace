# frozen_string_literal: true

module CodingAgentTools
  module Models
    # Model for autofix operations
    AutofixOperation = Struct.new(
      :file,
      :line,
      :column,
      :original_content,
      :fixed_content,
      :linter,
      :rule,
      :description,
      :applied,
      :error,
      keyword_init: true
    ) do
      def initialize(*)
        super
        self.applied ||= false
      end

      def successful?
        applied && error.nil?
      end

      def failed?
        !successful?
      end
    end
  end
end
