# frozen_string_literal: true

require "etc"
require "ace/hitl/lifecycle"

module Ace
  module Hitl
    module Hermes
      module Boundary
        # The local worker ask step of the nh0-A scenario (spec
        # 8xa.t.nh0): runs INSIDE the authority's container as the real
        # worker actor and creates asks through the SUPPORTED mechanism
        # — the authority's Unix boundary, where the serve-path binding
        # (Providers::Lab::AssignmentBinding →
        # AttemptCoordinator#with_verified_attempt) verifies the
        # assignment/attempt against the REAL Assign state under the
        # kernel requester identity.
        #
        # This step NEVER invents attempts, grants or receipts: the
        # assignment/attempt ids come from the fixture-declared manifest
        # (genuine state), and a create that fails binding verification
        # fails the step truthfully. The TLS crossing never creates and
        # never supplies requester identity; the certificate identity
        # maps only to the transport role, the requester of record is
        # the local worker actor via kernel peer credentials.
        class LocalWorker
          RECEIPT_TYPE = "nh0_a_local_ask"
          STAGES = %w[create settle].freeze

          # @param local_client_factory [Proc] injectable Unix-boundary
          #   client factory (production: Lifecycle::Client with kernel
          #   peer credentials of the worker actor)
          def initialize(manifest:, state:, authority:, stage:, local_client_factory: nil,
            clock: -> { Time.now.utc }, id_generator: -> { SecureRandom.hex(12) })
            raise Scenario::Error, "unknown authority #{authority.inspect}" unless Scenario::AUTHORITIES.include?(authority)
            raise Scenario::Error, "unknown ask stage #{stage.inspect}" unless STAGES.include?(stage)

            @manifest = manifest
            @state = state
            @authority = authority
            @stage = stage
            @local_client_factory = local_client_factory || lambda do |socket:, service_uid:|
              Ace::Hitl::Lifecycle::Client.new(socket_path: socket, service_uid: service_uid)
            end
            @clock = clock
            @id_generator = id_generator
          end

          # @return [Hash] the closed receipt printed as ONE stdout JSON line
          def run
            ask = @manifest.ask(@authority)
            verify_worker_identity!(ask)
            client = @local_client_factory.call(socket: ask.fetch("socket"),
              service_uid: ask.fetch("service_uid"))
            outcome = @stage == "create" ? create_asks(client, ask) : settle_asks(client)
            {
              "type" => RECEIPT_TYPE,
              "version" => 1,
              "invocation_id" => @manifest.invocation_id,
              "scenario" => Scenario::SCENARIO_NAME,
              "authority" => @authority,
              "stage" => @stage,
              "worker_user" => ask.fetch("worker_user"),
              "worker_identity_verified" => true,
              "binding_verified" => outcome.fetch("binding_verified"),
              "passed" => outcome.fetch("passed"),
              "receipt_ids" => outcome.fetch(:receipt_ids),
              "completed_at" => @clock.call.utc.iso8601
            }
          end

          private

          # The certificate identity of the crossing maps to the Hermes
          # transport role ONLY. The actor that requests is the local
          # worker: this step refuses to run under any other account,
          # so the requester of record stays the kernel-verified worker
          # identity exactly as production maps it.
          def verify_worker_identity!(ask)
            worker = Etc.getpwuid(Process.euid).name
            return if worker == ask.fetch("worker_user")

            raise Scenario::Error,
              "worker identity mapping mismatch: the ask step runs as #{worker.inspect}, " \
              "not the declared worker actor #{ask.fetch('worker_user').inspect}"
          end

          # create goes through the authority's REAL binding: the store
          # verifies assignment/attempt/project/requester via
          # with_verified_attempt against real Assign state. A fabricated
          # or stale binding fails here, truthfully.
          def create_asks(client, ask)
            receipt_ids = []
            project = @manifest.project(@authority)
            payload = @manifest.payload
            main_id = create_one(client, ask, project, payload) do |result|
              receipt_ids << result.fetch(:receipt_id)
            end
            @state.record_request(@authority, main_id)
            # The mid-flight uncertainty case runs against authority A's
            # worker only.
            if @authority == "A"
              uncertainty_id = create_one(client, ask, project, payload,
                id: "ask-#{SecureRandom.hex(8)}", purpose: "uncertainty") do |result|
                receipt_ids << result.fetch(:receipt_id)
              end
              @state.record_uncertainty(uncertainty_id)
            end
            {"passed" => true, "binding_verified" => true,
             :receipt_ids => receipt_ids, "request_id" => main_id}
          rescue Ace::Hitl::Lifecycle::Error => e
            {"passed" => false, "binding_verified" => false, :receipt_ids => receipt_ids,
             "refusal" => e.class.to_s}
          end

          def create_one(client, ask, project, payload, id: "ask-#{SecureRandom.hex(8)}",
            purpose: "main", &_emit)
            result = client.create(
              "id" => id,
              "assignment" => ask.fetch("assignment"),
              "attempt" => ask.fetch("attempt"),
              "kind" => "text",
              "project" => project,
              "harness" => payload.fetch("harness"),
              "plan" => payload.fetch("question"),
              "question" => payload.fetch("question"),
              "ace_hitl_id" => "nh0a-boundary-#{purpose}")
            raise Scenario::Error, "the authority did not confirm the binding-verified ask" unless result.fetch("id") == id

            yield :receipt_id => @id_generator.call
            id
          end

          # settle consumes the delivered answers as the SAME worker
          # actor that asked (requester-only consume, kernel-verified).
          # settle consumes this authority's delivered answers as the
          # SAME worker actor that asked (requester-only consume,
          # kernel-verified). The uncertainty ask belongs to authority
          # A's worker.
          def settle_asks(client)
            receipt_ids = []
            consumed = true
            answer_matches = true
            ids = [@state.request_id(@authority)]
            ids << @state.uncertainty_request_id if @authority == "A"
            ids.compact.each do |request_id|
              answer = client.consume(request_id, timeout: 5).fetch("answer")
              answer_matches &&= answer == @manifest.payload.fetch("answer")
              receipt_ids << @id_generator.call
            rescue Ace::Hitl::Lifecycle::Error
              consumed = false
              answer_matches = false
            end
            consumed &&= ids.all? { |request_id| !request_id.nil? }
            @state.record_settle(@authority, consumed: consumed, answer_matches: answer_matches)
            {"passed" => consumed && answer_matches, "binding_verified" => true,
             :receipt_ids => receipt_ids}
          end
        end
      end
    end
  end
end
