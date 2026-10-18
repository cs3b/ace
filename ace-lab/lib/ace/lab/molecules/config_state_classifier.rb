# frozen_string_literal: true

module Ace
  module Lab
    module Molecules
      # Classifies the lab configuration namespace into exactly three
      # distinguished states (task 8xg.t.sbz.6.0): a valid empty set, missing
      # configuration, and a source error are never conflated.
      #
      #   :defaults_only — no overlay exists (gem defaults only) ⇒ missing
      #                    configuration; informational, exit-eligible success
      #   :configured    — at least one overlay present and valid; carries
      #                    topology counts (0/0/0 is a valid empty set)
      #   :invalid       — any cascade document unparsable/non-mapping or a
      #                    schema violation; carries the path-bearing message
      #
      # Also echoes runtime *configuration files* (project, user, ACE_RUNTIME
      # env): presence + the configured runtime value. No runtime detection
      # and no ace-runtime dependency — live runtime availability is
      # ace-herdr status's dimension.
      class ConfigStateClassifier
        RUNTIME_PATTERNS = %w[runtime/config.yml runtime/config.yaml].freeze

        class << self
          # @param documents [Array<Hash>, nil] cascade_documents output;
          #   nil means the cascade itself raised before documents existed
          # @param cascade_error [String, nil] path-bearing message from the
          #   InvalidConfigurationError raised while reading the cascade
          # @param root [String] project root for runtime config reads
          # @return [Hash] classified configuration section
          def classify(documents:, cascade_error: nil, root: Dir.pwd)
            return invalid_config(cascade_error) if cascade_error

            documents ||= []
            overlays = documents.reject { |document| document[:defaults] }
            return invalid_config("invalid lab configuration: no readable cascade documents") if documents.empty?

            project = overlays.find { |document| !document[:path].start_with?(Dir.home) }
            user = overlays.find { |document| document[:path].start_with?(Dir.home) }

            merged = deep_merge_documents(documents)
            begin
              topology = Atoms::TopologySchema.normalize!(merged).fetch("topology", {})
              {
                state: overlays.empty? ? :defaults_only : :configured,
                overlays: {project: project&.dig(:path), user: user&.dig(:path)},
                source_path: overlays.first&.dig(:path),
                error: nil,
                topology: {
                  projects: topology.fetch("projects", []).length,
                  agents: topology.fetch("agents", []).length,
                  services: topology.fetch("services", []).length
                }
              }
            rescue Ace::Lab::InvalidConfigurationError => e
              invalid_config(e.message)
            end
          end

          # Runtime configuration echo: files first (project, then user),
          # then the ACE_RUNTIME environment variable. Presence and value
          # only — never liveness.
          #
          # @param root [String] project root
          # @return [Hash] runtime configuration section
          def runtime_config(root: Dir.pwd)
            candidates = [
              {source: "project", paths: RUNTIME_PATTERNS.map { |pattern| File.join(root, ".ace", pattern) }},
              {source: "user", paths: RUNTIME_PATTERNS.map { |pattern| File.join(Dir.home, ".ace", pattern) }}
            ]
            found = candidates.find do |candidate|
              candidate[:paths].any? { |candidate_path| File.exist?(candidate_path) }
            end
            if found
              path = found[:paths].find { |candidate_path| File.exist?(candidate_path) }
              document = begin
                require "yaml"
                YAML.safe_load_file(path, permitted_classes: [Date], aliases: true)
              rescue StandardError
                nil
              end
              if document.is_a?(Hash)
                return {state: :valid, source: found[:source], path: path, runtime: document["runtime"]}
              end

              return {state: :invalid, source: found[:source], path: path, runtime: nil,
                      error: "#{path} could not be parsed as a YAML mapping"}
            end
            return runtime_from_env if ENV["ACE_RUNTIME"] && !ENV["ACE_RUNTIME"].empty?

            {state: :absent, source: nil, path: nil, runtime: nil}
          end

          private

          def runtime_from_env
            {state: :valid, source: "env", path: nil, runtime: ENV["ACE_RUNTIME"]}
          end

          def invalid_config(message)
            {
              state: :invalid,
              overlays: {},
              source_path: nil,
              error: message,
              topology: {projects: 0, agents: 0, services: 0}
            }
          end

          # Nearest-wins deep merge across cascade documents, gem defaults
          # first. Arrays replace (they are topology inventories, not
          # additive sets).
          def deep_merge_documents(documents)
            documents.sort_by { |document| document[:defaults] ? 0 : 1 }
              .map { |document| document[:document] }
              .reduce({}) { |merged, document| deep_merge(merged, document) }
          end

          def deep_merge(base, overlay)
            base.merge(overlay) do |_key, base_value, overlay_value|
              if base_value.is_a?(Hash) && overlay_value.is_a?(Hash)
                deep_merge(base_value, overlay_value)
              else
                overlay_value
              end
            end
          end
        end
      end
    end
  end
end
