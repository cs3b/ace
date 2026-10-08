# frozen_string_literal: true
require_relative "../../test_helper"
require_relative "../../support/endcap_result_owner_fixture"
require_relative "../../support/execution_boot_baseline_owner_fixture"
require_relative "../../../../ace-runtime/test/support/network_installation_fixture"

module Ace
  module Assign
    # Real journal, readiness wire, admission, observer and terminal owners.
    # Only host manager/kernel/resource and native transport observations are
    # controlled here. This does not prove installed Linux containment.
    class ObservedTerminalScopeTest < AceAssignTestCase
      include EndcapResultOwnerFixture
      include ExecutionBootBaselineOwnerFixture
      F = ExecutionScopeObservationFixtures

      class BootProtection
        def root_path!(_path); end
        def verify!(_path, handle, directory:)
          raise "wrong controlled artifact type" unless directory ? handle.stat.directory? : handle.stat.file?
        end
      end

      class Manager < F::Manager
        attr_accessor :on_start, :on_stop
        def start_service
          super
          service.merge!("ActiveState" => "activating", "MainPID" => 90,
            "ControlPID" => 92, "InvocationID" => "c" * 32)
          on_start.call
          service.merge!("ActiveState" => "active", "ControlPID" => 0)
        end
        def stop_service
          service.merge!("ActiveState" => "inactive", "MainPID" => 0, "ControlPID" => 0)
          on_stop.call
        end
      end

      class Native < Ace::Herdr::Molecules::ProtectedNativeControl
        def request(method, params = {})
          case method
          when "ping" then {"version" => "0.9.3", "protocol" => 22,
            "capabilities" => {"endpoint_protocol_generation" => 1}}
          when "workspace.get"
            raise "wrong selected workspace" unless params == {"workspace_id" => "w1"}
            {"workspace" => {"workspace_id" => "w1"}}
          else raise "unexpected native operation #{method}"
          end
        end
      end

      def configure_result_owner_fixture
        @service.merge!("uid" => 13000, "gid" => 13000, "groups" => [], "socket_path" => "/run/authority/socket")
        @map.fetch("execution_scope").merge!("slice_unit" => "ace-slot.slice", "runtime_directory" => "/run/slot/native")
        @map.fetch("native").merge!("socket_path" => "/run/slot/native/control.sock", "version" => "0.9.3")
        @files, @manager, @cgroups = F::Files.new, Manager.new, F::Cgroups.new
        @network = NetworkInstallationFixture.new
        artifact_root = @root
        store = @network.method(:store)
        @network.define_singleton_method(:store) do |path, bytes|
          local = File.join(artifact_root, path.delete_prefix("/"))
          FileUtils.mkdir_p(File.dirname(local))
          File.binwrite(local, bytes)
          store.call(local, bytes)
        end
        @network.profile.merge!("slot_id" => "slot", "namespace_path" => "/run/netns/slot")
        @network.expected.merge!("slot_id" => "slot", "namespace_path" => "/run/netns/slot",
          "boot_id" => F::BOOT, "namespace_identity" => @files.network.dup)
        @network.report_edit = ->(report) { report["slot_id"] = "slot" }
        @selection = @network.build
        retained = retained_boot_baseline_artifact(root: @root, name: "boot.json", map: @map,
          installer: @selection.fetch("installer_artifact"))
        pointer = File.join(@root, "boot-selection.json")
        File.binwrite(pointer, JSON.generate("schema" => "ace.execution-boot-selection/v1", "slot_id" => "slot", "baseline" => retained))
        @boot = fixture_boot_baseline_reader(protection: BootProtection.new,
          pointers: {"/etc/ace/execution-slots/slot/boot-baseline-selection.json" => pointer})
        @network_selection = F::NetworkSelection.new
        @network_selection.selection = @selection
        @files.manifest["network_installation"] = @selection.slice("profile", "installer_artifact").merge(
          "current_selection_path" => "/etc/ace/execution-slots/slot/network-installation-selection.json")
        @manager.profile = {"service" => {"ExecStartPostEx" => [["/fixed/ruby", [], [], 0, 0, 0, 0, 92, 0, 0]]}}
        @manager.on_start = -> { readiness }
        @manager.on_stop = -> { @files.native_present = false; @files.native_resource = nil }
      end

      def restart
        @launch = Authority::LaunchLifecycle.new(deployment: @deployment, kernel: @kernel, journals: {"project" => @journal},
          scope_observer_factory: lambda { |id|
            Authority::ExecutionScopeObservation.new(mapping_id: id, deployment: @deployment, kernel: @kernel,
              manager: @manager, cgroups: @cgroups, files: @files, network_selection: @network_selection,
              network_evidence: Ace::Runtime::Molecules::NetworkInstallationEvidence.new(artifacts: @network),
              boot_evidence: @boot)
          })
        @endcap = Authority::Endcap.new(deployment: @deployment, launch: @launch, kernel: @kernel, service_policy: @policy)
        @router = Authority::Router.new(launch: @launch, handlers: [@endcap])
      end

      def readiness
        @files.native_resource = @files.resource.merge("inode" => 100)
        @files.native_present = true
        resources = [@files.resource.merge("host_path" => "/private/scratch", "view_path" => "/scratch"),
          @files.native_resource.merge("host_path" => "/run/slot/native", "view_path" => "/run/slot/native")]
        report = {"mount_namespace_identity" => {"device" => 4, "inode" => 22},
          "network_namespace_identity" => @files.network.dup, "resource_identities" => resources,
          "resource_topology" => resources.map { |entry| entry.slice("host_path", "view_path").merge(
            "mountpoint" => entry.fetch("view_path"), "root" => entry.fetch("host_path"), "major_minor" => "8:1", "options" => ["rw"]) },
          "kernel_view_topology" => F.kernel_topology(resources: resources)}
        left, right = UNIXSocket.pair
        codec = Authority::TransferCodec.new(root: @root)
        receiver = Thread.new do
          request = WIRE.read(left, deadline: WIRE.deadline(10))
          raise "wrong readiness request" unless request["operation"] == "native_readiness"
          @launch.native_readiness!(mapping_id: "mapping", peer: @kernel.capture(92), socket: left,
            codec: codec, deadline: WIRE.deadline(10))
        ensure
          left.close
        end
        # Reuse only the actual ReadinessHook driver, never its fake observer.
        driver = ExecutionScopeNativeOwnerFixture.new(@map, @journal, @kernel, owner: nil, network_selection: @selection)
        driver.run_readiness_hook(right, report, boundary_resources: @files.manifest.fetch("resources"))
        receiver.value
      ensure
        right&.close
        receiver&.join(1)
      end

      def test_production_observer_requires_no_writers_before_terminal_receipt_and_release
        constructor = Native.method(:new)
        native = ->(mapping:, kernel:) { constructor.call(mapping: mapping, kernel: kernel) }
        endpoint = lambda do |path|
          raise "wrong native socket" unless path == "/run/slot/native/control.sock"
          [1, 2, 13001]
        end
        Ace::Runtime::Molecules::ExecutionBootBaseline.stub(:new, -> { @boot }) do
          Ace::Herdr::Molecules::ProtectedNativeControl.stub(:new, native) do
            WIRE.stub(:socket_identity, endpoint) do
              fixture do
                assert_equal 1, @manager.service_starts
                result = submit.fetch(:data)
                review = call("assign_review", {"head" => @head, "candidate_generation" => 1,
                  "expected_generation" => generation, "reviewer_uid" => @reviewer.fetch("uid"),
                  "reviewer_process_binding" => @reviewer}, id: "assign-review", peer: @launcher, role: :launcher).fetch(:data)
                _, _, receipt = upload(parts: ["independent review"])
                receipt.merge!("operation" => "review", "review" => {"head" => @head, "verdict" => "approved",
                  "reviewer" => {"actor" => review.fetch("reviewer_actor")}})
                review_params, input, = upload(parts: ["independent review"], receipt: receipt)
                call("accept_review", review_params.merge("purpose_id" => review.fetch("review_id")),
                  id: "accept-review", peer: @reviewer, role: :reviewer, transfer: input)
                finish = lambda do |id|
                  call("finish", {"result_id" => result.fetch("result_id"), "head" => @head,
                    "candidate_generation" => 1, "expected_generation" => generation}, id: id, peer: @launcher, role: :launcher)
                end
                before = @journal.ref_value
                assert_raises(AttemptErrors::EvidenceUnavailable) { finish.call("premature-finish") }
                assert_equal before, @journal.ref_value
                params = {"mapping_id" => "mapping", "assignment_id" => "assignment", "attempt_id" => @attempt}
                close = ->(id) { @launch.close_execution_scope!(params: params.merge("mutation_id" => id,
                  "expected_generation" => generation), peer: @launcher, role: :launcher) }
                close.call("seal")
                @cgroups.populated = 1
                before = @journal.ref_value
                assert_raises(Ace::Runtime::RuntimeUnavailableError) { close.call("busy") }
                assert_equal before, @journal.ref_value
                @cgroups.populated = 0
                proof = close.call("proof")
                assert_equal "succeeded", finish.call("finish").dig(:data, "state")
                @cgroups.populated = 1
                before = @journal.ref_value
                assert_raises(AttemptErrors::EvidenceUnavailable) do
                  @launch.release_scope_reservation!(params: params.merge("mutation_id" => "busy-release", "expected_generation" => generation),
                    peer: @launcher, role: :launcher)
                end
                assert_equal before, @journal.ref_value
                @cgroups.populated = 0
                released = @launch.release_scope_reservation!(params: params.merge("mutation_id" => "release", "expected_generation" => generation),
                  peer: @launcher, role: :launcher)
                assert_equal "released", released.dig(:data, "reservation")
                assert_equal proof.dig(:data, "proof_id"), released.dig(:data, "proof_id")
                terminal = @journal.read_events("assignment").find { |event| event["type"] == "receipt_accepted" }
                assert_equal terminal.fetch("digest"), released.dig(:data, "terminal_event_id")
                assert_equal result.fetch("receipt_digest"), terminal.dig("payload", "receipt", "digest")
                assert @network.reads.include?(@selection.fetch("report").fetch("path"))
              end
            end
          end
        end
      end
    end
  end
end
