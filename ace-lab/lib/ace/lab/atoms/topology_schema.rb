# frozen_string_literal: true

module Ace
  module Lab
    module Atoms
      # Pure schema validation and normalization for ace-lab topology
      # configuration (spec 8wq.t.1w4). Takes the ADR-022-resolved config hash
      # and returns a normalized structure; raises
      # Ace::Lab::InvalidConfigurationError with an actionable message on any
      # violation (duplicate IDs, unknown project references, malformed
      # capabilities, invalid defaults, unsupported schema version).
      #
      # Normalization: strings are stripped, capabilities are lowercased,
      # binding state is lowercased. Unknown keys are ignored.
      module TopologySchema
        SCHEMA_VERSION = 1

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
              raise invalid("unsupported schema_version: #{version.inspect} (expected #{SCHEMA_VERSION})")
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
            projects = raw["projects"].to_a.map { |entry| normalized_project(entry) }
            project_ids = projects.map { |p| p["id"] }
            agents = raw["agents"].to_a.map { |entry| normalized_agent(entry, project_ids) }
            services = raw["services"].to_a.map { |entry| normalized_service(entry, project_ids) }

            ensure_globally_unique!(projects, agents, services)

            {"projects" => projects, "agents" => agents, "services" => services}
          end

          def normalized_project(entry)
            raise invalid("project entries must be mappings") unless entry.is_a?(Hash)

            {
              "id" => require_id(entry["id"], "project"),
              "label" => optional_string(entry["label"], "project #{entry["id"].inspect} label")
            }
          end

          def normalized_agent(entry, project_ids)
            raise invalid("agent entries must be mappings") unless entry.is_a?(Hash)

            id = require_id(entry["id"], "agent")
            project = require_project_ref(entry["project"], "agent #{id.inspect}", project_ids)

            {
              "id" => id,
              "project" => project,
              "label" => optional_string(entry["label"], "agent #{id.inspect} label"),
              "role" => require_non_empty(entry["role"], "agent #{id.inspect} role"),
              "capabilities" => normalize_capabilities(entry["capabilities"], "agent #{id.inspect}"),
              "binding" => normalize_binding(entry["binding"], "agent #{id.inspect}")
            }
          end

          def normalized_service(entry, project_ids)
            raise invalid("service entries must be mappings") unless entry.is_a?(Hash)

            id = require_id(entry["id"], "service")
            project = require_project_ref(entry["project"], "service #{id.inspect}", project_ids)
            capabilities = normalize_capabilities(entry["capabilities"], "service #{id.inspect}")

            {
              "id" => id,
              "project" => project,
              "label" => optional_string(entry["label"], "service #{id.inspect} label"),
              "capabilities" => capabilities,
              "default_for" => normalize_default_for(entry["default_for"], id, capabilities),
              "endpoint" => normalize_endpoint(entry["endpoint"], id),
              "binding" => normalize_binding(entry["binding"], "service #{id.inspect}")
            }
          end

          def ensure_globally_unique!(projects, agents, services)
            seen = Hash.new { |h, k| h[k] = [] }
            projects.each { |e| seen[e["id"]] << "projects" }
            agents.each { |e| seen[e["id"]] << "agents" }
            services.each { |e| seen[e["id"]] << "services" }

            duplicate, kinds = seen.find { |_id, list| list.length > 1 }
            return unless duplicate

            raise invalid("duplicate id #{duplicate.inspect} defined in #{kinds.join(" and ")}; " \
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
            principals = (principals_raw || {}).each_with_object({}) do |(principal, policy), out|
              name = require_non_empty(principal, "authorization principal name")
              raise invalid("authorization policy for principal #{name.inspect} must be a mapping") unless policy.is_a?(Hash)

              allowed = policy["projects"].to_a.map do |project|
                unless project_ids.include?(project)
                  raise invalid("principal #{name.inspect} references unknown project #{project.inspect}")
                end

                project
              end
              out[name] = {"projects" => allowed.uniq}
            end

            {"principals" => principals}
          end

          def require_id(value, kind)
            require_non_empty(value, "#{kind} id")
          end

          def require_project_ref(value, context, project_ids)
            project = require_non_empty(value, "#{context} project")
            unless project_ids.include?(project)
              raise invalid("#{context} references unknown project #{project.inspect}")
            end

            project
          end

          def normalize_capabilities(value, context)
            unless value.is_a?(Array)
              raise invalid("#{context} capabilities must be a non-empty array of strings")
            end

            capabilities = value.map do |capability|
              require_non_empty(capability, "#{context} capability").downcase
            end
            unless capabilities.any?
              raise invalid("#{context} capabilities must be a non-empty array of strings")
            end

            capabilities.uniq
          end

          def normalize_default_for(value, service_id, capabilities)
            return [] if value.nil?
            unless value.is_a?(Array)
              raise invalid("service #{service_id.inspect} default_for must be an array of capabilities")
            end

            value.map do |capability|
              normalized = require_non_empty(capability, "service #{service_id.inspect} default_for entry").downcase
              unless capabilities.include?(normalized)
                raise invalid("service #{service_id.inspect} defaults for capability #{normalized.inspect} " \
                              "it does not declare")
              end

              normalized
            end.uniq
          end

          def normalize_endpoint(value, service_id)
            unless value.is_a?(Hash)
              raise invalid("service #{service_id.inspect} endpoint must be a mapping with kind and url")
            end

            {
              "kind" => require_non_empty(value["kind"], "service #{service_id.inspect} endpoint kind"),
              "url" => require_non_empty(value["url"], "service #{service_id.inspect} endpoint url")
            }
          end

          def normalize_binding(value, context)
            unless value.is_a?(Hash)
              raise invalid("#{context} binding must be a mapping")
            end

            {
              "kind" => require_non_empty(value["kind"], "#{context} binding kind"),
              "state" => optional_string(value["state"], "#{context} binding state")&.downcase,
              "instance_id" => optional_string(value["instance_id"], "#{context} binding instance_id"),
              "attested_instance_id" => optional_string(value["attested_instance_id"], "#{context} binding attested_instance_id")
            }
          end

          def require_non_empty(value, what)
            unless value.is_a?(String) && !value.strip.empty?
              raise invalid("#{what} must be a non-empty string")
            end

            value.strip
          end

          def optional_string(value, what)
            return nil if value.nil?

            require_non_empty(value, what)
          end

          def invalid(message)
            Ace::Lab::InvalidConfigurationError.new("invalid lab configuration: #{message}")
          end
        end
      end
    end
  end
end
