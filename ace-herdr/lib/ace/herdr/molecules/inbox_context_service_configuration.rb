# frozen_string_literal: true

require "ace/runtime/molecules/protected_artifact_set"
require "ace/runtime/molecules/execution_unit_installation"
require_relative "inbox_context_store"

module Ace
  module Herdr
    module Molecules
      # The generated entry's accepted literal stage precedes the final owner.
      # Fresh key contents remain owned by InboxContextKey, not this snapshot.
      class InboxContextServiceConfiguration
        LIMIT = 65_536
        TOKEN = /\A[A-Za-z0-9][A-Za-z0-9._-]{0,127}\z/
        MAX_ID = (1 << 32) - 2
        STAGE_FIELDS = %w[codex_runtime configuration inbox_context_id project_id schema].freeze
        FIELDS = %w[authority control_socket_path deliveries_dir grants inbox_context_id key native_clients native_mapping_id owner_credentials project_id schema socket_gid state_root].freeze
        PURPOSES = %w[deliver enqueue maintenance_inventory observe_to_sign reconcile].freeze
        ROLES = %w[authority maintenance observer signer supervisor].freeze
        attr_reader :data, :reference, :codex_runtime_reference

        def self.load(stage:, artifacts: Ace::Runtime::Molecules::ProtectedArtifactSet.new)
          strict!(stage, STAGE_FIELDS)
          unless stage["schema"] == "ace.herdr.inbox-context-stage/v1"
            raise ValidationError, "context service stage differs"
          end
          runtime = stage.fetch("codex_runtime")
          metadata_reference!(runtime)
          load_configuration!(reference: stage.fetch("configuration"), project_id: stage.fetch("project_id"),
            inbox_context_id: stage.fetch("inbox_context_id"), runtime: runtime, artifacts: artifacts)
        rescue KeyError, TypeError, Ace::Runtime::RuntimeUnavailableError
          raise ValidationError, "context service configuration unavailable"
        end

        def self.load_static(configuration_reference:, project_id:, inbox_context_id:,
          artifacts: Ace::Runtime::Molecules::ProtectedArtifactSet.new)
          load_configuration!(reference: configuration_reference, project_id: project_id,
            inbox_context_id: inbox_context_id, runtime: nil, artifacts: artifacts)
        rescue KeyError, TypeError, Ace::Runtime::RuntimeUnavailableError
          raise ValidationError, "context service configuration unavailable"
        end

        def self.metadata_reference!(reference)
          strict!(reference, %w[bytes path sha256])
          unless path?(reference["path"]) && reference["bytes"].is_a?(Integer) && reference["bytes"].between?(1, LIMIT) &&
              reference["sha256"].is_a?(String) && reference["sha256"].match?(/\A[0-9a-f]{64}\z/)
            raise ValidationError, "context service metadata reference differs"
          end
        end

        def self.load_configuration!(reference:, project_id:, inbox_context_id:, runtime:, artifacts:)
          unless token?(project_id) && token?(inbox_context_id)
            raise ValidationError, "context service identity differs"
          end
          metadata_reference!(reference)
          artifacts.with do |reader|
            data = InboxContextStore.decode(reader.read!(reference), limit: LIMIT)
            validate!(data)
            unless data.values_at("project_id", "inbox_context_id") == [project_id, inbox_context_id]
              raise ValidationError, "context service configuration association differs"
            end
            reader.verify_unchanged!
            new(data, reference, runtime)
          end
        end
        private_class_method :metadata_reference!, :load_configuration!

        def self.validate!(data)
          strict!(data, FIELDS)
          unless data["schema"] == "ace.herdr.inbox-context-service/v1" &&
              %w[project_id inbox_context_id native_mapping_id].all? { |key| token?(data[key]) } &&
              %w[control_socket_path state_root deliveries_dir].all? { |key| path?(data[key]) }
            raise ValidationError, "context service configuration fields differ"
          end
          credentials!(data.fetch("owner_credentials"), root: false)
          native_clients!(data.fetch("native_clients"))
          authority = data.fetch("authority")
          strict!(authority, %w[gid groups socket_path uid])
          credentials!(authority.slice("uid", "gid", "groups"), root: false)
          raise ValidationError, "context service authority path differs" unless path?(authority["socket_path"])
          key = data.fetch("key")
          strict!(key, %w[configuration_path public_key_path])
          unless key.values.all? { |path| path?(path) } && key.values.uniq.size == 2
            raise ValidationError, "context service key paths differ"
          end
          grants = data.fetch("grants")
          unless grants.is_a?(Array) && grants.size.between?(1, 64) && grants.all? { |grant| grant.is_a?(Hash) } &&
              grants.map { |grant| grant["uid"] }.uniq.size == grants.size
            raise ValidationError, "context service grants overlap or exceed bounds"
          end
          grants.each do |grant|
            strict!(grant, %w[gid groups purposes role uid])
            credentials!(grant.slice("uid", "gid", "groups"), root: true)
            unless ROLES.include?(grant["role"]) && grant["purposes"].is_a?(Array) &&
                grant["purposes"] == grant["purposes"].sort.uniq && (grant["purposes"] - PURPOSES).empty? &&
                (grant["role"] != "maintenance" || grant["purposes"] == ["maintenance_inventory"])
              raise ValidationError, "context service grant differs"
            end
          end
          uid = data.fetch("owner_credentials").fetch("uid")
          if uid == authority.fetch("uid") || grants.any? { |grant| grant.fetch("uid") == uid }
            raise ValidationError, "context service owner overlaps a caller principal"
          end
          gid = data["socket_gid"]
          unless gid.is_a?(Integer) && gid.between?(1, MAX_ID) &&
              (data.fetch("owner_credentials").fetch("groups") + [data.fetch("owner_credentials").fetch("gid")]).include?(gid) &&
              grants.all? { |grant| grant.fetch("uid").zero? || (grant.fetch("groups") + [grant.fetch("gid")]).include?(gid) }
            raise ValidationError, "context service socket group is unavailable"
          end
          private_roots = data.values_at("state_root", "deliveries_dir")
          protected = key.values + [authority.fetch("socket_path"), data.fetch("control_socket_path")]
          if overlap?(*private_roots) || private_roots.any? { |root| protected.any? { |path| overlap?(root, path) } } ||
              data.fetch("control_socket_path") == authority.fetch("socket_path")
            raise ValidationError, "context service private roots overlap"
          end
          true
        rescue KeyError, TypeError, NoMethodError
          raise ValidationError, "context service configuration malformed"
        end

        def self.credentials!(value, root:)
          strict!(value, %w[gid groups uid])
          minimum = root ? 0 : 1
          unless value.values_at("uid", "gid").all? { |id| id.is_a?(Integer) && id.between?(minimum, MAX_ID) } &&
              value["groups"].is_a?(Array) && value["groups"].size <= 64 &&
              value["groups"].all? { |id| id.is_a?(Integer) && id.between?(0, MAX_ID) } &&
              value["groups"] == value["groups"].sort.uniq
            raise ValidationError, "context service credentials differ"
          end
        end

        # The accepted release owns executable startup bytes and IPC placement;
        # no PATH discovery, inherited HOME or ambient queue-client fallback.
        def self.native_clients!(value)
          strict!(value, %w[codex codex_runtime_intent codex_runtime_service cwd dependencies environment herdr pi resources])
          dependencies = value.fetch("dependencies")
          unless dependencies.is_a?(Array) && dependencies.size <= 506
            raise ValidationError, "context native dependency closure exceeds bounds"
          end
          unless value.fetch("codex_runtime_intent").is_a?(Hash) &&
              value.fetch("codex_runtime_intent")["bytes"].is_a?(Integer) &&
              value.fetch("codex_runtime_intent").fetch("bytes").between?(1, 65_536)
            raise ValidationError, "context Codex runtime intent exceeds bounds"
          end
          service = value.fetch("codex_runtime_service")
          codex_runtime_service!(service)
          refs = native_references(value)
          refs.each do |ref|
            strict!(ref, %w[bytes path sha256])
            unless path?(ref["path"]) && ref["bytes"].is_a?(Integer) && ref["bytes"].between?(1, 268_435_456) &&
                ref["sha256"].is_a?(String) && ref["sha256"].match?(/\A[0-9a-f]{64}\z/)
              raise ValidationError, "context native executable reference differs"
            end
          end
          unless refs.map { |ref| ref.fetch("path") }.uniq.size == refs.size &&
              refs.sum { |ref| ref.fetch("bytes") } <= 268_435_456 && path?(value["cwd"])
            raise ValidationError, "context native closure overlaps or exceeds bounds"
          end
          environment = value.fetch("environment")
          unless environment.is_a?(Hash) && environment.size <= 32 && environment.all? { |name, item|
            name.is_a?(String) && Ace::Runtime::Molecules::ExecutionUnitInstallation::NATIVE_ENVIRONMENT.include?(name) && item.is_a?(String) &&
              item.bytesize <= 4096 && item.encoding == Encoding::UTF_8 && item.valid_encoding? && !item.include?("\0")
          }
            raise ValidationError, "context native environment differs"
          end
          resources = value.fetch("resources")
          unless resources.is_a?(Array) && resources.size <= 64 && resources.all? { |row|
            row.is_a?(Hash) && row.keys.sort == %w[access gid kind mode path uid] && path?(row["path"]) &&
              %w[directory socket].include?(row["kind"]) && %w[read write].include?(row["access"]) &&
              row.values_at("uid", "gid").all? { |id| id.is_a?(Integer) && id.between?(0, MAX_ID) } &&
              row["mode"].is_a?(Integer) && row["mode"].between?(0, 0o777)
          } && resources.map { |row| row.fetch("path") }.uniq.size == resources.size &&
              resources.any? { |row| row.fetch("path") == value.fetch("cwd") && row.fetch("kind") == "directory" }
            raise ValidationError, "context native resource selection differs"
          end
          true
        rescue KeyError, TypeError, NoMethodError
          raise ValidationError, "context native selection is malformed"
        end

        def self.native_references(value)
          service = value.fetch("codex_runtime_service")
          value.values_at("codex", "pi", "herdr", "codex_runtime_intent") +
            service.values_at("unit_manifest", "boundary_manifest") + value.fetch("dependencies")
        end

        def self.codex_runtime_service!(service)
          strict!(service, %w[boundary_manifest execution_scope unit_manifest])
          %w[unit_manifest boundary_manifest].each do |name|
            ref = service.fetch(name)
            strict!(ref, %w[bytes path sha256])
            unless path?(ref["path"]) && ref["bytes"].is_a?(Integer) && ref["bytes"].between?(1, LIMIT) &&
                ref["sha256"].is_a?(String) && ref["sha256"].match?(/\A[0-9a-f]{64}\z/)
              raise ValidationError, "context Codex service reference differs"
            end
          end
          scope = service.fetch("execution_scope")
          strict!(scope, %w[backend boundary_manifest_sha256 network_namespace_path root_directory runtime_directory service_unit slice_unit slot_id unit_manifest_sha256])
          unless scope["backend"] == "linux_systemd_cgroup_v2" && token?(scope["slot_id"]) &&
              %w[root_directory runtime_directory network_namespace_path].all? { |key| path?(scope[key]) } &&
              scope["runtime_directory"].start_with?("/run/") && !overlap?(scope["root_directory"], scope["runtime_directory"]) &&
              {"service_unit" => ".service", "slice_unit" => ".slice"}.all? { |key, suffix|
                token?(scope[key]) && scope[key].end_with?(suffix) && !scope[key].downcase.include?("overseer")
              } && scope["unit_manifest_sha256"] == service.fetch("unit_manifest").fetch("sha256") &&
              scope["boundary_manifest_sha256"] == service.fetch("boundary_manifest").fetch("sha256")
            raise ValidationError, "context Codex service scope differs"
          end
        end

        def self.strict!(value, fields)
          raise ValidationError, "context service fields differ" unless value.is_a?(Hash) && value.keys.sort == fields
        end

        def self.token?(value) = value.is_a?(String) && TOKEN.match?(value)
        def self.path?(value)
          value.is_a?(String) && value.bytesize.between?(2, 4096) && value.start_with?("/") &&
            !value.match?(/[\s\0;]/) && File.expand_path(value) == value
        end
        def self.overlap?(left, right) = left == right || left.start_with?(right + "/") || right.start_with?(left + "/")

        private

        def initialize(data, reference, runtime)
          @data, @reference, @codex_runtime_reference = [data, reference, runtime].map { |value| immutable(value) }
          freeze
        end

        def immutable(value)
          case value
          when Hash then value.to_h { |key, item| [key.dup.freeze, immutable(item)] }.freeze
          when Array then value.map { |item| immutable(item) }.freeze
          when String then value.dup.freeze
          else value.freeze
          end
        end
        private_class_method :new
      end
    end
  end
end
