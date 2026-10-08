# frozen_string_literal: true
require_relative "endcap_result_owner_fixture"
require_relative "prepared_workspace_resource_fixture"
require "ace/assign/authority/server"
require "ace/assign/authority/client"
require "ace/assign/authority/deployment_history"
require "securerandom"

# Shared helpers only: no runnable test class or inherited test methods.
module Ace
  module Assign
    module PreparedWorkFetchFixture
      include EndcapResultOwnerFixture
      include PreparedWorkspaceResourceFixture

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
        if @oversized_worker_entry
          @map.fetch("worker_entry").each_value { |reference| reference["path"] = "/" + "\n" * 4094 }
        end
        unless @real_history_fixture
          configure_original_workspace_resource
          return
        end
        @map = @map.merge("worker_entry" => {"interpreter" => {"path" => "/usr/bin/python3", "bytes" => 100, "sha256" => "3" * 64}, "wrapper" => {"path" => "/usr/libexec/ace-worker.py", "bytes" => 200, "sha256" => "4" * 64}}, "worker_env" => {"PATH" => "/usr/bin"},
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
        configure_original_workspace_resource
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

    end
  end
end
