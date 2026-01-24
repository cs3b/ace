# frozen_string_literal: true

require_relative "../../commands/decode_command"

module Ace
  module Support
    module Timestamp
      module CLI
        module Commands
          # Decode a compact ID to a timestamp
          class Decode < Dry::CLI::Command
            include Ace::Core::CLI::DryCli::Base

            desc "Decode a compact ID (2-8 characters) to a timestamp"

            argument :compact_id, required: true, desc: "2-8 character compact ID to decode (auto-detects format)"
            option :year_zero, type: :integer, aliases: ["-y"], desc: "Base year for decoding (default: 2000)"
            option :format, type: :string, aliases: ["-f"], desc: "Output format (readable, iso, timestamp)"
            option :quiet, type: :boolean, aliases: ["-q"], desc: "Suppress config summary output"
            option :verbose, type: :boolean, aliases: ["-v"], desc: "Verbose output"
            option :debug, type: :boolean, aliases: ["-d"], desc: "Debug output"

            example [
              "i5                        # Decode 2-char month ID",
              "i5v                       # Decode 3-char week ID (3rd char 31-35)",
              "i50                       # Decode 3-char day ID (3rd char 0-30)",
              "i50j                      # Decode 4-char 40min ID",
              "i50jj3                    # Decode 6-char 2sec ID",
              "i50jj3z                   # Decode 7-char 50ms ID",
              "i50jj3zz                  # Decode 8-char ms ID",
              "i50jj3 --format iso       # Decode to ISO format",
              "i50jj3 --format timestamp # Decode to YYYYMMDD-HHMMSS"
            ]

            def call(compact_id:, **options)
              # Convert numeric options from strings to integers
              convert_types(options, year_zero: :integer)

              Ace::Support::Timestamp::Commands::DecodeCommand.execute(compact_id, options)
            end
          end
        end
      end
    end
  end
end
