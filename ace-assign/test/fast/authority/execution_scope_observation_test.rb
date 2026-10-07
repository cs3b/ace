# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/assign/authority/execution_scope_observation"
require_relative "../../support/execution_scope_observation_fixtures"
require_relative "../../support/execution_scope_native_owner_fixture"

module Ace
  module Assign
    # Controlled native-owner observations exercise the production join. These
    # fixtures do not execute systemd, mount, proc, ACL or installed-host probes.
    class ExecutionScopeObservationTest < AceAssignTestCase
      BOOT = ExecutionScopeObservationFixtures::BOOT
      Files = ExecutionScopeObservationFixtures::Files
      Manager = ExecutionScopeObservationFixtures::Manager
      Cgroups = ExecutionScopeObservationFixtures::Cgroups

      class SelectionProtection < Ace::Runtime::Molecules::ProtectedArtifactSet::Protection
        def initialize(root)
          @root = root
          mounts = Object.new
          mounts.define_singleton_method(:mount_identity) { |_handle| {"filesystem_type" => "ext4"} }
          super(mounts: mounts)
        end
        def root_path!(_path); end
        def verify!(path, handle, directory:)
          super if path == @root || path.start_with?(@root + "/")
        end
        private
        def trusted_owner?(stat); stat.uid == Process.uid; end
      end

      class Kernel
        attr_accessor :identities
        def capture(pid); identities.fetch(pid); end
        def live!(identity); raise Ace::Runtime::RuntimeUnavailableError unless capture(identity.fetch("pid")) == identity; true; end
        def same?(left, right); left == right; end
      end

      def test_missing_installed_namespace_refuses_before_parent_activation
        @files.network = nil
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { @observer.activate_parent!(@context) }
        assert_equal 0, @manager.starts
        assert_equal 0, @manager.service_starts
      end

      def test_boot_proof_unavailable_refuses_before_parent_activation
        @boot_evidence.unavailable = true
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { @observer.activate_parent!(@context) }
        assert_equal 0, @manager.starts
        assert_equal 0, @manager.service_starts
      end

      def test_parent_pins_boot_proof_and_observation_reauthenticates_original_context
        binding = @observer.activate_parent!(@context)
        assert_equal ExecutionScopeObservationFixtures::BOOT_BASELINE_SELECTION, binding.fetch("boot_baseline_selection")
        expected = {"slot_id" => "slot", "boot_id" => BOOT, "deployment_digest" => binding.fetch("deployment_digest"),
          "installer_artifact" => ExecutionScopeObservationFixtures::NETWORK_SELECTION.fetch("installer_artifact")}
        assert_equal [expected], @boot_evidence.selections
        append("scope_bound", binding)
        @boot_evidence.selected = {"path" => "/etc/ace/boot/replacement.json", "sha256" => "e" * 64, "bytes" => 2}
        assert_equal 0, @observer.observe(lineage).fetch("populated")
        assert_equal [{"selection" => binding.fetch("boot_baseline_selection"), "expected" => expected}], @boot_evidence.verifications
        assert_equal [expected], @boot_evidence.selections
        @boot_evidence.unavailable = true
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { @observer.observe(lineage) }
        assert_equal 0, @manager.service_starts
      end

      def test_selection_shape_and_namespace_replacement_cannot_be_adopted
        original = @files.manifest.fetch("network_installation")
        @files.manifest["network_installation"] = ExecutionScopeObservationFixtures::NETWORK_SELECTION
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { @observer.activate_parent!(@context) }
        assert_equal 0, @manager.starts
        @files.manifest["network_installation"] = original.merge("unknown" => {})
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { @observer.activate_parent!(@context) }
        assert_equal 0, @manager.starts
        @files.manifest["network_installation"] = original
        binding = @observer.activate_parent!(@context)
        append("scope_bound", binding)
        @files.network["inode"] += 1
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { @observer.observe(lineage) }
        assert_equal 0, @manager.service_starts
      end

      def test_actual_protected_pointer_is_pinned_before_activation_and_advance_cannot_be_adopted
        Dir.mktmpdir("scope-network-selection-") do |temporary|
          root = File.realpath(temporary)
          artifact = lambda do |name, bytes|
            path = File.join(root, name)
            File.binwrite(path, bytes)
            File.chmod(0600, path)
            {"path" => path, "bytes" => bytes.bytesize, "sha256" => Digest::SHA256.hexdigest(bytes)}
          end
          selection = Ace::Runtime::Molecules::ExecutionNetworkSelection::FIELDS.to_h { |name| [name, artifact.call(name, "selected #{name}")] }
          static = selection.slice("profile", "installer_artifact").merge("current_selection_path" => "/etc/ace/execution-slots/slot/network-installation-selection.json")
          pointer = artifact.call("pointer", "missing evidence")
          @files.manifest["network_installation"] = static
          reader = Ace::Runtime::Molecules::ProtectedArtifactSet.new(protection: SelectionProtection.new(root))
          read = reader.method(:read_path!)
          reader.define_singleton_method(:read_path!) do |path, limit:|
            raise "wrong source-owned slot pointer" unless path == static.fetch("current_selection_path")
            read.call(pointer.fetch("path"), limit: limit)
          end
          @observer.instance_variable_set(:@network_selection, Ace::Runtime::Molecules::ExecutionNetworkSelection.new(artifacts: reader))
          assert_raises(Ace::Runtime::RuntimeUnavailableError) { @observer.activate_parent!(@context) }
          assert_equal 0, @manager.starts
          publish = ->(value) { File.binwrite(pointer.fetch("path"), JSON.generate("schema" => "ace.network-installation-selection/v1", "slot_id" => "slot", "selection" => value)) }
          publish.call(selection)
          binding = @observer.activate_parent!(@context)
          assert_equal selection, binding.fetch("network_installation_selection")
          assert binding.fetch("network_installation_selection").frozen?
          append("scope_bound", binding)
          assert_equal 0, @observer.observe(lineage).fetch("populated")
          advanced = selection.merge("report" => artifact.call("new-report", "another current report"))
          publish.call(advanced)
          assert_raises(Ace::Runtime::RuntimeUnavailableError) { @observer.observe(lineage) }
          assert_equal selection, binding.fetch("network_installation_selection")
          assert_equal 0, @manager.service_starts
        end
      end

      def setup
        super
        @files, @manager, @cgroups = Files.new, Manager.new, Cgroups.new
        @kernel = Kernel.new
        @kernel.identities = [90, 92].to_h { |pid| [pid, {"pid" => pid, "uid" => 13001, "gid" => 13001, "groups" => [],
          "parent_pid" => 1, "started_at" => "linux:#{BOOT}:#{pid}", "host" => "fixture"}] }
        @map = {"project_id" => "project", "authority_id" => "authority", "worker_uid" => 13001, "worker_gid" => 13001, "worker_groups" => [], "launcher_uid" => 13002,
          "native" => {"workspace_id" => "w1"}, "execution_scope" => {"slot_id" => "slot", "slice_unit" => "ace-slot.slice",
          "service_unit" => "ace-slot.service", "runtime_directory" => "/run/slot/native", "network_namespace_path" => "/run/netns/slot"}}
        deployment = Object.new
        mapping = @map
        deployment.define_singleton_method(:mapping) { |_id| mapping }
        deployment.define_singleton_method(:verify!) { |*_args, **_options| true }
        deployment.define_singleton_method(:authority) { |_id| {"uid" => 13000, "socket_path" => "/run/authority/socket"} }
        deployment.define_singleton_method(:project) { |_id| {"supervisor_uids" => [13003]} }
        network = Object.new
        network.define_singleton_method(:verify!) { |selection:, expected:| ExecutionScopeObservationFixtures::NETWORK_OUTPUT }
        @boot_evidence = ExecutionScopeObservationFixtures::BootEvidence.new
        @network_selection = ExecutionScopeObservationFixtures::NetworkSelection.new
        @observer = Authority::ExecutionScopeObservation.new(mapping_id: "mapping", deployment: deployment, kernel: @kernel,
          manager: @manager, cgroups: @cgroups, files: @files, network_evidence: network, boot_evidence: @boot_evidence, network_selection: @network_selection)
        @events = []
        @context = {"project_id" => "project", "mapping_id" => "mapping", "assignment_id" => "assignment", "attempt_id" => "attempt",
          "reservation_generation" => 1, "scope_generation" => 2}
        append("intent", {})
        append("authority_mutation", {"operation" => "reserve_attempt", "data" => @context.reject { |key, _| key == "scope_generation" }.merge(
          "generation" => 1, "launch_ticket" => "ticket")})
      end

      def append(type, payload)
        @events << Models::EvidenceEvent.build(type: type, attempt_id: "attempt", payload: payload, previous_digest: @events.last&.fetch("digest"))
      end

      def lineage
        Molecules::ExecutionScopeLineage.new(events: @events, project_id: "project", assignment_id: "assignment", attempt_id: "attempt", mapping_id: "mapping")
      end

      def bind_parent
        @binding = @observer.activate_parent!(@context)
        append("scope_bound", @binding)
        append("authority_mutation", {"operation" => "scope_parent_binding", "data" => {}})
      end

      def seal_parent
        append("scope_sealed", {"scope_generation" => 2, "scope_binding_event_id" => lineage.binding_event.fetch("digest")})
        append("authority_mutation", {"operation" => "close_execution_scope", "data" => {}})
      end

      def test_fresh_owner_activation_observes_only_existing_parent_resources
        bind_parent
        assert_equal 1, @manager.starts
        assert_equal 0, @manager.service_starts
        assert_equal @files.namespace, @binding.fetch("resource_mount_namespace_identity")
        assert_equal 2, @binding.fetch("resource_identities").size
        assert_equal 99, @binding.dig("resource_identities", 1, "inode")
        assert @cgroups.handles.all?(&:closed)
        assert_equal 0, @observer.observe(lineage).fetch("populated")
        assert_equal ExecutionScopeObservationFixtures::NETWORK_OUTPUT, @observer.native_admission_ready!(lineage)
        assert_equal 0, @manager.service_starts
      end

      def test_never_admitted_sealed_parent_can_prove_empty_without_network_readiness
        bind_parent
        seal_parent
        proof = @observer.closed_observation_for_proof!(lineage, events: @events)
        assert_equal 0, proof.fetch("populated")
        assert_equal @binding.fetch("cgroup_identity"), proof.fetch("cgroup_identity")
        append("scope_closed_no_writers", proof)
        assert @observer.verify_closed!(lineage)
        @manager.service["ControlPID"] = 90
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { @observer.verify_closed!(lineage) }
        @manager.service["ControlPID"] = 0
        @manager.service["Job"] = [1, "/job/1"]
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { @observer.verify_closed!(lineage) }
      end

      def test_stopped_admitted_unbound_generation_requires_positive_writer_baseline
        bind_parent
        append("authority_mutation", {"operation" => "scope_service_admission", "data" => @context.slice("project_id", "assignment_id", "attempt_id", "mapping_id").merge(
          "generation" => 3, "scope_generation" => 2, "scope_binding_event_id" => @events.find { |event| event["type"] == "scope_bound" }.fetch("digest"),
          "native_admission" => "issued_uncertain", "network_installation" => ExecutionScopeObservationFixtures::NETWORK_OUTPUT)})
        seal_parent
        assert_equal 0, @observer.closed_observation_for_proof!(lineage, events: @events).fetch("populated")
        @files.outside_worker = true
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { @observer.closed_observation_for_proof!(lineage, events: @events) }
      end

      def ready_report
        bind_parent
        append("authority_mutation", {"operation" => "scope_service_admission", "data" => @context.slice("project_id", "assignment_id", "attempt_id", "mapping_id").merge(
          "generation" => 3, "scope_generation" => 2, "scope_binding_event_id" => lineage.binding_event.fetch("digest"),
          "native_admission" => "issued_uncertain", "network_installation" => ExecutionScopeObservationFixtures::NETWORK_OUTPUT)})
        @manager.service.merge!("ActiveState" => "activating", "MainPID" => 90, "ControlPID" => 92, "InvocationID" => "c" * 32)
        @manager.profile = {"service" => {"ExecStartPostEx" => [["/fixed/ruby", [], [], 0, 0, 0, 0, 92, 0, 0]]}}
        @files.native_resource = @files.resource.merge("inode" => 100)
        resources = [@files.resource.merge("host_path" => "/private/scratch", "view_path" => "/scratch"),
          @files.native_resource.merge("host_path" => "/run/slot/native", "view_path" => "/run/slot/native")]
        topology = resources.map { |entry| entry.slice("host_path", "view_path").merge("mountpoint" => entry.fetch("view_path"),
          "root" => entry.fetch("host_path"), "major_minor" => "8:1", "options" => ["rw"] ) }
        {"version" => 1, "challenge_id" => "a" * 64, "server_identity" => @kernel.capture(90),
          "resource_observer_identity" => @kernel.capture(92), "mount_namespace_identity" => {"device" => 4, "inode" => 22},
          "resource_identities" => resources, "resource_topology" => topology,
          "kernel_view_topology" => ExecutionScopeObservationFixtures.kernel_topology(resources: resources)}
      end

      def test_private_report_joins_exact_direct_manager_actor_and_complete_backing_topology
        report = ready_report
        hook = @kernel.capture(92)
        assert_equal @kernel.capture(90), @observer.readiness_peer!(lineage, hook)
        value = @observer.verify_readiness_report!(lineage, hook, report, challenge: report.slice("challenge_id"))
        assert_equal report.fetch("resource_identities"), value.fetch("resource_identities")
        assert_equal lineage.admission_event.fetch("digest"), value.fetch("network_admission_event_id")
        @manager.profile["service"]["ExecStartPostEx"][0][7] = 93
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { @observer.readiness_peer!(lineage, hook) }
      end

      def test_actual_readiness_hook_report_round_trips_into_production_observer
        report = ready_report
        left, right = UNIXSocket.pair
        root = Dir.mktmpdir("ace-ready-wire-", Etc.getpwuid(Process.uid).dir)
        File.chmod(0o700, root)
        wire = Ace::Runtime::Molecules::ProtectedSocket
        receiver = Thread.new do
          request = wire.read(left, deadline: wire.deadline(10))
          raise "wrong hook request" unless request["operation"] == "native_readiness" && request["params"] == {"mapping_id" => "mapping"}
          challenge = {"version" => 1, "challenge_id" => "a" * 64, "server_identity" => @kernel.capture(90)}
          wire.write(left, challenge, deadline: wire.deadline(10))
          envelope = wire.read(left, deadline: wire.deadline(10))
          codec = Authority::TransferCodec.new(root: root)
          value = codec.receive(left, descriptor: envelope.fetch("transfer"), purpose: :scope_boundary_observation, deadline: wire.deadline(10)) do |input|
            actual = JSON.parse(input.bytes, create_additions: false, allow_duplicate_key: false)
            @observer.verify_readiness_report!(lineage, @kernel.capture(92), actual, challenge: challenge)
          end
          wire.write(left, {"version" => 1, "challenge_id" => "a" * 64, "status" => "ready"}, deadline: wire.deadline(10))
          value
        ensure
          left.close
        end
        fixture = ExecutionScopeNativeOwnerFixture.new(@map, nil, @kernel, owner: nil)
        assert fixture.run_readiness_hook(right, report, boundary_resources: @files.manifest.fetch("resources"))
        value = receiver.value
        assert_equal report.fetch("resource_identities"), value.fetch("resource_identities")
        assert_equal lineage.admission_event.fetch("digest"), value.fetch("network_admission_event_id")
      ensure
        right&.close
        receiver&.join(1)
        left&.close unless left&.closed?
        FileUtils.rm_rf(root) if root
      end

      def test_report_omitted_resource_foreign_subtree_and_wrong_actor_refuse
        report = ready_report
        hook = @kernel.capture(92)
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { @observer.readiness_peer!(lineage, @kernel.capture(90)) }
        changed = Marshal.load(Marshal.dump(report))
        changed["resource_identities"].pop
        assert_raises(Ace::Runtime::RuntimeUnavailableError) do
          @observer.verify_readiness_report!(lineage, hook, changed, challenge: report.slice("challenge_id"))
        end
        changed = Marshal.load(Marshal.dump(report))
        changed["resource_topology"][0]["root"] = "/foreign"
        assert_raises(Ace::Runtime::RuntimeUnavailableError) do
          @observer.verify_readiness_report!(lineage, hook, changed, challenge: report.slice("challenge_id"))
        end
      end

      def test_stopped_admitted_scope_refuses_retained_native_leaf_or_outside_uid_writer
        ready_report
        seal_parent
        @manager.service.merge!("ActiveState" => "inactive", "MainPID" => 0, "ControlPID" => 0)
        @files.native_present = true
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { @observer.closed_observation_for_proof!(lineage, events: @events) }
        @files.native_present = false
        assert_equal 0, @observer.closed_observation_for_proof!(lineage, events: @events).fetch("populated")
      end

      def stopped_native_scope
        report = ready_report
        native = @observer.verify_readiness_report!(lineage, @kernel.capture(92), report, challenge: report.slice("challenge_id"))
        append("scope_native_bound", native.merge("socket_identity" => [1, 2, 13001]))
        seal_parent
        @manager.service.merge!("ActiveState" => "inactive", "MainPID" => 0, "ControlPID" => 0, "Job" => [0, "/"])
        @files.native_present = false
      end

      def test_post_native_proof_and_retained_proof_require_exact_closed_incarnation
        stopped_native_scope
        proof = @observer.closed_observation_for_proof!(lineage, events: @events)
        append("scope_closed_no_writers", proof)
        assert @observer.verify_closed!(lineage)
        [{"InvocationID" => "d" * 32}, {"Job" => [9, "/job/9"]}, {"MainPID" => 90}, {"ControlPID" => 92}].each do |change|
          original = @manager.service.dup
          @manager.service.merge!(change)
          assert_raises(Ace::Runtime::RuntimeUnavailableError) { @observer.closed_observation_for_proof!(lineage, events: @events) }
          assert_raises(Ace::Runtime::RuntimeUnavailableError) { @observer.verify_closed!(lineage) }
          @manager.service.replace(original)
        end
        [[:native_present, true], [:outside_worker, true]].each do |field, value|
          @files.public_send("#{field}=", value)
          assert_raises(Ace::Runtime::RuntimeUnavailableError) { @observer.closed_observation_for_proof!(lineage, events: @events) }
          assert_raises(Ace::Runtime::RuntimeUnavailableError) { @observer.verify_closed!(lineage) }
          @files.public_send("#{field}=", false)
        end
        @cgroups.populated = 1
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { @observer.closed_observation_for_proof!(lineage, events: @events) }
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { @observer.verify_closed!(lineage) }
      end

      def test_post_native_final_baseline_recheck_refuses_late_job_and_recreated_leaf
        stopped_native_scope
        manager, files = @manager, @files
        files.define_singleton_method(:worker_uid_quiescent!) { |_uid| manager.service["Job"] = [9, "/job/9"]; true }
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { @observer.closed_observation_for_proof!(lineage, events: @events) }
        manager.service["Job"] = [0, "/"]
        files.define_singleton_method(:worker_uid_quiescent!) { |_uid| files.native_present = true; true }
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { @observer.closed_observation_for_proof!(lineage, events: @events) }
      end

      def test_resource_namespace_mount_object_and_parent_replacement_refuse
        bind_parent
        seal_parent
        %w[inode mount_id].each do |key|
          original = @files.resource.fetch(key)
          @files.resource[key] += 1
          assert_raises(Ace::Runtime::RuntimeUnavailableError) { @observer.closed_observation_for_proof!(lineage, events: @events) }
          @files.resource[key] = original
        end
        @files.namespace["inode"] += 1
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { @observer.observe(lineage) }
        @files.namespace["inode"] -= 1
        @cgroups.inode += 1
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { @observer.observe(lineage) }
        assert @cgroups.handles.all?(&:closed)
      end

      def test_lost_parent_start_reply_cannot_adopt_or_restart_same_name
        @manager.lost_start = true
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { @observer.activate_parent!(@context) }
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { @observer.activate_parent!(@context) }
        assert_equal 1, @manager.starts
      end

      def test_public_traversal_or_outside_writable_alias_refuses_before_start
        @files.outside_acl = true
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { @observer.activate_parent!(@context) }
        assert_equal 0, @manager.starts
        @files.outside_acl = false
        @files.outside_alias = true
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { @observer.activate_parent!(@context) }
        assert_equal 0, @manager.starts
      end

      def test_outside_worker_uid_process_refuses_never_admitted_proof
        bind_parent
        seal_parent
        @files.outside_worker = true
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { @observer.closed_observation_for_proof!(lineage, events: @events) }
      end

      def test_retirement_requires_the_exact_closed_released_parent
        bind_parent
        seal_parent
        append("scope_closed_no_writers", @observer.closed_observation_for_proof!(lineage, events: @events))
        assert_equal "retired", @observer.retire_released_parent!([lineage]).fetch("state")
        assert_equal 1, @manager.slice_stops
        assert_equal "already_retired", @observer.retire_released_parent!([lineage]).fetch("state")
        assert_equal 1, @manager.slice_stops
      end
    end
  end
end
