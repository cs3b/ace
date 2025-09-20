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

          @patterns.each do |pattern|
            full_pattern = File.join(@root_dir, pattern)
            matched_files = Dir.glob(full_pattern).select { |f| File.file?(f) }
            files.concat(matched_files)
          end

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

          @patterns.any? do |pattern|
            File.fnmatch?(pattern, path) ||
              File.fnmatch?(pattern, path.sub(@root_dir + "/", ""))
          end
        end
      end
    end
  end
end