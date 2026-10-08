# frozen_string_literal: true

require "json"
require "ace/support/cli"
require_relative "support"
require_relative "../../organisms/protected_service_request"

module Ace
  module Lab
    module CLI
      module Commands
        module Service
          module Output
            def service
              @service ||= Organisms::ServiceRequestService.new
            end

            def protected_service
              @protected_service ||= Organisms::ProtectedServiceRequest.new
            end

            def protected_refusal(error)
              code = error.is_a?(ArgumentError) || error.is_a?(SecurityError) ? "protected_service_refused" : "protected_service_unavailable"
              message = error.is_a?(JSON::ParserError) ? "protected installed selection unavailable" : error.message.to_s.scrub[0, 512]
              emit({"status" => "error", "error" => {"code" => code, "message" => message}})
            end

            def emit(envelope)
              puts JSON.generate(envelope)
              return if envelope["status"] == "ok"
              error = envelope.fetch("error")
              code = error.fetch("code")
              message = error.fetch("message")
              raise Ace::Support::Cli::Error, "#{code}: #{message}"
            end
          end

          class Request < Ace::Support::Cli::Command
            include Ace::Support::Cli::Base
            include Runtime
            include Output

            desc "Request one authorized, configured service operation"
            option :project, type: :string, required: true, desc: "Project stable ID"
            option :assignment, type: :string, required: true, desc: "Assignment ID"
            option :attempt, type: :string, required: true, desc: "Managed attempt ID"
            option :operation, type: :string, required: true, desc: "Named operation"
            option :input, type: :string, required: true, desc: "Structured JSON input file"
            option :authorization, type: :string, required: true, desc: "Exact authorization reference"
            option :request_id, type: :string, required: true, desc: "Idempotency key"
            option :dry_run, type: :boolean, desc: "Validate without claiming or executing"

            option :mapping, type: :string, desc: "Original protected mapping ID"
            option :scope, type: :string, desc: "Original hierarchical prepared scope"
            option :service, type: :string, desc: "Installed receiver ID"
            option :candidate_head, type: :string, desc: "Exact approved candidate head"
            option :candidate_generation, type: :integer, desc: "Original candidate generation"
            option :expected_generation, type: :integer, desc: "Original authority generation"

            def call(project:, assignment:, attempt:, operation:, input:, authorization:, request_id:, **options)
              reject_identity_flags!(options)
              selected = protected_service.selected?(options)
              if selected
                return emit(protected_service.request(project: project, assignment: assignment, attempt: attempt,
                  operation: operation, input_path: input, authorization: authorization, request_id: request_id, **options))
              end
              emit(service.request(project: project, assignment: assignment, attempt: attempt,
                operation: operation, input_path: input, authorization: authorization,
                request_id: request_id, dry_run: options[:dry_run]))
            rescue ArgumentError, Ace::Assign::Error, Ace::Git::Error, Ace::Runtime::RuntimeUnavailableError, JSON::ParserError, SecurityError, KeyError, SystemCallError => error
              raise if selected == false
              protected_refusal(error)
            end
          end

          class Status < Ace::Support::Cli::Command
            include Ace::Support::Cli::Base
            include Runtime
            include Output

            desc "Read the authoritative outcome of a service request"
            option :request, type: :string, required: true, desc: "Request ID"
            option :format, type: :string, desc: "Output format (json only)"

            option :project, type: :string, desc: "Original project ID"
            option :assignment, type: :string, desc: "Original assignment ID"
            option :attempt, type: :string, desc: "Original attempt ID"
            option :mapping, type: :string, desc: "Original protected mapping ID"
            option :scope, type: :string, desc: "Original hierarchical prepared scope"
            option :candidate_head, type: :string, desc: "Exact approved candidate head"
            option :candidate_generation, type: :integer, desc: "Original candidate generation"
            option :input_digest, type: :string, desc: "Original normalized input SHA-256"
            option :target, type: :string, desc: "Original target resource ID"
            option :artifact_digest, type: :string, desc: "Original artifact SHA-256 (omit for null)"

            def call(request:, **options)
              reject_identity_flags!(options)
              ensure_json_format!(options)
              selected = protected_service.selected?(options)
              if selected
                return emit(protected_service.status(request_id: request, **options))
              end
              emit(service.status(request_id: request))
            rescue ArgumentError, Ace::Assign::Error, Ace::Git::Error, Ace::Runtime::RuntimeUnavailableError, JSON::ParserError, SecurityError, KeyError, SystemCallError => error
              raise if selected == false
              protected_refusal(error)
            end
          end
        end
      end
    end
  end
end
