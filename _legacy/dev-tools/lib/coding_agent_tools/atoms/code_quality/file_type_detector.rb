# frozen_string_literal: true

module CodingAgentTools
  module Atoms
    module CodeQuality
      # Detects file types based on configuration-defined patterns
      class FileTypeDetector
        # Default file patterns for supported languages
        DEFAULT_PATTERNS = {
          ruby: [
            "*.rb",
            "*.gemspec",
            "Gemfile",
            "Rakefile",
            "exe/*"
          ].freeze,
          markdown: [
            "*.md",
            "*.markdown"
          ].freeze
        }.freeze

        def initialize(config: nil)
          @config = config
          @patterns = build_patterns
        end

        # Detect file type for a single file path
        def detect_type(file_path)
          file_name = File.basename(file_path)
          file_dir = File.dirname(file_path)

          @patterns.each do |language, patterns|
            patterns.each do |pattern|
              return language if matches_pattern?(file_path, file_name, file_dir, pattern)
            end
          end

          nil
        end

        # Check if file matches any patterns for the given language
        def matches_language?(file_path, language)
          detect_type(file_path) == language
        end

        # Get all configured patterns for a language
        def patterns_for(language)
          @patterns[language.to_sym] || []
        end

        # Get all supported languages
        def supported_languages
          @patterns.keys
        end

        private

        def build_patterns
          patterns = DEFAULT_PATTERNS.dup

          # Override with configuration if provided
          if @config&.dig(:file_patterns)
            @config[:file_patterns].each do |language, lang_patterns|
              patterns[language.to_sym] = lang_patterns if lang_patterns.is_a?(Array)
            end
          end

          patterns
        end

        def matches_pattern?(file_path, file_name, file_dir, pattern)
          case pattern
          when /^\*\./
            # Extension pattern like "*.rb"
            extension = pattern[2..]
            file_name.end_with?(".#{extension}")
          when %r{/\*$}
            # Directory pattern like "exe/*"
            dir_pattern = pattern[0..-3]
            file_dir.end_with?(dir_pattern) || file_path.include?("/#{dir_pattern}/")
          else
            # Exact filename match like "Gemfile"
            file_name == pattern || File.basename(file_path) == pattern
          end
        end
      end
    end
  end
end
