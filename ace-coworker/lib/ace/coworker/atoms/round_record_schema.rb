# frozen_string_literal: true

module Ace
  module Coworker
    module Atoms
      # Pure validation of a single review-round record at the store
      # boundary (Atoms::RolePresetSchema.errors pattern): field-specific
      # errors, no IO, no coercion. A record must be a Hash with string
      # keys; "type" full|delta, "status" completed|aborted, "confirmed"
      # an array of hashes with string id+severity, "resolved" an array
      # of strings. Garbage must surface as an actionable Ace::Coworker
      # Error, never a TypeError or a silently wrong verdict.
      module RoundRecordSchema
        TYPES = %w[full delta].freeze
        STATUSES = %w[completed aborted].freeze

        # @param record [Object] candidate round record
        # @return [Array<String>] field-specific error messages (empty when valid)
        def self.errors(record)
          return ["round record must be a Hash with string keys, got #{record.class}"] unless record.is_a?(Hash)
          return ["round record keys must be strings, got: #{record.keys.inspect}"] if record.keys.any? { |k| !k.is_a?(String) }

          errors = []
          errors << "'type' must be one of: #{TYPES.join(', ')}" unless TYPES.include?(record["type"])
          errors << "'status' must be one of: #{STATUSES.join(', ')}" unless STATUSES.include?(record["status"])
          errors.concat(confirmed_errors(record["confirmed"]))
          errors.concat(resolved_errors(record["resolved"]))
          errors
        end

        class << self
          private

          def confirmed_errors(value)
            return ["'confirmed' must be an array, got #{value.class}"] unless value.is_a?(Array)

            value.each_with_index.flat_map do |finding, index|
              if !finding.is_a?(Hash)
                ["'confirmed[#{index}]' must be a Hash, got #{finding.class}"]
              elsif finding.keys.any? { |k| !k.is_a?(String) }
                ["'confirmed[#{index}]' keys must be strings"]
              elsif !finding["id"].is_a?(String) || finding["id"].empty? ||
                    !finding["severity"].is_a?(String) || finding["severity"].empty?
                ["'confirmed[#{index}]' must have non-empty string 'id' and 'severity'"]
              else
                []
              end
            end
          end

          def resolved_errors(value)
            return ["'resolved' must be an array, got #{value.class}"] unless value.is_a?(Array)

            value.each_with_index.map do |id, index|
              id.is_a?(String) && !id.empty? ? nil : "'resolved[#{index}]' must be a non-empty string"
            end.compact
          end
        end
      end
    end
  end
end
