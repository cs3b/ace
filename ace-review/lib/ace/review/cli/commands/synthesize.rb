# frozen_string_literal: true

module Ace
  module Review
    module CLI
      module Commands
      # dry-cli Command class for the synthesize command
      #
      # Synthesizes multiple review reports into a consolidated report.
      class Synthesize < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base

        desc <<~DESC.strip
          Synthesize multiple review reports into a consolidated report

          Configuration:
            Global config:  ~/.ace/review/config.yml
            Project config: .ace/review/config.yml
            Example:        ace-review/.ace-defaults/review/config.yml
        DESC

        example [
          '--session .cache/ace-review/sessions/review-20251201-143022/',
          '--reports report1.md,report2.md --output synthesis.md'
        ]

        option :session, type: :string, desc: "Session directory containing review reports"
        option :reports, type: :string, desc: "Explicit report files to synthesize (comma-separated)"
        option :synthesis_model, type: :string, desc: "Model to use for synthesis"
        option :output, type: :string, desc: "Output file path (default: synthesis-report.md)"
        option :verbose, type: :boolean, aliases: %w[-v], desc: "Verbose output"

        def call(**options)
          # Validate inputs
          if options[:session].nil? && options[:reports].nil?
            raise Ace::Core::CLI::Error.new("Either --session or --reports is required")
          end

          # Determine report paths
          report_paths = if options[:reports]
                           parse_report_files(options[:reports])
                         else
                           find_review_reports(options[:session])
                         end

          # Determine session directory for output
          session_dir = determine_session_dir(options)

          # Execute synthesis
          require_relative "../molecules/report_synthesizer"
          synthesizer = Molecules::ReportSynthesizer.new

          result = synthesizer.synthesize(
            report_paths: report_paths,
            model: options[:synthesis_model],
            session_dir: session_dir,
            output_file: options[:output]
          )

          unless result[:success]
            raise Ace::Core::CLI::Error.new("Synthesis failed: #{result[:error]}")
          end
        rescue StandardError => e
          raise Ace::Core::CLI::Error.new(e.message)
        end

        private

        def parse_report_files(reports_value)
          # Split comma-separated values
          reports_value.split(",").map(&:strip).compact
        end

        def find_review_reports(session_dir)
          unless Dir.exist?(session_dir)
            $stderr.puts "✗ Error: Session directory not found: #{session_dir}"
            raise "Session directory not found"
          end

          Dir.glob(File.join(session_dir, "review-*.md"))
        end

        def determine_session_dir(options)
          if options[:session]
            options[:session]
          elsif options[:reports]
            File.dirname(parse_report_files(options[:reports]).first)
          else
            Dir.pwd
          end
        end
      end
    end
  end
end
end
