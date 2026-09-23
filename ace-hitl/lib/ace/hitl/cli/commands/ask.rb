# frozen_string_literal: true

require "ace/support/cli"
require_relative "../../atoms/hitl_effect_validator"
require_relative "../../providers/providers"

module Ace
  module Hitl
    module CLI
      module Commands
        class Ask < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Ask a human via HITL and forward the request through a provider adapter"

          argument :question, required: true, desc: "Question text for the human"

          option :title, type: :string, desc: "Local HITL event title (defaults to the question)"
          option :provider, type: :string, desc: "HITL provider adapter (default: ACE_HITL_PROVIDER or lab)"
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
            effect = build_effect(options)
            validate_effect!(effect)

            work = require_work!(options)
            attempt = require_attempt!(options)
            provider = resolve_provider(options[:provider])
            ref = capture_ref

            result = provider.ask(
              question: question,
              title: options[:title],
              ref: ref,
              work: work,
              attempt: attempt,
              project: options[:project] || Providers::Lab::DEFAULT_PROJECT,
              harness: options[:harness] || Providers::Lab::DEFAULT_HARNESS,
              plan: options[:plan] || Providers::Lab::DEFAULT_PLAN,
              effect: effect
            )

            puts "HITL event: #{result.event_id}"
            puts "Provider: #{Providers::Lab::PROVIDER_NAME} (ref #{ref.session}/#{ref.pane}, #{Providers::Ref::SCHEMA})"
            puts "Lab request: #{result.request_id}"
          rescue Providers::ProviderUnavailableError => e
            raise_cli_error(e.message)
          end

          private

          def build_effect(options)
            {
              match: options[:"effect-match"],
              effect_args: Array(options[:"effect-arg"]),
              effect_cwd: options[:"effect-cwd"],
              effect_timeout: options[:"effect-timeout-s"]
            }
          end

          def validate_effect!(effect)
            Atoms::HitlEffectValidator.validate!(**effect)
          rescue Atoms::HitlEffectValidator::ValidationError => e
            raise_cli_error(e.message)
          end

          def require_work!(options)
            work = options[:work]
            raise_cli_error("--work required (Lab Work id, e.g. W685)") if work.nil? || work.strip.empty?

            work
          end

          def require_attempt!(options)
            attempt = options[:attempt] || ENV["LAB_ATTEMPT_ID"]
            unless attempt && !attempt.strip.empty?
              raise_cli_error("--attempt required (or set LAB_ATTEMPT_ID)")
            end

            attempt
          end

          def resolve_provider(raw)
            name = raw || ENV["ACE_HITL_PROVIDER"] || Providers::Lab::PROVIDER_NAME
            Providers.resolve(name)
          rescue Providers::UnknownProviderError => e
            raise_cli_error(e.message)
          end

          # Fail closed BEFORE any state is created: the reverse address is
          # required so the answer can be delivered back to this pane.
          def capture_ref
            Providers::Ref.from_env
          rescue Providers::InvalidRefError => e
            raise_cli_error(e.message)
          end
        end
      end
    end
  end
end
