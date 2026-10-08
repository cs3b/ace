# frozen_string_literal: true
require_relative "protected_inbox_context_pipeline_fixture"
module Ace
  module Assign
    # Existing durable journal/context fixture shared without creating another environment.
    module EndcapInboxFixture
      include ProtectedInboxContextPipelineFixture
      BOOT = "12345678-1234-1234-1234-123456789abc"
      class Kernel
        attr_accessor :dead, :authority_peer
        def live!(identity)
          raise AttemptErrors::EvidenceUnavailable, "dead peer" if Array(dead).include?(identity["pid"])
        end
        def capture(_pid); authority_peer; end
        def same?(left, right); left == right; end
        def supported!; raise "consumed proof must not open native endpoint"; end
      end
      class Launch
        attr_reader :journals, :locked
        def initialize(journal, launcher); @journal, @launcher = journal, launcher; @journals = {"project" => journal}; end
        def with_assignment(params:, map:)
          @locked = true
          yield @journal, {}
        ensure
          @locked = false
        end
        def origin(*, **); {"launcher_identity" => @launcher}; end
      end
      Parts = Struct.new(:parts) do
        def count; parts.size; end
        def bytes(index: 0); parts.fetch(index); end
      end

      def fixture(child: false, inbox: true, direct: false, original_terminal: "terminal", resources: nil, original_map_override: nil)
        @direct_fixture = direct
        child = true if direct
        original_terminal = "term_aa" if direct && original_terminal == "terminal"
        Dir.mktmpdir do |root|
          root = File.realpath(root)
          repo = File.join(root, "repo"); FileUtils.mkdir_p(repo)
          git_in(repo, "init", "-b", "main")
          git_in(repo, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "--allow-empty", "-m", "fixture")
          @journal = Molecules::EvidenceJournal.new(repo_root: repo, checkout_root: File.join(root, "checkout"), mode: :protected,
            evidence_reader: ->(*) { raise "unused" }, service_authorizer: ->(*) { raise "unused" })
          @peer = process(82, 13004)
          @launcher = process(81, 13002)
          server = process(90, 13001)
          @map = {"project_id" => "project", "authority_id" => "authority", "launcher_uid" => 13002, "worker_uid" => 13001, "worker_gid" => 13001, "worker_groups" => [13001],
            "native" => {"socket_path" => "/fixed/native.sock", "executable" => "/fixed/herdr", "executable_sha256" => "a" * 64,
              "version" => "0.9.3", "protocol" => 22, "workspace_id" => "w1"}, "execution_scope" => {"slot_id" => "slot"}}
          @map = @map.merge(original_map_override) if original_map_override
          key = OpenSSL::PKey::RSA.new(2048)
          @key = key
          key_path = File.join(root, "public.pem"); File.write(key_path, key.public_to_pem)
          @context = {"native_mapping_id" => "mapping", "supervisor_uids" => [13004], "deliveries_dir" => File.join(root, "deliveries"),
            "receipt_public_key" => key_path, "pi_queue_client" => "/absent/client"}
          @unsafe = false
          @deployment = Object.new
          owner = self
          @deployment.define_singleton_method(:project) do |_|
            journal = owner.instance_variable_get(:@journal)
            {"inbox_contexts" => {"context" => owner.instance_variable_get(:@context)}, "journal_repository" => journal.repo_root,
              "evidence_git_ref" => journal.ref, "evidence_checkout_root" => journal.checkout_root}
          end
          @deployment.define_singleton_method(:mapping_digest) { |_| Atoms::EvidenceDigest.digest(owner.instance_variable_get(:@map)) }
          @deployment.define_singleton_method(:mapping) { |id| raise KeyError unless id == "mapping"; owner.instance_variable_get(:@map) }
          @deployment.define_singleton_method(:inbox_context) { |_mapping, id| raise AttemptErrors::EvidenceUnavailable unless id == "context"; owner.instance_variable_get(:@context) }
          @deployment.define_singleton_method(:verify_inbox_context!) { |*| raise Ace::Runtime::RuntimeUnavailableError if owner.instance_variable_get(:@unsafe); true }
          @kernel = Kernel.new
          @authority_peer = process(83, 13000)
          @context_peer = process(84, 13007)
          @kernel.authority_peer = @authority_peer
          @descriptor_sha256 = Digest::SHA256.hexdigest(JSON.generate(@map))
          @retained_key = key.public_key
          @history = Object.new
          @history.define_singleton_method(:descriptor!) do |sha256:|
            raise AttemptErrors::EvidenceUnavailable unless sha256 == owner.instance_variable_get(:@descriptor_sha256)
            owner.instance_variable_get(:@deployment)
          end
          @history.define_singleton_method(:public_key!) do |sha256:|
            selected = owner.instance_variable_get(:@retained_key)
            raise AttemptErrors::EvidenceUnavailable unless sha256 == Digest::SHA256.hexdigest(selected.public_to_der)
            selected
          end
          @policy = Object.new
          @policy.define_singleton_method(:visible!) { |**| true }
          restart
          mutate("reserve_attempt", "reserve", 0, {data: {"project_id" => "project", "assignment_id" => "assignment",
            "attempt_id" => "attempt", "mapping_id" => "mapping", "reservation_generation" => 1, "launch_ticket" => "ticket"},
            events: [{type: "intent", payload: {"scope" => "010"}}, {type: "scope_provisioning", payload: {
              "descriptor_sha256" => @descriptor_sha256, "deployment_digest" => @deployment.mapping_digest("mapping"),
              "reservation_generation" => 1, "slot_id" => "slot"}}]})
          parent = {"project_id" => "project", "assignment_id" => "assignment", "attempt_id" => "attempt", "mapping_id" => "mapping",
            "slot_id" => "slot", "reservation_generation" => 1, "scope_generation" => 2, "deployment_digest" => @deployment.mapping_digest("mapping"),
            "boot_id" => BOOT, "slice_invocation_id" => "b" * 32,
            "boot_baseline_selection" => ExecutionScopeObservationFixtures::BOOT_BASELINE_SELECTION, "network_installation_selection" => ExecutionScopeObservationFixtures::NETWORK_SELECTION,
            "network_namespace_identity" => {"device" => 7, "inode" => 88},
            "resource_mount_namespace_identity" => {"device" => 4, "inode" => 1111},
            "cgroup_identity" => {"path" => "/sys/fs/cgroup/slot.slice", "mount_id" => 1, "filesystem_type" => "cgroup2", "device" => 2, "inode" => 3},
            "resource_identities" => resources || [{"host_path" => "/var/lib/slot", "view_path" => "/scratch", "mount_id" => 4,
              "filesystem_type" => "ext4", "device" => 5, "inode" => 6, "uid" => 13001, "gid" => 13001}]}
          mutate("fixture_parent", "parent", 1, {data: {}, events: [{type: "scope_bound", payload: parent}]})
          parent_event = events.find { |event| event["type"] == "scope_bound" }
          mutate("scope_service_admission", "admission", 2, {data: parent.slice("project_id", "assignment_id", "attempt_id", "mapping_id").merge(
            "scope_generation" => 2, "scope_binding_event_id" => parent_event.fetch("digest"),
            "native_admission" => "issued_uncertain", "network_installation" => ExecutionScopeObservationFixtures::NETWORK_OUTPUT)})
          admission = events.find { |event| event.dig("payload", "operation") == "scope_service_admission" }
          mutate("fixture_native", "native", 3, {data: {}, events: [{type: "scope_native_bound", payload: {
            "scope_generation" => 2, "scope_binding_event_id" => parent_event.fetch("digest"), "service_invocation_id" => "c" * 32,
            "server_identity" => server, "socket_identity" => [1, 2, 13001], "workspace_id" => "w1",
            "mount_namespace_identity" => {"device" => 4, "inode" => 2222}, "resource_observer_identity" => process(92, 13001),
            "resource_identities" => parent.fetch("resource_identities").map { |resource| resource.merge("mount_id" => 99) },
            "network_namespace_identity" => parent.fetch("network_namespace_identity"), "network_admission_event_id" => admission.fetch("digest")}}]})
          if child
            original = {"runtime" => "herdr", "session" => "w1", "pane" => "p1", "terminal_id" => original_terminal,
              "process_identity" => process(91, 13001).merge("parent_pid" => 90), "shell_identity" => process(91, 13001).merge("parent_pid" => 90),
              "native_origin" => {"workspace" => "w1", "tab" => "t1", "pane" => "p1", "server_identity" => server,
                "socket_identity" => [1, 2, 13001], "command" => ["/fixture/gate", "mapping", "ticket"], "cwd" => "/scratch"}}
            mutate("fixture_child", "child", 4, {data: {}, events: [{type: "scope_child_bound", payload: {
              "scope_generation" => 2, "scope_binding_event_id" => parent_event.fetch("digest"),
              "native_binding_event_id" => events.find { |event| event["type"] == "scope_native_bound" }.fetch("digest"),
              "original_process_binding" => original}}]})
          end
          if direct
            guarded = {"terminal_id" => original.fetch("terminal_id"), "runtime_incarnation" => BOOT, "child" => original.fetch("process_identity")}
            mutate("record_launch", "fixture-original-record", 5, {data: {"assignment_id" => "assignment", "mapping_id" => "mapping",
              "attempt_id" => "attempt", "process_binding" => original, "guarded_origin" => guarded}})
          end
          unless inbox
            FileUtils.mkdir_p(@context.fetch("deliveries_dir"))
            @params = {"mapping_id" => "mapping", "assignment_id" => "assignment", "attempt_id" => "attempt"}
            yield
            next
          end
          executor = Object.new
          executor.define_singleton_method(:pane_get_bounded) do |_pane|
            Ace::Herdr::Molecules::ExecutionResult.new(stdout: JSON.generate("result" => {"pane" => {
              "pane_id" => "p1", "workspace_id" => "w1", "terminal_id" => original_terminal, "agent" => "codex", "agent_status" => "busy",
              "agent_session" => {"agent" => "codex", "kind" => "id", "value" => "0123abcd-0000-4000-8000-000000000001"}}}),
              stderr: "", success: true, exit_code: 0)
          end
          native = Object.new
          # This maintained fixture injects queue acceptance; observer tests
          # separately install and verify retained source correlation.
          native.define_singleton_method(:prepare_submission) { |**| nil }
          @native_calls = 0
          native.define_singleton_method(:submit) do |**|
            owner.instance_variable_set(:@native_calls, owner.instance_variable_get(:@native_calls) + 1)
            direct ? {"accepted" => false, "error" => "controlled lost native acknowledgement"} : {"accepted" => true}
          end
          @box = Ace::Herdr::Organisms::Inbox.new(executor: executor, native: native, deliveries_dir: @context.fetch("deliveries_dir"), receipt_public_key: key.public_key)
          original_options = direct ? {original_context: direct_original_context, original_binding_digest: events.find { |event| event.dig("payload", "operation") == "record_launch" }.fetch("digest")} : {}
          @box.enqueue(event: "event", attempt: "attempt", ref: {"session" => "w1", "pane" => "p1"}, payload: "message", **original_options)
          record = direct ? @box.retained_status(event: "event") : @box.deliver(event: "event")
          @registration = record.slice("event_id", "attempt_id", "payload_sha256", "receipt_key_sha256")
          mutate("fixture_registration", "registration", direct ? 6 : child ? 5 : 4, {data: {}, events: [{type: "inbox_binding", payload: {
            "event_id" => "event", "attempt_id" => "attempt", "inbox_context_id" => "context", "registration" => @registration}}]})
          receipt = record.slice("event_id", "attempt_id", "claim_generation", "payload_sha256", "binding").merge(
            "outcome" => "consumed", "observer" => {"role" => "supervisor", "id" => "observer"},
            "evidence" => {"kind" => "consumed_acknowledged", "native_reference" => "native:1", "observation" => "consumed"})
          @bytes = JSON.generate(receipt); @signature = key.sign(OpenSSL::Digest::SHA256.new, @bytes)
          start_context_pipeline(root)
          restart
          @params = {"mapping_id" => "mapping", "assignment_id" => "assignment", "attempt_id" => "attempt",
            "expected_generation" => direct ? 7 : child ? 6 : 5, "event_id" => "event", "inbox_context_id" => "context", "expected_registration" => @registration,
            "receipt_sha256" => Digest::SHA256.hexdigest(@bytes), "signature_sha256" => Digest::SHA256.hexdigest(@signature), "transfer" => {}}
          yield
        ensure
          stop_context_pipeline
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
        @launch = Launch.new(@journal, @launcher)
        @owner = Authority::Endcap.new(deployment: @deployment, launch: @launch, kernel: @kernel, service_policy: @policy,
          inbox_context_clients: @context_clients, deployment_history: @history)
      end
      def reconcile(params: @params, peer: @peer, role: :supervisor, id: "reconcile", parts: [@bytes, @signature])
        @owner.dispatch(request: {"operation" => "reconcile_inbox", "project_id" => "project", "mutation_id" => id, "params" => params},
          peer: peer, role: role, transfer: Parts.new(parts))
      end

    end
  end
end
