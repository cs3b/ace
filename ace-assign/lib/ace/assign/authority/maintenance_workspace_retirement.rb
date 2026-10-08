# frozen_string_literal: true
require_relative "../molecules/execution_scope_lineage"
require "json"

module Ace
  module Assign
    module Authority
      # Source capabilities only. A serialized descriptor is not admission.
      module MaintenanceWorkspaceRetirement
        SCHEMA = "ace.maintenance-workspace-retirement/v1"
        TARGET_FIELDS = %w[project_id mapping_id assignment_id attempt_id resource journal_commit binding_event_digest release_event_digest descriptor_sha256].freeze
        INVOCATION_FIELDS = %w[request_id input_digest operation_owner_binding_digest dispatch_event_digest].freeze
        REFERENCES = {
          "captured" => %w[intent captured preservation],
          "removed" => %w[intent captured preservation removal fence],
          "completed" => %w[intent captured preservation removal fence receipt]
        }.freeze

        def self.immutable(value)
          case value
          when Hash then value.to_h { |key, item| [key.dup.freeze, immutable(item)] }.freeze
          when Array then value.map { |item| immutable(item) }.freeze
          when String then value.dup.freeze
          else value.freeze
          end
        end

        def self.unavailable!(message)
          raise AttemptErrors::EvidenceUnavailable, message
        end

        class Evidence
          attr_reader :descriptor, :owner

          # Only the installed adapter mints this after validating its complete
          # collection. Consumers additionally bind the exact adapter instance,
          # original canonical projection and held operation before using it.
          def self.mint!(owner:, descriptor:)
            new(owner: owner, descriptor: descriptor)
          end
          private_class_method :new

          def initialize(owner:, descriptor:)
            @owner = owner
            MaintenanceWorkspaceRetirement.unavailable!("retirement evidence descriptor is not an object") unless descriptor.is_a?(Hash)
            @descriptor = MaintenanceWorkspaceRetirement.immutable(descriptor)
            @thread = Thread.current
            @consumption = nil
            @expired = false
            validate_descriptor!
          rescue KeyError, TypeError, ArgumentError
            MaintenanceWorkspaceRetirement.unavailable!("retirement evidence descriptor differs")
          end

          def verify!(owner:, target:, projection:, phase:, deadline:)
            unless !@expired && @thread.equal?(Thread.current) && @owner.equal?(owner) && descriptor.fetch("target") == target &&
                descriptor.fetch("phase") == phase && descriptor.fetch("resource") == projection.fetch("workspace_resource")
              MaintenanceWorkspaceRetirement.unavailable!("retirement evidence original owner or selection differs")
            end
            identities = projection.fetch("resource_identities")
            root = projection.fetch("worker_cwd")
            expected = projection.fetch("parent_resource_declarations").filter_map do |declaration|
              path = declaration.fetch("host_path")
              next unless declaration.fetch("stage") == "parent" && (path == root || path.start_with?(root + "/"))
              matches = identities.select { |row| row.values_at("host_path", "view_path") == declaration.values_at("host_path", "view_path") }
              MaintenanceWorkspaceRetirement.unavailable!("retirement declared row has no unique original identity") unless matches.one?
              matches.first
            end.sort_by { |row| row.values_at("host_path", "view_path") }
            unless descriptor.fetch("covered_resources").map { |row| row.fetch("original") } == expected
              MaintenanceWorkspaceRetirement.unavailable!("retirement evidence covered resources are not exhaustive")
            end
            @owner.verify_retirement_evidence!(evidence: self, projection: projection, deadline: deadline)
            true
          end

          def expire! = @expired = true

          def covered_resource(path)
            descriptor.fetch("covered_resources").find { |entry| entry.fetch("original").fetch("host_path") == path }
          end

          def verify_consumption!
            unless !@expired && @consumption && @thread.equal?(Thread.current)
              MaintenanceWorkspaceRetirement.unavailable!("retirement evidence is outside its held observation")
            end
            true
          end

          def with_consumption(verification)
            MaintenanceWorkspaceRetirement.unavailable!("retirement observation cannot be nested") if @consumption
            installed = true
            @consumption = verification
            verify_consumption!
            verification.call
            result = yield
            verify_consumption!
            verification.call
            result
          ensure
            @consumption = nil if installed
          end

          private

          def validate_descriptor!
            fields = %w[schema phase target resource covered_resources invocation refs]
            target = descriptor.fetch("target")
            invocation = descriptor.fetch("invocation")
            phase = descriptor.fetch("phase")
            unless descriptor.keys.sort == fields.sort && descriptor.fetch("schema") == SCHEMA && REFERENCES.key?(phase) &&
                target.is_a?(Hash) && target.keys.sort == TARGET_FIELDS.sort &&
                invocation.is_a?(Hash) && invocation.keys.sort == INVOCATION_FIELDS.sort
              MaintenanceWorkspaceRetirement.unavailable!("retirement evidence is not a closed supported descriptor")
            end
            resource!(descriptor.fetch("resource"))
            unless target.fetch("resource") == "workspace:#{target.fetch('project_id')}:#{target.fetch('mapping_id')}:#{target.fetch('assignment_id')}" &&
                %w[project_id mapping_id assignment_id attempt_id].all? { |key| token?(target[key]) } &&
                target.fetch("journal_commit").is_a?(String) && target.fetch("journal_commit").match?(/\A[0-9a-f]{40}\z/) &&
                %w[binding_event_digest release_event_digest descriptor_sha256].all? { |key| digest?(target[key]) } &&
                token?(invocation.fetch("request_id")) && (INVOCATION_FIELDS - ["request_id"]).all? { |key| digest?(invocation[key]) }
              MaintenanceWorkspaceRetirement.unavailable!("retirement evidence selectors differ")
            end
            covered = descriptor.fetch("covered_resources")
            unless covered.is_a?(Array) && covered.size.between?(1, 64)
              MaintenanceWorkspaceRetirement.unavailable!("retirement evidence covered inventory differs")
            end
            covered.each do |entry|
              unless entry.is_a?(Hash) && entry.keys.sort == %w[captured_host_path original] && path?(entry["captured_host_path"])
                MaintenanceWorkspaceRetirement.unavailable!("retirement evidence covered row differs")
              end
              resource!(entry.fetch("original"))
            end
            unless covered.map { |entry| entry.fetch("original") }.uniq.size == covered.size &&
                covered.map { |entry| entry.fetch("captured_host_path") }.uniq.size == covered.size
              MaintenanceWorkspaceRetirement.unavailable!("retirement evidence covered rows repeat")
            end
            roots = covered.select { |entry| entry.fetch("original") == descriptor.fetch("resource") }
            unless roots.one? && covered.all? { |entry|
                original = entry.fetch("original").fetch("host_path")
                root = descriptor.fetch("resource").fetch("host_path")
                (original == root || original.start_with?(root + "/")) &&
                  entry.fetch("captured_host_path") == roots.first.fetch("captured_host_path") + original.delete_prefix(root) }
              MaintenanceWorkspaceRetirement.unavailable!("retirement evidence captured paths do not match exact relative resources")
            end
            refs = descriptor.fetch("refs")
            unless refs.is_a?(Hash) && refs.keys.sort == REFERENCES.fetch(phase).sort
              MaintenanceWorkspaceRetirement.unavailable!("retirement evidence reference set differs")
            end
            refs.each_value do |ref|
              unless ref.is_a?(Hash) && ref.keys.sort == %w[bytes path sha256] && path?(ref["path"]) && digest?(ref["sha256"]) &&
                  ref["bytes"].is_a?(Integer) && ref["bytes"].between?(1, 64 * 1024 * 1024)
                MaintenanceWorkspaceRetirement.unavailable!("retirement evidence reference differs")
              end
            end
          end

          def token?(value) = value.is_a?(String) && value.match?(/\A[A-Za-z0-9][A-Za-z0-9._:-]{0,127}\z/)
          def digest?(value) = value.is_a?(String) && value.match?(/\A[0-9a-f]{64}\z/)
          def path?(value)
            value.is_a?(String) && value.valid_encoding? && value.bytesize.between?(1, 4096) &&
              value.start_with?("/") && !value.include?("\0") && File.expand_path(value) == value
          end
          def resource!(value)
            unless value.is_a?(Hash) && value.keys.sort == Molecules::ExecutionScopeLineage::RESOURCE_FIELDS.sort &&
                %w[host_path view_path].all? { |key| path?(value[key]) } &&
                %w[mount_id device inode].all? { |key| value[key].is_a?(Integer) && value[key].positive? } &&
                %w[uid gid].all? { |key| value[key].is_a?(Integer) && value[key] >= 0 } &&
                %w[ext4 xfs btrfs tmpfs].include?(value["filesystem_type"])
              MaintenanceWorkspaceRetirement.unavailable!("retirement evidence resource identity differs")
            end
          end
        end
        class Session
          attr_reader :projection
          def self.open!(**arguments) = new(**arguments)
          private_class_method :new

          def initialize(lifecycle:, mapping_id:, journal:, commit:, target:, projection:, evidence_owner:, deadline:, contexts:)
            @lifecycle, @mapping_id, @journal, @commit = lifecycle, mapping_id, journal, commit
            @target, @projection = MaintenanceWorkspaceRetirement.immutable(target), projection
            @owner, @deadline, @contexts = evidence_owner, deadline, contexts
            @thread, @active, @phase = Thread.current, true, nil
            @evidences = []
            @writer = @owner.retirement_workspace_writer!
            unless @writer.is_a?(Molecules::LifecycleExclusion::WorkspaceWriter) && @writer.projection == projection.fetch("workspace_exclusion")
              MaintenanceWorkspaceRetirement.unavailable!("retirement session requires the original maintained workspace writer")
            end
            verify_held!
          end

          def verify_captured!(evidence:) = verify_phase!("captured", evidence)
          def verify_removed!(evidence:) = verify_phase!("removed", evidence)
          def close!
            @active = false
            @evidences.each(&:expire!)
          end

          private

          def verify_held!
            unless @active && @thread.equal?(Thread.current) &&
                Thread.current[:ace_assign_maintenance_contexts]&.[](@lifecycle.object_id).equal?(@contexts)
              MaintenanceWorkspaceRetirement.unavailable!("retirement session no longer owns complete maintenance contexts")
            end
            @lifecycle.send(:maintenance_deadline!, @deadline)
            @lifecycle.send(:require_maintenance_context!, @mapping_id, @journal, @commit)
            @writer.verify_unchanged!
          end

          def verify_phase!(phase, evidence)
            unless evidence.is_a?(Evidence) && (phase == "captured" && @phase.nil? || phase == "removed" && @phase == "captured")
              MaintenanceWorkspaceRetirement.unavailable!("retirement session phase or evidence differs")
            end
            @evidences << evidence
            verify = -> {
              verify_held!
              evidence.verify!(owner: @owner, target: @target, projection: @projection, phase: phase, deadline: @deadline)
            }
            evidence.with_consumption(verify) do
              @lifecycle.send(:verify_retirement_contexts!, evidence: evidence, deadline: @deadline)
            end
            @phase = phase
            true
          end
        end
      end
    end
  end
end
