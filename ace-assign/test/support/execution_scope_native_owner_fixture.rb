# frozen_string_literal: true
require_relative "execution_scope_observation_fixtures"

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
            @owner.native_readiness!(mapping_id: "mapping", peer: @kernel.capture(92), socket: left,
              codec: codec, deadline: wire.deadline(10))
          ensure
            left.close
          end
          challenge = wire.read(right, deadline: wire.deadline(10), limit: 16_384)
          report = payload.slice("mount_namespace_identity", "resource_identities", "server_identity", "resource_observer_identity")
            .merge("version" => 1, "challenge_id" => challenge.fetch("challenge_id"), "resource_topology" => [])
          bytes = JSON.generate(report)
          transfer = codec.descriptor([bytes], purpose: :scope_boundary_observation)
          wire.write(right, {"version" => 1, "challenge_id" => challenge.fetch("challenge_id"), "transfer" => transfer}, deadline: wire.deadline(10))
          codec.send(right, parts: [bytes], descriptor: transfer, purpose: :scope_boundary_observation, deadline: wire.deadline(10))
          right.shutdown(Socket::SHUT_WR)
          acknowledgment = wire.read(right, deadline: wire.deadline(10))
          raise "private callback failed" unless acknowledgment["status"] == "ready"
          handler.value
        ensure
          right&.close
          handler&.join(1)
        end
        def readiness_peer!(_lineage, peer)
          raise "wrong controlled actor" unless peer == @kernel.capture(92)
          @kernel.capture(90)
        end
        def verify_readiness_report!(lineage, peer, report, challenge:)
          raise "wrong controlled callback" unless report["challenge_id"] == challenge["challenge_id"] && peer == @kernel.capture(92)
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
