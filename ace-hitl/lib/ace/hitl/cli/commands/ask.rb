# frozen_string_literal: true

require "ace/support/cli"
require_relative "../../lifecycle"
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
          # Managed binding (spec 8wq.t.34i): the request binds to the
          # exact active managed attempt of the calling identity.
          option :assignment, type: :string, desc: "Managed assignment id (compact id)"
          option :kind, type: :string, desc: "Request kind (default: text; otp requires the challenge evidence)"
          option :"otp-operation", type: :string, desc: "OTP challenge: the ONE authorized operation name"
          option :"otp-result-ref", type: :string, desc: "OTP challenge: OTP-required publisher result reference"
          option :"otp-input-digest", type: :string, desc: "OTP challenge: sha256 input digest of the authorized input"
          option :"otp-expires-at", type: :string, desc: "OTP challenge: expiry as unix seconds (<= 24h ahead)"
          option :work, type: :string, desc: "Lab Work id (W...) - legacy binding until vs2 switches consumers"
          option :attempt, type: :string, desc: "Attempt id of the exact active attempt"
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

            work, assignment = require_binding!(options)
            attempt = require_attempt!(options)
            otp = build_otp_challenge!(options)
            provider = resolve_provider(options[:provider])
            ref = capture_ref

            result = provider.ask(
              question: question,
              title: options[:title],
              ref: ref,
              work: work,
              assignment: assignment,
              attempt: attempt,
              kind: options[:kind] || "text",
              otp: otp,
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

          # The binding is authority: exactly one of the managed
          # assignment binding or the legacy Work binding. An
          # environment variable never supplies attempt identity
          # (spec 8wq.t.34i).
          def require_binding!(options)
            work = options[:work]
            assignment = options[:assignment]
            if work && assignment
              raise_cli_error("--assignment and --work are mutually exclusive binding authorities")
            end
            if work.nil? && assignment.nil?
              raise_cli_error("--assignment required (managed binding), or --work for the legacy Work binding")
            end
            return [work, nil] unless work.nil?

            [nil, assignment]
          end

          # The OTP challenge evidence is non-secret, structurally
          # validated store-side; the CLI only assembles it (spec
          # 8wq.t.34i: no publisher result, no OTP request).
          def build_otp_challenge!(options)
            kind = options[:kind] || "text"
            return nil unless kind == "otp"

            operation = options[:"otp-operation"]
            result_ref = options[:"otp-result-ref"]
            input_digest = options[:"otp-input-digest"]
            expires_at = options[:"otp-expires-at"]
            missing = %w[--otp-operation --otp-result-ref --otp-input-digest --otp-expires-at]
              .zip([operation, result_ref, input_digest, expires_at])
              .select { |_flag, value| value.nil? || value.to_s.strip.empty? }
              .map(&:first)
            raise_cli_error("OTP requests require #{missing.join(", ")} (the OTP-required publisher evidence)") unless missing.empty?

            {operation: operation, result_ref: result_ref, input_digest: input_digest, expires_at: expires_at}
          end

          def require_attempt!(options)
            attempt = options[:attempt]
            unless attempt && !attempt.strip.empty?
              raise_cli_error("--attempt required (the exact active attempt id)")
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
