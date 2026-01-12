# frozen_string_literal: true

require_relative "../commands/decode_command"

module Ace
  module Support
    module Timestamp
    module Commands
      # Decode a compact ID to a timestamp
      class Decode < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base

        desc "Decode a compact ID to a timestamp"

        argument :compact_id, required: true, desc: "6-character compact ID to decode"
        option :year_zero, type: :integer, aliases: ["-y"], desc: "Base year for decoding (default: 2000)"
        option :format, type: :string, aliases: ["-f"], desc: "Output format (readable, iso, timestamp)"
        option :quiet, type: :boolean, aliases: ["-q"], desc: "Suppress config summary output"
        option :verbose, type: :boolean, aliases: ["-v"], desc: "Verbose output"
        option :debug, type: :boolean, aliases: ["-d"], desc: "Debug output"

        example [
          "i50jj3                    # Decode to readable format",
          "i50jj3 --format iso       # Decode to ISO format",
          "i50jj3 --format timestamp # Decode to YYYYMMDD-HHMMSS"
        ]

        def call(compact_id:, **options)
          DecodeCommand.execute(compact_id, options)
        end
      end
    end
  end
  end
end
