# frozen_string_literal: true
require_relative "../test_helper"
require "ace/assign/authority/endcap"
require "ace/herdr/organisms/inbox"

module Ace
  module Assign
    # Actual canonical Git CAS and Inbox signature/event lock; source fixtures
    # stand in for installed identities, never an installed scope/closure claim.
    class EndcapInboxesTest < AceAssignTestCase
      BOOT = "12345678-1234-1234-1234-123456789abc"
      class Kernel
        attr_accessor :dead
        def live!(identity)
          raise AttemptErrors::EvidenceUnavailable, "dead peer" if Array(dead).include?(identity["pid"])
        end
        def same?(left, right); left == right; end
        def supported!; raise "consumed proof must not open native endpoint"; end
      end
      class Launch
        def initialize(journal, launcher); @journal, @launcher = journal, launcher; end
        def with_assignment(params:, map:); yield @journal, {}; end
        def origin(*, **); {"launcher_identity" => @launcher}; end
      end
      Parts = Struct.new(:parts) do
        def count; parts.size; end
        def bytes(index: 0); parts.fetch(index); end
      end

      def fixture(child: false)
        Dir.mktmpdir do |root|
          repo = File.join(root, "repo"); FileUtils.mkdir_p(repo)
          git_in(repo, "init", "-b", "main")
          git_in(repo, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "--allow-empty", "-m", "fixture")
          @journal = Molecules::EvidenceJournal.new(repo_root: repo, checkout_root: File.join(root, "checkout"), mode: :protected,
            evidence_reader: ->(*) { raise "unused" }, service_authorizer: ->(*) { raise "unused" })
          @peer = process(82, 13004)
          @launcher = process(81, 13002)
          server = process(90, 13001)
          @map = {"project_id" => "project", "authority_id" => "authority", "launcher_uid" => 13002, "native" => {}}
          key = OpenSSL::PKey::RSA.new(1024)
          @key = key
          key_path = File.join(root, "public.pem"); File.write(key_path, key.public_to_pem)
          @context = {"native_mapping_id" => "mapping", "supervisor_uids" => [13004], "deliveries_dir" => File.join(root, "deliveries"),
            "receipt_public_key" => key_path, "pi_queue_client" => "/absent/client"}
          @unsafe = false
          @deployment = Object.new
          owner = self
          @deployment.define_singleton_method(:mapping) { |id| raise KeyError unless id == "mapping"; owner.instance_variable_get(:@map) }
          @deployment.define_singleton_method(:inbox_context) { |_mapping, id| raise AttemptErrors::EvidenceUnavailable unless id == "context"; owner.instance_variable_get(:@context) }
          @deployment.define_singleton_method(:verify_inbox_context!) { |*| raise Ace::Runtime::RuntimeUnavailableError if owner.instance_variable_get(:@unsafe); true }
          @kernel = Kernel.new
          @policy = Object.new
          @policy.define_singleton_method(:visible!) { |**| true }
          restart
          mutate("reserve_attempt", "reserve", 0, {data: {"project_id" => "project", "assignment_id" => "assignment",
            "attempt_id" => "attempt", "mapping_id" => "mapping", "reservation_generation" => 1, "launch_ticket" => "ticket"},
            events: [{type: "intent", payload: {"scope" => "010"}}]})
          parent = {"project_id" => "project", "assignment_id" => "assignment", "attempt_id" => "attempt", "mapping_id" => "mapping",
            "slot_id" => "slot", "reservation_generation" => 1, "scope_generation" => 2, "deployment_digest" => "a" * 64,
            "boot_id" => BOOT, "slice_invocation_id" => "b" * 32,
            "cgroup_identity" => {"path" => "/sys/fs/cgroup/slot.slice", "mount_id" => 1, "filesystem_type" => "cgroup2", "device" => 2, "inode" => 3},
            "resource_identities" => [{"host_path" => "/var/lib/slot", "view_path" => "/scratch", "mount_id" => 4,
              "filesystem_type" => "ext4", "device" => 5, "inode" => 6, "uid" => 13001, "gid" => 13001}]}
          mutate("fixture_parent", "parent", 1, {data: {}, events: [{type: "scope_bound", payload: parent}]})
          parent_event = events.find { |event| event["type"] == "scope_bound" }
          mutate("fixture_native", "native", 2, {data: {}, events: [{type: "scope_native_bound", payload: {
            "scope_generation" => 2, "scope_binding_event_id" => parent_event.fetch("digest"), "service_invocation_id" => "c" * 32,
            "server_identity" => server, "socket_identity" => [1, 2, 13001], "workspace_id" => "w1"}}]})
          if child
            original = {"runtime" => "herdr", "session" => "w1", "pane" => "p1", "terminal_id" => "terminal",
              "process_identity" => process(91, 13001).merge("parent_pid" => 90), "shell_identity" => process(91, 13001).merge("parent_pid" => 90),
              "native_origin" => {"workspace" => "w1", "tab" => "t1", "pane" => "p1", "server_identity" => server,
                "socket_identity" => [1, 2, 13001], "command" => ["/fixture/gate", "mapping", "ticket"], "cwd" => "/scratch"}}
            mutate("fixture_child", "child", 3, {data: {}, events: [{type: "scope_child_bound", payload: {
              "scope_generation" => 2, "scope_binding_event_id" => parent_event.fetch("digest"),
              "native_binding_event_id" => events.find { |event| event["type"] == "scope_native_bound" }.fetch("digest"),
              "original_process_binding" => original}}]})
          end
          executor = Object.new
          executor.define_singleton_method(:pane_get_bounded) do |_pane|
            Ace::Herdr::Molecules::ExecutionResult.new(stdout: JSON.generate("result" => {"pane" => {
              "pane_id" => "p1", "workspace_id" => "w1", "terminal_id" => "terminal", "agent" => "codex", "agent_status" => "busy",
              "agent_session" => {"agent" => "codex", "kind" => "id", "value" => "0123abcd-0000-4000-8000-000000000001"}}}),
              stderr: "", success: true, exit_code: 0)
          end
          native = Object.new; native.define_singleton_method(:submit) { |**| {"accepted" => true} }
          @box = Ace::Herdr::Organisms::Inbox.new(executor: executor, native: native, deliveries_dir: @context.fetch("deliveries_dir"), receipt_public_key: key.public_key)
          @box.enqueue(event: "event", attempt: "attempt", ref: {"session" => "w1", "pane" => "p1"}, payload: "message")
          record = @box.deliver(event: "event")
          @registration = record.slice("event_id", "attempt_id", "payload_sha256", "receipt_key_sha256")
          mutate("fixture_registration", "registration", child ? 4 : 3, {data: {}, events: [{type: "inbox_binding", payload: {
            "event_id" => "event", "attempt_id" => "attempt", "inbox_context_id" => "context", "registration" => @registration}}]})
          receipt = record.slice("event_id", "attempt_id", "claim_generation", "payload_sha256", "binding").merge(
            "outcome" => "consumed", "observer" => {"role" => "supervisor", "id" => "observer"},
            "evidence" => {"kind" => "consumed_acknowledged", "native_reference" => "native:1", "observation" => "consumed"})
          @bytes = JSON.generate(receipt); @signature = key.sign(OpenSSL::Digest::SHA256.new, @bytes)
          @params = {"mapping_id" => "mapping", "assignment_id" => "assignment", "attempt_id" => "attempt",
            "expected_generation" => child ? 5 : 4, "event_id" => "event", "inbox_context_id" => "context", "expected_registration" => @registration,
            "receipt_sha256" => Digest::SHA256.hexdigest(@bytes), "signature_sha256" => Digest::SHA256.hexdigest(@signature), "transfer" => {}}
          yield
        end
      end

      def process(pid, uid)
        {"pid" => pid, "uid" => uid, "gid" => uid, "groups" => [uid], "parent_pid" => 1,
          "started_at" => "linux:#{BOOT}:#{pid}", "host" => "fixture"}
      end
      def events; @journal.read_events("assignment").select { |event| event["attempt_id"] == "attempt" }; end
      def mutate(operation, id, generation, plan)
        @journal.mutate(assignment_id: "assignment", attempt_id: "attempt", mutation_id: id, operation: operation,
          parameters_digest: Digest::SHA256.hexdigest(id), expected_generation: generation) { plan }
      end
      def restart
        @owner = Authority::Endcap.new(deployment: @deployment, launch: Launch.new(@journal, @launcher), kernel: @kernel, service_policy: @policy)
      end
      def reconcile(params: @params, peer: @peer, role: :supervisor, id: "reconcile", parts: [@bytes, @signature])
        @owner.dispatch(request: {"operation" => "reconcile_inbox", "project_id" => "project", "mutation_id" => id, "params" => params},
          peer: peer, role: role, transfer: Parts.new(parts))
      end

      def test_signed_consumed_import_replay_fetch_and_corruption_after_native_stop
        fixture do
          result = reconcile
          assert_equal "completed", result.dig(:data, "state")
          assert_equal 5, result.dig(:data, "generation")
          assert_equal 2, events.count { |event| event["type"] == "evidence_import" }
          @kernel.dead = [90, 91]
          restart
          replay = reconcile
          assert replay.fetch(:replayed)
          assert_equal result.fetch(:data), replay.fetch(:data)
          ref = result.dig(:data, "receipt_ref")
          request = {"operation" => "evidence_fetch", "project_id" => "project", "mutation_id" => nil, "params" => {
            "mapping_id" => "mapping", "assignment_id" => "assignment", "attempt_id" => "attempt", "kind" => "inbox",
            "purpose_id" => "event", "artifact_id" => ref.fetch("artifact_id")}}
          fetched = @owner.dispatch(request: request, peer: @peer, role: :supervisor)
          assert_equal [@bytes], fetched.fetch(:transfer_parts)
          assert_equal "signer", fetched.dig(:data, "descriptor", "role")
          @journal.stub(:blob, "corrupt") do
            assert_raises(AttemptErrors::EvidenceUnavailable) { reconcile }
            assert_raises(AttemptErrors::EvidenceUnavailable) { @owner.dispatch(request: request, peer: @peer, role: :supervisor) }
          end
        end
      end

      def test_wrong_registration_role_context_signature_and_body_refuse_without_import
        fixture do
          assert_raises(AttemptErrors::Conflict) { reconcile(params: @params.merge("expected_registration" => @registration.merge("payload_sha256" => "a" * 64))) }
          assert_raises(AttemptErrors::UnauthorizedIdentity) { reconcile(role: :worker) }
          assert_raises(AttemptErrors::EvidenceUnavailable) { reconcile(params: @params.merge("inbox_context_id" => "missing")) }
          assert_raises(ArgumentError) { reconcile(parts: [@bytes, "wrong"]) }
          altered = @params.merge("signature_sha256" => Digest::SHA256.hexdigest("wrong"))
          assert_raises(AttemptErrors::EvidenceUnavailable) { reconcile(params: altered, parts: [@bytes, "wrong"]) }
          assert_equal 0, events.count { |event| event["type"] == "evidence_import" }
          @unsafe = true
          assert_raises(AttemptErrors::EvidenceUnavailable) { reconcile }
        end
      end

      def test_retained_proof_after_seal_requires_current_context_role_and_exact_launcher
        fixture do
          accepted = reconcile
          parent = events.find { |event| event["type"] == "scope_bound" }
          mutate("fixture_seal", "seal", 5, {data: {}, events: [{type: "scope_sealed", payload: {
            "scope_generation" => 2, "scope_binding_event_id" => parent.fetch("digest")}}]})
          @kernel.dead = [90, 91]
          assert_equal accepted.fetch(:data), reconcile.fetch(:data)
          assert_raises(AttemptErrors::UnauthorizedIdentity) { reconcile(peer: @launcher.merge("started_at" => "replaced"), role: :launcher) }
          assert_equal "completed", reconcile(peer: @launcher, role: :launcher).dig(:data, "state")
          @context["supervisor_uids"] = []
          assert_raises(AttemptErrors::UnauthorizedIdentity) { reconcile }
          @context["supervisor_uids"] = [13004]
          @policy.define_singleton_method(:visible!) { |**| raise AttemptErrors::UnauthorizedIdentity, "revoked" }
          assert_raises(AttemptErrors::UnauthorizedIdentity) { reconcile }
        end
      end

      def test_changed_same_id_and_uncontextual_registration_cannot_adopt_old_proof
        fixture do
          reconcile
          assert_raises(AttemptErrors::Conflict) { reconcile(params: @params.merge("expected_generation" => 5)) }
          assert_raises(ArgumentError) { reconcile(params: @params.merge("expected_registration" => nil)) }
          assert_raises(ArgumentError) { reconcile(params: @params.merge("extra" => true)) }
          assert_equal 2, events.count { |event| event["type"] == "evidence_import" }
        end
        fixture do
          mutate("fixture_duplicate_registration", "old-registration", 4, {data: {}, events: [{type: "inbox_binding", payload: @registration}]})
          assert_raises(AttemptErrors::EvidenceUnavailable) { reconcile }
          assert_equal 0, events.count { |event| event["type"] == "evidence_import" }
        end
      end

      def test_superseded_claim_history_is_retained_but_not_used_to_settle_a_new_claim
        fixture do
          receipt = JSON.parse(@bytes)
          receipt["outcome"] = "superseded"
          receipt["evidence"]["kind"] = "queue_evicted"
          @bytes = JSON.generate(receipt)
          @signature = @key.sign(OpenSSL::Digest::SHA256.new, @bytes)
          @params = @params.merge("receipt_sha256" => Digest::SHA256.hexdigest(@bytes),
            "signature_sha256" => Digest::SHA256.hexdigest(@signature))
          first = reconcile
          assert_equal "queued", first.dig(:data, "state")
          historical = events.find { |event| event["type"] == "inbox_reconciliation" }
          old_params, old_bytes, old_signature = @params, @bytes, @signature
          record = @box.deliver(event: "event")
          assert_equal 2, record.fetch("claim_generation")
          assert_raises(AttemptErrors::EvidenceUnavailable) { reconcile }
          receipt = record.slice("event_id", "attempt_id", "claim_generation", "payload_sha256", "binding").merge(
            "outcome" => "consumed", "observer" => {"role" => "supervisor", "id" => "observer"},
            "evidence" => {"kind" => "consumed_acknowledged", "native_reference" => "native:2", "observation" => "consumed"})
          @bytes = JSON.generate(receipt); @signature = @key.sign(OpenSSL::Digest::SHA256.new, @bytes)
          @params = @params.merge("expected_generation" => 5, "receipt_sha256" => Digest::SHA256.hexdigest(@bytes),
            "signature_sha256" => Digest::SHA256.hexdigest(@signature))
          second = reconcile(id: "claim-two")
          assert_equal "completed", second.dig(:data, "state")
          assert_equal [1, 2], events.select { |event| event["type"] == "inbox_reconciliation" }.map { |event| event.dig("payload", "claim_generation") }
          assert_equal historical, events.find { |event| event["digest"] == historical.fetch("digest") }
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            reconcile(params: old_params, parts: [old_bytes, old_signature])
          end
          assert_equal second.fetch(:data), reconcile(id: "claim-two").fetch(:data)
        end
      end

      def test_signed_foreign_workspace_and_original_child_mismatch_refuse_before_import
        fixture do
          store = Ace::Herdr::Molecules::DeliveryRecordStore
          record = store.load(@context.fetch("deliveries_dir"), "event")
          foreign = record.inbox.merge("binding" => record.inbox.fetch("binding").merge("session" => "foreign-workspace"))
          store.save(record.advance_inbox(state: record.state, inbox: foreign, detail: {"action" => "fixture"}, timestamp: Time.now.utc.iso8601), @context.fetch("deliveries_dir"))
          receipt = JSON.parse(@bytes)
          receipt["binding"]["session"] = "foreign-workspace"
          @bytes = JSON.generate(receipt); @signature = @key.sign(OpenSSL::Digest::SHA256.new, @bytes)
          @params = @params.merge("receipt_sha256" => Digest::SHA256.hexdigest(@bytes), "signature_sha256" => Digest::SHA256.hexdigest(@signature))
          assert_raises(AttemptErrors::EvidenceUnavailable) { reconcile }
          assert_equal 0, events.count { |event| event["type"] == "evidence_import" }
          assert_equal "delivered", @box.status(event: "event").fetch("state")
        end
        %w[pane terminal_id].each do |field|
          fixture(child: true) do
            store = Ace::Herdr::Molecules::DeliveryRecordStore
            record = store.load(@context.fetch("deliveries_dir"), "event")
            foreign_value = field == "pane" ? "p2" : "foreign-terminal"
            foreign = record.inbox.merge("origin_target" => record.inbox.fetch("origin_target").merge(field => foreign_value),
              "binding" => record.inbox.fetch("binding").merge(field => foreign_value))
            store.save(record.advance_inbox(state: record.state, inbox: foreign, detail: {"action" => "fixture"}, timestamp: Time.now.utc.iso8601), @context.fetch("deliveries_dir"))
            receipt = JSON.parse(@bytes); receipt["binding"][field] = foreign_value
            @bytes = JSON.generate(receipt); @signature = @key.sign(OpenSSL::Digest::SHA256.new, @bytes)
            @params = @params.merge("receipt_sha256" => Digest::SHA256.hexdigest(@bytes), "signature_sha256" => Digest::SHA256.hexdigest(@signature))
            assert_raises(AttemptErrors::EvidenceUnavailable) { reconcile }
            assert_equal 0, events.count { |event| event["type"] == "evidence_import" }
            assert_equal "delivered", @box.status(event: "event").fetch("state")
          end
        end
        fixture(child: true) do
          assert_equal "completed", reconcile.dig(:data, "state")
          @kernel.dead = [90, 91]
          assert reconcile.fetch(:replayed)
        end
      end

      def test_herdr_accepted_before_qjl_failure_replays_exact_signed_proof
        fixture do
          original = @journal.method(:mutate)
          @journal.define_singleton_method(:mutate) do |**args, &block|
            if args[:operation] == "reconcile_inbox"
              block.call(read_events("assignment").select { |event| event["attempt_id"] == "attempt" }, ref_value, 4)
              raise AttemptErrors::EvidenceUnavailable, "fixture crash before CAS"
            end
            original.call(**args, &block)
          end
          assert_raises(AttemptErrors::EvidenceUnavailable) { reconcile }
          assert_equal "completed", @box.status(event: "event").fetch("state")
          assert_equal 0, events.count { |event| event["type"] == "evidence_import" }
          @journal.define_singleton_method(:mutate) { |**args, &block| original.call(**args, &block) }
          assert_equal "completed", reconcile.dig(:data, "state")
          assert_equal 1, events.count { |event| event["type"] == "inbox_reconciliation" }
        end
      end
    end
  end
end
