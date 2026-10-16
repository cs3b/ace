# frozen_string_literal: true

module Ace
  module Herdr
    module Atoms
      # Herdr reports Pi sessions as paths and Codex sessions as IDs. Both
      # consumers bind the same immutable UUID; names never identify a session.
      module NativeAgentSession
        UUID = /\A[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}\z/
        PI_PATH = /_([0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12})\.jsonl\z/

        def self.normalize(session, agent:)
          return nil unless %w[codex pi].include?(agent) && session.is_a?(Hash) && session["agent"] == agent

          value = session["value"]
          return nil unless value.is_a?(String) && value.valid_encoding? && !value.include?("\0")

          kind = session["kind"]
          if agent == "pi" && kind == "path"
            return nil unless value.start_with?("/") && value.bytesize <= 4096

            value = PI_PATH.match(value)&.captures&.first
            kind = "id"
          end
          return nil unless kind == "id" && value.is_a?(String) && UUID.match?(value)

          {"agent" => agent, "kind" => "id", "value" => value}
        end
      end
    end
  end
end
