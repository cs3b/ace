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

          source_original_path = File.join(final_dir, "source.original.md")
          input_path = File.join(final_dir, "input.md")
          bundle_path = File.join(final_dir, "user.bundle.md")
          prompt_path = File.join(final_dir, "user.prompt.md")
          raw_output_path = File.join(final_dir, "output.sequence.md")
          report_path = File.join(final_dir, "suggestions.report.md")
          revised_source_path = File.join(final_dir, "source.revised.md")

          copy_source(source_original_path, session: session)
          write_input(input_path, session: session, chains: chains)
          write_bundle(bundle_path, workflow_ref: session.synthesis_workflow)

          bundle_result = command_runner.call(["ace-bundle", bundle_path, "--output", prompt_path])
          return failure("ace-bundle failed", bundle_result, report_path: report_path, raw_output_path: raw_output_path,
                         revised_source_path: revised_source_path) unless bundle_result[:success]

          provider = session.synthesis_provider.to_s.strip.empty? ? session.providers.first : session.synthesis_provider
          llm_result = command_runner.call(["ace-llm", provider, "--prompt", prompt_path, "--output", raw_output_path])
          return failure("ace-llm failed", llm_result, report_path: report_path, raw_output_path: raw_output_path,
                         revised_source_path: revised_source_path) unless llm_result[:success]

          sequence = read_non_empty(raw_output_path)
          return missing_output_failure("Final synthesis sequence missing or empty", provider, report_path, raw_output_path,
                                        revised_source_path) if sequence.nil?

          parsed = parse_sequence(sequence)
          unless parsed
            return {
              "status" => "failed",
              "provider" => provider,
              "error" => "Final synthesis output missing required tags: <suggestions-report> and <source-revised>",
              "source_original_path" => source_original_path,
              "input_path" => input_path,
              "bundle_path" => bundle_path,
              "prompt_path" => prompt_path,
              "raw_output_path" => raw_output_path,
              "report_path" => report_path,
              "revised_source_path" => revised_source_path,
              "output_path" => report_path
            }
          end

          File.write(report_path, parsed.fetch("suggestions_report"))
          File.write(revised_source_path, parsed.fetch("source_revised"))

          {
            "status" => "ok",
            "provider" => provider,
            "source_original_path" => source_original_path,
            "input_path" => input_path,
            "bundle_path" => bundle_path,
            "prompt_path" => prompt_path,
            "raw_output_path" => raw_output_path,
            "report_path" => report_path,
            "revised_source_path" => revised_source_path,
            "output_path" => report_path
          }
        rescue StandardError => e
          {
            "status" => "failed",
            "error" => e.message,
            "report_path" => report_path,
            "raw_output_path" => raw_output_path,
            "revised_source_path" => revised_source_path,
            "output_path" => report_path
          }
        end

        private

        attr_reader :command_runner

        def copy_source(path, session:)
          FileUtils.cp(session.source, path)
        end

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
                source_original:
                  files:
                    - ./source.original.md
                simulation_outputs:
                  files:
                    - ./input.md
            ---

            # Goal

            Produce final actionable synthesis from simulation outputs and the original source.

            ## Instructions

            1. Read `<source_original>` completely.
            2. Read `<simulation_outputs>` completely.
            3. Follow `<synthesis_workflow>` for evaluation structure.
            4. Return markdown only with both required tags:
               - `<suggestions-report>...</suggestions-report>`
               - `<source-revised>...</source-revised>`
            5. The revised source must be directly usable as the next source file iteration.
          MD

          File.write(path, content)
        end

        def read_non_empty(path)
          return nil unless File.exist?(path)

          content = File.read(path)
          return nil if content.strip.empty?

          content
        end

        def parse_sequence(content)
          report = extract_tag(content, "suggestions-report")
          revised = extract_tag(content, "source-revised")
          return nil if report.nil? || revised.nil?

          {
            "suggestions_report" => report,
            "source_revised" => revised
          }
        end

        def extract_tag(content, tag_name)
          match = content.match(%r{<#{Regexp.escape(tag_name)}>(.*?)</#{Regexp.escape(tag_name)}>}m)
          return nil unless match

          extracted = match[1].to_s.strip
          return nil if extracted.empty?

          extracted + "\n"
        end

        def missing_output_failure(message, provider, report_path, raw_output_path, revised_source_path)
          {
            "status" => "failed",
            "provider" => provider,
            "error" => "#{message}: #{raw_output_path}",
            "report_path" => report_path,
            "raw_output_path" => raw_output_path,
            "revised_source_path" => revised_source_path,
            "output_path" => report_path
          }
        end

        def failure(prefix, result, report_path:, raw_output_path:, revised_source_path:)
          detail = result[:stderr].to_s.strip
          detail = result[:stdout].to_s.strip if detail.empty?
          detail = "command failed" if detail.empty?

          {
            "status" => "failed",
            "error" => "#{prefix}: #{detail}",
            "report_path" => report_path,
            "raw_output_path" => raw_output_path,
            "revised_source_path" => revised_source_path,
            "output_path" => report_path
          }
        end
      end
    end
  end
end
