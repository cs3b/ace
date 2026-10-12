# frozen_string_literal: true

require "digest"
require "json"
require "open3"
require_relative "protected_service_request"
require_relative "../molecules/ordinary_socket"
require "ace/assign/atoms/fixed_merge_schemas"

module Ace
  module Lab
    module Organisms
      # The ordinary fixed merge admission producer (spec 8x3.t.xz9.4). One
      # mode of the maintained `service request/status` vocabulary: it
      # canonicalizes the immutable request binding, authenticates the
      # verified project overseer against the installed ordinary mapping,
      # resolves the named queue entry and attempt, transports the request
      # to the configured ordinary receiver, and emits the adopted ace-lab
      # envelopes — never a second protocol. Refusals are pre-effect and
      # carry no durable reference; unavailability is a caller-side blocker;
      # the canonical Assign attempt/evidence state stays the sole
      # queue/effect record, so this class owns no ledger.
      class OrdinaryMergeRequest
        MODE = "ordinary-merge"
        OPERATION = "merge"

        # The closed pre-effect refusal codes (exhaustive pre-effect mapping).
        CODES = %w[ordinary_merge_invalid_request ordinary_merge_unauthenticated
          ordinary_merge_forbidden ordinary_merge_selection_mismatch
          ordinary_merge_authorization_invalid ordinary_merge_provenance_mismatch
          ordinary_merge_target_changed ordinary_merge_evidence_invalid
          ordinary_merge_request_conflict ordinary_merge_unavailable].freeze

        # Selector keys this producer accepts; anything else — including the
        # protected mapping/scope/service/generation selectors and any
        # executable/argv/UID/socket/evidence-path/credential/token selector
        # — refuses before effect.
        REQUEST_KEYS = %i[project assignment attempt queue_entry operation input authorization
          request_id mode].freeze
        STATUS_KEYS = %i[project assignment attempt queue_entry reference request input_digest
          mode format].freeze

        ID = Molecules::ServicePolicy::ID

        def initialize(topology: nil, policy: nil, coordinator: nil, repo_root: nil, ingress: nil)
          @topology = topology || TopologyService.from_config
          @repo_root = repo_root || git_toplevel
          @coordinator = coordinator ||
            Ace::Assign::Organisms::AttemptCoordinator.new(repo_root: @repo_root)
          @policy = policy || Molecules::ServicePolicy.new(
            Molecules::GrantResolver.trusted_document(Ace::Lab.authorization_path)
          )
          @ingress = ingress
        end

        def request(project:, assignment:, attempt:, queue_entry:, operation:, input:,
          authorization:, request_id:, **options)
          digest = nil
          unless (options.keys - REQUEST_KEYS).empty?
            invalid!("unknown request selector: #{unknown(options.keys, REQUEST_KEYS)}", request_id)
          end
          invalid!("operation must be merge", request_id) unless operation == OPERATION
          identifiers!(project: project, assignment: assignment, attempt: attempt,
            queue_entry: queue_entry, request_id: request_id)
          unless authorization.is_a?(String) && authorization.match?(ID)
            invalid!("invalid authorization reference", request_id)
          end
          document = load_request_document(input, request_id)
          validate_document!(document, request_id)
          digest = input_digest(project: project, assignment: assignment, attempt: attempt,
            queue_entry: queue_entry, authorization: authorization, request_id: request_id,
            document: document)
          principal = authenticate!(project)
          existing = @coordinator.fixed_merge_record(request_id)
          if existing
            return ack_envelope(existing) if exact_replay?(existing, project: project,
              assignment: assignment, attempt: attempt, queue_entry: queue_entry,
              authorization: authorization, digest: digest)
            conflict!("request ID already exists with a different binding", request_id, digest)
          end
          receiver = receiver_mapping!(project)
          resolve_selection!(project: project, assignment: assignment, attempt: attempt,
            queue_entry: queue_entry)
          authorize!(authorization, project: project, assignment: assignment, attempt: attempt,
            queue_entry: queue_entry, document: document, digest: digest)
          verify_candidate_head!(document)
          submission = {"project_id" => project, "assignment_id" => assignment,
                        "attempt_id" => attempt, "queue_entry" => queue_entry, "operation" => OPERATION,
                        "authorization" => authorization, "request_id" => request_id,
                        "input_digest" => digest, "request" => document, "principal" => principal,
                        "receiver_id" => receiver.fetch("receiver_id"),
                        "configuration_sha256" => receiver.fetch("configuration_sha256")}
          response = deliver(receiver, submission)
          normalize_response(response, request_id: request_id, input_digest: digest)
        rescue OrdinaryMergeRefusal => e
          self.class.refusal_envelope(e.code, e.detail, request_id: e.request_id || request_id,
            input_digest: e.input_digest || digest)
        rescue Ace::Assign::AttemptErrors::Conflict => e
          self.class.refusal_envelope("ordinary_merge_request_conflict", e.message,
            request_id: request_id, input_digest: digest)
        rescue Molecules::OrdinarySocket::OrdinaryUnavailable => e
          self.class.refusal_envelope("ordinary_merge_unavailable", e.message,
            request_id: request_id, input_digest: digest)
        end

        # Read-only status: resolve the opaque reference against the canonical
        # record with every selector; performs no dispatch, retry,
        # authorization refresh or selector repair. Read-only status survives
        # rollback and receiver downtime because the canonical Assign state —
        # never a receiver — owns the record.
        def status(project:, assignment:, attempt:, queue_entry:, reference:, request:,
          input_digest:, **options)
          unless (options.keys - STATUS_KEYS).empty?
            return status_error(self.class.refusal_envelope("ordinary_merge_invalid_request",
              "unknown status selector: #{unknown(options.keys, STATUS_KEYS)}",
              request_id: request, input_digest: nil,
              schema: Ace::Assign::Atoms::FixedMergeSchemas::STATUS_ERROR_SCHEMA_ID))
          end
          identifiers!(project: project, assignment: assignment, attempt: attempt,
            queue_entry: queue_entry, request_id: request)
          unless options[:format] == "json"
            invalid!("status requires --format json", request)
          end
          unless reference.is_a?(String) && Ace::Assign::Molecules::FixedEffectReference.valid?(reference)
            invalid!("invalid reference", request)
          end
          unless input_digest.is_a?(String) && input_digest.match?(/\A[0-9a-f]{64}\z/)
            invalid!("invalid input digest", request)
          end
          authenticate!(project)
          record = @coordinator.fixed_merge_status(reference: reference, request_id: request,
            project_id: project, assignment_id: assignment, attempt_id: attempt,
            queue_entry: queue_entry, input_digest: input_digest)
          # Unknown or mismatched references answer identically, without
          # revealing whether another project holds the reference.
          return status_error(selection_error) unless record
          {"status" => "ok", "data" => {
            "schema" => Ace::Assign::Atoms::FixedMergeSchemas::STATUS_SCHEMA_ID,
            "state" => record.fetch("state"),
            "reference" => record.fetch("reference"),
            "request_id" => record.fetch("request_id"),
            "input_digest" => record.fetch("input_digest"),
            "receipt" => %w[pending uncertain].include?(record.fetch("state")) ? nil : record["receipt"]
          }}
        rescue OrdinaryMergeRefusal => e
          status_error(self.class.refusal_envelope(e.code, e.detail, request_id: request, input_digest: nil,
            schema: Ace::Assign::Atoms::FixedMergeSchemas::STATUS_ERROR_SCHEMA_ID))
        end

        # ---- envelope composition (the adopted ace-lab vocabulary) ---------

        def ack_envelope(record)
          {"status" => "ok", "data" => {
            "schema" => Ace::Assign::Atoms::FixedMergeSchemas::ACK_SCHEMA_ID,
            "type" => "accepted",
            "request_id" => record.fetch("request_id"),
            "input_digest" => record.fetch("input_digest"),
            "reference" => record.fetch("reference")
          }}
        end

        def self.sanitize(message)
          cleaned = message.to_s.scrub.gsub(/\s+/, " ").strip[0, 512]
          cleaned.empty? ? "ordinary merge request refused" : cleaned
        end

        # Envelope composition is instance-independent; the CLI reuses it for
        # mode-selection refusals before any producer exists.
        def self.refusal_envelope(code, message, request_id:, input_digest:,
          schema: Ace::Assign::Atoms::FixedMergeSchemas::REFUSAL_SCHEMA_ID)
          raise ArgumentError, "unknown ordinary merge refusal code" unless CODES.include?(code)
          echo = request_id.to_s[0, 256]
          echo = "unknown" if echo.empty?
          {"status" => "error", "error" => {
            "schema" => schema,
            "code" => code,
            "message" => sanitize(message),
            "request_id" => echo,
            "input_digest" => input_digest
          }}
        end

        private

        # The immutable binding: command selectors plus the canonical input
        # document, the authorization reference and the request ID, digested
        # as lowercase SHA-256 over the sorted-key canonical JSON.
        def input_digest(project:, assignment:, attempt:, queue_entry:, authorization:,
          request_id:, document:)
          canonical = Atoms::ServiceInput.canonical({
            "project" => project, "assignment" => assignment, "attempt" => attempt,
            "queue_entry" => queue_entry, "operation" => OPERATION,
            "authorization" => authorization, "request_id" => request_id, "input" => document
          })
          Digest::SHA256.hexdigest(JSON.generate(canonical))
        end

        def validate_document!(document, request_id)
          Ace::Assign::Atoms::FixedMergeSchemas.validate_request!(document)
          Ace::Assign::Atoms::FixedMergeSchemas.require_request_joins!(document)
        rescue Ace::Assign::Atoms::FixedMergeSchemas::SchemaError => e
          invalid!(e.message, request_id)
        end

        # The verified local process owner is the only caller identity; it
        # must be the configured ordinary project overseer principal.
        def authenticate!(project)
          identities = Molecules::CallerAuthorizer.local_identity
          refused("ordinary_merge_unauthenticated", "verified local identity is unavailable") if identities.empty?
          receiver = @policy.ordinary_receiver!(project)
          unless receiver.is_a?(Hash) && identities.include?(receiver.fetch("principal"))
            refused("ordinary_merge_forbidden",
              "authenticated principal is not the configured ordinary project overseer")
          end
          receiver.fetch("principal")
        end

        # The installed ordinary section supplies identity and placement only.
        # A disabled or absent admission mapping is rollback: a caller-side
        # blocker that never redirects ordinary callers and never deletes the
        # canonical records — read-only status stays fully available.
        def receiver_mapping!(project)
          receiver = @policy.ordinary_receiver!(project)
          if receiver.nil? || receiver.fetch("admission", "enabled") != "enabled"
            raise Molecules::OrdinarySocket::OrdinaryUnavailable,
              "ordinary merge admission is not available in the installed configuration"
          end
          receiver.merge("configuration_sha256" => Atoms::ServiceInput.digest(@policy.document))
        end

        def resolve_selection!(project:, assignment:, attempt:, queue_entry:)
          @coordinator.service_attempt("assignment_id" => assignment, "attempt_id" => attempt,
            "project_id" => project)
        rescue Ace::Assign::AttemptErrors::NotFound, Ace::Assign::AttemptErrors::ReceiptRejected,
          Ace::Assign::AttemptErrors::InvalidState => e
          refused("ordinary_merge_selection_mismatch", e.message)
        end

        def authorize!(authorization, project:, assignment:, attempt:, queue_entry:, document:, digest:)
          binding = {"operation" => OPERATION, "project_id" => project,
                     "assignment_id" => assignment, "attempt_id" => attempt, "queue_entry" => queue_entry,
                     "input_digest" => digest, "forge" => document.fetch("forge"),
                     "pr_url" => document.fetch("pr_url"), "head_repository" => document.fetch("head_repository"),
                     "head_ref" => document.fetch("head_ref"), "candidate_head" => document.fetch("candidate_head"),
                     "base_repository" => document.fetch("base_repository"), "base_ref" => document.fetch("base_ref"),
                     "expected_base_head" => document.fetch("expected_base_head")}
          @policy.authorize_ordinary!(authorization, binding)
        rescue SecurityError => e
          case e.message
          when /unresolved|expired/ then refused("ordinary_merge_authorization_invalid", e.message)
          else refused("ordinary_merge_provenance_mismatch", e.message)
          end
        end

        def verify_candidate_head!(document)
          unless current_head == document.fetch("candidate_head")
            refused("ordinary_merge_target_changed", "candidate head moved from the immutable request")
          end
        end

        def deliver(receiver, submission)
          ingress = @ingress || default_ingress(receiver)
          ingress.call(submission: submission)
        end

        def default_ingress(receiver)
          socket = Molecules::OrdinarySocket.new(socket_path: receiver.fetch("socket_path"),
            receiver_uid: receiver.fetch("receiver_uid"))
          ->(submission:) { socket.submit(submission) }
        end

        # A valid receiver acknowledgment is relayed exactly; a valid receiver
        # refusal is relayed with its closed code; anything else is a lost or
        # unauthenticated response — a caller-side blocker, never a proven
        # refusal and never a resubmission authorization.
        def normalize_response(response, request_id:, input_digest:)
          unless response.is_a?(Hash) && (response.keys - %w[status data error]).empty? &&
              %w[ok error].include?(response["status"])
            raise Molecules::OrdinarySocket::OrdinaryUnavailable, "receiver response envelope is invalid"
          end
          return normalize_ack(response, request_id: request_id, input_digest: input_digest) if
            response.fetch("status") == "ok"
          normalize_refusal(response, request_id: request_id, input_digest: input_digest)
        end

        def normalize_ack(response, request_id:, input_digest:)
          data = response.fetch("data") { {} }
          expected = %w[schema type request_id input_digest reference]
          digest = data["input_digest"]
          unless data.is_a?(Hash) && (data.keys - expected).empty? &&
              expected.all? { |key| data[key].is_a?(String) && !data[key].empty? } &&
              data.fetch("schema") == Ace::Assign::Atoms::FixedMergeSchemas::ACK_SCHEMA_ID &&
              data.fetch("type") == "accepted" && data.fetch("request_id") == request_id &&
              digest == input_digest && digest.match?(/\A[0-9a-f]{64}\z/) &&
              Ace::Assign::Molecules::FixedEffectReference.valid?(data.fetch("reference"))
            raise Molecules::OrdinarySocket::OrdinaryUnavailable,
              "receiver acknowledgment is invalid or lost before durability could be confirmed"
          end
          {"status" => "ok", "data" => data.slice(*expected)}
        end

        def normalize_refusal(response, request_id:, input_digest:)
          error = response.fetch("error") { {} }
          expected = %w[schema code message request_id input_digest]
          valid = error.is_a?(Hash) && (error.keys - expected).empty? &&
            error.fetch("schema") == Ace::Assign::Atoms::FixedMergeSchemas::REFUSAL_SCHEMA_ID &&
            CODES.include?(error.fetch("code")) &&
            error.fetch("message").is_a?(String) && !error.fetch("message").empty? &&
            error.fetch("message").length <= 512 &&
            error.fetch("request_id") == request_id &&
            (error.fetch("input_digest").nil? || error.fetch("input_digest") == input_digest)
          unless valid
            raise Molecules::OrdinarySocket::OrdinaryUnavailable, "receiver refusal envelope is invalid"
          end
          {"status" => "error", "error" => error.slice(*expected)}
        end

        def selection_error
          self.class.refusal_envelope("ordinary_merge_selection_mismatch",
            "reference and selectors do not match a canonical ordinary merge record",
            request_id: nil, input_digest: nil,
            schema: Ace::Assign::Atoms::FixedMergeSchemas::STATUS_ERROR_SCHEMA_ID)
        end

        def status_error(envelope)
          {"status" => "error", "error" => envelope.fetch("error")}
        end

        def identifiers!(project:, assignment:, attempt:, queue_entry:, request_id:)
          {"project" => project, "assignment" => assignment, "attempt" => attempt,
           "queue_entry" => queue_entry, "request_id" => request_id}.each do |name, value|
            invalid!("invalid #{name} ID", request_id) unless value.is_a?(String) && value.match?(ID)
          end
        end

        def load_request_document(input, request_id)
          Atoms::ServiceInput.load(input)
        rescue ArgumentError => e
          invalid!(e.message, request_id)
        end

        def unknown(keys, allowed)
          (keys - allowed).sort.join(", ")
        end

        # A pre-effect refusal carries its closed code, sanitized message and
        # the request binding for the wire envelope — never a reference.
        OrdinaryMergeRefusal = Class.new(::StandardError) do
          attr_reader :code, :detail, :request_id, :input_digest

          def initialize(code, detail, request_id: nil, input_digest: nil)
            @code = code
            @detail = detail
            @request_id = request_id
            @input_digest = input_digest
            super(detail)
          end
        end

        def invalid!(message, request_id)
          raise OrdinaryMergeRefusal.new("ordinary_merge_invalid_request", message, request_id: request_id)
        end

        def conflict!(message, request_id, digest)
          raise OrdinaryMergeRefusal.new("ordinary_merge_request_conflict", message,
            request_id: request_id, input_digest: digest)
        end

        # A replay must match every caller-supplied immutable field: command
        # selectors, authorization, input byte meaning and canonical digest.
        def exact_replay?(existing, project:, assignment:, attempt:, queue_entry:,
          authorization:, digest:)
          existing["state"] &&
            existing.slice("project_id", "assignment_id", "attempt_id", "queue_entry",
              "authorization", "input_digest") == {
                "project_id" => project, "assignment_id" => assignment, "attempt_id" => attempt,
                "queue_entry" => queue_entry, "authorization" => authorization, "input_digest" => digest
              }
        end

        def refused(code, message)
          raise OrdinaryMergeRefusal.new(code, message)
        end

        # The git toplevel (not a package directory that happens to hold a
        # Rakefile) bounds candidate-head verification for nested invocations.
        def git_toplevel
          out, status = Open3.capture2("git", "rev-parse", "--show-toplevel")
          (status&.success? ? out.strip : Dir.pwd)
        rescue Errno::ENOENT
          Dir.pwd
        end

        def current_head
          out, _stderr, status = Open3.capture3("git", "rev-parse", "HEAD", chdir: @repo_root)
          refused("ordinary_merge_target_changed", "candidate head is unavailable") unless status.success?
          out.strip
        end
      end
    end
  end
end
