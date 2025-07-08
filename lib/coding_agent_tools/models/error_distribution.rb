# frozen_string_literal: true

module CodingAgentTools
  module Models
    # Model for error distribution results
    ErrorDistribution = Struct.new(
      :file_number,
      :file_path,
      :errors,
      :error_count,
      :files_covered,
      keyword_init: true
    ) do
      def initialize(*)
        super
        self.errors ||= []
        self.error_count ||= errors.size
        self.files_covered ||= errors.map { |e| e[:file] }.uniq.size
      end

      def empty?
        errors.empty?
      end

      def add_error(error)
        self.errors << error
        self.error_count = errors.size
        self.files_covered = errors.map { |e| e[:file] }.uniq.size
      end
    end
  end
end