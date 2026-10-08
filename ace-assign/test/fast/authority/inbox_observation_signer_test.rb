# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/assign/authority/inbox_observation_signer"

module Ace
  module Assign
    class InboxObservationSignerTest < AceAssignTestCase
      KEY = OpenSSL::PKey::RSA.new(2048)
      UUID = "0123abcd-0000-4000-8000-000000000001"

      class Kernel
        attr_accessor :uid
        def initialize = (@uid = 40)
        def capture(_pid) = {"uid" => uid}
        def live!(_caller) = true
      end

      class Context
        attr_accessor :record, :drift
        attr_reader :calls
        def initialize(record, fingerprint)
          @record, @fingerprint, @calls = record, fingerprint, []
        end
        def request(operation, params)
          @calls << operation
          case operation
          when "begin_context_operation"
            raise "wrong purpose" unless params["purpose"] == "observe_to_sign"
            {"operation_id" => "b" * 32, "key_generation" => 1, "fingerprint" => @fingerprint, "state" => "admitted"}
          when "snapshot_context"
            value = Marshal.load(Marshal.dump(record))
            value["claim_generation"] += 1 if drift && calls.count(operation) > 1
            {"operation_id" => "b" * 32, "key_generation" => 1, "context_id" => "context", "record" => value}
          when "end_context_operation" then {"operation_id" => "b" * 32, "state" => "ended"}
          else raise "unexpected context operation"
          end
        end
      end

      class Client
        attr_accessor :data, :bytes, :fail_reply
        attr_reader :uploads
        def initialize(data, bytes)
          @data, @bytes, @uploads = data, bytes, []
        end
        def mapping_id = "mapping"
        def call(operation, params, **options)
          case operation
          when "fetch_observation"
            raise "bad fetch mode" unless options == {download: true, purpose: :artifacts}
            Authority::Client::Reply.new(data: data, parts: [bytes], replayed: false)
          when "reconcile_inbox"
            @uploads << [params, options]
            raise AttemptErrors::EvidenceUnavailable, "reply lost" if fail_reply
            Authority::Client::Reply.new(data: {"state" => "completed"}, replayed: uploads.size > 1)
          else raise "unexpected authority operation"
          end
        end
      end

      def setup
        super
        @kernel = Kernel.new
        fingerprint = Digest::SHA256.hexdigest(KEY.public_to_der)
        target = {"session" => "w1", "pane" => "p1", "terminal_id" => "term1", "agent" => "codex", "thread" => UUID, "thread_kind" => "id"}
        process = {"pid" => 123, "uid" => 50, "start" => "birth", "host" => "host"}
        runtime = {"assignment_id" => "assignment", "attempt_id" => "attempt", "provider" => "codex", "provider_version" => "0.159.3",
          "native_target" => target, "runtime_process_binding" => process, "endpoint_reference_sha256" => "d" * 64, "observer_uid" => 30}
        intent = {"schema" => "ace.herdr.codex-submission/v1", "provider_version" => "0.159.3", "endpoint_reference_sha256" => "d" * 64,
          "server_process_binding" => process, "thread_id" => UUID, "event_id" => "event", "attempt_id" => "attempt",
          "claim_generation" => 1, "payload_sha256" => "a" * 64, "client_user_message_id" => "ace-#{'e' * 32}"}
        @record = {"event_id" => "event", "attempt_id" => "attempt", "claim_generation" => 1, "payload_sha256" => "a" * 64,
          "receipt_key_sha256" => fingerprint, "binding" => target, "state" => "delivered", "codex_submission" => intent, "codex_receipt" => nil}
        reference = {"provider" => "codex", "version" => "0.159.3", "thread_id" => UUID, "queued_submission_id" => nil,
          "client_user_message_id" => intent["client_user_message_id"], "turn_id" => UUID, "item_id" => "item-1", "payload_sha256" => "a" * 64}
        source = {"status" => "completed", "native_reference" => reference}
        observation = @record.slice("event_id", "attempt_id", "claim_generation", "payload_sha256", "binding").merge(
          "schema" => "ace.native-observation.v1", "provider" => "codex", "provider_version" => "0.159.3", "outcome" => "consumed",
          "runtime_process_binding" => process, "native_reference" => reference,
          "source_sha256" => Digest::SHA256.hexdigest(JSON.generate(source)), "source_bytes" => JSON.generate(source).bytesize, "source_excerpt" => source)
        bytes = JSON.generate(observation)
        binding = {"project_id" => "ace", "mapping_id" => "mapping", "assignment_id" => "assignment", "attempt_id" => "attempt", "event_id" => "event",
          "inbox_context_id" => "context", "registration" => @record.slice(*Authority::InboxObservationSigner::REGISTRATION),
          "claim_generation" => 1, "native_binding" => target, "codex_submission" => intent, "codex_receipt" => nil,
          "runtime_id" => "runtime", "runtime_binding" => runtime, "native_event_digest" => "f" * 64, "observer_uid" => 30}
        descriptor = {"version" => 1, "artifact_id" => "evidence", "kind" => "observation", "project_id" => "ace",
          "assignment_id" => "assignment", "attempt_id" => "attempt", "peer_uid" => 30, "role" => "observer",
          "binding_digest" => Atoms::EvidenceDigest.digest(binding), "sha256" => Digest::SHA256.hexdigest(bytes), "bytes" => bytes.bytesize,
          "admitted_at" => "2026-10-08T00:00:00Z", "admitted_after_event_digest" => "f" * 64,
          "request_id_or_event_id" => "event", "candidate_generation_or_claim_generation" => 1}
        @client = Client.new({"descriptor" => descriptor, "binding" => binding, "journal_commit" => "a" * 40, "generation" => 4,
          "current_claim_generation" => 1, "eligible" => true}, bytes)
        fixed = {"owner_credentials" => {"uid" => 20}, "native_mapping_id" => "mapping", "observer_uids" => [30], "signer_uids" => [40],
          "runtime_bindings" => {"runtime" => runtime}, "receipt_private_key" => {"path" => "/fixed"}}
        map = {"project_id" => "ace", "authority_id" => "authority", "worker_uid" => 10, "launcher_uid" => 11}
        @deployment = Object.new
        @deployment.define_singleton_method(:mapping) { |_| map }
        @deployment.define_singleton_method(:project) { |_| {"signer_uids" => [40], "inbox_contexts" => {"context" => fixed}} }
        @deployment.define_singleton_method(:authority) { |_| {"uid" => 12} }
        @context = Context.new(@record, fingerprint)
        loader = Object.new
        loader.define_singleton_method(:with) do |**_args, &block|
          reader = Object.new
          reader.define_singleton_method(:verify_unchanged!) { true }
          block.call(KEY, reader)
        end
        @signer = Authority::InboxObservationSigner.new(client: @client, deployment: @deployment, kernel: @kernel,
          context_client_factory: ->(*) { @context }, signing_key_factory: ->(*) { loader })
      end

      def settle
        @signer.settle(assignment_id: "assignment", attempt_id: "attempt", event_id: "event", inbox_context_id: "context",
          evidence_id: "evidence", mutation_id: "mutation", expected_generation: 4)
      end

      def test_signs_only_canonical_evidence_and_replays_exact_bytes_after_lost_reply
        @client.fail_reply = true
        assert_raises(AttemptErrors::EvidenceUnavailable) { settle }
        @client.fail_reply = false
        assert_equal "completed", settle["state"]
        first, second = @client.uploads.map { |_, options| options.fetch(:upload_parts) }
        assert_equal first, second
        assert KEY.verify(OpenSSL::Digest::SHA256.new, first.last, first.first)
        assert_equal @record.slice(*Authority::InboxObservationSigner::REGISTRATION), @client.uploads.last.first["expected_registration"]
        assert_equal ["begin_context_operation", "snapshot_context", "snapshot_context", "end_context_operation"] * 2, @context.calls
      end

      def test_generation_drift_or_ineligible_evidence_cannot_sign_or_reconcile
        @context.drift = true
        assert_raises(AttemptErrors::EvidenceUnavailable) { settle }
        assert_empty @client.uploads
        assert_equal "end_context_operation", @context.calls.last
        @context.drift = false
        @client.data["eligible"] = false
        assert_raises(AttemptErrors::EvidenceUnavailable) { settle }
        assert_empty @client.uploads
      end

      def test_descriptor_hash_role_peer_and_scope_substitution_refuse
        [{"sha256" => "0" * 64}, {"role" => "signer"}, {"peer_uid" => 99}, {"project_id" => "other"}].each do |changes|
          original = @client.data["descriptor"]
          @client.data["descriptor"] = original.merge(changes)
          assert_raises(AttemptErrors::EvidenceUnavailable) { settle }
          assert_empty @client.uploads
          @client.data["descriptor"] = original
        end
      end

      def test_worker_observer_and_owner_cannot_act_as_signer
        [10, 20, 30].each do |uid|
          @kernel.uid = uid
          assert_raises(AttemptErrors::EvidenceUnavailable) { settle }
        end
        assert_empty @context.calls
        assert_empty @client.uploads
      end
    end
  end
end
