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
          output_dir: Demo.config["output_dir"],
          vhs_bin: Demo.config["vhs_bin"]
        )
          @resolver = resolver
          @executor = executor
          @output_dir = output_dir || ".ace-local/demo"
          @vhs_bin = vhs_bin || "vhs"
        end

        def record(tape_ref:, output: nil, format: "gif")
          raise ArgumentError, "Unsupported format: #{format}" unless SUPPORTED_FORMATS.include?(format)

          tape_path = @resolver.resolve(tape_ref)
          output_path = output || default_output_path(tape_ref, format)
          FileUtils.mkdir_p(File.dirname(output_path))

          cmd = Atoms::VhsCommandBuilder.build(
            tape_path: tape_path,
            output_path: output_path,
            vhs_bin: @vhs_bin
          )
          @executor.run(cmd)

          output_path
        end

        private

        def default_output_path(tape_ref, format)
          basename = File.basename(tape_ref, ".tape")
          File.expand_path(File.join(@output_dir, "#{basename}.#{format}"), Dir.pwd)
        end
      end
    end
  end
end
