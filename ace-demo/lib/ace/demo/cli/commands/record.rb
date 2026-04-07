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
          option :format, type: :string, aliases: ["-f"], desc: "Output format: gif|webm"
          option :backend, type: :string, aliases: ["-b"], desc: "Backend override: asciinema|vhs"
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
            explicit_format = Atoms::RecordOptionValidator.normalize_format(
              options[:format],
              supported_formats: Organisms::DemoRecorder::SUPPORTED_FORMATS
            )
            backend = normalize_backend_option(options[:backend])
            options = options.dup
            options.delete(:format)
            options.delete(:backend)

            commands = collect_commands(args)

            if commands
              Atoms::RecordOptionValidator.validate_raw_tape_backend!(backend: backend)
              record_inline(name: tape, commands: commands, format: explicit_format || "gif", **options)
            else
              record_tape(tape: tape, format: explicit_format, backend: backend, **options)
            end
          rescue TapeNotFoundError, VhsNotFoundError, VhsExecutionError, FfmpegNotFoundError, MediaRetimeError,
            PrNotFoundError, GhAuthenticationError, GhUploadError, GhCommentError, GhCommandError,
            AsciinemaNotFoundError, AsciinemaExecutionError, AggNotFoundError, AggExecutionError,
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

          def record_tape(tape:, format:, backend:, **options)
            if options[:dry_run]
              context = build_tape_record_context(
                tape: tape,
                format: format,
                backend: backend,
                output: options[:output],
                playback_speed: options[:playback_speed],
                allow_missing_tape: true
              )
              puts "[dry-run] Would record tape: #{tape} (format: #{context[:format]})"
              puts "[dry-run] Would write recording to: #{context[:record_preview_output]}" if context[:record_preview_output]
              if context[:speed]
                puts "[dry-run] Would retime recording to #{context[:speed][:label]}: #{context[:retime_output]}"
              end
              preview_attach(context[:format], options, speed: context[:speed])
              return
            end

            context = build_tape_record_context(
              tape: tape,
              format: format,
              backend: backend,
              output: options[:output],
              playback_speed: options[:playback_speed],
              allow_missing_tape: false
            )

            recorder = Organisms::DemoRecorder.new
            record_kwargs = {
              tape_ref: tape,
              output: context[:record_output],
              format: context[:yaml] ? context[:format] : format,
              playback_speed: context[:yaml] ? context[:speed]&.dig(:label) : nil,
              retime_output: context[:yaml] ? context[:retime_output_override] : nil
            }
            record_kwargs[:yaml_spec] = context[:spec] if context[:yaml]
            record_kwargs[:backend] = context[:backend] if context[:yaml] && context[:backend]
            recording = normalize_recording_result(recorder.record(**record_kwargs))
            puts "Recorded backend: #{recording.backend}"
            puts "Cast: #{recording.cast_path}" if recording.cast_path
            ensure_successful_verification!(recording)
            puts "Recorded: #{recording.visual_path}"

            attach_path = recording.visual_path
            if context[:speed] && !context[:yaml]
              retimed = retime_recording(recording.visual_path, context[:speed], output_path: context[:retime_output])
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

          def resolve_playback_speed(options, tape_speed: nil)
            configured = Demo.config.dig("record", "postprocess", "playback_speed")
            selected = options[:playback_speed] || tape_speed || configured
            Atoms::PlaybackSpeedParser.parse(selected)
          end

          def normalize_backend_option(value)
            Atoms::RecordOptionValidator.normalize_backend(value)
          end

          def retime_recording(input_path, speed, output_path: nil)
            Molecules::MediaRetimer.new.retime(
              input_path: input_path,
              speed: speed[:label],
              output_path: output_path
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

          def build_tape_record_context(tape:, format:, backend:, output:, playback_speed:, allow_missing_tape:)
            resolved_tape = resolve_tape_ref(tape, allow_missing_tape: allow_missing_tape)
            spec = load_yaml_spec(resolved_tape)
            yaml = !spec.nil?
            if yaml
              configured_speed = Demo.config.dig("record", "postprocess", "playback_speed")
              selected_speed_setting = playback_speed || spec.dig("settings", "playback_speed") || configured_speed
              yaml_plan = Atoms::YamlRecordPlanner.plan(
                tape_path: resolved_tape,
                output: output,
                format: format,
                playback_speed: selected_speed_setting,
                retime_output: nil,
                yaml_spec: spec,
                yaml_parser: Atoms::DemoYamlParser,
                supported_formats: Organisms::DemoRecorder::SUPPORTED_FORMATS,
                default_output_path_builder: ->(selected_format) { default_output_for_tape(resolved_tape, selected_format) },
                backend: backend,
                default_backend: Demo.config.dig("record", "backend") || "asciinema"
              )
              selected_backend = yaml_plan[:backend]
              selected_format = yaml_plan[:format]
              selected_speed = yaml_plan[:speed]
              selected_output = yaml_plan[:selected_output]
              combined_yaml = selected_speed && selected_output
              record_output = combined_yaml ? nil : selected_output
              record_preview_output = yaml_plan[:raw_output_path]
              retime_output =
                if selected_speed
                  yaml_plan[:retime_output_path] || retime_output_path(record_preview_output, selected_speed)
                end
              retime_output_override = combined_yaml ? selected_output : nil
            else
              if backend && backend != "vhs"
                raise ArgumentError, "Raw .tape recordings support backend 'vhs' only"
              end
              selected_format = (format || "gif").to_s.downcase
              selected_output = output
              selected_speed = resolve_playback_speed({playback_speed: playback_speed})
              selected_backend = nil
              record_output = selected_output
              record_preview_output = record_output || default_output_for_tape(resolved_tape || tape, selected_format)
              retime_output = selected_speed ? retime_output_path(record_preview_output, selected_speed) : nil
              retime_output_override = nil
            end

            {
              yaml: yaml,
              spec: spec,
              backend: selected_backend,
              format: selected_format,
              speed: selected_speed,
              record_output: record_output,
              record_preview_output: record_preview_output,
              retime_output: retime_output,
              retime_output_override: retime_output_override
            }
          end

          def normalize_recording_result(result)
            return result if result.respond_to?(:visual_path) && result.respond_to?(:backend)

            Models::RecordingResult.new(
              backend: "vhs",
              visual_path: result.to_s
            )
          end

          def resolve_tape_ref(tape, allow_missing_tape:)
            Molecules::TapeResolver.new.resolve(tape)
          rescue TapeNotFoundError
            raise unless allow_missing_tape

            tape
          end

          def load_yaml_spec(resolved_tape)
            return nil unless yaml_tape_ref?(resolved_tape)
            return nil unless File.exist?(resolved_tape)

            Atoms::DemoYamlParser.parse_file(resolved_tape)
          end

          def retime_output_path(output_path, speed)
            ext = File.extname(output_path)
            base = output_path.sub(/#{Regexp.escape(ext)}\z/, "")
            "#{base}-#{speed[:label]}#{ext}"
          end

          def print_verification(verification)
            puts "Verification: #{verification.status}"
            return if verification.success?

            puts "Classification: #{verification.classification}" if verification.classification
            puts "Summary: #{verification.summary}" if verification.summary
            missing = verification.commands_missing
            puts "Missing commands: #{missing.join(', ')}" unless missing.empty?
            missing_vars = verification.details&.fetch(:missing_vars, [])
            puts "Missing vars: #{missing_vars.join(', ')}" unless missing_vars.empty?
          end

          def ensure_successful_verification!(recording)
            verification = recording.verification
            return unless verification

            print_verification(verification)
            return if verification.success?

            report_path = Molecules::VerificationReportWriter.new.write(
              demo_name: verification_demo_name(recording),
              verification: verification
            )
            puts "Verification report: #{report_path}"
            raise Ace::Support::Cli::Error, "Demo verification failed (#{verification.classification}). Report: #{report_path}"
          end

          def verification_demo_name(recording)
            source = recording.cast_path || recording.visual_path || "demo"
            File.basename(source, File.extname(source))
          end
        end
      end
    end
  end
end
