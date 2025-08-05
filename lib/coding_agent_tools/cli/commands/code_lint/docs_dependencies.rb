# frozen_string_literal: true

require 'dry/cli'
require_relative '../../../organisms/doc_dependency_analyzer'

module CodingAgentTools
  module Cli
    module Commands
      module CodeLint
        # CLI command for documentation dependency analysis
        # Provides same functionality as bin/analyze-doc-dependencies
        class DocsDependencies < Dry::CLI::Command
          desc 'Analyze dependencies between documentation files'

          option :format,
            aliases: ['-f'],
            default: 'text',
            values: ['text', 'json'],
            desc: 'Output format (text, json)'

          option :output,
            aliases: ['-o'],
            desc: 'Output file path (default: stdout)'

          option :dot_file,
            aliases: ['-d'],
            default: 'doc-dependencies.dot',
            desc: 'DOT graph output file'

          option :json_file,
            aliases: ['-j'],
            default: 'doc-dependencies.json',
            desc: 'JSON export output file'

          option :no_exports,
            aliases: ['--no-exports'],
            type: :boolean,
            default: false,
            desc: 'Skip DOT and JSON file exports'

          option :stats_only,
            aliases: ['--stats-only'],
            type: :boolean,
            default: false,
            desc: 'Show only summary statistics'

          option :config,
            aliases: ['-c'],
            desc: 'Path to configuration file'

          example [
            '                                      # Full analysis with exports',
            '--format json                         # JSON output format',
            '--output analysis.txt                 # Save to file',
            '--no-exports                          # Skip file exports',
            '--stats-only                          # Summary only',
            '--config custom-lint.yml             # Use custom config file'
          ]

          def call(**options)
            config_path = options[:config] || '.coding-agent/lint.yml'
            analyzer = CodingAgentTools::Organisms::DocDependencyAnalyzer.new(config_path)

            if options[:stats_only]
              output_statistics_only(analyzer)
            else
              output_full_analysis(analyzer, options)
            end
          rescue => e
            warn "Error during analysis: #{e.message}"
            warn e.backtrace.join("\n") if ENV['DEBUG']
            exit 1
          end

          private

          def output_statistics_only(analyzer)
            # Run analysis without exports for stats only
            analyzer.analyze_dependencies_only
            stats = analyzer.get_statistics

            puts '## Documentation Dependency Statistics'
            puts "- Total files analyzed: #{stats[:total_files]}"
            puts "- Files with outgoing references: #{stats[:files_with_outgoing_refs]}"
            puts "- Files with incoming references: #{stats[:files_with_incoming_refs]}"
            puts "- Total references: #{stats[:total_references]}"
            puts "- Average outgoing references per file: #{stats[:average_outgoing_refs]}"
            puts "- Average incoming references per file: #{stats[:average_incoming_refs]}"

            orphaned = analyzer.get_orphaned_files
            puts "- Orphaned files: #{orphaned.length}"

            circular = analyzer.get_circular_dependencies
            puts "- Circular dependencies: #{circular.length}"
          end

          def output_full_analysis(analyzer, options)
            # Configure export options
            export_dot = !options[:no_exports]
            export_json = !options[:no_exports]

            # Run full analysis
            result = analyzer.analyze(
              output_format: options[:format].to_sym,
              export_dot: export_dot,
              export_json: export_json
            )

            # Handle output destination
            if options[:output]
              File.write(options[:output], result)
              puts "Analysis saved to: #{options[:output]}"
            else
              puts result
            end

            # Show export file info
            if export_dot && !options[:stats_only]
              puts "\nVisualization files:"
              puts "- DOT graph: #{options[:dot_file]}"
              puts "- To generate PNG: dot -Tpng #{options[:dot_file]} -o doc-dependencies.png"
            end

            return unless export_json && !options[:stats_only]

            puts "- JSON data: #{options[:json_file]}"
          end
        end
      end
    end
  end
end
