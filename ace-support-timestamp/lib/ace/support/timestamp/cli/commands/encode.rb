# frozen_string_literal: true

require_relative "../../commands/encode_command"

module Ace
  module Support
    module Timestamp
      module CLI
        module Commands
          # Encode a timestamp to a 6-character compact ID
          class Encode < Dry::CLI::Command
            include Ace::Core::CLI::DryCli::Base

            desc "Encode a timestamp to a compact ID (2-8 characters)"

            argument :timestamp, required: false, desc: "Timestamp to encode (ISO, readable, 'now', or empty for current time)"
            option :format, type: :string, aliases: ["-f"], desc: "Output format: 2sec (default), month, week, day, 40min, 50ms, ms"
            option :year_zero, type: :integer, aliases: ["-y"], desc: "Base year for encoding (default: 2000)"
            option :quiet, type: :boolean, aliases: ["-q"], desc: "Suppress config summary output"
            option :verbose, type: :boolean, aliases: ["-v"], desc: "Verbose output"
            option :debug, type: :boolean, aliases: ["-d"], desc: "Debug output"

            example [
              "'2025-01-06 12:30:00'    # Encode readable timestamp",
              "now                       # Encode current time",
              "--format day '2025-01-06' # Encode to day format",
              "--format month now        # Encode to month format",
              "--format 40min now        # Encode to 40min format",
              "--format 50ms now         # Encode to 50ms format",
              "--year-zero 2025 '2025-01-06'  # Encode with custom base year"
            ]

            def call(timestamp: nil, **options)
              # Convert numeric options from strings to integers
              convert_types(options, year_zero: :integer)

              Ace::Support::Timestamp::Commands::EncodeCommand.execute(timestamp, options)
            end
          end
        end
      end
    end
  end
end
