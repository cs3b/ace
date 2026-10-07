# frozen_string_literal: true

require_relative "../models/evidence_event"
require "json"

module Ace
  module Assign
    module Molecules
      # Canonical lineage only. Live owner/boundary observation and lifecycle
      # exclusion are mandatory before recording or consuming a fresh proof.
      # This reader never promotes cached population into a proof event.
      class ExecutionScopeLineage
        BINDING_FIELDS = %w[project_id assignment_id attempt_id mapping_id slot_id reservation_generation
          scope_generation deployment_digest boot_id slice_invocation_id cgroup_identity resource_mount_namespace_identity resource_identities network_installation_selection network_namespace_identity boot_baseline_selection].freeze
        PROOF_FIELDS = %w[scope_generation scope_binding_event_id seal_event_id boot_id slice_invocation_id
          cgroup_identity populated].freeze
        PROCESS_FIELDS = %w[pid uid gid groups started_at host parent_pid].freeze
        RESOURCE_FIELDS = %w[host_path view_path mount_id filesystem_type device inode uid gid].freeze
        CGROUP_FIELDS = %w[path mount_id filesystem_type device inode].freeze
        ID = /\A[a-zA-Z0-9][a-zA-Z0-9_.-]{0,127}\z/
        DIGEST = /\A[0-9a-f]{64}\z/
        INVOCATION = /\A[0-9a-f]{32}\z/
        BOOT = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/

        def self.validate_network_selection!(selection)
          unless selection.is_a?(Hash) && selection.keys.sort == %w[installer_artifact policy_export profile report]
            raise AttemptErrors::EvidenceUnavailable, "network installation selection is not closed"
          end
          selection.each_value do |ref|
            unless ref.is_a?(Hash) && ref.keys.sort == %w[bytes path sha256] && ref["path"].is_a?(String) &&
                ref["path"].bytesize.between?(1, 4096) && ref["path"].start_with?("/") && !ref["path"].include?("\0") &&
                File.expand_path(ref["path"]) == ref["path"] && ref["sha256"].is_a?(String) && DIGEST.match?(ref["sha256"]) &&
                ref["bytes"].is_a?(Integer) && ref["bytes"].between?(1, 1_048_576)
              raise AttemptErrors::EvidenceUnavailable, "network installation artifact reference differs"
            end
          end
          selection
        end

        def self.validate_boot_baseline_selection!(ref)
          unless ref.is_a?(Hash) && ref.keys.sort == %w[bytes path sha256] && ref["path"].is_a?(String) &&
              ref["path"].bytesize.between?(1, 4096) && ref["path"].start_with?("/") && !ref["path"].include?("\0") &&
              File.expand_path(ref["path"]) == ref["path"] && ref["sha256"].is_a?(String) && DIGEST.match?(ref["sha256"]) &&
              ref["bytes"].is_a?(Integer) && ref["bytes"].between?(1, 16_384)
            raise AttemptErrors::EvidenceUnavailable, "boot baseline artifact reference differs"
          end
          ref
        end

        attr_reader :binding_event, :native_event, :child_event, :seal_event, :proof_event, :admission_event

        def initialize(events:, project_id:, assignment_id:, attempt_id:, mapping_id:)
          events = freeze_tree(JSON.parse(JSON.generate(events)))
          unless events.is_a?(Array) && Models::EvidenceEvent.chain_valid?(events) &&
              events.all? { |event| event["attempt_id"] == attempt_id }
            unavailable!("scope requires its intact exact attempt chain")
          end
          @expected = {"project_id" => project_id, "assignment_id" => assignment_id,
            "attempt_id" => attempt_id, "mapping_id" => mapping_id}
          generation = 0
          events.each do |event|
            generation += 1 if event["type"] == "authority_mutation"
            accept_reservation!(event, generation) if event["type"] == "authority_mutation" &&
              event.dig("payload", "operation") == "reserve_attempt"
            accept_admission!(event, generation) if event["type"] == "authority_mutation" &&
              event.dig("payload", "operation") == "scope_service_admission"
            case event["type"]
            when "scope_bound" then accept_binding!(event, generation + 1)
            when "scope_native_bound" then accept_native!(event)
            when "scope_child_bound" then accept_child!(event)
            when "scope_sealed" then accept_seal!(event)
            when "scope_closed_no_writers" then accept_proof!(event)
            end
          end
        rescue KeyError, NoMethodError, TypeError
          unavailable!("canonical scope lineage is incomplete")
        end

        def binding
          binding_event&.fetch("payload")
        end

        def sealed?
          !seal_event.nil?
        end

        def proof_id
          proof_event&.fetch("digest")
        end

        def require_open!
          unavailable!("canonical scope binding is missing") unless binding
          raise AttemptErrors::Conflict, "execution generation is sealed" if sealed?
          true
        end

        def require_launch_bound!
          require_open!
          unavailable!("original native and child stages are missing") unless native_event && child_event
          child_event.fetch("payload").fetch("original_process_binding")
        end

        def require_positive!(scope_generation:, scope_binding_event_id:, seal_event_id:, proof_id:)
          unless proof_event && binding.fetch("scope_generation") == scope_generation &&
              binding_event.fetch("digest") == scope_binding_event_id && seal_event.fetch("digest") == seal_event_id &&
              proof_event.fetch("digest") == proof_id
            unavailable!("exact canonical scope proof is unavailable")
          end
          proof_event.fetch("payload")
        end

        private

        def accept_reservation!(event, generation)
          unavailable!("canonical reservation is repeated") if @reservation
          value = event.dig("payload", "data")
          unless value.is_a?(Hash) && value.slice(*@expected.keys) == @expected &&
              value["reservation_generation"] == generation && value["generation"] == generation &&
              value["launch_ticket"].is_a?(String) && ID.match?(value["launch_ticket"])
            unavailable!("canonical reservation binding differs")
          end
          @reservation = value
        end

        def freeze_tree(value)
          case value
          when Hash then value.each { |key, item| key.freeze; freeze_tree(item) }
          when Array then value.each { |item| freeze_tree(item) }
          end
          value.freeze
        end

        def accept_binding!(event, generation)
          unavailable!("scope binding cannot be replaced") if binding_event
          value = event.fetch("payload")
          exact_fields!(value, BINDING_FIELDS)
          unless value.slice(*@expected.keys) == @expected &&
              value["slot_id"].is_a?(String) && ID.match?(value["slot_id"]) &&
              value["scope_generation"] == generation && @reservation &&
              value["reservation_generation"] == @reservation["reservation_generation"] &&
              digest?(value["deployment_digest"]) && boot?(value["boot_id"]) &&
              invocation?(value["slice_invocation_id"])
            unavailable!("scope generation binding differs")
          end
          cgroup!(value.fetch("cgroup_identity"))
          namespace!(value.fetch("resource_mount_namespace_identity"))
          namespace!(value.fetch("network_namespace_identity"))
          self.class.validate_network_selection!(value.fetch("network_installation_selection"))
          self.class.validate_boot_baseline_selection!(value.fetch("boot_baseline_selection"))
          resources = value.fetch("resource_identities")
          resources!(resources)
          @binding_event = event
        end

        def stage_reference!(value)
          unavailable!("scope stage requires its original open parent") unless binding && !sealed?
          unless value["scope_generation"] == binding.fetch("scope_generation") &&
              value["scope_binding_event_id"] == binding_event.fetch("digest")
            unavailable!("scope stage references another parent")
          end
        end

        def accept_admission!(event, generation)
          unavailable!("native admission cannot replace an existing stage") if admission_event || native_event
          value = event.fetch("payload").fetch("data")
          stage_reference!(value)
          unless value.slice(*@expected.keys) == @expected && value["generation"] == generation &&
              value["native_admission"] == "issued_uncertain"
            unavailable!("native admission does not name the exact current reserved owner")
          end
          installation = value.fetch("network_installation")
          exact_fields!(installation, %w[report_id boot_id slot_id namespace_path namespace_identity profile_sha256 policy_export_sha256 report_sha256 installer_artifact_sha256])
          namespace!(installation.fetch("namespace_identity"))
          selection = binding.fetch("network_installation_selection")
          unless boot?(installation["report_id"]) && installation["boot_id"] == binding["boot_id"] &&
              installation["slot_id"] == binding["slot_id"] && installation["namespace_identity"] == binding["network_namespace_identity"] &&
              installation["namespace_path"].is_a?(String) && installation["namespace_path"].start_with?("/") &&
              !installation["namespace_path"].include?("\0") && File.expand_path(installation["namespace_path"]) == installation["namespace_path"] &&
              %w[profile policy_export report installer_artifact].all? { |key| installation["#{key}_sha256"] == selection.fetch(key).fetch("sha256") }
            unavailable!("native admission installation differs from original parent selection")
          end
          @admission_event = event
        end

        def accept_native!(event)
          unavailable!("native binding cannot be replaced") if native_event
          value = event.fetch("payload")
          exact_fields!(value, %w[scope_generation scope_binding_event_id service_invocation_id server_identity socket_identity workspace_id
            mount_namespace_identity resource_observer_identity resource_identities network_namespace_identity network_admission_event_id])
          stage_reference!(value)
          namespace!(value.fetch("network_namespace_identity"))
          unless admission_event && value["network_admission_event_id"] == admission_event.fetch("digest") &&
              value["network_namespace_identity"] == binding.fetch("network_namespace_identity")
            unavailable!("native server does not join the original admitted network installation")
          end
          process!(value.fetch("server_identity"), binding.fetch("boot_id"))
          socket = value.fetch("socket_identity")
          unless invocation?(value["service_invocation_id"]) && value["workspace_id"].is_a?(String) &&
              value["workspace_id"].match?(/\Aw[1-9][0-9]{0,8}\z/) && socket.is_a?(Array) && socket.size == 3 &&
              socket.all? { |part| part.is_a?(Integer) && part >= 0 } && socket.last == value.dig("server_identity", "uid")
            unavailable!("scope native incarnation differs")
          end
          namespace!(value.fetch("mount_namespace_identity"))
          observer = value.fetch("resource_observer_identity")
          process!(observer, binding.fetch("boot_id"))
          server = value.fetch("server_identity")
          unless observer.values_at("uid", "gid", "groups", "host") == server.values_at("uid", "gid", "groups", "host") &&
              observer["pid"] != server["pid"]
            unavailable!("native resource observer is not the distinct fixed same-user hook")
          end
          resources!(value.fetch("resource_identities"))
          parent_resources = binding.fetch("resource_identities").to_h { |resource| [resource.values_at("host_path", "view_path"), resource] }
          value.fetch("resource_identities").each do |resource|
            original = parent_resources[resource.values_at("host_path", "view_path")]
            if original && original.slice("device", "inode", "filesystem_type", "uid", "gid") != resource.slice("device", "inode", "filesystem_type", "uid", "gid")
              unavailable!("native view substitutes a parent-pinned backing object")
            end
          end
          @native_event = event
        end

        def accept_child!(event)
          unavailable!("child binding requires its single native predecessor") unless native_event && !child_event
          value = event.fetch("payload")
          exact_fields!(value, %w[scope_generation scope_binding_event_id native_binding_event_id original_process_binding])
          stage_reference!(value)
          unless value["native_binding_event_id"] == native_event.fetch("digest")
            unavailable!("child references another native incarnation")
          end
          native = native_event.fetch("payload")
          original = value.fetch("original_process_binding")
          exact_fields!(original, %w[runtime session pane terminal_id process_identity shell_identity native_origin])
          process!(original.fetch("process_identity"), binding.fetch("boot_id"))
          socket = native.fetch("socket_identity")
          server = native.fetch("server_identity")
          child = original.fetch("process_identity")
          origin = original.fetch("native_origin")
          exact_fields!(origin, %w[workspace tab pane server_identity socket_identity command cwd])
          command = origin.fetch("command")
          unless child["parent_pid"] == server["pid"] &&
              child.values_at("uid", "gid", "groups") == server.values_at("uid", "gid", "groups") &&
              original["runtime"] == "herdr" && original["shell_identity"] == child &&
              original["session"] == native["workspace_id"] && origin["workspace"] == native["workspace_id"] &&
              origin["server_identity"] == server && origin["socket_identity"] == socket &&
              origin["pane"] == original["pane"] && %w[pane terminal_id].all? { |key| original[key].is_a?(String) && !original[key].empty? } &&
              origin["tab"].is_a?(String) && !origin["tab"].empty? && path?(origin["cwd"]) &&
              command.is_a?(Array) && command.size == 3 && path?(command.first) && command[1] == binding["mapping_id"] &&
              command.last == @reservation.fetch("launch_ticket")
            unavailable!("scope original-child lineage differs")
          end
          @child_event = event
        end

        def accept_seal!(event)
          unavailable!("scope seal has no immutable binding or is repeated") unless binding && !seal_event
          value = event.fetch("payload")
          exact_fields!(value, %w[scope_generation scope_binding_event_id])
          unless value == {"scope_generation" => binding.fetch("scope_generation"),
                          "scope_binding_event_id" => binding_event.fetch("digest")}
            unavailable!("scope seal references another incarnation")
          end
          @seal_event = event
        end

        def accept_proof!(event)
          unavailable!("scope proof requires its original seal and single observation") unless sealed? && !proof_event
          value = event.fetch("payload")
          exact_fields!(value, PROOF_FIELDS)
          expected = binding.slice("scope_generation", "boot_id", "slice_invocation_id", "cgroup_identity")
          expected.merge!("scope_binding_event_id" => binding_event.fetch("digest"),
            "seal_event_id" => seal_event.fetch("digest"), "populated" => 0)
          unavailable!("scope proof is not exact sealed empty population") unless value == expected
          @proof_event = event
        end

        def namespace!(value)
          exact_fields!(value, %w[device inode])
          unless value["device"].is_a?(Integer) && value["device"] >= 0 && positive_integer?(value["inode"])
            unavailable!("scope mount namespace identity is malformed")
          end
        end

        def resources!(resources)
          unless resources.is_a?(Array) && resources.size <= 64 &&
              resources.all? { |resource| resource.is_a?(Hash) } &&
              resources.map { |resource| resource.values_at("host_path", "view_path") }.uniq.size == resources.size &&
              resources.map { |resource| resource["view_path"] }.uniq.size == resources.size
            unavailable!("scope resource observations are duplicate or oversized")
          end
          resources.each do |resource|
            exact_fields!(resource, RESOURCE_FIELDS)
            unless path?(resource["host_path"]) && path?(resource["view_path"]) && positive_integer?(resource["mount_id"]) &&
                %w[device inode uid gid].all? { |key| resource[key].is_a?(Integer) && resource[key] >= 0 } &&
                resource["filesystem_type"].is_a?(String) && resource["filesystem_type"].bytesize.between?(1, 64) &&
                resource["filesystem_type"].ascii_only? && !resource["filesystem_type"].match?(/[\s\0]/)
              unavailable!("scope resource identity is malformed")
            end
          end
        end

        def cgroup!(value)
          exact_fields!(value, CGROUP_FIELDS)
          unless path?(value["path"]) && value["path"].start_with?("/sys/fs/cgroup/") &&
              value["filesystem_type"] == "cgroup2" &&
              %w[mount_id device inode].all? { |key| value[key].is_a?(Integer) && value[key] >= 0 }
            unavailable!("scope parent object identity is malformed")
          end
        end

        def process!(value, boot_id)
          exact_fields!(value, PROCESS_FIELDS)
          groups = value["groups"]
          unless %w[pid uid gid parent_pid].all? { |key| positive_integer?(value[key]) } &&
              groups.is_a?(Array) && groups.all? { |id| positive_integer?(id) } && groups == groups.sort.uniq &&
              value["started_at"].is_a?(String) && value["started_at"].match?(/\Alinux:#{Regexp.escape(boot_id)}:[0-9]+\z/) &&
              value["host"].is_a?(String) && !value["host"].empty?
            unavailable!("scope process birth/credentials are malformed")
          end
        end

        def exact_fields!(value, keys)
          unavailable!("scope event schema differs") unless value.is_a?(Hash) && value.keys.sort == keys.sort
        end

        def path?(value)
          value.is_a?(String) && value.bytesize.between?(2, 4096) && !value.include?("\0") &&
            value.start_with?("/") && File.expand_path(value) == value
        end

        def positive_integer?(value) = value.is_a?(Integer) && value.positive?
        def digest?(value) = value.is_a?(String) && DIGEST.match?(value)
        def boot?(value) = value.is_a?(String) && BOOT.match?(value)
        def invocation?(value) = value.is_a?(String) && INVOCATION.match?(value)
        def unavailable!(message) = raise(AttemptErrors::EvidenceUnavailable, message)
      end
    end
  end
end
