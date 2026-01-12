# frozen_string_literal: true

require_relative "../commands/encode_command"

module Ace
  module Support
    module Timestamp
    module Commands
      # Encode a timestamp to a 6-character compact ID
      class Encode < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base

        desc "Encode a timestamp to a 6-character compact ID"

        argument :timestamp, required: false, desc: "Timestamp to encode (ISO, readable, 'now', or empty for current time)"
        option :year_zero, type: :integer, aliases: ["-y"], desc: "Base year for encoding (default: 2000)"
        option :quiet, type: :boolean, aliases: ["-q"], desc: "Suppress config summary output"
        option :verbose, type: :boolean, aliases: ["-v"], desc: "Verbose output"
        option :debug, type: :boolean, aliases: ["-d"], desc: "Debug output"

        example [
          "'2025-01-06 12:30:00'    # Encode readable timestamp",
          "now                       # Encode current time",
          "--year-zero 2025 '2025-01-06'  # Encode with custom base year"
        ]

        def call(timestamp: nil, **options)
          EncodeCommand.execute(timestamp, options)
        end
      end
    end
  end
  end
end
