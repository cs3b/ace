# frozen_string_literal: true
module Ace
  module Assign
    module Authority
      # Fixed installation data, never an observer-supplied endpoint or identity.
      module ObservationTrust
        FIELDS = %w[assignment_id attempt_id provider provider_version native_target runtime_process_binding endpoint_reference_sha256 observer_uid].freeze
        TARGET = %w[session pane terminal_id agent thread thread_kind].freeze
        PROCESS = %w[pid uid gid groups parent_pid started_at host].freeze
        TOKEN = /\A[A-Za-z0-9][A-Za-z0-9._-]{0,127}\z/
        SHA = /\A[0-9a-f]{64}\z/
        UUID = /\A[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}\z/i
        module_function

        def validate!(context, project, authority_uids)
          return true unless context.key?("runtime_bindings")
          dedicated = []
          %w[observer_uids signer_uids].each do |key|
            list = context.fetch(key)
            unless list.is_a?(Array) && !list.empty? && list == list.sort.uniq &&
                list.all? { |uid| uid.is_a?(Integer) && uid.positive? } &&
                (list - project.fetch(key)).empty?
              raise ArgumentError, "observation context principals differ"
            end
            dedicated.concat(list)
          end
          ordinary = %w[launcher_uids reviewer_uids worker_uids service_executor_uids supervisor_uids].flat_map { |key| project.fetch(key) }
          if dedicated.uniq != dedicated || !(dedicated & (ordinary + authority_uids + [context.fetch("owner_credentials").fetch("uid")])).empty?
            raise ArgumentError, "observation requires dedicated observer and signer principals"
          end
          bindings = context.fetch("runtime_bindings")
          unless bindings.is_a?(Hash) && !bindings.empty? && bindings.size <= 64 && bindings.keys.all? { |key| key.is_a?(String) && TOKEN.match?(key) }
            raise ArgumentError, "invalid observation runtime map"
          end
          bindings.each_value do |binding|
            unless binding.is_a?(Hash) && binding.keys.sort == FIELDS.sort &&
                %w[assignment_id attempt_id].all? { |key| binding[key].is_a?(String) && TOKEN.match?(binding[key]) } &&
                binding.values_at("provider", "provider_version") == ["codex", "0.159.3"] &&
                context.fetch("observer_uids").include?(binding["observer_uid"]) &&
                binding["endpoint_reference_sha256"].is_a?(String) && SHA.match?(binding["endpoint_reference_sha256"])
              raise ArgumentError, "invalid fixed observation runtime binding"
            end
            target, process = binding.values_at("native_target", "runtime_process_binding")
            unless target.is_a?(Hash) && target.keys.sort == TARGET.sort && target.values.all? { |value| value.is_a?(String) && value.valid_encoding? && value.bytesize.between?(1, 256) && !value.include?("\0") } &&
                target.values_at("agent", "thread_kind") == ["codex", "id"] && UUID.match?(target.fetch("thread")) && process?(process) &&
                !(project.fetch("worker_uids") + dedicated).include?(process.fetch("uid"))
              raise ArgumentError, "worker-controlled or malformed observation runtime"
            end
          end
          true
        end

        def process?(value)
          value.is_a?(Hash) && value.keys.sort == PROCESS.sort &&
            %w[pid uid gid parent_pid].all? { |key| value[key].is_a?(Integer) && value[key].positive? } &&
            value["groups"].is_a?(Array) && value["groups"].size <= 64 && value["groups"] == value["groups"].sort.uniq &&
            value["groups"].all? { |group| group.is_a?(Integer) && group.positive? } &&
            value["started_at"].is_a?(String) && value["started_at"].match?(/\Alinux:[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}:[0-9]+\z/i) &&
            value["host"].is_a?(String) && value["host"].bytesize.between?(1, 256) && !value["host"].include?("\0")
        end
      end
    end
  end
end
