# frozen_string_literal: true
require "json"
require_relative "protected_artifact_set"

module Ace
  module Runtime
    module Molecules
      # Current selection only. Original canonical bindings retain literal refs
      # and authenticate through NetworkInstallationEvidence without this pointer.
      class ExecutionNetworkSelection
        LIMIT = 65_536
        FIELDS = %w[installer_artifact policy_export profile report].freeze

        def initialize(artifacts: ProtectedArtifactSet.new)
          @artifacts = artifacts
        end

        # Shape validation confers no pointer access or network admission proof.
        def self.validate_static!(selection, slot_id:)
          new.send(:static!, selection, slot_id)
        end

        def select!(static_selection:, slot_id:)
          static_selection = immutable(static_selection)
          path = static!(static_selection, slot_id)
          @artifacts.with do
            bytes, = @artifacts.read_path!(path, limit: LIMIT)
            bytes = bytes.dup.force_encoding(Encoding::UTF_8)
            refuse! unless bytes.valid_encoding? && bytes.bytesize.between?(1, LIMIT)
            pointer = JSON.parse(bytes, create_additions: false, max_nesting: 16, allow_duplicate_key: false, allow_comments: false)
            object!(pointer, %w[schema selection slot_id])
            refuse! unless pointer["schema"] == "ace.network-installation-selection/v1" && pointer["slot_id"] == slot_id
            selection = pointer.fetch("selection")
            object!(selection, FIELDS)
            selection.each_value { |ref| reference!(ref) }
            refuse! unless %w[profile installer_artifact].all? { |name| selection.fetch(name) == static_selection.fetch(name) }
            selection.each_value { |ref| @artifacts.read!(ref) }
            @artifacts.verify_unchanged!
            immutable(selection)
          end
        rescue KeyError, TypeError, NoMethodError, ArgumentError, IOError, SystemCallError, JSON::ParserError, EncodingError
          refuse!
        end

        private

        def static!(selection, slot_id)
          object!(selection, %w[current_selection_path installer_artifact profile])
          refuse! unless slot_id.is_a?(String) && slot_id.match?(/\A[A-Za-z0-9][A-Za-z0-9._-]{0,127}\z/)
          path = "/etc/ace/execution-slots/#{slot_id}/network-installation-selection.json"
          refuse! unless selection.fetch("current_selection_path") == path
          %w[profile installer_artifact].each { |name| reference!(selection.fetch(name)) }
          path
        rescue KeyError, TypeError, NoMethodError, ArgumentError
          refuse!
        end

        def reference!(value)
          object!(value, %w[bytes path sha256])
          path = value.fetch("path")
          refuse! unless path.is_a?(String) && path.bytesize.between?(1, 4096) && path.start_with?("/") &&
            !path.include?("\0") && File.expand_path(path) == path && value["bytes"].is_a?(Integer) &&
            value["bytes"].between?(1, ProtectedArtifactSet::LIMIT) && value["sha256"].is_a?(String) &&
            value["sha256"].match?(/\A[0-9a-f]{64}\z/)
        end

        def object!(value, keys)
          refuse! unless value.is_a?(Hash) && value.keys.sort == keys.sort
        end

        def immutable(value)
          case value
          when Hash then value.to_h { |key, item| [key.dup.freeze, immutable(item)] }.freeze
          when String then value.dup.freeze
          else value
          end
        end

        def refuse!
          raise RuntimeUnavailableError, "protected current network selection unavailable"
        end
      end
    end
  end
end
