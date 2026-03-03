# frozen_string_literal: true

module Ace
  module Task
    module Atoms
      module TaskValidationRules
        VALID_STATUSES = %w[pending in-progress done blocked draft skipped cancelled].freeze
        TERMINAL_STATUSES = %w[done skipped cancelled].freeze
        REQUIRED_FIELDS = %w[id status title].freeze
        RECOMMENDED_FIELDS = %w[tags created_at].freeze
        MAX_TITLE_LENGTH = 80

        def self.valid_status?(status)
          VALID_STATUSES.include?(status.to_s)
        end

        def self.terminal_status?(status)
          TERMINAL_STATUSES.include?(status.to_s)
        end

        def self.valid_id?(id)
          id.to_s.match?(/^[0-9a-z]{3}\.[a-z]\.[0-9a-z]{3}$/)
        end

        def self.scope_consistent?(status, special_folder)
          issues = []
          if terminal_status?(status) && special_folder != "_archive"
            issues << { type: :warning, message: "Task with terminal status '#{status}' not in _archive/" }
          end
          if special_folder == "_archive" && !terminal_status?(status) && status
            issues << { type: :warning, message: "Task in _archive/ but status is '#{status}' (expected terminal status)" }
          end
          if special_folder == "_maybe" && terminal_status?(status)
            issues << { type: :warning, message: "Task in _maybe/ with terminal status '#{status}' (should be in _archive/)" }
          end
          issues
        end

        def self.missing_required_fields(frontmatter)
          return REQUIRED_FIELDS.dup if frontmatter.nil? || !frontmatter.is_a?(Hash)
          REQUIRED_FIELDS.select { |field| frontmatter[field].nil? || frontmatter[field].to_s.strip.empty? }
        end

        def self.missing_recommended_fields(frontmatter)
          return RECOMMENDED_FIELDS.dup if frontmatter.nil? || !frontmatter.is_a?(Hash)
          RECOMMENDED_FIELDS.select { |field| frontmatter[field].nil? }
        end
      end
    end
  end
end
