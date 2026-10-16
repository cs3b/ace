# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../support/prepared_registration_fixture"
require "ace/assign/authority/ordinary_lifecycle"
require "ace/assign/authority/ordinary_server"
require "ace/assign/authority/ordinary_client"
require "ace/assign/authority/router"

module Ace
  module Assign
    class OrdinaryLifecycleTest < AceAssignTestCase
      # Wire, transfer, Git and replay are real. Installed/native permission
      # selection is tested in Lab; this is not a distinct-user receipt.
      class Admission
        attr_reader :service
        attr_accessor :role, :authorized, :native
        def initialize(service)
          @service, @role, @authorized, @native = service, :supervisor, true, true
          @peer = Authority::OrdinaryPeer.new
        end
        def verify_listener! = true
        def peer(socket, deadline:) = @peer.capture(socket, deadline: deadline)
        def authorize!(request:, peer:, deadline:)
          @peer.live!(peer, deadline: deadline)
          raise AttemptErrors::UnauthorizedIdentity unless @authorized && request.fetch("project_id") == "atlas"
          @role
        end
        def identity!(peer:, pane:, deadline:)
          @peer.live!(peer, deadline: deadline)
          raise AttemptErrors::UnauthorizedIdentity unless @native && pane == "w1:p1"
          Struct.new(:role, :actor).new("coordinator", Etc.getpwuid(peer.fetch("uid")).name)
        end
      end

      def test_registration_replay_survives_owner_restart_and_uses_only_canonical_bytes
        with_fixture do
          first = with_owner { |client| register(client) }
          commit = @journal.ref_value
          assert_equal "registered", first.data.fetch("phase")
          assert_equal @bundle, @journal.blob(first.data.fetch("prepared_bundle_ref"), commit: commit)
          assert_equal @artifact.definition_bytes, @journal.blob(first.data.fetch("definition_ref"), commit: commit)
          queue = Authority::OrdinaryQueue.new(work: @artifact.work, root: @inputs,
            bytes: @journal.blob(first.data.fetch("queue_ref"), commit: commit))
          assert_equal :pending, queue.status.steps.first.status
          # Remove the disposable projection. A new owner reads original
          # registration/reply from Git, not the old coordinator's memory.
          FileUtils.rm_rf(@journal.checkout_root)
          FileUtils.mkdir_p(@journal.checkout_root, mode: 0700)
          with_owner do |client|
            second = register(client)
            assert second.replayed
            assert_equal first.data, second.data
            assert_equal commit, @journal.ref_value
            status = client.call("registration_status", {"assignment_id" => "batch"})
            assert_equal first.data, status.data
            assert_raises(AttemptErrors::EvidenceUnavailable) { register(client, mutation: "replacement") }
            assert_equal commit, @journal.ref_value
            assert_raises(AttemptErrors::EvidenceUnavailable) do
              register(client, params: @params.merge("pane" => "w1:p2"))
            end
          end
          assert_equal 1, @journal.read_events("batch").count { |event| event["type"] == "authority_mutation" }
        end
      end

      def test_no_native_start_wrong_role_and_revocation_cannot_admit_or_replay
        with_fixture do
          with_owner do |client|
            @admission.native = false
            assert_raises(AttemptErrors::EvidenceUnavailable) { register(client) }
            assert_empty @journal.read_events("batch")
            @admission.native = true
            @admission.role = :worker
            assert_raises(AttemptErrors::EvidenceUnavailable) { register(client) }
            assert_empty @journal.read_events("batch")
            @admission.role = :supervisor
            accepted = register(client)
            @admission.authorized = false
            assert_raises(AttemptErrors::EvidenceUnavailable) { register(client) }
            assert_equal accepted.data.fetch("journal_commit"), @journal.ref_value
          end
        end
      end

      def test_duplicate_waiting_for_journal_lock_rechecks_revocation_before_reply
        with_fixture do
          with_owner do |client|
            register(client)
            commit = @journal.ref_value
            lock = File.open(@journal.send(:lock_path), File::RDWR)
            lock.flock(File::LOCK_EX)
            entered = Queue.new
            original = @journal.method(:with_lock)
            @journal.define_singleton_method(:with_lock) do |**options, &block|
              entered << true
              original.call(**options, &block)
            end
            waiting = Thread.new do
              register(client)
            rescue AttemptErrors::EvidenceUnavailable => error
              error
            end
            Timeout.timeout(5) { entered.pop }
            @admission.authorized = false
            lock.flock(File::LOCK_UN)
            assert waiting.join(3), "revoked replay must finish"
            assert_kind_of AttemptErrors::EvidenceUnavailable, waiting.value
            assert_equal commit, @journal.ref_value
          ensure
            lock&.close
          end
        end
      end

      def test_lifecycle_and_journal_lock_contention_respect_original_deadline
        with_fixture do
          with_owner { |client| register(client) }
          exclusion = Molecules::LifecycleExclusion.new(root: File.join(@root, "exclusion"))
          key = exclusion.task_key("8xf.t.ei9.0")
          exclusion.with_exclusive(key) do
            before = Process.clock_gettime(Process::CLOCK_MONOTONIC)
            assert_raises(AttemptErrors::MaintenanceBusy) do
              exclusion.with_shared_multi([key], deadline: before + 0.05) { flunk "contended lock must not admit" }
            end
            assert_operator Process.clock_gettime(Process::CLOCK_MONOTONIC) - before, :<, 1
          end
          File.open(@journal.send(:lock_path), File::RDWR) do |lock|
            lock.flock(File::LOCK_EX)
            before = Process.clock_gettime(Process::CLOCK_MONOTONIC)
            assert_raises(AttemptErrors::Conflict) do
              @journal.mutate(assignment_id: "batch", attempt_id: "definition-batch", mutation_id: "blocked",
                operation: "register_assignment", parameters_digest: "a" * 64, expected_generation: 1,
                deadline: before + 0.05) { flunk "contended journal must not mutate" }
            end
            assert_operator Process.clock_gettime(Process::CLOCK_MONOTONIC) - before, :<, 1
          end
        end
      end

      private

      def register(client, mutation: "original-registration", params: @params)
        client.call("register_assignment", params, mutation_id: mutation, upload_parts: [@bundle], purpose: :candidate)
      end

      def with_owner
        owner = Authority::OrdinaryLifecycle.new(project: "atlas", admission: @admission, journal: @journal,
          exclusion: Molecules::LifecycleExclusion.new(root: File.join(@root, "exclusion")), input_root: @inputs)
        server = Authority::OrdinaryServer.new(admission: @admission, lifecycle: Authority::Router.new(handlers: [owner]))
        thread = Thread.new { server.serve }
        Timeout.timeout(3) { sleep 0.005 until File.socket?(@service.fetch("socket_path")) }
        yield Authority::OrdinaryClient.new(project_id: "atlas", service: @service, verify_selection: -> {})
      ensure
        server&.request_stop
        server&.stop
        assert thread.join(3), "ordinary owner must drain"
      end

      def with_fixture
        Dir.mktmpdir("ordinary-lifecycle-", Etc.getpwuid(Process.uid).dir) do |root|
          @root = root
          File.chmod(0o700, root)
          repository = File.join(root, "journal")
          @inputs = File.join(root, "inputs")
          FileUtils.mkdir_p([repository, @inputs], mode: 0700)
          git(repository, "init", "-b", "main")
          git(repository, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "--allow-empty", "-m", "seed")
          @journal = Molecules::EvidenceJournal.new(repo_root: repository, checkout_root: File.join(root, "checkout"))
          @artifact = PreparedRegistrationFixture.build(root: @inputs, scope: "010.01", definition: {
            "session_id" => "batch", "project_id" => "atlas", "task_id" => "8xf.t.ei9.0",
            "name" => "verified delivery", "created_at" => "2026-10-16T00:00:00Z", "source_config" => "job.yaml"})
          @bundle = @artifact.bundle
          @params = @artifact.header(expected_generation: 0).merge("pane" => "w1:p1")
          @service = {"uid" => Process.uid, "gid" => Process.gid, "socket_path" => File.join(root, "owner.sock"), "state_root" => root}
          @admission = Admission.new(@service)
          yield
        end
      end

      def git(directory, *args)
        output, error, status = Open3.capture3("/usr/bin/git", "-C", directory, *args)
        raise error unless status.success?
        output
      end

    end
  end
end
