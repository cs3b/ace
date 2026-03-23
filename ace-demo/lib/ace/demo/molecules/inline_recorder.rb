# frozen_string_literal: true

require "fileutils"
require "ace/b36ts"
require_relative "../atoms/demo_name_sanitizer"

module Ace
  module Demo
    module Molecules
      class InlineRecorder
        def initialize(
          executor: VhsExecutor.new,
          output_dir: Demo.config["output_dir"],
          vhs_bin: Demo.config["vhs_bin"]
        )
          @executor = executor
          @output_dir = output_dir || ".ace-local/demo"
          @vhs_bin = vhs_bin || "vhs"
        end

        def record(name:, commands:, format: "gif", output: nil, description: nil, tags: nil,
          font_size: 16, width: 960, height: 480, timeout: "2s")
          safe_name = Atoms::DemoNameSanitizer.sanitize(name)
          session_id = generate_session_id
          session_dir = File.expand_path(File.join(@output_dir, session_id), Dir.pwd)
          tape_path = File.join(session_dir, "#{safe_name}.tape")
          output_path = output ? File.expand_path(output, Dir.pwd) : File.join(session_dir, "#{safe_name}.#{format}")

          content = Atoms::TapeContentGenerator.generate(
            name: safe_name,
            commands: commands,
            description: description,
            tags: tags,
            output_path: "./#{safe_name}.#{format}",
            font_size: font_size,
            width: width,
            height: height,
            timeout: timeout
          )

          FileUtils.mkdir_p(session_dir)
          File.write(tape_path, content)

          cmd = Atoms::VhsCommandBuilder.build(
            tape_path: tape_path,
            output_path: output_path,
            vhs_bin: @vhs_bin
          )
          @executor.run(cmd)

          {output_path: output_path, tape_path: tape_path, session_dir: session_dir}
        end

        private

        def generate_session_id
          Ace::B36ts.now
        end
      end
    end
  end
end
