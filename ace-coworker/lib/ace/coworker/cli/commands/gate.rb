# frozen_string_literal: true

require "json"

module Ace
  module Coworker
    module CLI
      module Commands
        class Gate < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Evaluate the pre-merge integration gate and print :ready or :blocked with reasons"

          example [
            "gate --candidate-head 1a2b3c4 --review-head 1a2b3c4 --review-verdict accept \\",
            "     --tests executed,passed --dep 8xg.t.sbz.4.2=integrated",
            "gate --candidate-head 1a2b3c4 --review-head 0d0e0f --review-verdict accept \\",
            "     --tests executed,passed --dep 8xg.t.sbz.4.2=missing"
          ]

          option :candidate_head, desc: "Current head of the candidate branch (omit when unknown)"
          option :review_head, desc: "Candidate head the review verdict covers"
          option :review_verdict, required: true, desc: "Independent review verdict (accept, continue, escalate)"
          option :tests, type: :array, default: [], desc: "Test evidence flags: executed, passed"
          option :dep, type: :array, default: [], desc: "Dependency states as name=integrated|missing pairs"
          option :format, default: "table", desc: "Output format (table, json)"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress non-essential output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Show debug output"

          def call(candidate_head: nil, review_head: nil, review_verdict: nil, tests: [], dep: [],
                   format: "table", **options)
            result = Atoms::IntegrationGate.evaluate(
              "candidate_head" => candidate_head.to_s,
              "review" => {"head" => review_head.to_s, "verdict" => review_verdict.to_s},
              "tests" => tests_flags(tests),
              "dependencies" => dependency_states(dep)
            )

            return if options[:quiet]

            if format == "json"
              puts JSON.pretty_generate(json_payload(result))
            else
              puts render(result)
            end
          end

          private

          def tests_flags(tests)
            flags = Array(tests).flat_map { |value| value.to_s.split(",") }.map { |f| f.strip.downcase }.reject(&:empty?)
            {"executed" => flags.include?("executed"), "passed" => flags.include?("passed")}
          end

          def dependency_states(dep)
            Array(dep).each_with_object({}) do |pair, states|
              name, state = pair.to_s.split("=", 2)
              name = name.to_s.strip
              raise Ace::Support::Cli::Error, "invalid --dep '#{pair}' (expected name=integrated|missing)" if name.empty?

              states[name] = state.to_s.strip.downcase == "integrated"
            end
          end

          def json_payload(result)
            {
              "verdict" => result[:verdict].to_s,
              "reasons" => result[:reasons],
              "failed_checks" => result[:failed_checks].map(&:to_s)
            }
          end

          def render(result)
            lines = ["Coworker integration gate"]
            lines << "  verdict:        #{result[:verdict]}"
            result[:reasons].each { |reason| lines << "  blocked:        #{reason}" }
            lines.join("\n")
          end
        end
      end
    end
  end
end
