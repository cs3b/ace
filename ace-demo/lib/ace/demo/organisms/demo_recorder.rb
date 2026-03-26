# frozen_string_literal: true

require "fileutils"

module Ace
  module Demo
    module Organisms
      class DemoRecorder
        SUPPORTED_FORMATS = %w[gif mp4 webm].freeze

        def initialize(
          resolver: Molecules::TapeResolver.new,
          executor: Molecules::VhsExecutor.new,
          yaml_parser: Atoms::DemoYamlParser,
          yaml_compiler: Atoms::VhsTapeCompiler,
          media_retimer: Molecules::MediaRetimer.new,
          sandbox_builder: Molecules::DemoSandboxBuilder.new,
          teardown_executor: Molecules::DemoTeardownExecutor.new,
          output_dir: Demo.config["output_dir"],
          vhs_bin: Demo.config["vhs_bin"]
        )
          @resolver = resolver
          @executor = executor
          @yaml_parser = yaml_parser
          @yaml_compiler = yaml_compiler
          @media_retimer = media_retimer
          @sandbox_builder = sandbox_builder
          @teardown_executor = teardown_executor
          @output_dir = output_dir || ".ace-local/demo"
          @vhs_bin = vhs_bin || "vhs"
        end

        def record(tape_ref:, output: nil, format: nil, playback_speed: nil, retime_output: nil, yaml_spec: nil)
          normalized_format = format&.to_s&.downcase
          if normalized_format && !SUPPORTED_FORMATS.include?(normalized_format)
            raise ArgumentError, "Unsupported format: #{normalized_format}"
          end

          tape_path = @resolver.resolve(tape_ref)
          return record_yaml_tape(
            tape_path: tape_path,
            output: output,
            format: normalized_format,
            playback_speed: playback_speed,
            retime_output: retime_output,
            yaml_spec: yaml_spec
          ) if yaml_tape?(tape_path)

          record_tape_file(tape_path: tape_path, output: output, format: normalized_format || "gif")
        end

        private

        def record_tape_file(tape_path:, output:, format:)
          output_path = File.expand_path(output || default_output_path(tape_path, format), Dir.pwd)
          FileUtils.mkdir_p(File.dirname(output_path))

          cmd = Atoms::VhsCommandBuilder.build(tape_path: tape_path, output_path: output_path, vhs_bin: @vhs_bin)
          @executor.run(cmd)
          output_path
        end

        def record_yaml_tape(tape_path:, output:, format:, playback_speed:, retime_output:, yaml_spec:)
          plan = Atoms::YamlRecordPlanner.plan(
            tape_path: tape_path,
            output: output,
            format: format,
            playback_speed: playback_speed,
            retime_output: retime_output,
            yaml_spec: yaml_spec,
            yaml_parser: @yaml_parser,
            supported_formats: SUPPORTED_FORMATS,
            default_output_path_builder: ->(selected_format) { default_output_path(tape_path, selected_format) }
          )
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
            return raw_output_path unless selected_speed

            retimed = @media_retimer.retime(
              input_path: raw_output_path,
              speed: selected_speed[:label],
              output_path: retime_output_path
            )
            retimed[:output_path]
          ensure
            @teardown_executor.execute(steps: spec["teardown"] || [], sandbox_path: sandbox[:path]) if sandbox
          end
        end

        def inject_sandbox_env(spec, sandbox_path)
          settings = spec["settings"] ||= {}
          env = settings["env"] ||= {}
          env["PROJECT_ROOT_PATH"] ||= sandbox_path
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
