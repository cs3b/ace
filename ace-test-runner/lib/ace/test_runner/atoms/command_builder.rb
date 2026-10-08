# frozen_string_literal: true

require_relative "line_number_resolver"
require_relative "../molecules/selection_resolver"
require "shellwords"

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
          selection = options[:selection_plan] || Molecules::SelectionResolver.resolve(Array(files))
          return exact_selection_command(selection, options) if selection.qualified?
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

        def exact_selection_command(plan, options)
          argv = []
          argv.concat(["bundle", "exec"]) if @bundler && bundler_available?
          argv.concat(Shellwords.split(@ruby_command))
          argv << "-Ilib:test" unless options[:no_load_path]
          model = File.expand_path("../models/test_selection_plan", __dir__)
          verifier = File.expand_path("../molecules/selection_verifier", __dir__)
          script = <<~RUBY
            begin
              require #{model.inspect}
              require #{verifier.inspect}
              plan = Ace::TestRunner::Models::TestSelectionPlan.new(
                files: #{plan.files.inspect}, identities: #{plan.identities.inspect},
                source_digests: #{plan.source_digests.inspect})
              verifier = Ace::TestRunner::Molecules::SelectionVerifier
              verifier.verify_sources!(plan)
              require "minitest/autorun"
              plan.files.each { |file| require file }
              pattern = verifier.verify_loaded!(plan)
              args = ["--name", "/" + pattern + "/"]
              args << "--verbose" if #{!!options[:profile]}
              Minitest::Reporters.use! Minitest::Reporters::DefaultReporter.new
              success = verifier.verify_execution!(plan) { Minitest.run(args) }
              STDOUT.flush
              STDERR.flush
              exit!(success ? 0 : 1)
            rescue Exception => error
              STDERR.puts(error.message)
              STDERR.flush
              exit!(1)
            end
          RUBY
          argv.concat(["-e", script])
          argv.concat(Array(options[:args])) if options[:args]
          argv
        end

        def bundler_available?
          @bundler_available ||= system("which bundle > /dev/null 2>&1")
        end
      end
    end
  end
end
