# frozen_string_literal: true

require "ace/support/cli"
require_relative "../../atoms/hitl_effect_validator"
require_relative "../../molecules/lab_request_submitter"

module Ace
  module Hitl
    module CLI
      module Commands
        class Ask < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Ask a human via HITL and forward the request to the Lab"

          argument :question, required: true, desc: "Question text for the human"

          option :title, type: :string, desc: "Local HITL event title (defaults to the question)"
          option :work, type: :string, desc: "Lab Work id (W...)"
          option :attempt, type: :string, desc: "Lab Attempt id (A-...); defaults to LAB_ATTEMPT_ID"
          option :project, type: :string, desc: "Lab project label (default: ace)"
          option :harness, type: :string, desc: "Lab harness label (default: lab-admin)"
          option :plan, type: :string, desc: "Lab plan label (default: ace-hitl ask)"

          option :"effect-match", type: :string, desc: "Effect callback regex gate on the answer (<= 200 chars)"
          option :"effect-arg", type: :string, repeat: true, desc: "Effect callback argv element, repeatable (1..16 x 1..512 chars)"
          option :"effect-cwd", type: :string, desc: "Effect callback working directory (absolute, must exist)"
          option :"effect-timeout-s", type: :string, desc: "Effect callback timeout in seconds (1..600)"

          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

          def call(question:, **options)
            effect = {
              match: options[:"effect-match"],
              effect_args: Array(options[:"effect-arg"]),
              effect_cwd: options[:"effect-cwd"],
              effect_timeout: options[:"effect-timeout-s"]
            }
            begin
              Atoms::HitlEffectValidator.validate!(**effect)
            rescue Atoms::HitlEffectValidator::ValidationError => e
              raise_cli_error(e.message)
            end

            work = require_work!(options)
            attempt = options[:attempt] || ENV["LAB_ATTEMPT_ID"]
            unless attempt && !attempt.strip.empty?
              raise_cli_error("--attempt required (or set LAB_ATTEMPT_ID)")
            end

            submitter = Molecules::LabRequestSubmitter.new
            request_id = submitter.generate_request_id

            manager = Ace::Hitl::Organisms::HitlManager.new
            event = manager.create(
              options[:title] || question,
              questions: [question]
            )

            argv = submitter.build_argv(
              request_id: request_id,
              work: work,
              attempt: attempt,
              project: options[:project] || "ace",
              harness: options[:harness] || "lab-admin",
              plan: options[:plan] || "ace-hitl ask",
              question: question,
              ace_hitl_id: event.id,
              **effect
            )

            begin
              lab_request_id = submitter.submit(argv)
            rescue Molecules::LabRequestSubmitter::SubmissionError => e
              raise_cli_error(e.message)
            end

            manager.update(event.id, set: {
              "lab_request_id" => lab_request_id,
              "lab_request_state" => "created"
            })

            puts "HITL event: #{event.id}"
            puts "Lab request: #{lab_request_id}"
            puts "Answer relay: lab-hitl consume #{lab_request_id}"
          end

          private

          def require_work!(options)
            work = options[:work]
            raise_cli_error("--work required (Lab Work id, e.g. W685)") if work.nil? || work.strip.empty?

            work
          end
        end
      end
    end
  end
end
