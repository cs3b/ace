# frozen_string_literal: true
require_relative "execution_scope_observation_fixtures"
require "ace/assign/authority/readiness_hook"

module Ace
  module Assign
      class ExecutionScopeNativeOwnerFixture
        def initialize(map, journal, kernel, owner:, network_selection: ExecutionScopeObservationFixtures::NETWORK_SELECTION,
          boot_baseline_selection: ExecutionScopeObservationFixtures::BOOT_BASELINE_SELECTION,
          network_installation: ExecutionScopeObservationFixtures::NETWORK_OUTPUT)
          @map, @journal, @kernel, @owner = map, journal, kernel, owner
          @network_selection, @boot_baseline_selection, @network_installation = network_selection, boot_baseline_selection, network_installation
        end
        def retire_released_parent!(_lineages); true; end
        def activate_parent!(context)
          context.merge("slot_id" => "slot", "deployment_digest" => Digest::SHA256.hexdigest(JSON.generate(canonical(@map))),
            "boot_id" => ExecutionScopeObservationFixtures::BOOT, "slice_invocation_id" => "b" * 32,
            "resource_mount_namespace_identity" => {"device" => 4, "inode" => 11}, "resource_identities" => [],
            "network_namespace_identity" => @network_installation.fetch("namespace_identity"), "boot_baseline_selection" => @boot_baseline_selection, "network_installation_selection" => @network_selection,
            "cgroup_identity" => {"path" => "/sys/fs/cgroup/ace-slot.slice", "mount_id" => 4, "filesystem_type" => "cgroup2", "device" => 5, "inode" => 6})
        end
        def observe(_lineage); {"populated" => 0}; end
        def native_admission_ready!(lineage)
          @lineage = lineage
          @network_installation
        end
        def start_admitted_service!
          events = @journal.read_events("assignment").select { |event| event["attempt_id"] == @lineage.binding.fetch("attempt_id") }
          admission = events.find { |event| event.dig("payload", "operation") == "scope_service_admission" }
          payload = {"scope_generation" => 2, "scope_binding_event_id" => @lineage.binding_event.fetch("digest"),
            "service_invocation_id" => "c" * 32, "server_identity" => @kernel.capture(90), "socket_identity" => [1, 2, 13001], "workspace_id" => "w1",
            "mount_namespace_identity" => {"device" => 4, "inode" => 22}, "resource_observer_identity" => @kernel.capture(92), "resource_identities" => [],
            "network_namespace_identity" => @network_installation.fetch("namespace_identity"), "network_admission_event_id" => admission.fetch("digest")}
          left, right = UNIXSocket.pair
          codec = Authority::TransferCodec.new(root: File.dirname(@journal.repo_root))
          wire = Ace::Runtime::Molecules::ProtectedSocket
          handler = Thread.new do
            request = wire.read(left, deadline: wire.deadline(10))
            raise "wrong readiness control request" unless request["operation"] == "native_readiness" && request["params"] == {"mapping_id" => "mapping"}
            @owner.native_readiness!(mapping_id: "mapping", peer: @kernel.capture(92), socket: left,
              codec: codec, deadline: wire.deadline(10))
          ensure
            left.close
          end
          run_readiness_hook(right, payload)
          handler.value
        ensure
          right&.close
          if $!
            begin
              handler&.join(1)
            rescue StandardError
              # Preserve the original producer failure; peer closure is secondary.
            end
          else
            handler&.join(1)
          end
        end
        def readiness_peer!(_lineage, peer)
          raise "wrong controlled actor" unless peer == @kernel.capture(92)
          @kernel.capture(90)
        end
        def verify_readiness_report!(lineage, peer, report, challenge:)
          raise "wrong controlled callback" unless report.keys.sort == %w[challenge_id kernel_view_topology mount_namespace_identity resource_identities resource_observer_identity resource_topology server_identity version] &&
            report["challenge_id"] == challenge["challenge_id"] && peer == @kernel.capture(92)
          Ace::Runtime::Molecules::KernelViewTopology.new.verify!(topology: report.fetch("kernel_view_topology"),
            host_ipc: {"device" => 4, "inode" => 900}, authority_socket: [1, 2, 13000], writable_resources: [],
            host_devpts: ExecutionScopeObservationFixtures::DEVPTS_HOST, selected_devpts: ExecutionScopeObservationFixtures::DEVPTS_SELECTED)
          report.slice("server_identity", "resource_observer_identity", "mount_namespace_identity", "resource_identities").merge(
            "scope_generation" => lineage.binding.fetch("scope_generation"), "scope_binding_event_id" => lineage.binding_event.fetch("digest"),
            "service_invocation_id" => "c" * 32, "workspace_id" => "w1", "network_namespace_identity" => @network_installation.fetch("namespace_identity"),
            "network_admission_event_id" => lineage.admission_event.fetch("digest"))
        end
        def complete_native_readiness!(_lineage, payload)
          raise "private callback missing" unless payload
          payload.merge("socket_identity" => [1, 2, 13001])
        end
        def stop_sealed_service!; true; end
        def sealed_service_stop_required?(_lineage); false; end
        def closed_observation_for_proof!(lineage, events:)
          raise "source proof requires seal" unless lineage.sealed?
          lineage.binding.slice("scope_generation", "boot_id", "slice_invocation_id", "cgroup_identity").merge(
            "scope_binding_event_id" => lineage.binding_event.fetch("digest"), "seal_event_id" => lineage.seal_event.fetch("digest"), "populated" => 0)
        end
        def verify_closed!(lineage)
          raise "source proof missing" unless lineage.sealed? && lineage.proof_event
          true
        end
        def run_readiness_hook(socket, payload, boundary_resources: nil)
          config = {"slot_id" => "slot", "project_id" => "project", "mapping_id" => "mapping",
            "worker" => @kernel.capture(92).slice("uid", "gid", "groups"),
            "authority" => {"socket_path" => "/run/authority/socket", "uid" => 13000, "gid" => 13000, "groups" => []}}
          configuration = Struct.new(:data).new(config)
          peer = @kernel.capture(92).merge("pid" => 93, "uid" => 13000, "gid" => 13000, "groups" => [])
          original_kernel = @kernel
          kernel = Object.new
          kernel.define_singleton_method(:supported!) { true }
          kernel.define_singleton_method(:capture) { |pid| original_kernel.capture(pid == Process.pid ? 92 : pid) }
          kernel.define_singleton_method(:peer) { |_socket| peer }
          kernel.define_singleton_method(:live!) { |identity| identity == peer || original_kernel.live!(identity) }
          wire = Object.new
          %i[deadline read write].each { |name| wire.define_singleton_method(name) { |*args, **kwargs| Ace::Runtime::Molecules::ProtectedSocket.public_send(name, *args, **kwargs) } }
          wire.define_singleton_method(:root_path!) { |path, **options| raise "wrong endpoint ancestry" unless path == "/run/authority" && options == {directory: true, owner: 13000} }
          wire.define_singleton_method(:socket_identity) { |path| raise "wrong endpoint path" unless path == "/run/authority/socket"; [1, 2, 13000] }
          wire.define_singleton_method(:connect) { |_path, &block| block.call(socket) }
          files = Object.new
          selection = @network_selection
          declarations = boundary_resources || [{"host_path" => "/private", "view_path" => "/private", "worker_visible" => false, "read_only" => true, "stage" => "parent"}]
          files.define_singleton_method(:boundary_manifest!) do |_config|
            {"schema" => "ace.execution-boundary-manifest/v1", "slot_id" => "slot", "network_installation" => selection.slice("profile", "installer_artifact").merge("current_selection_path" => "/etc/ace/execution-slots/slot/network-installation-selection.json"),
              "resources" => declarations}
          end
          files.define_singleton_method(:verify_native!) { |server, _config| raise "wrong native server" unless server == original_kernel.capture(90) }
          resources = Object.new
          resources.define_singleton_method(:observe!) do |server:, entries:, authority_socket:|
            raise "wrong resource observation inputs" unless server == original_kernel.capture(90) &&
              entries == declarations.select { |entry| entry.fetch("worker_visible") } && authority_socket == "/run/authority/socket"
            payload.slice("mount_namespace_identity", "resource_identities").merge("resource_topology" => payload.fetch("resource_topology", []),
              "kernel_view_topology" => payload.fetch("kernel_view_topology", ExecutionScopeObservationFixtures.kernel_topology))
          end
          Authority::ReadinessHook.new(slot: "slot", configuration: configuration, kernel: kernel, wire: wire,
            files: files, resources: resources).run
        end
        def canonical(value)
          case value
          when Hash then value.keys.sort.to_h { |key| [key, canonical(value[key])] }
          when Array then value.map { |item| canonical(item) }
          else value
          end
        end
      end

  end
end
