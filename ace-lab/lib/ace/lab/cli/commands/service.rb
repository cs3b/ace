# frozen_string_literal: true

require "json"
require "ace/support/cli"
require_relative "support"

module Ace
  module Lab
    module CLI
      module Commands
        module Service
          module Output
            def service
              @service ||= Organisms::ServiceRequestService.new
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

            def call(project:, assignment:, attempt:, operation:, input:, authorization:, request_id:, **options)
              reject_identity_flags!(options)
              emit(service.request(project: project, assignment: assignment, attempt: attempt,
                operation: operation, input_path: input, authorization: authorization,
                request_id: request_id, dry_run: options[:dry_run]))
            end
          end

          class Status < Ace::Support::Cli::Command
            include Ace::Support::Cli::Base
            include Runtime
            include Output

            desc "Read the authoritative outcome of a service request"
            option :request, type: :string, required: true, desc: "Request ID"
            option :format, type: :string, desc: "Output format (json only)"

            def call(request:, **options)
              ensure_json_format!(options)
              emit(service.status(request_id: request))
            end
          end
        end
      end
    end
  end
end
