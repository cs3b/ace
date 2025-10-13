# frozen_string_literal: true

require_relative '../organisms/lint_orchestrator'
require_relative '../organisms/result_reporter'

module Ace
  module Lint
    module Commands
      # Thor command for linting files
      class LintCommand
        # Execute lint command
        # @param file_paths [Array<String>] Paths to files to lint
        # @param options [Hash] Command options
        # @return [Integer] Exit code
        def self.execute(file_paths, options = {})
          # Validate inputs
          if file_paths.empty?
            puts 'Error: No files specified'.red
            puts 'Usage: ace-lint [FILES...] [OPTIONS]'
            return 1
          end

          # Expand globs
          expanded_paths = expand_file_paths(file_paths)

          if expanded_paths.empty?
            puts 'Error: No files found matching the given patterns'.red
            return 1
          end

          # Create orchestrator
          orchestrator = Organisms::LintOrchestrator.new

          # Prepare options
          lint_options = prepare_options(options)

          # Lint files
          results = orchestrator.lint_files(expanded_paths, options: lint_options)

          # Report results
          verbose = !options[:quiet]
          Organisms::ResultReporter.report(results, verbose: verbose)

          # Return exit code
          Organisms::ResultReporter.exit_code(results)
        end

        def self.expand_file_paths(paths)
          expanded = []

          paths.each do |path|
            # Check if it's a glob pattern
            if path.include?('*')
              matched_files = Dir.glob(path)
              expanded.concat(matched_files)
            elsif File.exist?(path)
              expanded << path
            else
              puts "Warning: File not found: #{path}".yellow
            end
          end

          expanded.uniq.sort
        end

        def self.prepare_options(options)
          prepared = {}

          # Type option
          prepared[:type] = options[:type].to_sym if options[:type]

          # Fix/format options
          prepared[:fix] = options[:fix] if options[:fix]
          prepared[:format] = options[:format] if options[:format]

          # Kramdown options
          kramdown_opts = {}
          kramdown_opts[:line_width] = options[:line_width] if options[:line_width]
          prepared[:kramdown_options] = kramdown_opts unless kramdown_opts.empty?

          prepared
        end
      end
    end
  end
end
