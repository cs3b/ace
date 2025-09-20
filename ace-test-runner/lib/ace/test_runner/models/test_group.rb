# frozen_string_literal: true

module Ace
  module TestRunner
    module Models
      # Represents a group of tests to be executed together
      class TestGroup
        attr_reader :name, :patterns, :files, :options

        def initialize(name:, patterns: [], files: [], options: {})
          @name = name
          @patterns = Array(patterns)
          @files = Array(files)
          @options = options
        end

        # Find all test files matching this group's patterns
        def find_files
          return @files unless @files.empty?

          detector = Atoms::TestDetector.new(patterns: @patterns)
          detector.find_test_files
        end

        # Execute this group's tests
        def execute(executor, formatter_options = {})
          test_files = find_files
          return empty_result if test_files.empty?

          options = @options.merge(formatter_options)
          executor.execute_tests(test_files, options)
        end

        # Check if a file belongs to this group
        def includes_file?(file_path)
          return true if @files.include?(file_path)

          @patterns.any? do |pattern|
            File.fnmatch(pattern, file_path, File::FNM_PATHNAME)
          end
        end

        def to_h
          {
            name: @name,
            patterns: @patterns,
            files: @files,
            options: @options
          }
        end

        # Load groups from configuration
        def self.from_config(config)
          groups = config.fetch("groups", default_groups)

          groups.map do |name, definition|
            new(
              name: name,
              patterns: definition["patterns"] || [],
              files: definition["files"] || [],
              options: definition.fetch("options", {}).transform_keys(&:to_sym)
            )
          end
        end

        # Default test groups for common Ruby project structures
        def self.default_groups
          {
            "unit" => {
              "patterns" => ["test/unit/**/*_test.rb", "test/*_test.rb"],
              "options" => {}
            },
            "integration" => {
              "patterns" => ["test/integration/**/*_test.rb"],
              "options" => {}
            },
            "system" => {
              "patterns" => ["test/system/**/*_test.rb"],
              "options" => { "timeout" => 60 }
            },
            "all" => {
              "patterns" => ["test/**/*_test.rb"],
              "options" => {}
            }
          }
        end

        private

        def empty_result
          {
            stdout: "",
            stderr: "No test files found for group '#{@name}'",
            status: OpenStruct.new(success?: true, exitstatus: 0),
            command: "",
            start_time: Time.now,
            end_time: Time.now,
            duration: 0.0,
            success: true
          }
        end
      end
    end
  end
end