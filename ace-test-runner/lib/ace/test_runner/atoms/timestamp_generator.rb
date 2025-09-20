# frozen_string_literal: true

module Ace
  module TestRunner
    module Atoms
      # Generates consistent timestamps for reports
      class TimestampGenerator
        DEFAULT_FORMAT = "%Y-%m-%d-%H-%M-%S"
        ISO_FORMAT = "%Y-%m-%dT%H:%M:%S"

        def initialize(format: DEFAULT_FORMAT)
          @format = format
        end

        def generate(time = Time.now)
          time.strftime(@format)
        end

        def iso_timestamp(time = Time.now)
          time.strftime(ISO_FORMAT)
        end

        def directory_name(time = Time.now)
          generate(time)
        end

        def filename_timestamp(time = Time.now, extension = nil)
          base = generate(time)
          extension ? "#{base}#{extension}" : base
        end

        def parse(timestamp_str, format = @format)
          Time.strptime(timestamp_str, format)
        rescue ArgumentError
          nil
        end

        def elapsed_time(start_time, end_time = Time.now)
          duration = end_time - start_time
          format_duration(duration)
        end

        private

        def format_duration(seconds)
          if seconds < 1
            "#{(seconds * 1000).round(2)}ms"
          elsif seconds < 60
            "#{seconds.round(2)}s"
          else
            minutes = (seconds / 60).floor
            remaining_seconds = (seconds % 60).round
            "#{minutes}m #{remaining_seconds}s"
          end
        end
      end
    end
  end
end