# frozen_string_literal: true

require_relative "line_number_resolver"

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

          # Note: fail_fast is handled by test executor, not minitest
          # We don't use minitest/fail_fast gem to avoid extra dependencies

          # Add the test files
          if files.is_a?(Array)
            # Check if any file has a line number (file:line format)
            has_line_numbers = files.any? { |f| f.match?(/:\d+$/) }

            if has_line_numbers
              # For files with line numbers, resolve to test names and filter
              build_line_number_command(cmd_parts, files, options)
            else
              # Build a Ruby script that requires each file and fails on LoadError
              requires_script = files.map do |f|
                # Add ./ prefix if it's a relative path without one
                path = f.start_with?("/", "./") ? f : "./#{f}"
                # Escape the path for shell safety
                escaped_path = path.gsub("'", "\\\\'")
                "begin; require '#{escaped_path}'; rescue LoadError => e; STDERR.puts \\\"Failed to load #{escaped_path}: \\\" + e.message; exit(1); end"
              end.join("; ")

              # Build the script parts
              script_parts = []
              # Inject ARGV with --verbose for Minitest if profile is requested
              # (Ruby's --verbose flag only sets $VERBOSE, doesn't enable Minitest verbose mode)
              script_parts << "ARGV.replace(['--verbose'])" if options[:profile]
              script_parts << requires_script
              script_parts << "exit_code = Minitest.autorun"
              script_parts << "exit(exit_code)"

              # Execute the requires and then run Minitest
              cmd_parts << "-e"
              # Use double quotes to wrap the entire script
              cmd_parts << "\"#{script_parts.join("; ")}\""
            end
          elsif files.match?(/:\d+$/)
            # Check if single file has line number
            build_line_number_command(cmd_parts, [files], options)
          elsif options[:profile]
            # Single file without line number
            cmd_parts << "-e"
            escaped_path = files.gsub("'", "\\\\'")
            path = files.start_with?("/", "./") ? escaped_path : "./#{escaped_path}"
            cmd_parts << "\"ARGV.replace(['--verbose']); require '#{path}'; exit_code = Minitest.autorun; exit(exit_code)\""
          # Inject ARGV with --verbose for Minitest profiling
          else
            # Just pass file as argument (Minitest autoruns)
            cmd_parts << files
          end

          # Add any extra arguments
          if options[:args]
            cmd_parts.concat(Array(options[:args]))
          end

          cmd_parts.join(" ")
        end

        def build_single_file_command(file, options = {})
          # Single file uses the same logic as multiple files
          build_test_command(file, options)
        end

        def build_pattern_command(pattern)
          cmd = []
          cmd << "bundle exec" if @bundler && bundler_available?
          cmd << @ruby_command
          cmd << "-Ilib:test"
          cmd << "-e"
          cmd << %{'Dir.glob("#{pattern}").each { |f| require f }'}

          cmd.join(" ")
        end

        private

        def build_line_number_command(cmd_parts, files, options = {})
          # For files with line numbers, we need to:
          # 1. Load each file
          # 2. Resolve line numbers to test names
          # 3. Filter using --name option

          file_requires = []
          test_names = []

          files.each do |file_with_line|
            parsed = LineNumberResolver.parse_file_with_line(file_with_line)
            file_path = parsed[:file]
            line_number = parsed[:line]

            # Add ./ prefix if it's a relative path without one
            path = file_path.start_with?("/", "./") ? file_path : "./#{file_path}"
            escaped_path = path.gsub("'", "\\\\'")

            # Always require the file
            file_requires << "require '#{escaped_path}'"

            # If there's a line number, resolve it to a test name
            if line_number
              test_name = LineNumberResolver.resolve_test_at_line(file_path, line_number)
              if test_name
                test_names << test_name
              end
            end
          end

          # Build the command
          script_parts = []

          # Require all files
          script_parts << file_requires.join("; ")

          # Set up ARGV with --name filter and --verbose if needed
          argv_args = []
          argv_args << "--verbose" if options[:profile]
          if test_names.any?
            # Create a regex pattern that matches any of the test names
            pattern = test_names.map { |name| Regexp.escape(name) }.join("|")
            argv_args << "--name"
            argv_args << "/#{pattern}/"
          end
          script_parts << "ARGV.replace([#{argv_args.map { |a| "'#{a}'" }.join(", ")}])" if argv_args.any?

          # Run Minitest
          script_parts << "exit_code = Minitest.autorun"
          script_parts << "exit(exit_code)"

          # Add to command
          cmd_parts << "-e"
          cmd_parts << "\"#{script_parts.join("; ")}\""
        end

        def bundler_available?
          @bundler_available ||= system("which bundle > /dev/null 2>&1")
        end
      end
    end
  end
end
