# frozen_string_literal: true

require_relative "retro_id_formatter"

module Ace
  module Retro
    module Atoms
      # Pure validation predicates and constants for retro health checking.
      # Used by doctor validators to determine correctness of frontmatter,
      # file structure, and scope/status consistency.
      module RetroValidationRules
        VALID_STATUSES = %w[active done].freeze
        TERMINAL_STATUSES = %w[done].freeze
        REQUIRED_FIELDS = %w[id title type status created_at].freeze
        RECOMMENDED_FIELDS = %w[tags].freeze

        # Check if a status string is valid
        # @param status [String] Status to validate
        # @return [Boolean]
        def self.valid_status?(status)
          VALID_STATUSES.include?(status.to_s)
        end

        # Check if a status is terminal (belongs in _archive)
        # @param status [String] Status to check
        # @return [Boolean]
        def self.terminal_status?(status)
          TERMINAL_STATUSES.include?(status.to_s)
        end

        # Check if an ID string is a valid b36ts retro ID
        # @param id [String] ID to validate
        # @return [Boolean]
        def self.valid_id?(id)
          RetroIdFormatter.valid?(id)
        end

        # Check if scope (special folder) is consistent with status
        # @param status [String] Retro status
        # @param special_folder [String, nil] Special folder name (e.g., "_archive", nil)
        # @return [Array<Hash>] List of inconsistency issues (empty if consistent)
        def self.scope_consistent?(status, special_folder)
          issues = []

          if terminal_status?(status) && special_folder != "_archive"
            issues << {
              type: :warning,
              message: "Retro with terminal status '#{status}' not in _archive/"
            }
          end

          if special_folder == "_archive" && !terminal_status?(status) && status
            issues << {
              type: :warning,
              message: "Retro in _archive/ but status is '#{status}' (expected terminal status)"
            }
          end

          issues
        end

        # Return list of missing required fields from frontmatter
        # @param frontmatter [Hash] Parsed frontmatter
        # @return [Array<String>] Names of missing required fields
        def self.missing_required_fields(frontmatter)
          return REQUIRED_FIELDS.dup if frontmatter.nil? || !frontmatter.is_a?(Hash)

          REQUIRED_FIELDS.select { |field| frontmatter[field].nil? || frontmatter[field].to_s.strip.empty? }
        end

        # Return list of missing recommended fields from frontmatter
        # @param frontmatter [Hash] Parsed frontmatter
        # @return [Array<String>] Names of missing recommended fields
        def self.missing_recommended_fields(frontmatter)
          return RECOMMENDED_FIELDS.dup if frontmatter.nil? || !frontmatter.is_a?(Hash)

          RECOMMENDED_FIELDS.select { |field| frontmatter[field].nil? }
        end
      end
    end
  end
end
