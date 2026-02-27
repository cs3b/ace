# frozen_string_literal: true

require "fileutils"
require "open3"

module Ace
  module Sim
    module Molecules
      class FinalSynthesisExecutor
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

        def execute(run_dir:, session:, chains:)
          final_dir = File.join(run_dir, "final")
          FileUtils.mkdir_p(final_dir)

          input_path = File.join(final_dir, "input.md")
          bundle_path = File.join(final_dir, "user.bundle.md")
          prompt_path = File.join(final_dir, "user.prompt.md")
          report_path = File.join(final_dir, "suggestions.report.md")

          write_input(input_path, session: session, chains: chains)
          write_bundle(bundle_path, workflow_ref: session.synthesis_workflow)

          bundle_result = command_runner.call(["ace-bundle", bundle_path, "--output", prompt_path])
          return failure("ace-bundle failed", bundle_result, report_path) unless bundle_result[:success]

          provider = session.synthesis_provider.to_s.strip.empty? ? session.providers.first : session.synthesis_provider
          llm_result = command_runner.call(["ace-llm", provider, "--prompt", prompt_path, "--output", report_path])
          return failure("ace-llm failed", llm_result, report_path) unless llm_result[:success]

          unless valid_output?(report_path)
            return {
              "status" => "failed",
              "provider" => provider,
              "error" => "Final suggestions report missing or empty: #{report_path}",
              "output_path" => report_path
            }
          end

          {
            "status" => "ok",
            "provider" => provider,
            "input_path" => input_path,
            "bundle_path" => bundle_path,
            "prompt_path" => prompt_path,
            "output_path" => report_path
          }
        rescue StandardError => e
          {
            "status" => "failed",
            "error" => e.message,
            "output_path" => report_path
          }
        end

        private

        attr_reader :command_runner

        def write_input(path, session:, chains:)
          content = +"# ace-sim final synthesis input\n\n"
          content << "Source file: #{session.source}\n\n"
          content << "## Chain outputs\n\n"

          chains.each do |chain|
            content << "### Chain #{chain['provider']}##{chain['iteration']} (#{chain['status']})\n\n"
            chain.fetch("steps", []).each do |step|
              content << "#### Step #{step['step']} (#{step['status']})\n\n"
              if step["output_path"] && File.exist?(step["output_path"])
                content << "```markdown\n"
                content << File.read(step["output_path"])
                content << "\n```\n\n"
              else
                content << "_No output captured_\n\n"
              end
            end
          end

          File.write(path, content)
        end

        def write_bundle(path, workflow_ref:)
          content = <<~MD
            ---
            description: "ace-sim final suggestions synthesis bundle"
            bundle:
              embed_document_source: true
              sections:
                synthesis_workflow:
                  files:
                    - #{workflow_ref}
                simulation_outputs:
                  files:
                    - ./input.md
            ---

            # Goal

            Produce a final suggestions report from the simulation outputs.

            ## Instructions

            1. Read `<simulation_outputs>` completely.
            2. Follow `<synthesis_workflow>` for evaluation structure.
            3. Return markdown with:
               - what to update
               - what needs precision
               - prioritized next actions
          MD

          File.write(path, content)
        end

        def valid_output?(path)
          return false unless File.exist?(path)

          !File.read(path).strip.empty?
        end

        def failure(prefix, result, report_path)
          detail = result[:stderr].to_s.strip
          detail = result[:stdout].to_s.strip if detail.empty?
          detail = "command failed" if detail.empty?

          {
            "status" => "failed",
            "error" => "#{prefix}: #{detail}",
            "output_path" => report_path
          }
        end
      end
    end
  end
end
