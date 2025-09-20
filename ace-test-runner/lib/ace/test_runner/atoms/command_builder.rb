# frozen_string_literal: true

module Ace
  module TestRunner
    module Atoms
      # Builds test execution commands
      class CommandBuilder
        def initialize(ruby_command: "ruby", bundler: true)
          @ruby_command = ruby_command
          @bundler = bundler
        end

        def build_test_command(files, options = {})
          cmd_parts = []

          # Use bundler if available and requested
          cmd_parts << "bundle exec" if @bundler && bundler_available?

          # Ruby command
          cmd_parts << @ruby_command

          # Add test framework options
          cmd_parts << "-Ilib:test" unless options[:no_load_path]

          # Add minitest options if needed
          if options[:fail_fast]
            cmd_parts << "-rminitest/fail_fast"
          end

          # Add the test files
          if files.is_a?(Array)
            files.each { |f| cmd_parts << "-r#{f}" }
            cmd_parts << "-e ''"  # Run all loaded tests
          else
            cmd_parts << files
          end

          # Add any extra arguments
          if options[:args]
            cmd_parts.concat(Array(options[:args]))
          end

          cmd_parts.join(" ")
        end

        def build_single_file_command(file, options = {})
          build_test_command(file, options)
        end

        def build_pattern_command(pattern)
          cmd = []
          cmd << "bundle exec" if @bundler && bundler_available?
          cmd << @ruby_command
          cmd << "-Ilib:test"
          cmd << "-e"
          cmd << %Q{'Dir.glob("#{pattern}").each { |f| require f }'}

          cmd.join(" ")
        end

        private

        def bundler_available?
          @bundler_available ||= begin
            system("which bundle > /dev/null 2>&1")
          end
        end
      end
    end
  end
end