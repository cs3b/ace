# frozen_string_literal: true
require_relative "../test_helper"
require_relative "../support/endcap_result_owner_fixture"
require "ace/assign/authority/server"
require "ace/assign/authority/client"
require "ace/assign/authority/deployment_history"
require "securerandom"

module Ace
  module Assign
    class PreparedWorkFetchTest < AceAssignTestCase
      include EndcapResultOwnerFixture

      class ArtifactProtection
        def root_path!(_path); true; end
        def verify!(_path, handle, directory:)
          raise "wrong held artifact kind" unless directory ? handle.stat.directory? : handle.stat.file?
        end
      end

      def protected_artifact(name, bytes)
        path = File.join(@root, name)
        File.binwrite(path, bytes)
        {"path" => path, "bytes" => bytes.bytesize, "sha256" => Digest::SHA256.hexdigest(bytes)}
      end

      def with_artifact_protection
        factory = lambda do
          owner = Ace::Runtime::Molecules::ProtectedArtifactSet.allocate
          owner.send(:initialize, protection: ArtifactProtection.new)
          owner
        end
        Ace::Runtime::Molecules::ProtectedArtifactSet.stub(:new, factory) { yield }
      end

      def configure_result_owner_fixture
        @project.merge!("journal_repository" => @journal.repo_root, "evidence_git_ref" => @journal.ref,
          "evidence_checkout_root" => @journal.checkout_root)
        return unless @real_history_fixture
        @map = @map.merge("worker_argv" => ["/usr/bin/true", "authority", "worker"], "worker_env" => {"PATH" => "/usr/bin"},
          "execution_scope" => @map.fetch("execution_scope").merge("backend" => "linux_systemd_cgroup_v2",
            "slice_unit" => "ace-slot.slice", "unit_manifest_sha256" => "b" * 64,
            "boundary_manifest_sha256" => "c" * 64, "root_directory" => "/var/lib/ace-slot/root", "runtime_directory" => "/run/ace-slot"),
          "native" => @map.fetch("native").merge("socket_path" => "/fixture/herdr.sock", "executable" => "/fixture/herdr",
            "version" => "0.9.3", "protocol" => 22, "executable_sha256" => "e" * 64))
        @project = @project.merge("candidate_root" => File.join(@root, "candidates"), "launcher_uids" => [13002], "worker_uids" => [13001])
        @project["peer_credentials"] = [@worker, @launcher, @reviewer, @executor, @supervisor].to_h do |peer|
          [peer.fetch("uid").to_s, peer.slice("gid", "groups").merge("scratch_root" => File.join(@root, "scratch-#{peer.fetch('uid')}"))]
        end
        value = {"schema" => "ace.assign.authorities/v2", "authorities" => {"authority" => @service.slice("uid", "gid", "groups", "socket_path", "state_root").merge("composition" => "launch")},
          "projects" => {"project" => @project}, "launch_mappings" => {"mapping" => @map}}
        reference = protected_artifact("original-descriptor.json", JSON.generate(value))
        @deployment = with_artifact_protection { Authority::Deployment.load_artifact(reference) }
        @map = @deployment.mapping("mapping")
        @project = @deployment.project("project")
      end

      def prepared_fetch(**options)
        call("evidence_fetch", {"kind" => "prepared_work", "purpose_id" => "original_prepared_work",
          "artifact_id" => "prepared_bundle"}, **options)
      end

      def issue_original
        state = call("inspect_launch", {}, peer: @launcher, role: :launcher).fetch(:data)
        @bound_state = state
        server, worker = UNIXSocket.pair
        request = {"params" => {"mapping_id" => "mapping", "launch_ticket" => state.fetch("launch_ticket")}}
        gate = Thread.new { @launch.gate_ready(request: request, peer: @worker, socket: server, deadline: WIRE.deadline(5)) }
        assert_equal "ready", WIRE.read(worker, deadline: WIRE.deadline(5)).dig("data", "phase")
        issued = call("release_launch", {"launch_ticket" => state.fetch("launch_ticket"), "process_binding" => @binding,
          "expected_generation" => state.fetch("generation")}, id: "release", peer: @launcher, role: :launcher)
        @release_permission = WIRE.read(worker, deadline: WIRE.deadline(5))
        assert_equal "release", @release_permission.fetch("operation")
        gate.join(2)
        refute gate.alive?
        issued
      ensure
        server&.close
        worker&.close
        gate&.kill if gate&.alive?
      end

      def start_server
        @kernel.peer_identity = @worker
        @server = Authority::Server.new(authority_id: "authority", lifecycle: @router,
          deployment: @deployment, kernel: @kernel, composition: "launch")
        # Only installed-directory admission is injected; framing and body EOF
        # are the maintained public Server/Client/TransferCodec implementations.
        wire = Object.new
        wire.define_singleton_method(:root_path!) { |*_, **_| true }
        %i[socket_identity read write deadline].each do |name|
          wire.define_singleton_method(name) { |*args, **options| WIRE.public_send(name, *args, **options) }
        end
        @server.define_singleton_method(:wire) { wire }
        @owner = Thread.new { @server.serve }
        Timeout.timeout(3) { sleep 0.005 until File.socket?(@service.fetch("socket_path")) }
        client_kernel = Kernel.new
        original_worker = @worker
        client_kernel.define_singleton_method(:capture) { |_| original_worker }
        client_kernel.peer_identity = @service.slice("uid", "gid", "groups")
        @client = Authority::Client.new(mapping_id: "mapping", deployment: @deployment, kernel: client_kernel)
      end

      def client_fetch
        @client.call("evidence_fetch", {"assignment_id" => "assignment", "attempt_id" => @attempt,
          "kind" => "prepared_work", "purpose_id" => "original_prepared_work", "artifact_id" => "prepared_bundle"},
          download: true, purpose: :candidate, timeout: 30)
      end

      def alter_current_artifacts(updates)
        @journal.send(:with_lock) do
          checkout = @journal.send(:checkout_dir)
          updates.each { |path, bytes| File.binwrite(File.join(checkout, path), bytes) }
          git(checkout, "add", "--", *updates.keys)
          git(checkout, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "-m", "replace current projection")
          git(@journal.repo_root, "update-ref", @journal.ref, git(checkout, "rev-parse", "HEAD"))
        end
      end

      def test_real_client_server_downloads_bundle_larger_than_evidence_artifact_limit
        @prepared_context_text = SecureRandom.hex(100_000)
        fixture do
          issue_original
          original = prepared_fetch.fetch(:data).fetch("descriptor")
          assert_equal @worker, original.fetch("original_worker_identity")
          assert_equal @map.fetch("task_context_entry"), original.fetch("task_context_entry")
          assert_operator original.fetch("bytes"), :>, 64 * 1024
          start_server
          before = @journal.ref_value
          reply = client_fetch
          assert_equal [@prepared_registration.bundle], reply.parts
          assert_equal original, reply.data.fetch("descriptor")
          assert_equal false, reply.replayed
          assert_equal before, @journal.ref_value
          assert_equal :artifacts, @router.transfer_binding({"operation" => "evidence_fetch", "params" => {"kind" => "result"}}).fetch(:purpose)
          assert_equal :candidate, @router.transfer_binding({"operation" => "evidence_fetch", "params" => {"kind" => "prepared_work"}}).fetch(:purpose)
        end
      ensure
        @prepared_context_text = nil
      end

      def test_release_pins_exact_original_registration_and_replay_does_not_replace_it
        fixture do
          issued = issue_original.fetch(:data)
          pin = issued.fetch("prepared_input")
          assert_equal %w[bundle_bytes bundle_ref bundle_sha256 definition_digest original_binding_digest prepared_work registration_commit registration_generation], pin.keys.sort
          assert_equal pin, @release_permission.fetch("prepared_input")
          descriptor = prepared_fetch.fetch(:data).fetch("descriptor")
          assert_equal descriptor.values_at("registration_generation", "registration_commit", "definition_digest", "original_binding_digest", "ref", "bytes", "sha256"),
            pin.values_at("registration_generation", "registration_commit", "definition_digest", "original_binding_digest", "bundle_ref", "bundle_bytes", "bundle_sha256")
          assert_equal @prepared_registration.work.reference(head: @prepared_registration.head, tree: @prepared_registration.tree), pin.fetch("prepared_work")
          before = @journal.ref_value
          replay = call("release_launch", {"launch_ticket" => @bound_state.fetch("launch_ticket"), "process_binding" => @binding,
            "expected_generation" => @bound_state.fetch("generation")}, id: "release", peer: @launcher, role: :launcher)
          assert replay.fetch(:replayed)
          assert_equal pin, replay.fetch(:data).fetch("prepared_input")
          assert_equal before, @journal.ref_value
        end
      end

      def test_release_refuses_unavailable_original_bundle_before_issued_commit
        fixture do
          original = @journal.method(:bounded_blob)
          @journal.define_singleton_method(:bounded_blob) do |path, **options|
            path.start_with?("execution/prepared/") ? nil : original.call(path, **options)
          end
          before = @journal.ref_value
          assert_raises(AttemptErrors::EvidenceUnavailable) { issue_original }
          assert_equal before, @journal.ref_value
          refute @journal.read_events("assignment").any? { |event| event.dig("payload", "operation") == "release_launch" }
        end
      end

      def test_fetch_refuses_missing_or_changed_accepted_release_pin_before_bundle_bytes
        fixture do
          issue_original
          inventory_owner = @journal.method(:canonical_event_inventory!)
          bad = :missing
          @journal.define_singleton_method(:canonical_event_inventory!) do |**options|
            inventory = Marshal.load(Marshal.dump(inventory_owner.call(**options)))
            release = inventory.fetch("events").fetch("assignment").find { |event| event.dig("payload", "operation") == "release_launch" }
            if bad == :missing
              release.fetch("payload").fetch("data").delete("prepared_input")
            elsif bad == :float
              pin = release.fetch("payload").fetch("data").fetch("prepared_input")
              pin["registration_generation"] = pin.fetch("registration_generation").to_f
            else
              release.fetch("payload").fetch("data").fetch("prepared_input")["bundle_sha256"] = "f" * 64
            end
            inventory
          end
          blob_owner = @journal.method(:bounded_blob)
          bundle_reads = 0
          @journal.define_singleton_method(:bounded_blob) do |path, **options|
            bundle_reads += 1 if path.start_with?("execution/prepared/")
            blob_owner.call(path, **options)
          end
          before = @journal.ref_value
          assert_raises(AttemptErrors::EvidenceUnavailable) { prepared_fetch }
          bad = :changed
          assert_raises(AttemptErrors::EvidenceUnavailable) { prepared_fetch }
          bad = :float
          assert_raises(AttemptErrors::EvidenceUnavailable) { prepared_fetch }
          assert_equal 0, bundle_reads
          assert_equal before, @journal.ref_value
        end
      end

      def test_real_client_refuses_wrong_selector_open_descriptor_extra_part_and_replay_before_body
        fixture do
          issue_original
          start_server
          original = @router.method(:dispatch)
          corruption = nil
          @router.define_singleton_method(:dispatch) do |**options|
            result = original.call(**options)
            if options.fetch(:request).fetch("operation") == "evidence_fetch"
              result = Marshal.load(Marshal.dump(result))
              case corruption
              when :selector then result[:data]["descriptor"]["attempt_id"] = "different-attempt"
              when :purpose then result[:data]["descriptor"]["purpose"] = "different-purpose"
              when :ref then result[:data]["descriptor"]["ref"] = "execution/prepared/other.bundle"
              when :digest then result[:data]["descriptor"]["sha256"] = "f" * 64
              when :identity then result[:data]["descriptor"]["original_worker_identity"]["started_at"] = "reused-worker"
              when :entry then result[:data]["descriptor"]["task_context_entry"]["wrapper"]["bytes"] = 0
              when :open then result[:data]["descriptor"]["private"] = "must not escape"
              when :extra then result[:transfer_parts] << "extra"
              when :replay then result[:replayed] = true
              end
            end
            result
          end
          descriptor = prepared_fetch.fetch(:data).fetch("descriptor")
          codec = @client.send(:prepared_transfer_codec, descriptor)
          original_receive = codec.method(:receive)
          receives = 0
          codec.define_singleton_method(:receive) do |*args, **options, &block|
            receives += 1
            original_receive.call(*args, **options, &block)
          end
          @client.define_singleton_method(:prepared_transfer_codec) { |_descriptor| codec }
          before = @journal.ref_value
          %i[selector purpose ref digest identity entry open extra replay].each do |bad|
            corruption = bad
            assert_raises(AttemptErrors::EvidenceUnavailable) { client_fetch }
            assert_equal 0, receives, "#{bad} must refuse before transferred bytes"
          end
          corruption = nil
          assert_equal [@prepared_registration.bundle], client_fetch.parts
          assert_equal 1, receives
          assert_equal before, @journal.ref_value
        end
      end

      def test_authenticated_descendant_fetch_uses_exact_original_anchor
        fixture do
          issue_original
          child = @kernel.capture(92).merge("parent_pid" => @worker.fetch("pid"))
          anchor = @worker.dup
          @kernel.define_singleton_method(:descendant?) do |peer, original|
            live!(peer); live!(original)
            original == anchor && (peer == original || peer == child)
          end
          before = @journal.ref_value
          assert_equal [@prepared_registration.bundle], prepared_fetch(peer: child).fetch(:transfer_parts)
          assert_raises(AttemptErrors::UnauthorizedIdentity) { prepared_fetch(peer: child.merge("started_at" => "reused-child")) }
          assert_raises(AttemptErrors::UnauthorizedIdentity) { prepared_fetch(peer: @kernel.capture(93)) }
          assert_equal before, @journal.ref_value
        end
      end

      def test_new_current_artifact_bytes_cannot_replace_original_prepared_selection
        fixture do
          issue_original
          original = prepared_fetch
          params = {"assignment_id" => "assignment", "attempt_id" => @attempt, "mapping_id" => "mapping"}
          selected = @launch.original_prepared_registration!(journal: @journal, params: params, commit: @journal.ref_value)
          registration = selected.fetch(:registration)
          assert selected.frozen?
          assert registration.fetch("prepared_work").frozen?
          assert selected.fetch(:state).fetch("process_binding").frozen?
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            @journal.bounded_blob(registration.fetch("prepared_bundle_ref"), commit: selected.fetch(:registration_commit), max_bytes: 1)
          end
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            @journal.bounded_blob("execution/prepared/missing.bundle", commit: selected.fetch(:registration_commit), max_bytes: 1024)
          end
          alter_current_artifacts(registration.fetch("definition_ref") => "changed current definition",
            registration.fetch("prepared_bundle_ref") => "changed current bundle")
          before = @journal.ref_value
          assert_equal "changed current bundle", @journal.blob(registration.fetch("prepared_bundle_ref"))
          reply = prepared_fetch
          assert_equal original.fetch(:transfer_parts), reply.fetch(:transfer_parts)
          assert_equal original.fetch(:data).fetch("descriptor"), reply.fetch(:data).fetch("descriptor")
          assert_equal before, reply.fetch(:data).fetch("journal_commit")
          assert_equal before, @journal.ref_value
        end
      end

      def test_current_descriptor_cannot_replace_original_mapping_and_missing_retention_refuses
        @real_history_fixture = true
        installed_verify = Authority::Deployment.instance_method(:verify!)
        # Only actual installed/native checks are controlled. Descriptor bytes,
        # schema, held artifacts, history selection and canonical joins are real.
        Authority::Deployment.define_method(:verify!) { |mapping_id, **| mapping(mapping_id) }
        fixture do
          issue_original
          expected = prepared_fetch
          original = @deployment
          value = JSON.parse(JSON.generate(original.data))
          value.fetch("launch_mappings").fetch("mapping")["worker_cwd"] = "/different/current/worker"
          value.fetch("launch_mappings").fetch("mapping").fetch("task_context_entry").fetch("wrapper")["sha256"] = "9" * 64
          value.fetch("projects").fetch("project").fetch("peer_credentials").fetch("13001")["scratch_root"] = File.join(@root, "different-current-scratch")
          current_ref = protected_artifact("current-descriptor.json", JSON.generate(value))
          current = with_artifact_protection { Authority::Deployment.load_artifact(current_ref) }
          history_ref = protected_artifact("history.json", JSON.generate("schema" => "ace.assign.deployment-history/v1",
            "original_descriptor" => original.artifact_reference, "candidate_descriptor" => current.artifact_reference,
            "descriptors" => [original.artifact_reference, current.artifact_reference], "public_keys" => []))
          @history = with_artifact_protection { Authority::DeploymentHistory.load_artifact(history_ref) }
          @deployment = current
          restart
          before = @journal.ref_value
          assert_equal expected, prepared_fetch
          @history = nil
          restart
          assert_raises(AttemptErrors::EvidenceUnavailable) { prepared_fetch }
          assert_equal before, @journal.ref_value
        end
      ensure
        Authority::Deployment.define_method(:verify!, installed_verify) if installed_verify
        @real_history_fixture = false
      end

      def test_unreleased_original_refuses_without_journal_effect
        fixture do
          before = @journal.ref_value
          assert_raises(AttemptErrors::EvidenceUnavailable) { prepared_fetch }
          assert_equal before, @journal.ref_value
        end
      end

      def test_issued_fetch_refuses_other_birth_role_upload_and_purpose_without_effect
        fixture do
          issue_original
          before = @journal.ref_value
          assert_raises(AttemptErrors::UnauthorizedIdentity) { prepared_fetch(peer: @launcher, role: :launcher) }
          assert_raises(AttemptErrors::UnauthorizedIdentity) { prepared_fetch(peer: @worker.merge("started_at" => "different-birth")) }
          assert_raises(ArgumentError) { prepared_fetch(transfer: Object.new) }
          assert_raises(ArgumentError) do
            call("evidence_fetch", {"kind" => "prepared_work", "purpose_id" => "different-purpose", "artifact_id" => "prepared_bundle"})
          end
          assert_equal before, @journal.ref_value
        end
      end

      def test_issued_original_fetches_exact_retained_bytes_without_journal_effect
        fixture do
          issue_original
          before = @journal.ref_value
          reply = prepared_fetch
          descriptor = reply.fetch(:data).fetch("descriptor")
          bytes = reply.fetch(:transfer_parts).fetch(0)
          assert_equal Digest::SHA256.hexdigest(bytes), descriptor.fetch("sha256")
          assert_equal bytes.bytesize, descriptor.fetch("bytes")
          assert_equal "original_prepared_work", descriptor.fetch("purpose")
          assert_equal @attempt, descriptor.fetch("attempt_id")
          assert_equal before, @journal.ref_value
          assert_equal false, reply.fetch(:replayed)
        end
      end
    end
  end
end
