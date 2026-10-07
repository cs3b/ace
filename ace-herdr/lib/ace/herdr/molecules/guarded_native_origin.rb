# frozen_string_literal: true
require "ace/runtime/errors"

module Ace
  module Herdr
    module Molecules
      # Closed N1 producer value. Native endpoint selection and kernel capture
      # belong to ProtectedNativeControl; this value never discovers a target.
      module GuardedNativeOrigin
        UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/
        TERMINAL = /\Aterm_[0-9a-f]{2,48}\z/
        CHILD_FIELDS = %w[gid groups host parent_pid pid started_at uid].freeze
        module_function

        def verify!(value, terminal_id:, child:)
          unless value.is_a?(Hash) && value.keys.all? { |key| key.is_a?(String) } && value.keys.sort == %w[child runtime_incarnation terminal_id] &&
              value["terminal_id"] == terminal_id && terminal_id.is_a?(String) && terminal_id.ascii_only? && TERMINAL.match?(terminal_id) &&
              value["runtime_incarnation"].is_a?(String) && value["runtime_incarnation"].ascii_only? && UUID.match?(value["runtime_incarnation"])
            unavailable!
          end
          identity = value.fetch("child")
          unless identity.is_a?(Hash) && identity.keys.all? { |key| key.is_a?(String) } && identity.keys.sort == CHILD_FIELDS && identity == child &&
              %w[pid parent_pid].all? { |key| uint32?(identity[key]) && identity[key].positive? } &&
              %w[uid gid].all? { |key| uint32?(identity[key]) } && identity["groups"].is_a?(Array) &&
              identity["groups"].size <= 256 && identity["groups"].all? { |group| uint32?(group) } &&
              identity["groups"] == identity["groups"].sort.uniq && valid_birth?(identity["started_at"]) &&
              identity["host"].is_a?(String) && identity["host"].valid_encoding? && (identity["host"].encoding == Encoding::UTF_8 || identity["host"].ascii_only?) &&
              identity["host"].bytesize.between?(1, 255) && !identity["host"].match?(/\p{Cc}/)
            unavailable!
          end
          immutable(value)
        end

        def uint32?(value) = value.is_a?(Integer) && value.between?(0, 0xffff_ffff)

        def valid_birth?(value)
          return false unless value.is_a?(String) && value.ascii_only?
          parts = value.split(":", -1)
          parts.size == 3 && parts[0] == "linux" && UUID.match?(parts[1]) &&
            parts[2].match?(/\A[0-9]+\z/) && parts[2].to_i.between?(1, 0xffff_ffff_ffff_ffff)
        end

        def immutable(value)
          case value
          when Hash then value.to_h { |key, item| [key.dup.freeze, immutable(item)] }.freeze
          when Array then value.map { |item| immutable(item) }.freeze
          when String then value.dup.freeze
          else value.freeze
          end
        end

        def unavailable!
          raise Ace::Runtime::RuntimeUnavailableError, "original native guarded origin is unavailable"
        end
        private_class_method :uint32?, :valid_birth?, :immutable, :unavailable!
      end
    end
  end
end
