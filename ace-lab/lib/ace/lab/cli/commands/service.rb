# frozen_string_literal: true

require "json"
require "ace/support/cli"
require "ace/assign"
require_relative "support"
require_relative "../../organisms/protected_service_request"
require_relative "../../organisms/ordinary_merge_request"
require_relative "../../organisms/ordinary_merge_receiver"
require_relative "../../molecules/ordinary_listener"
require_relative "../../molecules/ordinary_receiver_config"

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
              code = (error.is_a?(ArgumentError) || error.is_a?(SecurityError)) ? "protected_service_refused" : "protected_service_unavailable"
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
            option :mode, type: :string, desc: "ordinary-merge selects the ordinary fixed merge producer"
            option :queue_entry, type: :string, desc: "Original queue entry (ordinary merge)"

            option :mapping, type: :string, desc: "Original protected mapping ID"
            option :scope, type: :string, desc: "Original hierarchical prepared scope"
            option :service, type: :string, desc: "Installed receiver ID"
            option :candidate_head, type: :string, desc: "Exact approved candidate head"
            option :candidate_generation, type: :integer, desc: "Original candidate generation"
            option :expected_generation, type: :integer, desc: "Original authority generation"

            def call(project:, assignment:, attempt:, operation:, input:, authorization:, request_id:, **options)
              reject_identity_flags!(options)
              mode = options[:mode]
              if mode && mode != Organisms::OrdinaryMergeRequest::MODE
                return emit(Organisms::OrdinaryMergeRequest.refusal_envelope("ordinary_merge_invalid_request",
                  "unknown service mode", request_id: request_id, input_digest: nil))
              end
              if mode
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
              selected = protected_service.selected?(options)
              if selected
                return emit(protected_service.request(project: project, assignment: assignment, attempt: attempt,
                  operation: operation, input_path: input, authorization: authorization, request_id: request_id, **options))
              end
              emit(service.request(project: project, assignment: assignment, attempt: attempt,
                operation: operation, input_path: input, authorization: authorization,
                request_id: request_id, dry_run: options[:dry_run]))
            rescue ArgumentError, Ace::Assign::Error, Ace::Git::Error, Ace::Runtime::RuntimeUnavailableError, JSON::ParserError, SecurityError, KeyError, SystemCallError => error
              raise if selected == false || mode
              protected_refusal(error)
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

            desc "Read the authoritative outcome of a service request"
            option :request, type: :string, required: true, desc: "Request ID"
            option :format, type: :string, desc: "Output format (json only)"
            option :mode, type: :string, desc: "ordinary-merge selects the read-only ordinary status"
            option :reference, type: :string, desc: "Opaque ordinary merge reference"
            option :queue_entry, type: :string, desc: "Original queue entry (ordinary merge)"

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
              mode = options[:mode]
              if mode && mode != Organisms::OrdinaryMergeRequest::MODE
                return emit(Organisms::OrdinaryMergeRequest.refusal_envelope("ordinary_merge_invalid_request",
                  "unknown service mode", request_id: request, input_digest: nil,
                  schema: Ace::Assign::Atoms::FixedMergeSchemas::STATUS_ERROR_SCHEMA_ID))
              end
              if mode
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
              selected = protected_service.selected?(options)
              if selected
                return emit(protected_service.status(request_id: request, **options))
              end
              emit(service.status(request_id: request))
            rescue ArgumentError, Ace::Assign::Error, Ace::Git::Error, Ace::Runtime::RuntimeUnavailableError, JSON::ParserError, SecurityError, KeyError, SystemCallError => error
              raise if selected == false || mode
              protected_refusal(error)
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

            desc "Serve the ordinary fixed merge receiver on its configured socket"
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
              policy_document = Molecules::GrantResolver.trusted_document(
                receiver_config.policy_path
              )
              # The ONE canonical Assign journal: the coordinator binds the
              # evidence ref of the canonical repository the receiver is
              # installed for (config repo_path — the producer project's
              # canonical checkout, the same authoritative journal the
              # producer coordinator uses). Never an integration-checkout
              # duplicate; the service identity's reviewed permissions are
              # journal ref read/append, evidence checkout and no-effect
              # attestation writes inside that repository.
              coordinator = Ace::Assign::Organisms::AttemptCoordinator.new(
                repo_root: receiver_config.repo_path
              )
              receiver = Organisms::OrdinaryMergeReceiver.new(
                config: receiver_config, coordinator: coordinator,
                policy_document: policy_document
              )
              listener = Molecules::OrdinaryListener.new(
                socket_path: receiver_config.socket_path,
                peer_uid: receiver_config.principal_uid,
                socket_gid: receiver_config.socket_gid,
                handler: receiver
              )
              receiver.recover_pending!
              listener.serve
            rescue Ace::Lab::InvalidConfigurationError, Ace::Assign::AttemptErrors::EvidenceUnavailable => e
              emit(Organisms::OrdinaryMergeRequest.refusal_envelope(
                "ordinary_merge_unavailable", e.message,
                request_id: "unknown", input_digest: nil
              ))
            end
          end
        end
      end
    end
  end
end
