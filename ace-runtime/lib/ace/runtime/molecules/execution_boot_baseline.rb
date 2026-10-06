# frozen_string_literal: true
require "json"
require_relative "protected_artifact_set"

module Ace
  module Runtime
    module Molecules
      # Content authentication over the existing trusted host installer proof.
      # Actual original-host capture and boot refresh belong to gad.8/gad.b.
      class ExecutionBootBaseline
        LIMIT = 16_384
        ID = /\A[A-Za-z0-9][A-Za-z0-9._-]{0,127}\z/
        SHA = /\A[0-9a-f]{64}\z/
        BOOT = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/
        EXPECTED = %w[boot_id deployment_digest installer_artifact slot_id].freeze
        FIELDS = %w[boot_id deployment_digest host_ipc_namespace_identity original_host_context producer_artifact schema slot_id].freeze

        def initialize(artifacts: ProtectedArtifactSet.new)
          @artifacts = artifacts
        end

        # Fresh provisioning only. Never called for historical authentication.
        def select!(expected:)
          expected!(expected)
          @artifacts.with do
            path = "/etc/ace/execution-slots/#{expected.fetch('slot_id')}/boot-baseline-selection.json"
            bytes, = @artifacts.read_path!(path, limit: LIMIT)
            pointer = json!(bytes)
            object!(pointer, %w[baseline schema slot_id])
            refuse! unless pointer["schema"] == "ace.execution-boot-selection/v1" && pointer["slot_id"] == expected.fetch("slot_id")
            selected = pointer.fetch("baseline")
            baseline = authenticate!(selected, expected)
            @artifacts.verify_unchanged!
            immutable({"selection" => selected, "baseline" => baseline})
          end
        rescue KeyError, TypeError, NoMethodError, ArgumentError, IOError, SystemCallError, JSON::ParserError
          refuse!
        end

        # Pure original-ref reader: expected boot comes from canonical lineage,
        # not current discovery. Runtime owners separately check current boot.
        def verify!(selection:, expected:)
          expected!(expected)
          @artifacts.with do
            value = authenticate!(selection, expected)
            @artifacts.verify_unchanged!
            immutable(value)
          end
        rescue KeyError, TypeError, NoMethodError, ArgumentError, IOError, SystemCallError, JSON::ParserError
          refuse!
        end

        private

        def authenticate!(selected, expected)
          reference!(selected, limit: LIMIT)
          reference!(expected.fetch("installer_artifact"))
          value = json!(@artifacts.read!(selected))
          object!(value, FIELDS)
          reference!(value.fetch("producer_artifact"))
          unless value["schema"] == "ace.execution-boot-baseline/v1" &&
              value.values_at("boot_id", "deployment_digest", "slot_id") == expected.values_at("boot_id", "deployment_digest", "slot_id") &&
              value["producer_artifact"] == expected.fetch("installer_artifact")
            refuse!
          end
          @artifacts.read!(expected.fetch("installer_artifact"))
          identity = value.fetch("host_ipc_namespace_identity")
          object!(identity, %w[device inode])
          refuse! unless identity.values.all? { |number| number.is_a?(Integer) && number.positive? }
          context = value.fetch("original_host_context")
          object!(context, %w[gid pid started_at uid])
          unless context.values_at("pid", "uid", "gid").all? { |number| number.is_a?(Integer) } &&
              context.values_at("pid", "uid", "gid") == [1, 0, 0] && context["started_at"].is_a?(String) &&
              context["started_at"].match?(/\Alinux:#{Regexp.escape(expected.fetch('boot_id'))}:(?:0|[1-9][0-9]*)\z/) &&
              context["started_at"].bytesize <= 128
            refuse!
          end
          value
        end

        def expected!(value)
          object!(value, EXPECTED)
          refuse! unless value["slot_id"].is_a?(String) && ID.match?(value["slot_id"]) &&
            value["boot_id"].is_a?(String) && BOOT.match?(value["boot_id"]) &&
            value["deployment_digest"].is_a?(String) && SHA.match?(value["deployment_digest"])
          reference!(value.fetch("installer_artifact"))
        end

        def reference!(value, limit: ProtectedArtifactSet::LIMIT)
          object!(value, %w[bytes path sha256])
          refuse! unless value["path"].is_a?(String) && value["path"].bytesize.between?(1, 4096) &&
            value["path"].start_with?("/") && !value["path"].include?("\0") && File.expand_path(value["path"]) == value["path"] &&
            value["bytes"].is_a?(Integer) && value["bytes"].between?(1, limit) &&
            value["sha256"].is_a?(String) && SHA.match?(value["sha256"])
        end

        def json!(bytes)
          bytes = bytes.dup.force_encoding(Encoding::UTF_8)
          refuse! unless bytes.bytesize.between?(1, LIMIT) && bytes.valid_encoding?
          JSON.parse(bytes, create_additions: false, max_nesting: 8, allow_duplicate_key: false, allow_comments: false)
        end

        def object!(value, keys)
          refuse! unless value.is_a?(Hash) && value.keys.sort == keys.sort
        end

        def immutable(value)
          case value
          when Hash then value.to_h { |key, item| [key.dup.freeze, immutable(item)] }.freeze
          when Array then value.map { |item| immutable(item) }.freeze
          when String then value.dup.freeze
          else value
          end
        end

        def refuse!
          raise RuntimeUnavailableError, "authenticated original host boot baseline unavailable"
        end
      end
    end
  end
end
