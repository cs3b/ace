# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"

module Ace
  module Demo
    module CLI
      module Commands
        class Record < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

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
          option :playback_speed, type: :string, desc: "Optional postprocess speed: 1x|2x|4x|8x"

          def call(tape:, args: [], **options)
            explicit_format = options[:format]&.downcase
            if explicit_format && !Organisms::DemoRecorder::SUPPORTED_FORMATS.include?(explicit_format)
              raise Ace::Support::Cli::Error, "Unsupported format: #{explicit_format}. Use gif, mp4, or webm."
            end
            options = options.dup
            options.delete(:format)

            commands = collect_commands(args)

            if commands
              record_inline(name: tape, commands: commands, format: explicit_format || "gif", **options)
            else
              record_tape(tape: tape, format: explicit_format, **options)
            end
          rescue TapeNotFoundError, VhsNotFoundError, VhsExecutionError, FfmpegNotFoundError, MediaRetimeError,
                 PrNotFoundError, GhAuthenticationError, GhUploadError, GhCommentError, GhCommandError,
                 ArgumentError, DemoYamlParseError => e
            raise Ace::Support::Cli::Error, e.message
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
            speed = resolve_playback_speed(options)
            default_output = options[:output] || "<session>/#{safe_name}.#{format}"

            if options[:dry_run]
              content = Atoms::TapeContentGenerator.generate(
                name: safe_name,
                commands: commands,
                description: options[:desc],
                tags: options[:tags],
                output_path: default_output,
                font_size: options[:font_size],
                width: options[:width],
                height: options[:height],
                timeout: options[:timeout]
              )
              puts content
              if speed
                puts "[dry-run] Would retime recording to #{speed[:label]}: #{retime_output_path(default_output, speed)}"
              end
              preview_attach(format, options, speed: speed)
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

            attach_path = result[:output_path]
            if speed
              retimed = retime_recording(result[:output_path], speed)
              puts "Retimed: #{retimed[:output_path]} (#{retimed[:speed]})"
              attach_path = retimed[:output_path]
            end

            attach_to_pr(attach_path, options)
          end

          def record_tape(tape:, format:, **options)
            speed = resolve_playback_speed(options)

            if options[:dry_run]
              preview = dry_run_preview_for_tape(tape: tape, format: format, output: options[:output])
              puts "[dry-run] Would record tape: #{tape} (format: #{preview[:format]})"
              out = preview[:output]
              if speed
                puts "[dry-run] Would retime recording to #{speed[:label]}: #{retime_output_path(out, speed)}"
              end
              preview_attach(preview[:format], options, speed: speed)
              return
            end

            recorder = Organisms::DemoRecorder.new
            output_path = recorder.record(tape_ref: tape, output: options[:output], format: format)
            puts "Recorded: #{output_path}"

            attach_path = output_path
            if speed
              retimed = retime_recording(output_path, speed)
              puts "Retimed: #{retimed[:output_path]} (#{retimed[:speed]})"
              attach_path = retimed[:output_path]
            end

            attach_to_pr(attach_path, options)
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

          def preview_attach(format, options, speed: nil)
            return unless options[:pr]

            target = speed ? "retimed #{speed[:label]} #{format}" : "#{format}"
            puts "[dry-run] Would attach #{target} recording to PR ##{options[:pr]}"
          end

          def resolve_playback_speed(options)
            configured = Demo.config.dig("record", "postprocess", "playback_speed")
            selected = options[:playback_speed] || configured
            Atoms::PlaybackSpeedParser.parse(selected)
          end

          def retime_recording(output_path, speed)
            Molecules::MediaRetimer.new.retime(
              input_path: output_path,
              speed: speed[:label]
            )
          end

          def default_output_for_tape(tape, format)
            basename = File.basename(tape)
                           .sub(/\.tape\.ya?ml\z/, "")
                           .sub(/\.tape\z/, "")
                           .sub(/\.ya?ml\z/, "")
            File.expand_path(File.join(".ace-local/demo", "#{basename}.#{format}"), Dir.pwd)
          end

          def yaml_tape_ref?(tape)
            tape.end_with?(".tape.yml", ".tape.yaml")
          end

          def dry_run_preview_for_tape(tape:, format:, output:)
            resolved_tape = tape
            begin
              resolved_tape = Molecules::TapeResolver.new.resolve(tape)
            rescue TapeNotFoundError
              # Keep user-provided reference when resolution fails in dry-run previews.
            end

            selected_format = format
            if yaml_tape_ref?(resolved_tape) && File.exist?(resolved_tape)
              spec = Atoms::DemoYamlParser.parse_file(resolved_tape)
              selected_format = spec.dig("settings", "format") if selected_format.nil?
            end

            selected_format = (selected_format || "gif").to_s.downcase
            {
              format: selected_format,
              output: output || default_output_for_tape(resolved_tape, selected_format)
            }
          end

          def retime_output_path(output_path, speed)
            ext = File.extname(output_path)
            base = output_path.sub(/#{Regexp.escape(ext)}\z/, "")
            "#{base}-#{speed[:label]}#{ext}"
          end

        end
      end
    end
  end
end
