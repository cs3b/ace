# frozen_string_literal: true

require_relative "file_type_detector"

module CodingAgentTools
  module Atoms
    module CodeQuality
      # Filters file lists by language using configured patterns
      class LanguageFileFilter
        def initialize(config: nil)
          @detector = FileTypeDetector.new(config: config)
        end

        # Filter file paths to only include files of the specified language
        def filter_by_language(file_paths, language)
          return [] if file_paths.nil? || file_paths.empty?

          language_sym = language.to_sym
          file_paths.select do |path|
            @detector.matches_language?(path, language_sym)
          end
        end

        # Expand directory paths to find files of the specified language
        def expand_paths_for_language(paths, language)
          return [] if paths.nil? || paths.empty?

          all_files = []
          language_sym = language.to_sym
          patterns = @detector.patterns_for(language_sym)

          paths.each do |path|
            if File.directory?(path)
              all_files.concat(find_files_in_directory(path, patterns))
            elsif File.file?(path) && @detector.matches_language?(path, language_sym)
              all_files << path
            end
          end

          all_files.uniq
        end

        # Get file patterns for a specific language
        def patterns_for(language)
          @detector.patterns_for(language)
        end

        # Check if file matches language patterns
        def matches_language?(file_path, language)
          @detector.matches_language?(file_path, language)
        end

        private

        def find_files_in_directory(directory, patterns)
          found_files = []

          patterns.each do |pattern|
            case pattern
            when /^\*\./
              # Extension pattern like "*.rb"
              extension = pattern[2..-1]
              found_files.concat(Dir.glob(File.join(directory, "**", "*.#{extension}")))
            when /\/\*$/
              # Directory pattern like "exe/*"
              dir_pattern = pattern[0..-3]
              found_files.concat(Dir.glob(File.join(directory, "**", dir_pattern, "*")))
            else
              # Exact filename match like "Gemfile"
              found_files.concat(Dir.glob(File.join(directory, "**", pattern)))
            end
          end

          found_files.select { |f| File.file?(f) }
        end
      end
    end
  end
end