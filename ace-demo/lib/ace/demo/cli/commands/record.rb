# frozen_string_literal: true

require "dry/cli"
require "ace/core"

module Ace
  module Demo
    module CLI
      module Commands
        class Record < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc "Record terminal demo from VHS tape"

          argument :tape, required: true, desc: "Tape file path, preset name, or inline demo name (with --)"

          option :output, type: :string, aliases: ["-o"], desc: "Output file path"
          option :format, type: :string, aliases: ["-f"], desc: "Output format: gif|mp4|webm"
          option :pr, type: :string, desc: "PR number"
          option :dry_run, type: :boolean, aliases: ["-n"], default: false, desc: "Preview without recording"
          option :timeout, type: :string, aliases: ["-t"], default: "2s", desc: "Wait time after each command (inline mode)"
          option :desc, type: :string, aliases: ["-D"], desc: "Description metadata (inline mode)"
          option :tags, type: :string, aliases: ["-T"], desc: "Comma-separated tags (inline mode)"
          option :width, type: :integer, default: 960, desc: "Terminal width in pixels (inline mode)"
          option :height, type: :integer, default: 480, desc: "Terminal height in pixels (inline mode)"
          option :font_size, type: :integer, default: 16, desc: "Font size (inline mode)"

          def call(tape:, args: [], **options)
            format = (options[:format] || "gif").downcase
            unless Organisms::DemoRecorder::SUPPORTED_FORMATS.include?(format)
              raise Ace::Core::CLI::Error, "Unsupported format: #{format}. Use gif, mp4, or webm."
            end

            commands = collect_commands(args)

            if commands
              record_inline(name: tape, commands: commands, format: format, **options)
            else
              record_tape(tape: tape, format: format, **options)
            end
          rescue TapeNotFoundError, VhsNotFoundError, VhsExecutionError, PrNotFoundError,
                 GhAuthenticationError, GhUploadError, GhCommentError, GhCommandError, ArgumentError => e
            raise Ace::Core::CLI::Error, e.message
          end

          private

          def collect_commands(args)
            commands = args.reject { |a| a.strip.empty? }

            if commands.empty? && !$stdin.tty?
              commands = $stdin.read.lines.map(&:strip).reject(&:empty?)
            end

            commands.empty? ? nil : commands
          end

          def record_inline(name:, commands:, format:, **options)
            safe_name = Atoms::DemoNameSanitizer.sanitize(name)

            if options[:dry_run]
              content = Atoms::TapeContentGenerator.generate(
                name: safe_name,
                commands: commands,
                description: options[:desc],
                tags: options[:tags],
                output_path: options[:output] || "<session>/#{safe_name}.#{format}",
                font_size: options[:font_size],
                width: options[:width],
                height: options[:height],
                timeout: options[:timeout]
              )
              puts content
              preview_attach(format, options)
              return
            end

            recorder = Molecules::InlineRecorder.new
            result = recorder.record(
              name: name,
              commands: commands,
              format: format,
              output: options[:output],
              description: options[:desc],
              tags: options[:tags],
              font_size: options[:font_size],
              width: options[:width],
              height: options[:height],
              timeout: options[:timeout]
            )
            puts "Recorded: #{result[:output_path]}"
            puts "Tape: #{result[:tape_path]}"

            attach_to_pr(result[:output_path], options)
          end

          def record_tape(tape:, format:, **options)
            if options[:dry_run]
              puts "[dry-run] Would record tape: #{tape} (format: #{format})"
              preview_attach(format, options)
              return
            end

            recorder = Organisms::DemoRecorder.new
            output_path = recorder.record(tape_ref: tape, output: options[:output], format: format)
            puts "Recorded: #{output_path}"

            attach_to_pr(output_path, options)
          end

          def attach_to_pr(output_path, options)
            return unless options[:pr]

            result = Organisms::DemoAttacher.new.attach(
              file: output_path,
              pr: options[:pr],
              dry_run: options[:dry_run]
            )
            Atoms::AttachOutputPrinter.print(result)
          end

          def preview_attach(format, options)
            return unless options[:pr]

            puts "[dry-run] Would attach #{format} recording to PR ##{options[:pr]}"
          end
        end
      end
    end
  end
end
