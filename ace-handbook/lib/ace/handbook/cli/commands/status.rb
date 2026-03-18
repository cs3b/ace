# frozen_string_literal: true

module Ace
  module Handbook
    module CLI
      module Commands
        class Status < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Show handbook provider integration status"

          option :provider, aliases: ["-p"], desc: "Limit status to a single provider"
          option :format, default: "table", desc: "Output format (table, json)"

          def initialize(collector: nil)
            super()
            @collector = collector || Ace::Handbook::Organisms::StatusCollector.new
          end

          def call(provider: nil, format: "table", **)
            snapshot = @collector.collect(provider: provider)

            if format == "json"
              puts JSON.pretty_generate(snapshot)
              return
            end

            puts @collector.to_table(snapshot)
          rescue StandardError => e
            raise Ace::Support::Cli::Error.new(e.message)
          end
        end
      end
    end
  end
end
