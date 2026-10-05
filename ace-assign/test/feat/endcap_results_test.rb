# frozen_string_literal: true
require_relative "../test_helper"
require "ace/assign/authority/endcap"
require "ace/assign/authority/launch_lifecycle"
require "ace/assign/authority/router"
require "ace/assign/authority/server"
require "ace/assign/authority/client"

module Ace
  module Assign
    # Real journal and wire seams with injected source-authorization identities.
    # This fixture does not claim installed native launch/scope/security proof.
    class EndcapResultsTest < AceAssignTestCase
      WIRE = Ace::Runtime::Molecules::ProtectedSocket
      class Kernel
        Handle = Struct.new(:identity) { def close; end }
        attr_accessor :peer_identity
        attr_reader :dead
        def initialize; @dead = []; end
        def supported!; true; end
        def capture(pid)
          {"pid" => pid, "uid" => pid == Process.pid ? Process.uid : 13001,
            "gid" => pid == Process.pid ? Process.gid : 13001,
            "groups" => pid == Process.pid ? Process.groups.sort : [13001],
            "started_at" => "fixture:#{pid}", "host" => "fixture", "parent_pid" => pid == 91 ? 90 : 1}
        end
        def live!(identity)
          raise AttemptErrors::EvidenceUnavailable, "source fixture process exited" if dead.include?(identity.fetch("pid"))
          true
        end
        def same?(left, right); left == right; end
        def descendant?(left, right); live!(right); left == right; end
        def pin(identity); live!(identity); Handle.new(identity); end
        def exited?(handle); dead.include?(handle.identity.fetch("pid")); end
        def peer(_socket); peer_identity; end
      end

      def git(root, *args)
        output, error, status = Open3.capture3("git", "-C", root, *args)
        assert status.success?, error
        output.strip
      end

      def fixture
        Dir.mktmpdir("ace-results-", Etc.getpwuid(Process.uid).dir) do |root|
          @root = root
          File.chmod(0700, root)
          repo = File.join(root, "repo")
          FileUtils.mkdir_p(repo)
          git(repo, "init", "-b", "main")
          git(repo, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "--allow-empty", "-m", "candidate")
          @head = git(repo, "rev-parse", "HEAD")
          @kernel = Kernel.new
          @launcher = @kernel.capture(81).merge("uid" => 13002, "gid" => 13002, "groups" => [13002])
          @worker = @kernel.capture(91)
          @reviewer = @kernel.capture(82).merge("uid" => 13003, "gid" => 13003, "groups" => [13003])
          @supervisor = @kernel.capture(83).merge("uid" => 13004, "gid" => 13004, "groups" => [13004])
          @executor = @kernel.capture(84).merge("uid" => 13005, "gid" => 13005, "groups" => [13005])
          @service = @kernel.capture(Process.pid).merge("socket_path" => File.join(root, "authority.sock"), "state_root" => root)
          @map = {"project_id" => "project", "authority_id" => "authority", "worker_uid" => 13001,
            "worker_gid" => 13001, "worker_groups" => [13001], "worker_actor" => "worker",
            "launcher_uid" => 13002, "launcher_gid" => 13002, "launcher_groups" => [13002],
            "bootstrap" => "/fixture/gate", "bootstrap_sha256" => "a" * 64, "worker_cwd" => "/fixture/worker",
            "native" => {"workspace_id" => "w1", "server_identity" => @kernel.capture(90), "socket_identity" => [1, 2, 13001]}}
          @project = {"assignment_root" => File.join(root, "assignments"), "supervisor_uids" => [13004],
            "reviewer_uids" => [13003], "service_executor_uids" => [13005], "peer_credentials" => {}}
          [@reviewer, @executor, @supervisor, @service].each do |identity|
            @project["peer_credentials"][identity.fetch("uid").to_s] = identity.slice("gid", "groups").merge("scratch_root" => root)
          end
          map, project, service = @map, @project, @service
          @deployment = Object.new
          @deployment.define_singleton_method(:mapping) { |_id| map }
          @deployment.define_singleton_method(:project) { |_id| project }
          @deployment.define_singleton_method(:authority) { |_id| service }
          @deployment.define_singleton_method(:verify!) { |*_, **_| map }
          @deployment.define_singleton_method(:verify_composition!) { |*_, **_| true }
          @deployment.define_singleton_method(:verify_receiver_paths!) { |_| true }
          @policy = Object.new
          @revoked = []
          revoked = @revoked
          @policy.define_singleton_method(:visible!) do |project:, uid:|
            raise AttemptErrors::UnauthorizedIdentity, "visibility revoked" if revoked.include?(uid)
            true
          end
          @journal = Molecules::EvidenceJournal.new(repo_root: repo, checkout_root: File.join(root, "checkout"), mode: :protected,
            evidence_reader: ->(*) { raise "unused service reader" }, service_authorizer: ->(*) { raise "unused service policy" })
          restart
          bytes = JSON.generate("session_id" => "assignment", "name" => "result fixture", "created_at" => "2026-10-05T00:00:00Z",
            "source_config" => "job.yaml", "task_id" => "task", "project_id" => "project")
          call("register_assignment", {"definition_bytes" => bytes, "definition_digest" => Digest::SHA256.hexdigest(bytes),
            "expected_generation" => 0}, id: "register", peer: @launcher, role: :launcher)
          state = call("reserve_attempt", {"scope" => "010", "worker_uid" => 13001, "runtime" => "herdr", "base_head" => @head,
            "launcher_process_binding" => @launcher, "expected_generation" => 1}, id: "reserve", peer: @launcher, role: :launcher).fetch(:data)
          @attempt = state.fetch("attempt_id")
          @binding = {"runtime" => "herdr", "session" => "w1", "pane" => "p1", "terminal_id" => "terminal",
            "process_identity" => @worker, "shell_identity" => @worker,
            "native_origin" => {"workspace" => "w1", "tab" => "t1", "pane" => "p1",
              "command" => ["/fixture/gate", "mapping", state.fetch("launch_ticket")], "cwd" => "/fixture/worker",
              "server_identity" => @map.dig("native", "server_identity"), "socket_identity" => [1, 2, 13001]}}
          state = call("record_launch", {"launch_ticket" => state.fetch("launch_ticket"), "process_binding" => @binding,
            "expected_generation" => state.fetch("generation")}, id: "record", peer: @launcher, role: :launcher).fetch(:data)
          call("bind_process", {"launch_ticket" => state.fetch("launch_ticket"), "process_binding" => @binding,
            "expected_generation" => state.fetch("generation")}, id: "bind", peer: @launcher, role: :launcher)
          candidate(1)
          yield
        ensure
          @server&.stop
          @owner&.join(3)
          @server = @owner = nil
        end
      end

      def restart
        @launch = Authority::LaunchLifecycle.new(deployment: @deployment, kernel: @kernel, journals: {"project" => @journal})
        @endcap = Authority::Endcap.new(deployment: @deployment, launch: @launch, kernel: @kernel, service_policy: @policy)
        @router = Authority::Router.new(launch: @launch, handlers: [@endcap])
      end

      def candidate(number)
        @journal.mutate(assignment_id: "assignment", attempt_id: @attempt, mutation_id: "candidate-#{number}",
          operation: "submit_candidate", parameters_digest: "a" * 64, expected_generation: generation) do
          {data: {"head" => @head, "candidate_generation" => number}}
        end
      end

      def generation
        @journal.authority_generation(@journal.read_events("assignment").select { |event| event["attempt_id"] == @attempt })
      end

      def call(operation, params, id: nil, peer: @worker, role: :worker, transfer: nil)
        request = {"version" => 1, "operation" => operation, "mutation_id" => id, "project_id" => "project",
          "params" => params.merge("mapping_id" => "mapping", "assignment_id" => "assignment")}
        request["params"]["attempt_id"] ||= @attempt unless %w[register_assignment reserve_attempt].include?(operation)
        @router.dispatch(request: request, peer: peer, role: role, transfer: transfer)
      end

      def upload(verdict: "succeeded", parts: ["first\x00\r\n".b, "second evidence"], receipt: nil)
        receipt ||= {"attempt_id" => @attempt, "assignment_id" => "assignment", "project_id" => "project", "scope" => "010",
          "operation" => "work", "producer" => {"actor" => "worker", "role" => "worker", "runtime" => "herdr"},
          "head" => @head, "verdict" => verdict, "checks" => [{"name" => "executed", "verdict" => "passed"}],
          "artifacts" => parts.each_with_index.map { |bytes, i| {"path" => "private-#{i}", "sha256" => Digest::SHA256.hexdigest(bytes)} }}
        bytes = JSON.generate(receipt)
        transferred = [bytes] + parts
        params = {"head" => @head, "candidate_generation" => 1, "expected_generation" => generation,
          "receipt_sha256" => Digest::SHA256.hexdigest(bytes), "transfer" => Authority::TransferCodec.new(root: @root).descriptor(transferred, purpose: :receipt_artifacts)}
        input = Struct.new(:parts) do
          def count; parts.length; end
          def bytes(index: 0); parts.fetch(index); end
        end.new(transferred)
        [params, input, receipt]
      end

      def submit(**options)
        params, input, = upload(**options)
        call("submit_result", params, id: "result", transfer: input)
      end

      def status(selector = nil, peer: @supervisor, role: :supervisor)
        call("attempt_status", {"result_candidate_generation" => selector}, peer: peer, role: role).fetch(:data)
      end

      def fetch(result, index = 0, peer: @supervisor, role: :supervisor)
        call("evidence_fetch", {"kind" => "result", "purpose_id" => result.fetch("result_id"),
          "artifact_id" => result.fetch("artifacts")[index].fetch("path").delete_prefix("evidence/imports/")}, peer: peer, role: role)
      end

      def test_result_private_record_and_ordered_blobs_commit_once_with_distinct_digests
        fixture do
          params, input, receipt = upload
          original = Models::ExecutionReceipt.from_h(receipt).digest
          result = call("submit_result", params, id: "result", transfer: input)
          data = result.fetch(:data)
          assert_equal (Authority::Endcap::RESULT_FIELDS + %w[generation journal_commit]).sort, data.keys.sort
          assert_equal original, data.fetch("original_receipt_digest")
          assert_equal params["receipt_sha256"], data["uploaded_receipt_sha256"]
          refute_equal data["receipt_digest"], data["original_receipt_digest"]
          events = @journal.read_events("assignment", commit: data.fetch("journal_commit")).select { |event| event["attempt_id"] == @attempt }
          assert Models::EvidenceEvent.chain_valid?(events)
          private_record = events.find { |event| event["type"] == "result_submitted" }.fetch("payload")
          assert_equal Authority::Endcap::RESULT_PAYLOAD_FIELDS.sort, private_record.keys.sort
          assert_equal @binding, private_record.dig("binding", "process_binding")
          assert_equal receipt["producer"], private_record.dig("receipt", "producer")
          assert_equal "first\x00\r\n".b, fetch(data).fetch(:transfer_parts).first
          assert_equal "second evidence", fetch(data, 1).fetch(:transfer_parts).first
          refute events.any? { |event| %w[receipt_accepted transition].include?(event["type"]) }
          before = @journal.ref_value
          replay = call("submit_result", params, id: "result", transfer: input)
          assert replay.fetch(:replayed)
          assert_equal data, replay.fetch(:data)
          assert_equal before, @journal.ref_value
          assert_equal 1, @journal.read_events("assignment").count { |event| event["type"] == "result_submitted" }
          assert_raises(AttemptErrors::Conflict) { call("submit_result", params, id: "new-result", transfer: input) }
          assert_raises(AttemptErrors::Conflict) { call("submit_result", params.merge("expected_generation" => 0), id: "result", transfer: input) }
          assert_equal before, @journal.ref_value
        end
      end

      def test_failed_empty_result_survives_restart_exit_discovery_and_same_head_correction
        fixture do
          data = submit(verdict: "failed", parts: []).fetch(:data)
          assert_empty data["artifacts"]
          FileUtils.rm_rf(@project.fetch("assignment_root"))
          FileUtils.rm_rf(File.join(@root, "checkout"))
          restart
          @kernel.dead << @worker.fetch("pid")
          assert_equal data.slice(*Authority::Endcap::RESULT_FIELDS), status.fetch("submitted_result")
          assert_raises(AttemptErrors::EvidenceUnavailable) { submit(verdict: "failed", parts: []) }
          @kernel.dead.clear
          candidate(2)
          params, input, = upload(parts: ["corrected"])
          corrected = call("submit_result", params.merge("candidate_generation" => 2), id: "corrected", transfer: input).fetch(:data)
          assert_equal @head, corrected["head"]
          refute_equal data["result_id"], corrected["result_id"]
          assert_equal corrected["result_id"], status.fetch("submitted_result").fetch("result_id")
          assert_equal data["result_id"], status(1).fetch("submitted_result").fetch("result_id")
          assert_raises(AttemptErrors::NotFound) { status(3) }
        end
      end

      def test_canonical_absence_is_null_and_selectors_schema_and_executor_fail_closed
        fixture do
          assert_nil status.fetch("submitted_result")
          assert_equal 1, status.fetch("result_candidate_generation")
          assert_raises(ArgumentError) { status(-1) }
          assert_raises(ArgumentError) { call("attempt_status", {}) }
          assert_raises(ArgumentError) { call("attempt_status", {"result_candidate_generation" => nil}, id: "illegal") }
          assert_raises(AttemptErrors::UnauthorizedIdentity) { status(nil, peer: @executor, role: :executor) }
        end
      end

      def test_source_authorization_roles_reassignment_visibility_and_wrong_purposes
        fixture do
          data = submit.fetch(:data)
          [[:worker, @worker], [:launcher, @launcher], [:supervisor, @supervisor]].each do |role, peer|
            projection = status(nil, peer: peer, role: role)
            assert_equal data["result_id"], projection.dig("submitted_result", "result_id")
            if role == :worker
              %w[process_binding launcher_identity mapping_id receipt producer binding].each { |key| refute projection.key?(key), key }
              %w[receipt producer binding process_binding].each { |key| refute projection.fetch("submitted_result").key?(key), key }
            end
            assert_equal "first\x00\r\n".b, fetch(data, peer: peer, role: role).fetch(:transfer_parts).first
          end
          assert_raises(AttemptErrors::UnauthorizedIdentity) { fetch(data, peer: @executor, role: :executor) }
          assert_raises(AttemptErrors::UnauthorizedIdentity) { fetch(data, peer: @launcher.merge("started_at" => "reused"), role: :launcher) }
          assert_raises(AttemptErrors::UnauthorizedIdentity) { fetch(data, peer: @reviewer, role: :reviewer) }
          review_params = {"head" => @head, "candidate_generation" => 1, "expected_generation" => generation,
            "reviewer_uid" => @reviewer["uid"], "reviewer_process_binding" => @reviewer}
          call("assign_review", review_params, id: "review", peer: @launcher, role: :launcher)
          projection = status(nil, peer: @reviewer, role: :reviewer)
          assert_equal data["result_id"], projection.dig("submitted_result", "result_id")
          %w[process_binding launcher_identity mapping_id receipt producer binding].each { |key| refute projection.key?(key), key }
          %w[receipt producer binding process_binding].each { |key| refute projection.fetch("submitted_result").key?(key), key }
          assert_equal "first\x00\r\n".b, fetch(data, peer: @reviewer, role: :reviewer).fetch(:transfer_parts).first
          candidate(2)
          assert_equal data["result_id"], status(1, peer: @reviewer, role: :reviewer).dig("submitted_result", "result_id")
          call("assign_review", review_params.merge("candidate_generation" => 2, "expected_generation" => generation),
            id: "review-new", peer: @launcher, role: :launcher)
          assert_raises(AttemptErrors::UnauthorizedIdentity) { fetch(data, peer: @reviewer, role: :reviewer) }
          @revoked << @supervisor["uid"]
          assert_raises(AttemptErrors::UnauthorizedIdentity) { status }
          assert_raises(AttemptErrors::UnauthorizedIdentity) { fetch(data) }
          assert_raises(AttemptErrors::UnauthorizedIdentity) do
            call("evidence_fetch", {"kind" => "review", "purpose_id" => "anything", "artifact_id" => "artifact"}, peer: @worker)
          end
        end
      end

      def test_bad_receipt_producer_digest_artifact_order_and_stale_candidate_do_not_change_ref
        fixture do
          before = @journal.ref_value
          params, input, receipt = upload
          [receipt.merge("producer" => {"actor" => "forged", "role" => "worker", "runtime" => "herdr"}),
           receipt.merge("digest" => "c" * 64), receipt.merge("campaign" => {}), receipt.merge("extra" => true)].each_with_index do |bad, i|
            bad_params, bad_input, = upload(receipt: bad)
            assert_raises(AttemptErrors::ReceiptRejected, AttemptErrors::EvidenceUnavailable) { call("submit_result", bad_params, id: "bad-#{i}", transfer: bad_input) }
            assert_equal before, @journal.ref_value
          end
          input.parts[1], input.parts[2] = input.parts[2], input.parts[1]
          assert_raises(AttemptErrors::ReceiptRejected) { call("submit_result", params, id: "reordered", transfer: input) }
          params, input, = upload
          assert_raises(AttemptErrors::Conflict) { call("submit_result", params.merge("candidate_generation" => 0), id: "stale", transfer: input) }
          assert_raises(AttemptErrors::UnauthorizedIdentity) { call("submit_result", params, id: "forged-peer", peer: @worker.merge("started_at" => "reused"), transfer: input) }
          assert_raises(ArgumentError) { call("submit_result", params.merge("actor" => "worker"), id: "extra", transfer: input) }
          assert_equal before, @journal.ref_value
        end
      end
    end
  end
end

module Ace
  module Assign
    class EndcapResultsTest
      def start_server
        @kernel.peer_identity = @worker
        @server = Authority::Server.new(authority_id: "authority", lifecycle: @router,
          deployment: @deployment, kernel: @kernel, composition: "services")
        # Private socket directory is a source fixture, not installer proof.
        wire = Object.new
        wire.define_singleton_method(:root_path!) { |*_, **_| true }
        %i[socket_identity read write deadline].each do |name|
          wire.define_singleton_method(name) { |*args, **options| WIRE.public_send(name, *args, **options) }
        end
        @server.define_singleton_method(:wire) { wire }
        @owner = Thread.new { @server.serve }
        Timeout.timeout(3) { sleep 0.005 until File.socket?(@service.fetch("socket_path")) }
        client_kernel = Kernel.new
        client_kernel.peer_identity = @service.slice("uid", "gid", "groups")
        @client = Authority::Client.new(mapping_id: "mapping", deployment: @deployment, kernel: client_kernel)
      end

      def client_params(params)
        params.except("mapping_id", "transfer").merge("assignment_id" => "assignment", "attempt_id" => @attempt)
      end

      def client_fetch(data)
        @client.call("evidence_fetch", client_params("kind" => "result", "purpose_id" => data.fetch("result_id"),
          "artifact_id" => data.fetch("artifacts").first.fetch("path").delete_prefix("evidence/imports/")),
          download: true, purpose: :artifacts)
      end

      def test_real_client_server_submit_lost_reply_exit_restart_status_and_exact_fetch
        fixture do
          start_server
          params, input, = upload
          original_dispatch = @router.method(:dispatch)
          lost_once = false
          @router.define_singleton_method(:dispatch) do |**options|
            result = original_dispatch.call(**options)
            if options.fetch(:request).fetch("operation") == "submit_result" && !lost_once
              lost_once = true
              raise IOError, "source fixture reply lost after durable CAS"
            end
            result
          end
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            @client.call("submit_result", client_params(params), mutation_id: "wire-result", upload_parts: input.parts, purpose: :receipt_artifacts)
          end
          @kernel.dead << @worker.fetch("pid")
          @kernel.peer_identity = @supervisor
          FileUtils.rm_rf(@project.fetch("assignment_root"))
          FileUtils.rm_rf(File.join(@root, "checkout"))
          @journal = Molecules::EvidenceJournal.new(repo_root: @journal.repo_root, checkout_root: File.join(@root, "new-checkout"),
            mode: :protected, evidence_reader: ->(*) { raise "unused" }, service_authorizer: ->(*) { raise "unused" })
          restart
          router = @router
          @server.instance_variable_set(:@lifecycle, router)
          discovered = @client.call("attempt_status", client_params("result_candidate_generation" => nil))
          assert_equal false, discovered.replayed
          data = discovered.data.fetch("submitted_result")
          assert_equal generation, discovered.data.fetch("authority_generation")
          assert_equal 2, data.fetch("artifacts").length
          refute data.key?("receipt")
          refute data.key?("binding")
          reply = client_fetch(data)
          assert_equal ["first\x00\r\n".b], reply.parts
          descriptor, transfer = reply.data.values_at("descriptor", "transfer")
          assert_equal [descriptor.slice("bytes", "sha256")], transfer.fetch("parts")
          assert_equal descriptor["sha256"], transfer["sha256"]
          assert_equal @journal.ref_value, reply.data["journal_commit"]
          assert_empty Dir.children(File.join(@root, "transfers"))
          @revoked << @supervisor.fetch("uid")
          assert_raises(AttemptErrors::EvidenceUnavailable) { client_fetch(data) }
        end
      end

      def test_real_client_refuses_missing_mismatched_extra_part_and_open_descriptor_before_bytes
        fixture do
          data = submit.fetch(:data)
          start_server
          original = @router.method(:dispatch)
          corruption = nil
          @router.define_singleton_method(:dispatch) do |**options|
            result = original.call(**options)
            if options.fetch(:request).fetch("operation") == "evidence_fetch"
              result = Marshal.load(Marshal.dump(result))
              case corruption
              when :missing then result[:data].delete("descriptor")
              when :mismatch then result[:data]["descriptor"]["sha256"] = "f" * 64
              when :extra then result[:transfer_parts] << "extra"
              when :open then result[:data]["descriptor"]["private"] = "must not escape"
              end
            end
            result
          end
          wire = @server.send(:wire)
          wire.define_singleton_method(:write) do |socket, value, **options|
            if corruption == :missing_transfer && value.dig("data", "descriptor")
              value = Marshal.load(Marshal.dump(value))
              value["data"].delete("transfer")
            end
            WIRE.write(socket, value, **options)
          end
          %i[missing missing_transfer mismatch extra open].each do |bad|
            corruption = bad
            assert_raises(AttemptErrors::EvidenceUnavailable) { client_fetch(data) }
          end
          corruption = nil
          assert_equal ["first\x00\r\n".b], client_fetch(data).parts
        end
      end

      def alter_canonical(path, bytes)
        @journal.send(:with_lock) do
          checkout = @journal.send(:checkout_dir)
          bytes.nil? ? File.unlink(File.join(checkout, path)) : File.binwrite(File.join(checkout, path), bytes)
          git(checkout, "add", "--", path)
          git(checkout, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "-m", "corrupt canonical fixture")
          git(@journal.repo_root, "update-ref", @journal.ref, git(checkout, "rev-parse", "HEAD"))
        end
      end

      def test_corrupt_blob_and_private_record_never_fall_back_to_workspace_or_cached_reply
        fixture do
          params, input, = upload
          data = call("submit_result", params, id: "result", transfer: input).fetch(:data)
          commit = @journal.ref_value
          artifact = data.fetch("artifacts").first.fetch("path")
          File.binwrite(File.join(@journal.repo_root, "private-0"), input.parts[1])
          alter_canonical(artifact, "corruption")
          assert_raises(AttemptErrors::EvidenceUnavailable) { status }
          assert_raises(AttemptErrors::EvidenceUnavailable) { fetch(data) }
          assert_raises(AttemptErrors::EvidenceUnavailable) { call("submit_result", params, id: "result", transfer: input) }
          git(@journal.repo_root, "update-ref", @journal.ref, commit)
          event = @journal.read_events("assignment").find { |item| item["type"] == "result_submitted" }
          path = "execution/assignment/events/#{@journal.send(:event_filename, event)}"
          changed = Marshal.load(Marshal.dump(event))
          changed["payload"]["receipt"]["producer"]["actor"] = "forged"
          alter_canonical(path, JSON.generate(changed))
          restart
          assert_raises(AttemptErrors::EvidenceUnavailable) { status }
          assert_raises(AttemptErrors::EvidenceUnavailable) { fetch(data) }
          git(@journal.repo_root, "update-ref", @journal.ref, commit)
          alter_canonical(path, nil)
          assert_raises(AttemptErrors::EvidenceUnavailable) { status }
          assert_raises(AttemptErrors::EvidenceUnavailable) { fetch(data) }
          git(@journal.repo_root, "update-ref", @journal.ref, commit)
          duplicate = Models::EvidenceEvent.build(type: "result_submitted", attempt_id: @attempt,
            previous_digest: @journal.read_events("assignment").last.fetch("digest"), payload: event.fetch("payload"))
          @journal.append(assignment_id: "assignment", attempt_id: @attempt, events: [duplicate])
          assert_raises(AttemptErrors::EvidenceUnavailable) { status }
          assert_raises(AttemptErrors::EvidenceUnavailable) { fetch(data) }
        end
      end

      def test_pre_cas_failure_leaves_no_result_and_cas_retry_revalidates_generation
        fixture do
          params, input, = upload
          before = @journal.ref_value
          @journal.stub(:update_ref_cas, ->(*) { raise IOError, "source fixture CAS failure" }) do
            assert_raises(IOError) { call("submit_result", params, id: "before-cas", transfer: input) }
          end
          assert_equal before, @journal.ref_value
          assert_nil status.fetch("submitted_result")
          assert_empty @journal.read_events("assignment").select { |event| event["type"] == "result_submitted" }
          original = @journal.method(:update_ref_cas)
          journal = @journal
          competed = false
          @journal.define_singleton_method(:update_ref_cas) do |new_commit, old|
            unless competed
              competed = true
              output, error, status = Open3.capture3("git", "-C", repo_root, "-c", "user.name=test", "-c", "user.email=test@example.invalid",
                "commit-tree", "#{new_commit}^{tree}", "-p", old, "-m", "same-id competing source fixture", stdin_data: "")
              raise error unless status.success?
              _out, error, status = Open3.capture3("git", "-C", repo_root, "update-ref", ref, output.strip, old)
              raise error unless status.success?
              next false
            end
            original.call(new_commit, old)
          end
          replay = call("submit_result", params, id: "competing", transfer: input)
          assert replay.fetch(:replayed)
          assert_equal @journal.ref_value, replay.dig(:data, "journal_commit")
          assert_equal 1, @journal.read_events("assignment").count { |event| event["type"] == "result_submitted" }
        end
      end
    end
  end
end

module Ace
  module Assign
    class EndcapResultsTest
      def test_retained_review_fetch_exact_reviewer_purpose_and_terminal_result_permissions
        fixture do
          data = submit.fetch(:data)
          review = call("assign_review", {"head" => @head, "candidate_generation" => 1, "expected_generation" => generation,
            "reviewer_uid" => @reviewer["uid"], "reviewer_process_binding" => @reviewer},
            id: "review", peer: @launcher, role: :launcher).fetch(:data)
          _, _, receipt = upload(parts: ["review report"])
          receipt.merge!("operation" => "review", "review" => {"head" => @head, "verdict" => "approved",
            "reviewer" => {"actor" => review.fetch("reviewer_actor")}})
          params, input, = upload(parts: ["review report"], receipt: receipt)
          accepted = call("accept_review", params.merge("purpose_id" => review.fetch("review_id")), id: "accept-review",
            peer: @reviewer, role: :reviewer, transfer: input).fetch(:data)
          ref = accepted.fetch("review_receipt").fetch("artifacts").first
          fetch_params = {"kind" => "review", "purpose_id" => review.fetch("review_id"),
            "artifact_id" => ref.fetch("path").delete_prefix("evidence/imports/")}
          [[:reviewer, @reviewer], [:launcher, @launcher], [:supervisor, @supervisor]].each do |role, peer|
            assert_equal ["review report"], call("evidence_fetch", fetch_params, peer: peer, role: role).fetch(:transfer_parts)
          end
          assert_raises(AttemptErrors::UnauthorizedIdentity) { call("evidence_fetch", fetch_params) }
          assert_raises(AttemptErrors::UnauthorizedIdentity) { call("evidence_fetch", fetch_params, peer: @executor, role: :executor) }
          # Fixture terminal history exercises retained reads, not finish proof.
          events = @journal.read_events("assignment").select { |event| event["attempt_id"] == @attempt }
          terminal = Models::EvidenceEvent.build(type: "transition", attempt_id: @attempt, previous_digest: events.last.fetch("digest"),
            payload: {"from" => "running", "to" => "failed", "reason" => "source-only retained-read fixture"})
          @journal.append(assignment_id: "assignment", attempt_id: @attempt, events: [terminal])
          @kernel.dead << @worker.fetch("pid")
          restart
          assert_equal data["result_id"], status(1).dig("submitted_result", "result_id")
          assert_equal ["first\x00\r\n".b], fetch(data).fetch(:transfer_parts)
          assert_equal ["review report"], call("evidence_fetch", fetch_params, peer: @reviewer, role: :reviewer).fetch(:transfer_parts)
          @kernel.dead << @reviewer.fetch("pid")
          assert_raises(AttemptErrors::EvidenceUnavailable) { call("evidence_fetch", fetch_params, peer: @reviewer, role: :reviewer) }
          assert_equal ["review report"], call("evidence_fetch", fetch_params, peer: @launcher, role: :launcher).fetch(:transfer_parts)
          assert_raises(AttemptErrors::EvidenceUnavailable) { submit }
        end
      end

      def test_recorded_executor_fetches_only_own_canonical_terminal_service_evidence
        fixture do
          owner = Authority::ServiceEvidence.new(journal: @journal)
          @journal.instance_variable_set(:@evidence_reader, ->(reference, record, state, pending) { owner.call(reference, record, state, pending) })
          @journal.instance_variable_set(:@service_authorizer, ->(*) {})
          binding = {"request_id" => "request-1", "assignment_id" => "assignment", "attempt_id" => @attempt,
            "project_id" => "project", "operation" => "publish", "input_digest" => "a" * 64, "target" => {"resource" => "fixture"},
            "candidate_head" => @head, "executor_uid" => @executor["uid"], "transport" => "unix", "dispatch_ticket_id" => "ticket",
            "claim_binding" => "b" * 64, "candidate_generation" => 1, "claim_generation" => 1, "policy_digest" => "c" * 64}
          claim = binding.merge("state" => "accepted")
          @journal.mutate(assignment_id: "assignment", attempt_id: @attempt, mutation_id: "claim", operation: "fixture",
            parameters_digest: "a" * 64, expected_generation: generation) do
            {data: {}, service_updates: [{request_id: "request-1", expected: nil, replacement: claim, event_type: "service_claim"}]}
          end
          bytes = "ace-service-attestation request:request-1 input:#{binding.fetch('input_digest')} outcome:succeeded\nexecuted fixture"
          events = @journal.read_events("assignment").select { |event| event["attempt_id"] == @attempt }
          plan = Molecules::CanonicalEvidence.new(journal: @journal).import_plan(**owner.context(binding), artifacts: [bytes],
            admitted_after_event_digest: events.last.fetch("digest"))
          receipt = binding.slice(*Molecules::EvidenceJournal::TERMINAL_BINDING_FIELDS).merge("outcome" => "succeeded", "evidence" => plan.fetch(:references))
          completed = binding.merge("state" => "succeeded", "receipt" => receipt)
          @journal.mutate(assignment_id: "assignment", attempt_id: @attempt, mutation_id: "complete", operation: "fixture",
            parameters_digest: "b" * 64, expected_generation: generation) do
            plan.merge(data: {}, service_updates: [{request_id: "request-1", expected: claim, replacement: completed, event_type: "service_transition"}])
          end
          params = {"kind" => "service", "purpose_id" => "request-1", "artifact_id" => plan.fetch(:references).first.fetch("ref").delete_prefix("evidence/imports/")}
          [[:executor, @executor], [:launcher, @launcher], [:supervisor, @supervisor]].each do |role, peer|
            assert_equal [bytes], call("evidence_fetch", params, peer: peer, role: role).fetch(:transfer_parts)
          end
          assert_raises(AttemptErrors::UnauthorizedIdentity) { call("evidence_fetch", params, peer: @executor.merge("uid" => 13006), role: :executor) }
          assert_raises(AttemptErrors::UnauthorizedIdentity) { call("evidence_fetch", params) }
          assert_raises(AttemptErrors::UnauthorizedIdentity) { call("evidence_fetch", params, peer: @reviewer, role: :reviewer) }
          @revoked << @executor["uid"]
          assert_raises(AttemptErrors::UnauthorizedIdentity) { call("evidence_fetch", params, peer: @executor, role: :executor) }
          %w[inbox observation].each do |kind|
            assert_raises(AttemptErrors::EvidenceUnavailable) do
              call("evidence_fetch", params.merge("kind" => kind), peer: @supervisor, role: :supervisor)
            end
          end
        end
      end
    end
  end
end

module Ace
  module Assign
    class EndcapResultsTest
      def test_services_read_body_and_mutation_metadata_refuse_without_canonical_change
        fixture do
          data = submit.fetch(:data)
          start_server
          @kernel.peer_identity = @supervisor
          before = @journal.ref_value
          requests = [
            ["attempt_status", {"result_candidate_generation" => nil}],
            ["evidence_fetch", {"kind" => "result", "purpose_id" => data.fetch("result_id"),
              "artifact_id" => data.fetch("artifacts").first.fetch("path").delete_prefix("evidence/imports/")}]
          ]
          socket = nil
          requests.each do |operation, params|
            socket = UNIXSocket.new(@service.fetch("socket_path"))
            WIRE.write(socket, {"version" => 1, "operation" => operation, "project_id" => "project", "mutation_id" => nil,
              "params" => client_params(params).merge("mapping_id" => "mapping")}, deadline: WIRE.deadline(2))
            socket.write("unexpected body")
            socket.shutdown(Socket::SHUT_WR)
            reply = WIRE.read(socket, deadline: WIRE.deadline(2))
            assert_equal "invalid_input", reply.dig("error", "code")
            refute reply.key?("data")
            socket.close
          end
          assert_equal before, @journal.ref_value
        ensure
          socket&.close
        end
      end
    end
  end
end

module Ace
  module Assign
    class EndcapResultsTest
      def test_campaign_result_and_review_refuse_before_local_campaign_manager_lookup
        require "ace/review"
        fixture do
          review = call("assign_review", {"head" => @head, "candidate_generation" => 1, "expected_generation" => generation,
            "reviewer_uid" => @reviewer["uid"], "reviewer_process_binding" => @reviewer},
            id: "review", peer: @launcher, role: :launcher).fetch(:data)
          bytes = JSON.generate("campaign_id" => "campaign-1", "accepted" => true, "dry_run" => false,
            "result_identity" => "fixture", "evidence" => {"current_head" => @head})
          _, _, receipt = upload(parts: [bytes])
          receipt.merge!("operation" => "review", "review" => {"head" => @head, "verdict" => "approved",
            "reviewer" => {"actor" => review.fetch("reviewer_actor")}},
            "campaign" => {"id" => "campaign-1", "result" => receipt.fetch("artifacts").first})
          params, input, = upload(parts: [bytes], receipt: receipt)
          before = @journal.ref_value
          Ace::Review::Organisms::CampaignManager.stub(:new, ->(**_) { flunk "protected receipt must never consult local campaign state" }) do
            assert_raises(AttemptErrors::EvidenceUnavailable) { call("submit_result", params, id: "campaign-result", transfer: input) }
            assert_raises(AttemptErrors::EvidenceUnavailable) do
              call("accept_review", params.merge("purpose_id" => review.fetch("review_id")), id: "campaign-review",
                transfer: input, peer: @reviewer, role: :reviewer)
            end
          end
          assert_equal before, @journal.ref_value
        end
      end
    end
  end
end
