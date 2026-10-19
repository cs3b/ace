# frozen_string_literal: true

module Ace
  module Overseer
    module CLI
      module Commands
        class ProcessReports < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Process incoming ace-hitl reports and continue the overseer queue"

          option :dry_run, type: :boolean, default: false, desc: "Interpret reports without writes or continuation"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress non-essential output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Show debug output"

          def initialize(processor: nil)
            super()
            @processor = processor
          end

          def call(dry_run: false, **options)
            Atoms::RepoGuard.ensure_repo!

            processor = @processor || Organisms::ReportProcessor.new
            result = processor.call(
              dry_run: dry_run,
              on_progress: options[:quiet] ? nil : ->(msg) { puts msg }
            )

            return if options[:quiet]

            puts
            result[:outcomes].each do |o|
              puts "  #{o[:event_id]}: #{o[:status]} - #{o[:message]}"
            end
            counts = result[:counts]
            puts
            puts "Processed #{result[:outcomes].size} event(s): " \
              "#{counts[:success]} success, #{counts[:error]} error, #{counts[:needs_answer]} question, " \
              "#{counts[:duplicate]} duplicate, #{counts[:unmatched]} unmatched."
          rescue Ace::Support::Cli::Error
            raise
          rescue => e
            raise Ace::Support::Cli::Error.new(e.message)
          end
        end
      end
    end
  end
end
