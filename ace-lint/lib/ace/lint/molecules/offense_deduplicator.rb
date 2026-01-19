# frozen_string_literal: true

module Ace
  module Lint
    module Molecules
      # Deduplicates linting offenses from multiple validators
      # Handles offenses from StandardRB, RuboCop, and other Ruby linters
      class OffenseDeduplicator
        # Deduplicate offenses by file:line:column:normalized_message
        # Keeps the offense with the most detailed message when duplicates found
        # @param offenses [Array<Hash>] Offenses to deduplicate
        # @return [Array<Hash>] Deduplicated offenses
        def self.deduplicate(offenses)
          return [] if offenses.empty?

          seen = {}

          offenses.each do |offense|
            key = offense_key(offense)
            if seen[key]
              # Keep the offense with the longer/more detailed message
              existing_len = seen[key][:message]&.length || 0
              new_len = offense[:message]&.length || 0
              seen[key] = offense if new_len > existing_len
            else
              seen[key] = offense
            end
          end

          seen.values
        end

        # Generate unique key for an offense
        # @param offense [Hash] Offense data
        # @return [String] Unique key
        def self.offense_key(offense)
          file = offense[:file] || ''
          line = offense[:line] || 0
          column = offense[:column] || 0
          # Normalize message: strip cop name prefix, downcase, remove extra whitespace
          message = normalize_message(offense[:message] || '')

          "#{file}:#{line}:#{column}:#{message}"
        end
        private_class_method :offense_key

        # Normalize message for comparison
        # @param message [String] Original message
        # @return [String] Normalized message
        def self.normalize_message(message)
          # Remove cop name prefix with various formats (e.g., "Style/StringLiterals: ", "Layout/TrailingWhitespace - ")
          # More defensive regex handles: "Name/SubName: ", "Name/SubName - ", "Name-SubName: "
          normalized = message.sub(/\A[A-Za-z]+[\/\-][A-Za-z]+[:\s-]+/, '')
          # Downcase and strip extra whitespace
          normalized.downcase.gsub(/\s+/, ' ').strip
        end
        private_class_method :normalize_message
      end
    end
  end
end
