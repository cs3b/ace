# frozen_string_literal: true

require "json"

module Ace
  module Overseer
    module CLI
      module Commands
        class Status < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc "Show status of active task worktrees"

          option :format, default: "table", desc: "Output format (table, json)"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Enable debug output"

          def initialize(collector: nil)
            super()
            @collector = collector || Organisms::StatusCollector.new
          end

          def call(format:, **options)
            return if options[:quiet]

            snapshot = @collector.collect

            if format == "json"
              puts JSON.pretty_generate(@collector.to_h(snapshot))
              return
            end

            puts @collector.to_table(snapshot)
          rescue StandardError => e
            raise Ace::Core::CLI::Error.new(e.message)
          end
        end
      end
    end
  end
end
