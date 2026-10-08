# frozen_string_literal: true

require "json"
require_relative "../../../authority/protected_assignment_context"

module Ace
  module Assign
    module CLI
      module Commands
        # Public `ace-assign attempt` command namespace (interface contract:
        # start, status, finish, reconcile).
        module Attempt
          # Shared coordinator construction, option validation, and JSON output.
          module Base
            private

            def protected_context(options)
              keys = %i[mapping assignment result head candidate_generation mutation expected_generation]
              keys.each do |key|
                if options.key?(key) && options[key].to_s.strip.empty?
                  raise Ace::Support::Cli::Error, "Empty protected --#{key.to_s.tr('_', '-')} selector"
                end
              end
              context = @protected_assignment_context ||= Ace::Assign::Authority::ProtectedAssignmentContext.load
              selected = keys.any? do |key|
                options.key?(key)
              end
              context if context.protected_participant? || selected || context.mapping_hint?
            rescue SecurityError, Ace::Runtime::RuntimeUnavailableError
              protected_transport_unavailable!
            end

            def protected_attempt_request(context, options, usage)
              params = {"assignment_id" => require_option(options, :assignment, usage),
                "attempt_id" => require_option(options, :attempt, usage),
                "expected_generation" => integer_option(options, :expected_generation, usage)}
              context.verify_attempt_hints!(assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"))
              [context.client(options: options), params, require_option(options, :mutation, usage)]
            rescue SecurityError, Ace::Runtime::RuntimeUnavailableError
              protected_transport_unavailable!
            end

            def protected_call(client, operation, params, mutation)
              client.call(operation, params, mutation_id: mutation, timeout: 30).data
            rescue SecurityError, Ace::Runtime::RuntimeUnavailableError
              protected_transport_unavailable!
            end

            def protected_transport_unavailable!
              raise AttemptErrors::EvidenceUnavailable, "Protected authority outcome unavailable; retain original selectors and mutation for reconciliation"
            end

            def integer_option(options, key, usage, positive: false)
              value = options[key]
              unless value.is_a?(Integer) || (value.is_a?(String) && value.match?(/\A(?:0|[1-9][0-9]*)\z/))
                raise Ace::Support::Cli::Error, "--#{key.to_s.tr('_', '-')} requires an exact integer: #{usage}"
              end
              number = value.is_a?(Integer) ? value : Integer(value, 10)
              unless positive ? number.positive? : number >= 0
                raise Ace::Support::Cli::Error, "--#{key.to_s.tr('_', '-')} is out of range"
              end
              number
            end

            def build_coordinator
              Organisms::AttemptCoordinator.new
            end

            def require_option(options, key, usage)
              value = options[key].to_s.strip
              raise Ace::Support::Cli::Error, "Missing --#{key}: usage: ace-assign attempt #{usage}" if value.empty?

              value
            end

            def emit_json(payload)
              puts JSON.generate(payload)
            end
          end
        end
      end
    end
  end
end
