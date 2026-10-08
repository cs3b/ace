# frozen_string_literal: true

module Ace
  module Runtime
    module Molecules
      # Private specialization of the SAME immutable/effective installation owner.
      class ExecutionUnitInstallation
        CODEX_TOKEN = /\A[A-Za-z0-9][A-Za-z0-9._-]{0,127}\z/.freeze
        CODEX_INTENT_FIELDS = %w[codex credentials cwd dependencies environment home inbox_context_id native_mapping_id project_id schema socket_gid socket_path thread_configuration unit_name].freeze

        private

        def initialize_codex_runtime(service, reference, mapping, mapping_id, authority, files)
          unless service.is_a?(Hash) && service.keys.sort == %w[boundary_manifest execution_scope unit_manifest] &&
              mapping.is_a?(Hash) && mapping_id.is_a?(String) && SystemdScopeManager::UNIT.match?(mapping_id)
            raise RuntimeUnavailableError, "Codex service selection differs"
          end
          [reference, *service.values_at("unit_manifest", "boundary_manifest")].each { |ref| codex_reference!(ref, 65_536) }
          bytes = files.read(reference.fetch("path"), limit: reference.fetch("bytes"))
          unless bytes.bytesize == reference.fetch("bytes") && Digest::SHA256.hexdigest(bytes) == reference.fetch("sha256")
            raise RuntimeUnavailableError, "Codex intent bytes differ"
          end
          intent = JSON.parse(bytes, create_additions: false, max_nesting: 32, allow_duplicate_key: false, allow_comments: false)
          unless intent.is_a?(Hash) && intent.keys.sort == CODEX_INTENT_FIELDS.sort &&
              intent["schema"] == "lab.codex-runtime-intent/v1" &&
              intent.values_at("project_id", "native_mapping_id", "cwd") == [mapping.fetch("project_id"), mapping_id, mapping.fetch("worker_cwd")] &&
              intent["unit_name"].is_a?(String) && SystemdScopeManager::UNIT.match?(intent["unit_name"]) && intent["unit_name"].end_with?(".service") &&
              intent["credentials"] == {"uid" => mapping.fetch("worker_uid"), "gid" => mapping.fetch("worker_gid"), "groups" => mapping.fetch("worker_groups")}
            raise RuntimeUnavailableError, "Codex intent original mapping differs"
          end
          credentials = intent.fetch("credentials")
          unless credentials.values_at("uid", "gid").all? { |id| id.is_a?(Integer) && id.positive? && id <= (1 << 32) - 2 } &&
              credentials["groups"].is_a?(Array) && credentials["groups"].size <= 64 &&
              credentials["groups"] == credentials["groups"].sort.uniq &&
              credentials["groups"].all? { |id| id.is_a?(Integer) && id.between?(0, (1 << 32) - 2) }
            raise RuntimeUnavailableError, "Codex original native credentials differ"
          end
          original = mapping.fetch("execution_scope")
          scope = service.fetch("execution_scope")
          changes = %w[service_unit unit_manifest_sha256]
          unless scope.is_a?(Hash) && scope.keys.sort == %w[backend boundary_manifest_sha256 network_namespace_path root_directory runtime_directory service_unit slice_unit slot_id unit_manifest_sha256] &&
              scope["backend"] == "linux_systemd_cgroup_v2" && scope.keys.sort == original.keys.sort &&
              scope.reject { |key, _| changes.include?(key) } == original.reject { |key, _| changes.include?(key) } &&
              scope["service_unit"] == intent.fetch("unit_name") && scope["service_unit"] != original.fetch("service_unit") &&
              scope["unit_manifest_sha256"] == service.fetch("unit_manifest").fetch("sha256") &&
              scope["boundary_manifest_sha256"] == service.fetch("boundary_manifest").fetch("sha256")
            raise RuntimeUnavailableError, "Codex service expands original containment"
          end
          codex_reference!(intent.fetch("codex"), 268_435_456)
          dependencies = intent.fetch("dependencies")
          unless dependencies.is_a?(Array) && dependencies.size <= 506 && ([intent.fetch("codex")] + dependencies).map { |ref| ref.fetch("path") }.uniq.size == dependencies.size + 1
            raise RuntimeUnavailableError, "Codex selected dependency inventory differs"
          end
          dependencies.each { |ref| codex_reference!(ref, 268_435_456) }
          unless ([intent.fetch("codex")] + dependencies).sum { |ref| ref.fetch("bytes") } <= 268_435_456 &&
              path?(intent["cwd"]) && path?(intent["home"]) && path?(intent["socket_path"]) &&
              intent["socket_path"].encoding == Encoding::UTF_8 && intent["socket_path"].valid_encoding? && intent["socket_path"].bytesize <= 107 &&
              intent["socket_gid"].is_a?(Integer) && intent["socket_gid"].between?(1, (1 << 32) - 2) &&
              intent["inbox_context_id"].is_a?(String) && CODEX_TOKEN.match?(intent["inbox_context_id"]) &&
              intent["thread_configuration"].is_a?(Hash) && intent["thread_configuration"].keys.sort == %w[approval_policy model sandbox] &&
              intent["thread_configuration"].values_at("approval_policy", "sandbox") == ["never", "danger-full-access"] &&
              intent["thread_configuration"]["model"].is_a?(String) && CODEX_TOKEN.match?(intent["thread_configuration"]["model"])
            raise RuntimeUnavailableError, "Codex runtime input bounds differ"
          end
          environment = intent.fetch("environment")
          unless environment.is_a?(Hash) && environment.size <= 32 && environment.all? { |key, value|
            NATIVE_ENVIRONMENT.include?(key) && value.is_a?(String) && value.encoding == Encoding::UTF_8 &&
              value.valid_encoding? && value.bytesize <= 4096 && !value.include?("\0") } &&
              (!environment.key?("HOME") || environment["HOME"] == intent.fetch("home"))
            raise RuntimeUnavailableError, "Codex runtime environment differs"
          end
          @codex_service, @codex_intent = immutable_selection(service), immutable_selection(intent)
          @codex_intent_reference, @codex_authority = immutable_selection(reference), immutable_selection(authority)
          @scope, @files = immutable_selection(scope), files
          @worker_uid, @worker_gid, @codex_groups = credentials.values_at("uid", "gid", "groups")
          @codex_groups = immutable_selection(@codex_groups)
        rescue KeyError, TypeError, NoMethodError, ArgumentError, JSON::ParserError
          raise RuntimeUnavailableError, "Codex installation selection is incomplete"
        end

        def codex_reference!(ref, limit)
          unless ref.is_a?(Hash) && ref.keys.sort == %w[bytes path sha256] && path?(ref["path"]) &&
              ref["bytes"].is_a?(Integer) && ref["bytes"].between?(1, limit) &&
              ref["sha256"].is_a?(String) && ref["sha256"].match?(/\A[0-9a-f]{64}\z/)
            raise RuntimeUnavailableError, "Codex immutable reference differs"
          end
        end

        def codex_reference_bytes!(ref)
          bytes = @files.read(ref.fetch("path"), limit: ref.fetch("bytes"))
          unless bytes.bytesize == ref.fetch("bytes") && Digest::SHA256.hexdigest(bytes) == ref.fetch("sha256")
            raise RuntimeUnavailableError, "Codex selected artifact bytes differ"
          end
          bytes
        end

        def verify_codex_artifacts!(roles)
          {"native_executable" => @codex_intent.fetch("codex"), "native_configuration" => @codex_intent_reference,
            "boundary_manifest" => @codex_service.fetch("boundary_manifest")}.each do |role, ref|
            artifact = roles.fetch(role).first
            unless artifact.values_at("host_path", "view_path", "sha256") == ref.values_at("path", "path", "sha256") &&
                codex_reference_bytes!(ref).bytesize == ref.fetch("bytes")
              raise RuntimeUnavailableError, "Codex artifact differs from original selection"
            end
          end
          unless roles.fetch("runtime_dependency", []).size == @codex_intent.fetch("dependencies").size
            raise RuntimeUnavailableError, "Codex installed dependency inventory differs"
          end
          @codex_intent.fetch("dependencies").each do |ref|
            selected = roles.fetch("runtime_dependency", []).select { |artifact| artifact.values_at("host_path", "view_path", "sha256") == ref.values_at("path", "path", "sha256") }
            unless selected.one? && codex_reference_bytes!(ref).bytesize == ref.fetch("bytes")
              raise RuntimeUnavailableError, "Codex selected dependency is not installed"
            end
          end
          roles
        end

        def verify_codex_protocol!(service, artifacts)
          executable = @codex_intent.fetch("codex").fetch("path")
          verify_command!(service.fetch("ExecStartEx"), executable)
          expected = @codex_intent.fetch("environment").merge("HOME" => @codex_intent.fetch("home")).map { |key, value| "#{key}=#{value}" }.sort
          unless service.fetch("ExecStartEx").first[1] == [executable, "app-server", "--listen", "unix://" + @codex_intent.fetch("socket_path")] &&
              service.fetch("ExecStartPostEx") == [] && service.fetch("Environment").sort == expected
            raise RuntimeUnavailableError, "Codex unit commands differ from fixed startup protocol"
          end
        end
      end
    end
  end
end
