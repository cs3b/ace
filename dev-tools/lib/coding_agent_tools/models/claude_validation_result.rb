# frozen_string_literal: true

module CodingAgentTools
  module Models
    # Carries validation results data for Claude commands
    # This is a pure data carrier with no behavior or external dependencies
    ClaudeValidationResult = Struct.new(
      :workflow_count,  # Integer - Total workflows found
      :command_count,   # Integer - Total commands found
      :missing,         # Array<String> - Missing command names
      :outdated,        # Array<Hash> - Outdated commands with details
      :duplicates,      # Array<Hash> - Duplicate commands with locations
      :orphaned,        # Array<Hash> - Orphaned commands
      :valid,           # Array<String> - Valid command names
      keyword_init: true
    ) do
      # Initialize with default values
      def initialize(**args)
        super(
          workflow_count: args[:workflow_count] || 0,
          command_count: args[:command_count] || 0,
          missing: args[:missing] || [],
          outdated: args[:outdated] || [],
          duplicates: args[:duplicates] || [],
          orphaned: args[:orphaned] || [],
          valid: args[:valid] || []
        )
      end

      # Check if validation found any issues
      def has_issues?
        missing.any? || outdated.any? || duplicates.any?
      end

      # Get summary counts for reporting
      def summary_counts
        {
          missing_count: missing.size,
          outdated_count: outdated.size,
          duplicate_count: duplicates.size,
          orphaned_count: orphaned.size,
          valid_count: valid.size
        }
      end

      # Check if all commands are valid
      def all_valid?
        !has_issues? && missing.empty?
      end

      # Get total number of issues
      def total_issues
        missing.size + outdated.size + duplicates.size
      end

      # Generate summary message
      def summary_message
        issues = []
        issues << "#{missing.size} missing" if missing.any?
        issues << "#{outdated.size} outdated" if outdated.any?
        issues << "#{duplicates.size} duplicate" if duplicates.any?

        if issues.empty?
          "All commands are valid and up to date"
        else
          "Summary: #{issues.join(", ")}"
        end
      end
    end
  end
end
