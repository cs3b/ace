# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"

module Ace
  module Demo
    module CLI
      module Commands
        class Retime < Ace::Support::Cli::Command
          include Ace::Core::CLI::Base

          desc "Post-process an existing recording into a faster playback artifact"

          argument :file, required: true, desc: "Input media file path (gif|mp4|webm)"

          option :playback_speed, type: :string, desc: "Playback speed: 1x|2x|4x|8x"
          option :output, type: :string, aliases: ["-o"], desc: "Output file path"
          option :dry_run, type: :boolean, aliases: ["-n"], default: false, desc: "Preview without writing output"

          def call(file:, **options)
            raise Ace::Core::CLI::Error, "Playback speed is required" unless options[:playback_speed]

            retimer = Molecules::MediaRetimer.new
            result = retimer.retime(
              input_path: File.expand_path(file, Dir.pwd),
              speed: options[:playback_speed],
              output_path: options[:output] && File.expand_path(options[:output], Dir.pwd),
              dry_run: options[:dry_run]
            )

            if result[:dry_run]
              puts "[dry-run] Would retime: #{result[:input_path]}"
              puts "[dry-run] Speed: #{result[:speed]}"
              puts "[dry-run] Output: #{result[:output_path]}"
            else
              puts "Retimed: #{result[:output_path]} (#{result[:speed]})"
            end
          rescue FfmpegNotFoundError, MediaRetimeError, ArgumentError => e
            raise Ace::Core::CLI::Error, e.message
          end
        end
      end
    end
  end
end
