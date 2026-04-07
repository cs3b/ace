# frozen_string_literal: true

require "fileutils"
require "json"

module Ace
  module Demo
    module Organisms
      class DemoRecorder
        SUPPORTED_FORMATS = %w[gif webm].freeze

        def initialize(
          resolver: Molecules::TapeResolver.new,
          executor: Molecules::VhsExecutor.new,
          asciinema_executor: Molecules::AsciinemaExecutor.new,
          agg_executor: Molecules::AggExecutor.new,
          cast_verifier: Molecules::CastVerifier.new,
          yaml_parser: Atoms::DemoYamlParser,
          yaml_compiler: Atoms::VhsTapeCompiler,
          asciinema_tape_compiler: Atoms::AsciinemaTapeCompiler,
          media_retimer: Molecules::MediaRetimer.new,
          sandbox_builder: Molecules::DemoSandboxBuilder.new,
          teardown_executor: Molecules::DemoTeardownExecutor.new,
          output_dir: Demo.config["output_dir"],
          vhs_bin: Demo.config["vhs_bin"],
          asciinema_bin: Demo.config["asciinema_bin"],
          agg_bin: Demo.config["agg_bin"],
          agg_font_family: Demo.config["agg_font_family"],
          default_backend: Demo.config.dig("record", "backend")
        )
          @resolver = resolver
          @executor = executor
          @asciinema_executor = asciinema_executor
          @agg_executor = agg_executor
          @cast_verifier = cast_verifier
          @yaml_parser = yaml_parser
          @yaml_compiler = yaml_compiler
          @asciinema_tape_compiler = asciinema_tape_compiler
          @media_retimer = media_retimer
          @sandbox_builder = sandbox_builder
          @teardown_executor = teardown_executor
          @output_dir = output_dir || ".ace-local/demo"
          @vhs_bin = vhs_bin || "vhs"
          @asciinema_bin = asciinema_bin || "asciinema"
          @agg_bin = agg_bin || "agg"
          @agg_font_family = agg_font_family
          @default_backend = default_backend || "asciinema"
        end

        def record(tape_ref:, output: nil, format: nil, playback_speed: nil, retime_output: nil, yaml_spec: nil, backend: nil)
          normalized_format = Atoms::RecordOptionValidator.normalize_format(
            format,
            supported_formats: SUPPORTED_FORMATS
          )
          normalized_backend = Atoms::RecordOptionValidator.normalize_backend(backend)

          tape_path = @resolver.resolve(tape_ref)
          return record_yaml_tape(
            tape_path: tape_path,
            output: output,
            format: normalized_format,
            playback_speed: playback_speed,
            retime_output: retime_output,
            yaml_spec: yaml_spec,
            backend: normalized_backend
          ) if yaml_tape?(tape_path)

          Atoms::RecordOptionValidator.validate_raw_tape_backend!(backend: normalized_backend)
          record_tape_file(tape_path: tape_path, output: output, format: normalized_format || "gif")
        end

        private

        def record_tape_file(tape_path:, output:, format:)
          output_path = File.expand_path(output || default_output_path(tape_path, format), Dir.pwd)
          FileUtils.mkdir_p(File.dirname(output_path))

          cmd = Atoms::VhsCommandBuilder.build(tape_path: tape_path, output_path: output_path, vhs_bin: @vhs_bin)
          @executor.run(cmd)
          Models::RecordingResult.new(
            backend: "vhs",
            visual_path: output_path
          )
        end

        def record_yaml_tape(tape_path:, output:, format:, playback_speed:, retime_output:, yaml_spec:, backend:)
          plan = Atoms::YamlRecordPlanner.plan(
            tape_path: tape_path,
            output: output,
            format: format,
            playback_speed: playback_speed,
            retime_output: retime_output,
            yaml_spec: yaml_spec,
            yaml_parser: @yaml_parser,
            supported_formats: SUPPORTED_FORMATS,
            default_output_path_builder: ->(selected_format) { default_output_path(tape_path, selected_format) },
            backend: backend,
            default_backend: @default_backend
          )
          selected_backend = plan[:backend]
          return record_yaml_tape_asciinema(tape_path: tape_path, plan: plan) if selected_backend == "asciinema"

          record_yaml_tape_vhs(tape_path: tape_path, plan: plan)
        end

        def record_yaml_tape_vhs(tape_path:, plan:)
          spec = plan[:spec]
          selected_speed = plan[:speed]
          raw_output_path = plan[:raw_output_path]
          retime_output_path = plan[:retime_output_path]
          FileUtils.mkdir_p(File.dirname(raw_output_path))
          FileUtils.mkdir_p(File.dirname(retime_output_path)) if retime_output_path

          sandbox = @sandbox_builder.build(source_tape_path: tape_path, setup_steps: spec["setup"] || [])
          begin
            compiled_tape_path = File.join(
              sandbox[:path],
              "#{File.basename(tape_path).sub(/\.ya?ml\z/, "")}.compiled.tape"
            )
            tape_output = "./#{File.basename(raw_output_path)}"
            inject_sandbox_env(spec, sandbox[:path])
            tape_content = @yaml_compiler.compile(spec: spec, output_path: tape_output)
            File.write(compiled_tape_path, tape_content)

            cmd = Atoms::VhsCommandBuilder.build(
              tape_path: compiled_tape_path,
              output_path: raw_output_path,
              vhs_bin: @vhs_bin
            )
            @executor.run(cmd, chdir: sandbox[:path])
            return Models::RecordingResult.new(backend: "vhs", visual_path: raw_output_path) unless selected_speed

            retimed = @media_retimer.retime(
              input_path: raw_output_path,
              speed: selected_speed[:label],
              output_path: retime_output_path
            )
            Models::RecordingResult.new(backend: "vhs", visual_path: retimed[:output_path])
          ensure
            @teardown_executor.execute(steps: spec["teardown"] || [], sandbox_path: sandbox[:path]) if sandbox
          end
        end

        def record_yaml_tape_asciinema(tape_path:, plan:)
          spec = plan[:spec]
          settings = spec["settings"] || {}
          selected_speed = plan[:speed]
          raw_output_path = plan[:raw_output_path]
          retime_output_path = plan[:retime_output_path]
          cast_output_path = raw_output_path.sub(/\.[a-z0-9]+\z/i, ".cast")

          FileUtils.mkdir_p(File.dirname(cast_output_path))
          FileUtils.mkdir_p(File.dirname(raw_output_path))
          FileUtils.mkdir_p(File.dirname(retime_output_path)) if retime_output_path

          sandbox = @sandbox_builder.build(source_tape_path: tape_path, setup_steps: spec["setup"] || [])
          begin
            inject_sandbox_env(spec, sandbox[:path])
            env = (settings["env"] || {}).transform_values(&:to_s)
            env["PS1"] ||= "$ "
            commands = interactive_commands_for(spec: spec)

            record_cmd = Atoms::AsciinemaCommandBuilder.build(
              output_path: cast_output_path,
              shell_command: "bash --noprofile --norc -i",
              tty_size: settings.fetch("tty_size", "80x24"),
              asciinema_bin: @asciinema_bin
            )
            @asciinema_executor.run_interactive(record_cmd, commands: commands, env: env, chdir: sandbox[:path])
            normalize_cast_terminal_size(cast_output_path, tty_size: settings.fetch("tty_size", "80x24"))

            convert_cmd = Atoms::AggCommandBuilder.build(
              input_path: cast_output_path,
              output_path: raw_output_path,
              font_size: settings["font_size"],
              font_family: settings["agg_font_family"] || @agg_font_family,
              agg_bin: @agg_bin
            )
            @agg_executor.run(convert_cmd, chdir: sandbox[:path])
            verification = @cast_verifier.verify(
              cast_path: cast_output_path,
              tape_spec: spec,
              sandbox_path: sandbox[:path],
              env: env.merge("PROJECT_ROOT_PATH" => sandbox[:path])
            )

            visual_path =
              if selected_speed
                retimed = @media_retimer.retime(
                  input_path: raw_output_path,
                  speed: selected_speed[:label],
                  output_path: retime_output_path
                )
                retimed[:output_path]
              else
                raw_output_path
              end

            Models::RecordingResult.new(
              backend: "asciinema",
              cast_path: cast_output_path,
              visual_path: visual_path,
              verification: verification
            )
          ensure
            @teardown_executor.execute(steps: spec["teardown"] || [], sandbox_path: sandbox[:path]) if sandbox
          end
        end

        def inject_sandbox_env(spec, sandbox_path)
          settings = spec["settings"] ||= {}
          env = settings["env"] ||= {}
          env["PROJECT_ROOT_PATH"] ||= sandbox_path
        end

        def interactive_commands_for(spec:)
          spec.fetch("scenes", []).flat_map do |scene|
            scene.fetch("commands", []).map do |command|
              {
                command: command.fetch("type"),
                sleep: sleep_seconds(command["sleep"] || "2s")
              }
            end
          end
        end

        def sleep_seconds(value)
          text = value.to_s.strip
          match = text.match(/\A(?<number>\d+(?:\.\d+)?)(?<unit>ms|s|m|h)?\z/)
          raise ArgumentError, "sleep must be a numeric duration (e.g. 0.5s, 250ms, 2)" unless match

          number = match[:number].to_f
          case match[:unit]
          when "ms" then number / 1000.0
          when "m" then number * 60.0
          when "h" then number * 3600.0
          else number
          end
        end

        def normalize_cast_terminal_size(cast_path, tty_size:)
          cols_text, rows_text = tty_size.to_s.split("x", 2)
          cols = cols_text.to_i
          rows = rows_text.to_i
          return unless cols.positive? && rows.positive?
          return unless File.file?(cast_path)

          lines = File.readlines(cast_path)
          return if lines.empty?

          header = JSON.parse(lines.first)
          term = header["term"] ||= {}
          return unless term["cols"].to_i <= 0 || term["rows"].to_i <= 0

          term["cols"] = cols
          term["rows"] = rows
          lines[0] = "#{JSON.generate(header)}\n"
          File.write(cast_path, lines.join)
        rescue JSON::ParserError
          nil
        end

        def default_output_path(tape_ref, format)
          basename = File.basename(tape_ref).sub(/\.tape\.ya?ml\z/, "").sub(/\.tape\z/, "").sub(/\.ya?ml\z/, "")
          File.expand_path(File.join(@output_dir, "#{basename}.#{format}"), Dir.pwd)
        end

        def yaml_tape?(path)
          path.end_with?(".tape.yml", ".tape.yaml")
        end
      end
    end
  end
end
