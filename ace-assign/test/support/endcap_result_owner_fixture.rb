# frozen_string_literal: true
require_relative "execution_scope_native_owner_fixture"
require_relative "prepared_registration_fixture"
require "ace/assign/authority/endcap"
require "ace/assign/authority/launch_lifecycle"
require "ace/assign/authority/router"

module Ace
  module Assign
    module EndcapResultOwnerFixture
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
            "started_at" => "linux:#{ExecutionScopeObservationFixtures::BOOT}:#{pid}", "host" => "fixture", "parent_pid" => pid == 91 ? 90 : 1}
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
          @map = {"task_context_entry" => {"manifest" => {"path" => "/fixture/assign-entry.json", "bytes" => 100, "sha256" => "1" * 64}, "wrapper" => {"path" => "/fixture/assign-entry.py", "bytes" => 200, "sha256" => "2" * 64}}, "project_id" => "project", "authority_id" => "authority", "worker_uid" => 13001,
            "worker_gid" => 13001, "worker_groups" => [13001], "worker_actor" => "worker",
            "launcher_uid" => 13002, "launcher_gid" => 13002, "launcher_groups" => [13002],
            "bootstrap" => "/fixture/gate", "bootstrap_sha256" => "a" * 64, "worker_cwd" => "/fixture/worker",
            "execution_scope" => {"slot_id" => "slot", "service_unit" => "ace-slot.service", "network_namespace_path" => "/run/netns/slot"},
            "native" => {"workspace_id" => "w1"}}
          @project = {"candidate_root" => root, "assignment_root" => File.join(root, "assignments"), "supervisor_uids" => [13004],
            "reviewer_uids" => [13003], "service_executor_uids" => [13005], "peer_credentials" => {}}
          [@worker, @reviewer, @executor, @supervisor, @service].each do |identity|
            @project["peer_credentials"][identity.fetch("uid").to_s] = identity.slice("gid", "groups").merge("scratch_root" => root)
          end
          map, project, service = @map, @project, @service
          @deployment = Object.new
          @deployment.define_singleton_method(:artifact_reference) { {"sha256" => "d" * 64} }
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
          configure_result_owner_fixture if respond_to?(:configure_result_owner_fixture)
          restart
          bytes = JSON.generate("session_id" => "assignment", "name" => "result fixture", "created_at" => "2026-10-05T00:00:00Z",
            "source_config" => "job.yaml", "task_id" => "task", "project_id" => "project")
          call("register_assignment", {"definition_bytes" => bytes, "definition_digest" => Digest::SHA256.hexdigest(bytes),
            "expected_generation" => 0}, id: "register", peer: @launcher, role: :launcher)
          state = call("reserve_attempt", {"scope" => "010", "worker_uid" => 13001, "runtime" => "herdr", "base_head" => @head,
            "launcher_process_binding" => @launcher, "expected_generation" => 1}, id: "reserve", peer: @launcher, role: :launcher).fetch(:data)
          @attempt = state.fetch("attempt_id")
          state = state.merge("generation" => generation)
          @binding = {"runtime" => "herdr", "session" => "w1", "pane" => "p1", "terminal_id" => "term_ab",
            "process_identity" => @worker, "shell_identity" => @worker,
            "native_origin" => {"workspace" => "w1", "tab" => "t1", "pane" => "p1",
              "command" => ["/fixture/gate", "mapping", state.fetch("launch_ticket")], "cwd" => "/fixture/worker",
              "server_identity" => @kernel.capture(90), "socket_identity" => [1, 2, 13001]}}
          state = call("record_launch", {"launch_ticket" => state.fetch("launch_ticket"), "process_binding" => @binding,
            "guarded_origin" => {"terminal_id" => @binding.fetch("terminal_id"), "runtime_incarnation" => ExecutionScopeObservationFixtures::BOOT, "child" => @worker},
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
        @launch = Authority::LaunchLifecycle.new(deployment: @deployment, deployment_history: @history, kernel: @kernel, journals: {"project" => @journal},
          scope_observer_factory: ->(_id) { ExecutionScopeNativeOwnerFixture.new(@map, @journal, @kernel, owner: @launch) })
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
        if operation == "register_assignment"
          FileUtils.mkdir_p(@project.fetch("candidate_root"), mode: 0700)
          fixture = PreparedRegistrationFixture.build(root: @root, definition: JSON.parse(params.fetch("definition_bytes")), scope: "010",
            context_text: @prepared_context_text || "Exact fixture context.\n")
          @prepared_registration = fixture
          fixture.with_input(root: @root) do |input, descriptor|
            @router.dispatch(request: request.merge("params" => fixture.header(expected_generation: params.fetch("expected_generation")).merge("mapping_id" => "mapping", "assignment_id" => "assignment", "transfer" => descriptor)), peer: peer, role: role, transfer: input)
          end
        else
          @router.dispatch(request: request, peer: peer, role: role, transfer: transfer)
        end
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

    end
  end
end
