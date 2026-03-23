# frozen_string_literal: true

module Ace
  module Bundle
    module Atoms
      # Pure functions for detecting typos in frontmatter keys
      # Uses Levenshtein-like edit distance for similarity detection
      module TypoDetector
        # Known keys for templates and workflows
        KNOWN_FRONTMATTER_KEYS = %w[
          context files commands include exclude diffs
          name description allowed-tools params argument-hint
          update frequency sections last-updated
          auto_generate template-refs embed_document_source
          doc-type purpose source title author version
        ].freeze

        class << self
          # Detect suspicious frontmatter keys that might be typos
          # @param frontmatter [Hash] Parsed frontmatter YAML
          # @param path [String] File path for warning message
          # @return [Array<String>] List of warning messages
          def detect_suspicious_keys(frontmatter, path)
            warnings = []
            frontmatter.keys.each do |key|
              next if KNOWN_FRONTMATTER_KEYS.include?(key)

              # Check for common typos using Levenshtein-like distance
              KNOWN_FRONTMATTER_KEYS.each do |known|
                if typo_distance(key, known) <= 2
                  warnings << "Possible typo in #{path}: frontmatter key '#{key}' looks similar to known key '#{known}'"
                  break
                end
              end
            end

            warnings
          end

          # Calculate simple edit distance between two strings
          # Uses Levenshtein distance algorithm
          # @param str1 [String] First string
          # @param str2 [String] Second string
          # @return [Integer] Edit distance
          def typo_distance(str1, str2)
            return str2.length if str1.empty?
            return str1.length if str2.empty?

            # Create distance matrix
            rows = str1.length + 1
            cols = str2.length + 1
            dist = Array.new(rows) { Array.new(cols, 0) }

            # Initialize first row and column
            (0...rows).each { |i| dist[i][0] = i }
            (0...cols).each { |j| dist[0][j] = j }

            # Fill in rest of matrix
            (1...rows).each do |i|
              (1...cols).each do |j|
                cost = (str1[i - 1] == str2[j - 1]) ? 0 : 1
                dist[i][j] = [
                  dist[i - 1][j] + 1,     # deletion
                  dist[i][j - 1] + 1,     # insertion
                  dist[i - 1][j - 1] + cost # substitution
                ].min
              end
            end

            dist[rows - 1][cols - 1]
          end
        end
      end
    end
  end
end
