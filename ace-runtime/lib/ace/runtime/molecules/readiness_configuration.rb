# frozen_string_literal: true

require "json"
require "digest"
require_relative "protected_artifact_set"

module Ace
  module Runtime
    module Molecules
      # Immutable local installer input. This contains selections only; live
      # process and resource observations must come from their owning readers.
      class ReadinessConfiguration
        LIMIT = 65_536
        SCHEMA = "ace.assign.readiness/v1"
        FIELDS = %w[authority boundary_manifest mapping_id native project_id runtime schema slot_id worker].freeze
        attr_reader :data

        def self.path(slot)
          unless slot.is_a?(String) && slot.match?(/\A[A-Za-z0-9][A-Za-z0-9._-]{0,127}\z/)
            raise RuntimeUnavailableError, "invalid readiness slot"
          end
          "/etc/ace/execution-slots/#{slot}/readiness.json"
        end

        def self.decode(bytes, slot:)
          text = bytes.dup.force_encoding(Encoding::UTF_8)
          unless text.bytesize.between?(1, LIMIT) && text.valid_encoding?
            raise RuntimeUnavailableError, "readiness configuration is not bounded UTF-8"
          end
          new(JSON.parse(text, create_additions: false, max_nesting: 8,
            allow_duplicate_key: false, allow_comments: false), slot: slot)
        rescue JSON::ParserError, EncodingError
          raise RuntimeUnavailableError, "readiness configuration is not strict JSON"
        end

        def self.load(slot:)
          ProtectedArtifactSet.new.with do |artifacts|
            bytes, = artifacts.read_path!(path(slot), limit: LIMIT)
            value = decode(bytes, slot: slot)
            artifacts.verify_unchanged!
            value
          end
        end

        def initialize(data, slot:)
          object!(data, FIELDS)
          unless data["schema"] == SCHEMA && data["slot_id"] == slot
            refuse!("readiness configuration selection differs")
          end
          %w[mapping_id project_id].each do |key|
            refuse!("invalid readiness identifier") unless data[key].is_a?(String) &&
              data[key].match?(/\A[A-Za-z0-9][A-Za-z0-9._-]{0,127}\z/)
          end
          object!(data.fetch("authority"), %w[gid groups socket_path uid])
          object!(data.fetch("worker"), %w[gid groups uid])
          %w[authority worker].each do |kind|
            principal = data.fetch(kind)
            unless %w[uid gid].all? { |key| principal[key].is_a?(Integer) && principal[key].positive? } &&
                principal["groups"].is_a?(Array) && principal["groups"].all? { |gid| gid.is_a?(Integer) && gid.positive? } &&
                principal["groups"].sort.uniq == principal["groups"]
              refuse!("readiness principal differs")
            end
          end
          native = data.fetch("native")
          object!(native, %w[executable executable_sha256 protocol socket_path version workspace_id])
          unless native["protocol"] == 22 && native["version"] == "0.9.3" &&
              native["workspace_id"].is_a?(String) && native["workspace_id"].match?(/\Aw[1-9][0-9]{0,8}\z/)
            refuse!("readiness native protocol differs")
          end
          digest!(native["executable_sha256"])
          boundary = data.fetch("boundary_manifest")
          object!(boundary, %w[path sha256])
          unless boundary["path"] == "/etc/ace/execution-slots/#{slot}/boundary-manifest.json"
            refuse!("readiness boundary path differs")
          end
          digest!(boundary["sha256"])
          [data.dig("authority", "socket_path"), native["socket_path"], native["executable"]].each { |path| path!(path) }
          runtime = data.fetch("runtime")
          object!(runtime, %w[dependencies interpreter_path load_paths])
          path!(runtime.fetch("interpreter_path"))
          paths = runtime.fetch("load_paths")
          unless paths.is_a?(Array) && paths.size.between?(1, 16) && paths.uniq == paths
            refuse!("readiness load paths differ")
          end
          paths.each { |path| path!(path) }
          dependencies = runtime.fetch("dependencies")
          unless dependencies.is_a?(Array) && dependencies.size.between?(1, 256) &&
              dependencies.map { |ref| ref.fetch("path") }.uniq.size == dependencies.size
            refuse!("readiness dependency closure differs")
          end
          dependencies.each do |ref|
            object!(ref, %w[bytes path sha256])
            path!(ref.fetch("path"))
            digest!(ref.fetch("sha256"))
            unless ref["bytes"].is_a?(Integer) && ref["bytes"].between?(1, ProtectedArtifactSet::LIMIT)
              refuse!("readiness dependency size differs")
            end
          end
          @data = immutable(data)
          freeze
        rescue KeyError, TypeError, ArgumentError
          refuse!("readiness configuration fields differ")
        end

        def verify_selection!(mapping_id:, mapping:, authority:, installation:)
          expected = {"schema" => SCHEMA, "slot_id" => mapping.fetch("execution_scope").fetch("slot_id"),
            "mapping_id" => mapping_id, "project_id" => mapping.fetch("project_id"),
            "authority" => authority.slice("socket_path", "uid", "gid", "groups"),
            "worker" => {"uid" => mapping.fetch("worker_uid"), "gid" => mapping.fetch("worker_gid"),
              "groups" => mapping.fetch("worker_groups")}, "native" => mapping.fetch("native"),
            "boundary_manifest" => {"path" => "/etc/ace/execution-slots/#{data.fetch('slot_id')}/boundary-manifest.json",
              "sha256" => mapping.fetch("execution_scope").fetch("boundary_manifest_sha256")}, "runtime" => data.fetch("runtime")}
          refuse!("readiness configuration does not join protected deployment") unless data == expected
          artifacts = installation.fetch("artifacts")
          closure = data.fetch("runtime").fetch("dependencies")
          unless closure.all? { |ref| artifacts.any? { |artifact|
              %w[runtime_dependency readiness_executable].include?(artifact.fetch("role")) &&
                artifact.fetch("view_path") == ref.fetch("path") && artifact.fetch("sha256") == ref.fetch("sha256") } } &&
              artifacts.any? { |artifact| artifact.fetch("role") == "runtime_dependency" &&
                artifact.fetch("view_path") == data.dig("runtime", "interpreter_path") }
            refuse!("readiness dependency closure does not join installation")
          end
          true
        end

        private

        def object!(value, keys)
          refuse!("readiness object fields differ") unless value.is_a?(Hash) && value.keys.sort == keys.sort
        end

        def path!(value)
          refuse!("readiness path differs") unless value.is_a?(String) && value.bytesize.between?(2, 4096) &&
            value.start_with?("/") && !value.include?("\0") && File.expand_path(value) == value
        end

        def digest!(value)
          refuse!("readiness digest differs") unless value.is_a?(String) && value.match?(/\A[0-9a-f]{64}\z/)
        end

        def immutable(value)
          case value
          when Hash then value.to_h { |key, item| [key.dup.freeze, immutable(item)] }.freeze
          when Array then value.map { |item| immutable(item) }.freeze
          when String then value.dup.freeze
          else value
          end
        end

        def refuse!(message) = raise(RuntimeUnavailableError, message)
      end
    end
  end
end
