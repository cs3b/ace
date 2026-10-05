# frozen_string_literal: true
require_relative "execution_scope_observation_fixtures"

module Ace
  module Assign
      class ExecutionScopeNativeOwnerFixture
        def initialize(map, journal, kernel)
          @map, @journal, @kernel = map, journal, kernel
        end
        def retire_released_parent!(_lineages); true; end
        def activate_parent!(context)
          context.merge("slot_id" => "slot", "deployment_digest" => Digest::SHA256.hexdigest(JSON.generate(canonical(@map))),
            "boot_id" => ExecutionScopeObservationFixtures::BOOT, "slice_invocation_id" => "b" * 32,
            "resource_mount_namespace_identity" => {"device" => 4, "inode" => 11}, "resource_identities" => [],
            "network_namespace_identity" => {"device" => 7, "inode" => 88}, "network_installation_selection" => ExecutionScopeObservationFixtures::NETWORK_SELECTION,
            "cgroup_identity" => {"path" => "/sys/fs/cgroup/ace-slot.slice", "mount_id" => 4, "filesystem_type" => "cgroup2", "device" => 5, "inode" => 6})
        end
        def observe(_lineage); {"populated" => 0}; end
        def native_admission_ready!(lineage)
          @lineage = lineage
          ExecutionScopeObservationFixtures::NETWORK_OUTPUT
        end
        def start_admitted_service!
          events = @journal.read_events("assignment").select { |event| event["attempt_id"] == @lineage.binding.fetch("attempt_id") }
          admission = events.find { |event| event.dig("payload", "operation") == "scope_service_admission" }
          payload = {"scope_generation" => 2, "scope_binding_event_id" => @lineage.binding_event.fetch("digest"),
            "service_invocation_id" => "c" * 32, "server_identity" => @kernel.capture(90), "socket_identity" => [1, 2, 13001], "workspace_id" => "w1",
            "mount_namespace_identity" => {"device" => 4, "inode" => 22}, "resource_observer_identity" => @kernel.capture(92), "resource_identities" => [],
            "network_namespace_identity" => {"device" => 7, "inode" => 88}, "network_admission_event_id" => admission.fetch("digest")}
          @journal.mutate(assignment_id: "assignment", attempt_id: @lineage.binding.fetch("attempt_id"),
            mutation_id: "native-#{@lineage.binding.fetch('attempt_id')}", operation: "scope_native_binding", parameters_digest: "a" * 64,
            expected_generation: @journal.authority_generation(events)) { {events: [{type: "scope_native_bound", payload: payload}], blobs: {}, data: {}} }
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
