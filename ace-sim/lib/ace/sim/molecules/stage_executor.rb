# frozen_string_literal: true

require "fileutils"

module Ace
  module Sim
    module Molecules
      class StageExecutor
        class CommandRunner
          def call(args)
            command = Ace::Core::Atoms::CommandExecutor.build_command(args[0], *args[1..])
            result = Ace::Core::Atoms::CommandExecutor.execute(command)
            {
              success: result[:success],
              stdout: result[:stdout].to_s,
              stderr: result[:stderr].to_s,
              exit_code: result[:exit_code]
            }
          end
        end

        def initialize(command_runner: nil)
          @command_runner = command_runner || CommandRunner.new
        end

        def execute(step:, provider:, iteration:, step_dir:, step_bundle_path:, input_source_path:)
          input_path = File.join(step_dir, "input.md")
          bundle_path = File.join(step_dir, "user.bundle.md")
          prompt_path = File.join(step_dir, "user.prompt.md")
          output_path = File.join(step_dir, "output.md")

          FileUtils.cp(input_source_path, input_path)
          FileUtils.cp(step_bundle_path, bundle_path)

          bundle_result = command_runner.call(["ace-bundle", bundle_path, "--output", prompt_path])
          return failure(step, provider, iteration, output_path, "ace-bundle failed", bundle_result) unless bundle_result[:success]

          llm_result = command_runner.call(["ace-llm", provider, "--prompt", prompt_path, "--output", output_path])
          return failure(step, provider, iteration, output_path, "ace-llm failed", llm_result) unless llm_result[:success]

          unless valid_output?(output_path)
            return {
              "step" => step,
              "provider" => provider,
              "iteration" => iteration,
              "status" => "failed",
              "input_path" => input_path,
              "bundle_path" => bundle_path,
              "prompt_path" => prompt_path,
              "output_path" => output_path,
              "error" => "Step output missing or empty: #{output_path}"
            }
          end

          {
            "step" => step,
            "provider" => provider,
            "iteration" => iteration,
            "status" => "ok",
            "input_path" => input_path,
            "bundle_path" => bundle_path,
            "prompt_path" => prompt_path,
            "output_path" => output_path
          }
        rescue StandardError => e
          {
            "step" => step,
            "provider" => provider,
            "iteration" => iteration,
            "status" => "failed",
            "input_path" => input_path,
            "bundle_path" => bundle_path,
            "prompt_path" => prompt_path,
            "output_path" => output_path,
            "error" => e.message
          }
        end

        private

        attr_reader :command_runner

        def valid_output?(output_path)
          return false unless File.exist?(output_path)

          !File.read(output_path).strip.empty?
        end

        def failure(step, provider, iteration, output_path, prefix, result)
          detail = result[:stderr].to_s.strip
          detail = result[:stdout].to_s.strip if detail.empty?
          detail = "command failed" if detail.empty?

          {
            "step" => step,
            "provider" => provider,
            "iteration" => iteration,
            "status" => "failed",
            "output_path" => output_path,
            "error" => "#{prefix}: #{detail}"
          }
        end
      end
    end
  end
end
