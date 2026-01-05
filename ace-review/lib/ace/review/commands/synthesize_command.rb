# frozen_string_literal: true

module Ace
  module Review
    module Commands
      class SynthesizeCommand
        def initialize(args, options = {})
          @args = args
          @options = options
        end

        def execute
          # Validate inputs
          if @options[:session].nil? && @options[:reports].nil?
            $stderr.puts "✗ Error: Either --session or --reports is required"
            return 1
          end

          # Determine report paths
          report_paths = if @options[:reports]
                           parse_report_files(@options[:reports])
                         else
                           find_review_reports(@options[:session])
                         end

          # Determine session directory for output
          session_dir = determine_session_dir

          # Execute synthesis
          require_relative "../molecules/report_synthesizer"
          synthesizer = Molecules::ReportSynthesizer.new

          result = synthesizer.synthesize(
            report_paths: report_paths,
            model: @options[:synthesis_model],
            session_dir: session_dir,
            output_file: @options[:output]
          )

          if result[:success]
            # Success message already displayed by synthesizer
            0
          else
            $stderr.puts "✗ Synthesis failed: #{result[:error]}"
            $stderr.puts result[:backtrace].join("\n") if @options[:verbose] && result[:backtrace]
            1
          end
        rescue StandardError => e
          $stderr.puts "✗ Error: #{e.message}"
          $stderr.puts e.backtrace if @options[:verbose]
          1
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

        def determine_session_dir
          if @options[:session]
            @options[:session]
          elsif @options[:reports]
            File.dirname(parse_report_files(@options[:reports]).first)
          else
            Dir.pwd
          end
        end
      end
    end
  end
end
