# frozen_string_literal: true

require "uri"

module Ace
  module Lab
    module Atoms
      # Pure schema validation and normalization for ace-lab topology
      # configuration (spec 8wq.t.1w4). Takes the ADR-022-resolved config hash
      # and returns a normalized structure; raises
      # Ace::Lab::InvalidConfigurationError on any violation (duplicate IDs,
      # unknown project references, malformed capabilities, invalid defaults,
      # unusable endpoints, unsupported schema version).
      #
      # Normalization: strings are stripped, capabilities are lowercased,
      # binding state is lowercased. Unknown keys are ignored.
      #
      # Error messages use positional field locations (e.g.
      # "topology.agents[0].project") and never echo configured values:
      # validation runs before authorization, so messages must not disclose
      # topology to unauthorized callers (review round 2, R2).
      module TopologySchema
        SCHEMA_VERSION = 1
        ENDPOINT_KINDS = %w[http https].freeze

        class << self
          # Validate and normalize the full lab configuration
          #
          # @param config [Hash] ADR-022-resolved configuration
          # @return [Hash] Normalized configuration
          # @raise [Ace::Lab::InvalidConfigurationError]
          def normalize!(config)
            raise invalid("configuration must be a mapping") unless config.is_a?(Hash)

            version = config["schema_version"]
            unless version == SCHEMA_VERSION
              raise invalid("unsupported schema_version (expected #{SCHEMA_VERSION})")
            end

            topology = normalized_topology(config["topology"])
            authorization = normalized_authorization(config["authorization"], topology)

            {
              "schema_version" => SCHEMA_VERSION,
              "authorization" => authorization,
              "topology" => topology
            }
          end

          private

          def normalized_topology(raw)
            raise invalid("topology must be a mapping") unless raw.nil? || raw.is_a?(Hash)

            raw ||= {}
            projects = require_array(raw["projects"], "topology.projects").map.with_index do |entry, i|
              normalized_project(entry, "topology.projects[#{i}]")
            end
            project_ids = projects.map { |p| p["id"] }
            agents = require_array(raw["agents"], "topology.agents").map.with_index do |entry, i|
              normalized_agent(entry, "topology.agents[#{i}]", project_ids)
            end
            services = require_array(raw["services"], "topology.services").map.with_index do |entry, i|
              normalized_service(entry, "topology.services[#{i}]", project_ids)
            end

            ensure_globally_unique!(projects, agents, services)

            {"projects" => projects, "agents" => agents, "services" => services}
          end

          def normalized_project(entry, context)
            raise invalid("#{context} must be a mapping") unless entry.is_a?(Hash)

            {
              "id" => require_id(entry["id"], "#{context}.id"),
              "label" => optional_string(entry["label"], "#{context}.label")
            }
          end

          def normalized_agent(entry, context, project_ids)
            raise invalid("#{context} must be a mapping") unless entry.is_a?(Hash)

            id = require_id(entry["id"], "#{context}.id")
            project = require_project_ref(entry["project"], "#{context}.project", project_ids)

            {
              "id" => id,
              "project" => project,
              "label" => optional_string(entry["label"], "#{context}.label"),
              "role" => require_non_empty(entry["role"], "#{context}.role must be a non-empty string"),
              "capabilities" => normalize_capabilities(entry["capabilities"], "#{context}.capabilities"),
              "binding" => normalize_binding(entry["binding"], "#{context}.binding")
            }
          end

          def normalized_service(entry, context, project_ids)
            raise invalid("#{context} must be a mapping") unless entry.is_a?(Hash)

            id = require_id(entry["id"], "#{context}.id")
            project = require_project_ref(entry["project"], "#{context}.project", project_ids)
            capabilities = normalize_capabilities(entry["capabilities"], "#{context}.capabilities")

            {
              "id" => id,
              "project" => project,
              "label" => optional_string(entry["label"], "#{context}.label"),
              "capabilities" => capabilities,
              "default_for" => normalize_default_for(entry["default_for"], "#{context}.default_for", capabilities),
              "endpoint" => normalize_endpoint(entry["endpoint"], "#{context}.endpoint"),
              "binding" => normalize_binding(entry["binding"], "#{context}.binding")
            }
          end

          def ensure_globally_unique!(projects, agents, services)
            seen = Hash.new { |h, k| h[k] = [] }
            projects.each_with_index { |e, i| seen[e["id"]] << "topology.projects[#{i}]" }
            agents.each_with_index { |e, i| seen[e["id"]] << "topology.agents[#{i}]" }
            services.each_with_index { |e, i| seen[e["id"]] << "topology.services[#{i}]" }

            _id, locations = seen.find { |_key, list| list.length > 1 }
            return unless locations

            raise invalid("duplicate stable id: #{locations.join(" and ")} define the same id; " \
                          "stable IDs must be globally unique")
          end

          def normalized_authorization(raw, topology)
            raise invalid("authorization must be a mapping") unless raw.nil? || raw.is_a?(Hash)

            raw ||= {}
            principals_raw = raw["principals"]
            unless principals_raw.nil? || principals_raw.is_a?(Hash)
              raise invalid("authorization.principals must be a mapping")
            end

            project_ids = topology["projects"].map { |p| p["id"] }
            principals = (principals_raw || {}).map.with_index do |(principal, policy), i|
              context = "authorization.principals[#{i}]"
              name = require_non_empty(principal, "#{context} name must be a non-empty string")
              raise invalid("#{context} policy must be a mapping") unless policy.is_a?(Hash)

              allowed = require_array(policy["projects"], "#{context}.projects").map.with_index do |project, j|
                unless project_ids.include?(project)
                  raise invalid("#{context}.projects[#{j}] references an unknown project")
                end

                project
              end
              [name, {"projects" => allowed.uniq}]
            end

            {"principals" => principals.to_h}
          end

          def require_id(value, context)
            require_non_empty(value, "#{context} must be a non-empty string")
          end

          # Malformed collections must classify as invalid_configuration, not
          # crash with NoMethodError/TypeError mid-iteration (review R2)
          def require_array(value, context)
            return [] if value.nil?
            raise invalid("#{context} must be an array") unless value.is_a?(Array)

            value
          end

          def require_project_ref(value, context, project_ids)
            project = require_non_empty(value, "#{context} must be a non-empty string")
            unless project_ids.include?(project)
              raise invalid("#{context} references an unknown project")
            end

            project
          end

          def normalize_capabilities(value, context)
            unless value.is_a?(Array)
              raise invalid("#{context} must be a non-empty array of strings")
            end

            capabilities = value.map do |capability|
              require_non_empty(capability, "#{context} entry must be a non-empty string").downcase
            end
            unless capabilities.any?
              raise invalid("#{context} must be a non-empty array of strings")
            end

            capabilities.uniq
          end

          def normalize_default_for(value, context, capabilities)
            return [] if value.nil?
            unless value.is_a?(Array)
              raise invalid("#{context} must be an array of capabilities")
            end

            value.map do |capability|
              normalized = require_non_empty(capability, "#{context} entry must be a non-empty string").downcase
              unless capabilities.include?(normalized)
                raise invalid("#{context} entry does not match a declared capability")
              end

              normalized
            end.uniq
          end

          def normalize_endpoint(value, context)
            unless value.is_a?(Hash)
              raise invalid("#{context} must be a mapping with kind and url")
            end

            kind = require_non_empty(value["kind"], "#{context}.kind must be a non-empty string").downcase
            unless ENDPOINT_KINDS.include?(kind)
              raise invalid("#{context}.kind must be one of: #{ENDPOINT_KINDS.join(", ")}")
            end

            url = require_non_empty(value["url"], "#{context}.url must be a non-empty string")
            validate_endpoint_url(url, context)

            {"kind" => kind, "url" => url}
          end

          # A malformed endpoint must fail configuration loading, never
          # become a routing candidate with an empty public identity
          # (review round 2, R1)
          def validate_endpoint_url(url, context)
            uri = URI.parse(url)
            usable = (uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)) && uri.host && !uri.host.empty?
            raise invalid("#{context}.url must be an absolute http(s) URL with a host") unless usable
          rescue URI::Error, ArgumentError
            raise invalid("#{context}.url must be an absolute http(s) URL with a host")
          end

          def normalize_binding(value, context)
            unless value.is_a?(Hash)
              raise invalid("#{context} must be a mapping")
            end

            {
              "kind" => require_non_empty(value["kind"], "#{context}.kind must be a non-empty string"),
              "state" => optional_string(value["state"], "#{context}.state")&.downcase,
              "instance_id" => optional_string(value["instance_id"], "#{context}.instance_id"),
              "attested_instance_id" => optional_string(value["attested_instance_id"], "#{context}.attested_instance_id")
            }
          end

          def require_non_empty(value, message)
            raise invalid(message) unless value.is_a?(String) && !value.strip.empty?

            value.strip
          end

          def optional_string(value, context)
            return nil if value.nil?

            require_non_empty(value, "#{context} must be a non-empty string")
          end

          def invalid(message)
            Ace::Lab::InvalidConfigurationError.new("invalid lab configuration: #{message}")
          end
        end
      end
    end
  end
end
