# frozen_string_literal: true

require_relative "synthesize_command"

module Ace
  module Review
    module Commands
      # dry-cli Command class for the synthesize command
      #
      # This wraps the existing SynthesizeCommand logic in a dry-cli compatible
      # interface, maintaining complete parity with the Thor implementation.
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
          # Remove dry-cli specific keys (args is leftover arguments)
          clean_options = options.reject { |k, _| k == :args }

          # Use the existing SynthesizeCommand logic
          SynthesizeCommand.new([], clean_options).execute
        end
      end
    end
  end
end
