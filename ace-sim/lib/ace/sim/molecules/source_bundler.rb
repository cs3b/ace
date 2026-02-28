# frozen_string_literal: true

require "open3"
require "fileutils"

module Ace
  module Sim
    module Molecules
      class SourceBundler
        class CommandRunner
          def call(args)
            stdout, stderr, status = Open3.capture3(*args)
            {
              success: status.success?,
              stdout: stdout,
              stderr: stderr,
              exit_code: status.exitstatus
            }
          end
        end

        def initialize(command_runner: nil)
          @command_runner = command_runner || CommandRunner.new
        end

        def bundle(sources:, output_path:)
          raise Ace::Sim::ValidationError, "source cannot be empty" if sources.nil? || sources.empty?

          run_dir = File.dirname(output_path)
          bundle_path = File.join(run_dir, "input.bundle.md")
          content_path = File.join(run_dir, "input.md")

          FileUtils.mkdir_p(run_dir)
          File.write(bundle_path, build_bundle_yaml(sources))

          result = command_runner.call(["ace-bundle", bundle_path, "--output", content_path])
          return content_path if result[:success]

          detail = result[:stderr].to_s.strip
          detail = result[:stdout].to_s.strip if detail.empty?
          detail = "command failed" if detail.empty?
          raise Ace::Sim::ValidationError, "ace-bundle failed: #{detail}"
        end

        private

        attr_reader :command_runner

        def build_bundle_yaml(sources)
          files_yaml = sources.map { |s| "      - #{s}" }.join("\n")
          <<~YAML
            ---
            description: "ace-sim source bundle"
            bundle:
              embed_document_source: true
              sections:
                source:
                  files:
            #{files_yaml}
            ---

            # Source Files

            Combined input from #{sources.length} source(s).
          YAML
        end
      end
    end
  end
end
