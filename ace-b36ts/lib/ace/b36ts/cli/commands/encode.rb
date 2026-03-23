# frozen_string_literal: true

require_relative "../../commands/encode_command"

module Ace
  module B36ts
    module CLI
      module Commands
        # Encode a timestamp to a 6-character compact ID
        class Encode < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Encode a timestamp to a compact ID (2-8 characters)"

          argument :timestamp, required: false, desc: "Timestamp to encode (ISO, readable, 'now', or empty for current time)"
          option :format, type: :string, aliases: ["-f"], desc: "Output format: 2sec (default), month, week, day, 40min, 50ms, ms"
          option :count, type: :integer, aliases: ["-n"], desc: "Generate N sequential IDs starting from timestamp"
          option :split, type: :string, desc: "Split levels for hierarchical output (month,week,day,block)"
          option :path_only, type: :boolean, desc: "Output only the split path"
          option :json, type: :boolean, desc: "Output split data as JSON (works with --split or --count)"
          option :year_zero, type: :integer, aliases: ["-y"], desc: "Base year for encoding (default: 2000)"
          option :quiet, type: :boolean, aliases: ["-q"], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: ["-v"], desc: "Show verbose output"
          option :debug, type: :boolean, aliases: ["-d"], desc: "Show debug output"

          example [
            "'2025-01-06 12:30:00'    # Encode readable timestamp",
            "now                       # Encode current time",
            "--format day '2025-01-06' # Encode to day format",
            "--format month now        # Encode to month format",
            "--format 40min now        # Encode to 40min format",
            "--format 50ms now         # Encode to 50ms format",
            "--count 10 --format ms now      # Generate 10 sequential ms-precision IDs",
            "-n 5 --format day now           # Generate 5 consecutive day IDs",
            "--count 3 --format 2sec --json now  # Generate 3 IDs as JSON array",
            "--split month,week now    # Encode to hierarchical split output",
            "--split month,week now --path-only  # Output only the path",
            "--split month,day now --json        # Output JSON split data",
            "--year-zero 2025 '2025-01-06'  # Encode with custom base year"
          ]

          def call(timestamp: nil, **options)
            # Convert numeric options from strings to integers
            coerce_types(options, year_zero: :integer, count: :integer)

            Ace::B36ts::Commands::EncodeCommand.execute(timestamp, options)
          end
        end
      end
    end
  end
end
