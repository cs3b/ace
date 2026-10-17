# frozen_string_literal: true

require "json"
require "ace/support/cli"
require "ace/assign"
require_relative "support"
require_relative "../../organisms/ordinary_merge_request"
require_relative "../../organisms/ordinary_merge_receiver"
require_relative "../../organisms/ordinary_authority_composition"
require_relative "../../molecules/ordinary_listener"
require_relative "../../molecules/ordinary_receiver_config"

module Ace
  module Lab
    module CLI
      module Commands
        module Service
          module Output
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

            desc "Request one authorized ordinary fixed merge operation"
            option :project, type: :string, required: true, desc: "Project stable ID"
            option :assignment, type: :string, required: true, desc: "Assignment ID"
            option :attempt, type: :string, required: true, desc: "Managed attempt ID"
            option :operation, type: :string, required: true, desc: "Named operation (merge)"
            option :input, type: :string, required: true, desc: "Structured JSON input file"
            option :authorization, type: :string, required: true, desc: "Exact authorization reference"
            option :request_id, type: :string, required: true, desc: "Idempotency key"
            option :mode, type: :string, required: true,
              desc: "ordinary-merge selects the ordinary fixed merge producer"
            option :queue_entry, type: :string, required: true, desc: "Original queue entry (ordinary merge)"

            def call(project:, assignment:, attempt:, operation:, input:, authorization:, request_id:, **options)
              reject_identity_flags!(options)
              unless options[:mode] == Organisms::OrdinaryMergeRequest::MODE
                return emit(Organisms::OrdinaryMergeRequest.refusal_envelope("ordinary_merge_invalid_request",
                  "unknown service mode", request_id: request_id, input_digest: nil))
              end
              begin
                return emit(ordinary_request(project: project, assignment: assignment, attempt: attempt,
                  queue_entry: options[:queue_entry], operation: operation, input: input,
                  authorization: authorization, request_id: request_id, **options))
              rescue Ace::Assign::AttemptErrors::EvidenceUnavailable, Ace::Lab::InvalidConfigurationError => e
                # Infra failures (unreadable canonical evidence, malformed
                # installed configuration, unavailable topology) are the
                # caller-side blocker, never a raw crash and never a durable
                # reference (review r1 finding B).
                return emit(Organisms::OrdinaryMergeRequest.refusal_envelope(
                  "ordinary_merge_unavailable", e.message, request_id: request_id, input_digest: nil
                ))
              end
            end

            private

            def ordinary_producer
              @ordinary_producer ||= Organisms::OrdinaryMergeRequest.new
            end

            # The ordinary refusal envelope is emitted exactly as received;
            # it is classified for the non-zero exit like every refusal.
            def ordinary_request(**arguments)
              ordinary_producer.request(**arguments)
            end
          end

          class Status < Ace::Support::Cli::Command
            include Ace::Support::Cli::Base
            include Runtime
            include Output

            desc "Read the authoritative outcome of an ordinary fixed merge request"
            option :request, type: :string, required: true, desc: "Request ID"
            option :format, type: :string, desc: "Output format (json only)"
            option :mode, type: :string, required: true,
              desc: "ordinary-merge selects the read-only ordinary status"
            option :reference, type: :string, required: true, desc: "Opaque ordinary merge reference"
            option :queue_entry, type: :string, required: true, desc: "Original queue entry (ordinary merge)"
            option :project, type: :string, required: true, desc: "Project ID"
            option :assignment, type: :string, required: true, desc: "Assignment ID"
            option :attempt, type: :string, required: true, desc: "Attempt ID"
            option :input_digest, type: :string, required: true, desc: "Original normalized input SHA-256"

            def call(request:, **options)
              reject_identity_flags!(options)
              unless options[:mode] == Organisms::OrdinaryMergeRequest::MODE
                return emit(Organisms::OrdinaryMergeRequest.refusal_envelope("ordinary_merge_invalid_request",
                  "unknown service mode", request_id: request, input_digest: nil,
                  schema: Ace::Assign::Atoms::FixedMergeSchemas::STATUS_ERROR_SCHEMA_ID))
              end
              ensure_json_format!(options)
              begin
                return emit(ordinary_producer.status(project: options[:project], assignment: options[:assignment],
                  attempt: options[:attempt], queue_entry: options[:queue_entry], reference: options[:reference],
                  request: request, input_digest: options[:input_digest], **options))
              rescue Ace::Assign::AttemptErrors::EvidenceUnavailable, Ace::Lab::InvalidConfigurationError => e
                return emit(Organisms::OrdinaryMergeRequest.refusal_envelope(
                  "ordinary_merge_unavailable", e.message, request_id: request, input_digest: nil,
                  schema: Ace::Assign::Atoms::FixedMergeSchemas::STATUS_ERROR_SCHEMA_ID
                ))
              end
            end

            private

            def ordinary_producer
              @ordinary_producer ||= Organisms::OrdinaryMergeRequest.new
            end
          end

          # The ordinary receiver serve entrypoint (spec 8x3.t.xz9.4
          # execution clauses; 8x3.t.xz9.5 integration handoff): binds the
          # configured unix socket, mutually authenticates every connection
          # through OS peer credentials, admits through the canonical Assign
          # coordinator, executes the authorized fixed operation — one REAL
          # Forgejo merge under the scoped host-installed service identity —
          # and settles the exact terminal receipt proven by real forge
          # readback. Configuration is one explicit deployment-owned file
          # plus the host-installed authorization and forge-merge documents;
          # the host owns their placement and credentials. Blocks until
          # stopped.
          class Listen < Ace::Support::Cli::Command
            include Ace::Support::Cli::Base
            include Output

            desc "Serve ordinary Assign, HITL and fixed merge under the installed journal owner"
            option :mode, type: :string, required: true,
              desc: "ordinary-merge selects the ordinary fixed merge receiver"
            option :project, type: :string, required: true, desc: "Project stable ID"
            option :config, type: :string, required: true,
              desc: "Deployment-owned receiver configuration file (YAML)"

            def call(mode:, project:, config:, **options)
              unless options.empty?
                return emit(Organisms::OrdinaryMergeRequest.refusal_envelope(
                  "ordinary_merge_invalid_request",
                  "unknown listen selector: #{options.keys.sort.join(", ")}",
                  request_id: "unknown", input_digest: nil
                ))
              end
              unless mode == Organisms::OrdinaryMergeRequest::MODE
                return emit(Organisms::OrdinaryMergeRequest.refusal_envelope(
                  "ordinary_merge_invalid_request", "unknown service mode",
                  request_id: "unknown", input_digest: nil
                ))
              end
              receiver_config = Molecules::OrdinaryReceiverConfig.load(config)
              unless receiver_config.project == project
                return emit(Organisms::OrdinaryMergeRequest.refusal_envelope(
                  "ordinary_merge_selection_mismatch",
                  "configured project does not match the requested project",
                  request_id: "unknown", input_digest: nil
                ))
              end
              unless receiver_config.receiver_uid == Process.uid
                raise Ace::Lab::InvalidConfigurationError, "receiver must run as its configured UID"
              end
              server = Organisms::OrdinaryAuthorityComposition.new(receiver_config: receiver_config).build
              signals = %w[INT TERM].to_h { |signal| [signal, Signal.trap(signal) { server.request_stop }] }
              server.serve
            rescue Ace::Lab::InvalidConfigurationError, Ace::Assign::Error, Ace::Runtime::Error,
              Ace::Hitl::Lifecycle::Error => e
              emit(Organisms::OrdinaryMergeRequest.refusal_envelope(
                "ordinary_merge_unavailable", e.message,
                request_id: "unknown", input_digest: nil
              ))
            ensure
              signals&.each { |signal, handler| Signal.trap(signal, handler) }
            end
          end
        end
      end
    end
  end
end
