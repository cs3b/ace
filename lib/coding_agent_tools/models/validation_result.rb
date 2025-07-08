# frozen_string_literal: true

module CodingAgentTools
  module Models
    # Model for validation results
    ValidationResult = Struct.new(
      :success,
      :linter,
      :language,
      :findings,
      :errors,
      :warnings,
      :exit_code,
      :duration,
      :metadata,
      keyword_init: true
    ) do
      def initialize(*)
        super
        self.success ||= false
        self.findings ||= []
        self.errors ||= []
        self.warnings ||= []
        self.metadata ||= {}
      end

      def issue_count
        findings.size + errors.size
      end

      def has_issues?
        issue_count > 0
      end

      def correctable_count
        findings.count { |f| f[:correctable] }
      end
    end
  end
end