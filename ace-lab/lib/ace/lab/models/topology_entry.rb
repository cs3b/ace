# frozen_string_literal: true

require_relative "runtime_binding"

module Ace
  module Lab
    module Models
      # Immutable stable-ID registry entry (spec 8wq.t.1w4). One of:
      # project, agent, or service. Stable IDs are canonical; labels are
      # display values only. Built from schema-normalized configuration.
      class TopologyEntry
        KINDS = %w[project agent service].freeze

        attr_reader :kind, :id, :project, :label, :role, :capabilities,
          :default_for, :endpoint, :binding

        def initialize(kind:, id:, project: nil, label: nil, role: nil,
          capabilities: [], default_for: [], endpoint: nil, binding: nil)
          unless KINDS.include?(kind)
            raise ArgumentError, "unknown entry kind: #{kind}"
          end

          @kind = kind
          # Defensive copies: public projections expose these strings, and a
          # mutated shared string would corrupt the stable-ID/index invariant
          # or freshness facts (review round 15, F1)
          @id = id.dup.freeze
          @project = project && project.dup.freeze
          @label = label && label.dup.freeze
          @role = role && role.dup.freeze
          @capabilities = capabilities.map(&:dup).freeze
          @default_for = default_for.map(&:dup).freeze
          @endpoint = endpoint && endpoint.transform_values(&:dup).freeze
          @binding = binding
          freeze
        end

        def self.project(hash)
          new(kind: "project", id: hash["id"], label: hash["label"])
        end

        def self.agent(hash)
          new(
            kind: "agent", id: hash["id"], project: hash["project"],
            label: hash["label"], role: hash["role"],
            capabilities: hash["capabilities"],
            binding: Models::RuntimeBinding.from_h(hash["binding"] || {})
          )
        end

        def self.service(hash)
          new(
            kind: "service", id: hash["id"], project: hash["project"],
            label: hash["label"], capabilities: hash["capabilities"],
            default_for: hash["default_for"], endpoint: hash["endpoint"],
            binding: Models::RuntimeBinding.from_h(hash["binding"] || {})
          )
        end

        def project?
          kind == "project"
        end

        # Capability check for routing; capabilities are normalized
        # (stripped, lowercased) at schema validation
        def capable_of?(capability)
          capabilities.include?(capability)
        end
      end
    end
  end
end
