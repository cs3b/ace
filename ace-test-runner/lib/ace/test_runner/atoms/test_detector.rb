# frozen_string_literal: true

module Ace
  module TestRunner
    module Atoms
      # Detects and finds test files based on patterns
      class TestDetector
        DEFAULT_PATTERNS = [
          "test/**/*_test.rb",
          "spec/**/*_spec.rb",
          "test/**/test_*.rb"
        ].freeze

        def initialize(patterns: nil, root_dir: ".")
          @patterns = patterns || DEFAULT_PATTERNS
          @root_dir = root_dir
        end

        def find_test_files
          files = []

          # Handle both hash (new format) and array (old format) patterns
          patterns_to_search = if @patterns.is_a?(Hash)
            @patterns.values
          else
            @patterns
          end

          patterns_to_search.each do |pattern|
            full_pattern = File.join(@root_dir, pattern)
            matched_files = Dir.glob(full_pattern).select { |f| File.file?(f) }
            files.concat(matched_files)
          end

          # Filter out helper files that aren't actual test files
          files = files.reject { |f| f.end_with?("/test_helper.rb", "/spec_helper.rb") }

          files.uniq.sort
        end

        def filter_by_pattern(files, pattern)
          return files unless pattern

          regex = Regexp.new(pattern, Regexp::IGNORECASE)
          files.select do |file|
            file.match?(regex) || File.basename(file).match?(regex)
          end
        end

        def test_file?(path)
          return false unless File.exist?(path) && File.file?(path)

          # Handle both hash (new format) and array (old format) patterns
          patterns_to_check = if @patterns.is_a?(Hash)
            @patterns.values
          else
            @patterns
          end

          patterns_to_check.any? do |pattern|
            File.fnmatch?(pattern, path) ||
              File.fnmatch?(pattern, path.sub(@root_dir + "/", ""))
          end
        end

        def classify_file(file_path)
          case file_path
          when /test\/unit\/atoms\//
            :atoms
          when /test\/unit\/molecules\//
            :molecules
          when /test\/unit\/organisms\//
            :organisms
          when /test\/unit\/models\//
            :models
          when /test\/integration\//
            :integration
          when /test\/system\//
            :system
          when /test\/unit\//
            :unit
          when /spec\/unit\/atoms\//
            :atoms
          when /spec\/unit\/molecules\//
            :molecules
          when /spec\/unit\/organisms\//
            :organisms
          when /spec\/unit\/models\//
            :models
          when /spec\/integration\//
            :integration
          when /spec\/system\//
            :system
          when /spec\/unit\//
            :unit
          else
            :other
          end
        end

        def group_test_files(files)
          grouped = Hash.new { |h, k| h[k] = [] }

          files.each do |file|
            group = classify_file(file)
            grouped[group] << file
          end

          grouped
        end
      end
    end
  end
end
