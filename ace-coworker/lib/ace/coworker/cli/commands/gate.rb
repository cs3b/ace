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
            "     --tests executed,passed --tests-head 1a2b3c4 --dep 8xg.t.sbz.4.2=integrated \\",
            "     --approval-head 1a2b3c4 --approval-by lab-merge-ace --author lab-overseer",
            "gate --candidate-head 1a2b3c4 --review-head 0d0e0f --review-verdict accept \\",
            "     --tests executed,passed --tests-head 1a2b3c4 --dep 8xg.t.sbz.4.2=missing"
          ]

          option :candidate_head, desc: "Current head of the candidate branch (omit when unknown)"
          option :review_head, desc: "Candidate head the review verdict covers"
          option :review_verdict, required: true, desc: "Independent review verdict (accept, continue, escalate)"
          option :tests, type: :array, default: [], desc: "Test evidence flags: executed, passed"
          option :tests_head, desc: "Candidate head the executed test run covered (required with test evidence)"
          option :approval_head, desc: "Candidate head the formal approval covers (lanes requiring formal approval)"
          option :approval_by, desc: "Account that gave the formal approval"
          option :author, desc: "Candidate author account (the formal approver must differ)"
          option :dep, type: :array, default: [], desc: "Dependency states as name=integrated|missing pairs"
          option :format, default: "table", desc: "Output format (table, json)"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress non-essential output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Show debug output"

          def call(candidate_head: nil, review_head: nil, review_verdict: nil, tests: [],
            tests_head: nil, approval_head: nil, approval_by: nil, author: nil, dep: [],
            format: "table", **options)
            result = Atoms::IntegrationGate.evaluate(
              "candidate_head" => candidate_head.to_s,
              "review" => {"head" => review_head.to_s, "verdict" => review_verdict.to_s},
              "tests" => tests_flags(tests).merge("head" => tests_head.to_s),
              "approval" => approval_for(approval_head, approval_by),
              "author" => author.to_s,
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

          # A formal approval participates only when the lane supplied
          # approval evidence; omitted approval facts skip the check.
          def approval_for(approval_head, approval_by)
            return {} if approval_head.to_s.strip.empty? && approval_by.to_s.strip.empty?

            {"head" => approval_head.to_s, "by" => approval_by.to_s}
          end

          def tests_flags(tests)
            flags = Array(tests).flat_map { |value| value.to_s.split(",") }.map { |f| f.strip.downcase }.reject(&:empty?)
            flags.each do |flag|
              unless %w[executed passed].include?(flag)
                raise Ace::Support::Cli::Error, "invalid --tests '#{flag}' (expected: executed, passed)"
              end
            end
            {"executed" => flags.include?("executed"), "passed" => flags.include?("passed")}
          end

          def dependency_states(dep)
            Array(dep).each_with_object({}) do |pair, states|
              name, state = pair.to_s.split("=", 2)
              name = name.to_s.strip
              if name.empty? || state.nil?
                raise Ace::Support::Cli::Error, "invalid --dep '#{pair}' (expected name=integrated|missing)"
              end
              raise Ace::Support::Cli::Error, "duplicate --dep '#{name}'" if states.key?(name)

              states[name] = state.strip.downcase == "integrated"
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
