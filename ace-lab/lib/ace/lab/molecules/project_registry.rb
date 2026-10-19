# frozen_string_literal: true

require_relative "../errors"
require_relative "../atoms/topology_schema"

module Ace
  module Lab
    module Molecules
      # Reads and updates the project registry: the project-tier lab
      # configuration at `<project>/.ace/lab/config.yml` (task
      # 8xg.t.sbz.7.1). This is the same ADR-022 cascade document every
      # consumer already reads (`ace-lab status`, `ace-lab projects`,
      # `ace-overseer projects`), so registering a project here makes it
      # visible to the whole chain — no second registry exists.
      #
      # Project entries carry the deployment facts the installer owns:
      # id, label, absolute path and origin remote. `TopologySchema`
      # ignores unknown keys, so the query surface (PublicProjection)
      # is unchanged. The molecule is idempotent and refuses before any
      # overwrite: a contradictory registration (same id, different
      # path/remote), a location conflict (same path, different id), an
      # unparseable or foreign document — all fail without writing.
      class ProjectRegistry
        REGISTRY_PATH = File.join(".ace", "lab", "config.yml")
        SCHEMA_VERSION = 1

        # @param root [String] absolute project root
        # @return [Hash, nil] parsed registry document, nil when absent
        # @raise [Ace::Lab::InvalidConfigurationError] unparseable or
        #   non-mapping document
        def load(root:)
          path = registry_path(root)
          return nil unless File.file?(path)

          require "yaml"
          document = YAML.safe_load_file(path, permitted_classes: [Date], aliases: true)
          unless document.nil? || document.is_a?(Hash)
            raise Ace::Lab::InvalidConfigurationError,
              "#{path} must contain a YAML mapping"
          end
          document || {}
        end

        # @param root [String] absolute project root
        # @return [String] absolute registry path
        def registry_path(root)
          File.join(root, REGISTRY_PATH)
        end

        # Idempotently register a project.
        #
        # @param root [String] absolute project root
        # @param project [Hash] {"id" =>, "label" =>, "path" =>,
        #   "remote" =>} — path is the absolute project path, remote the
        #   origin URL (nil allowed for an offline repository)
        # @param dry_run [Boolean]
        # @return [Hash] {path:, status:, message:} where status is
        #   created / exists / would_create / failed
        def register(root:, project:, dry_run: false)
          path = registry_path(root)
          document = begin
            load(root: root)
          rescue Ace::Lab::InvalidConfigurationError, StandardError
            return failure(path, "#{path} could not be read as the lab registry; refusing to overwrite")
          end

          if document.nil?
            document = {"schema_version" => SCHEMA_VERSION,
              "topology" => {"projects" => [], "agents" => [], "services" => []}}
            return write(root, path, document, project, dry_run)
          end

          version = document["schema_version"]
          unless version == SCHEMA_VERSION
            return failure(path, "#{path} has schema_version #{version.inspect}; " \
              "it is not this lab's registry — refusing to overwrite")
          end

          conflict = conflicting_registration(document, project)
          return failure(path, conflict) if conflict

          existing = projects_in(document).find { |entry| entry["id"] == project["id"] }
          return {"path" => path, "status" => "exists", "message" => nil} if existing

          write(root, path, document, project, dry_run)
        end

        private

        def write(root, path, document, project, dry_run)
          return {"path" => path, "status" => "would_create", "message" => nil} if dry_run

          updated = deep_copy(document)
          updated["topology"] ||= {}
          updated["topology"]["projects"] ||= []
          entry = {"id" => project["id"]}
          entry["label"] = project["label"] if project["label"]
          entry["path"] = project["path"]
          entry["remote"] = project["remote"] if project["remote"]
          updated["topology"]["projects"] << entry

          begin
            Atoms::TopologySchema.normalize!(updated)
          rescue Ace::Lab::InvalidConfigurationError => e
            return failure(path,
              "registering project '#{project['id']}' would produce an invalid lab configuration: #{e.message}")
          end

          begin
            require "fileutils"
            FileUtils.mkdir_p(File.join(root, ".ace", "lab"))
            File.write(path, YAML.dump(updated))
          rescue SystemCallError => e
            return failure(path, "writing #{path} failed: #{e.message}")
          end

          {"path" => path, "status" => "created", "message" => nil}
        end

        # Contradiction and location-conflict detection, checked before
        # any write: same id with a different path or remote, or the same
        # absolute path registered under a different id.
        def conflicting_registration(document, project)
          projects_in(document).each do |entry|
            next unless entry.is_a?(Hash)

            if entry["id"] == project["id"]
              if entry["path"] && entry["path"] != project["path"]
                return "project '#{project['id']}' is registered at '#{entry['path']}' " \
                  "but the request declares '#{project['path']}'"
              end
              if entry["remote"] && project["remote"] && entry["remote"] != project["remote"]
                return "project '#{project['id']}' is registered with remote '#{entry['remote']}' " \
                  "but the request declares '#{project['remote']}'"
              end
            elsif entry["path"] && entry["path"] == project["path"]
              return "path '#{project['path']}' is already registered as project '#{entry['id']}'"
            end
          end
          nil
        end

        def projects_in(document)
          topology = document["topology"]
          return [] unless topology.is_a?(Hash) && topology["projects"].is_a?(Array)

          topology["projects"]
        end

        def deep_copy(document)
          require "yaml"
          YAML.safe_load(YAML.dump(document), permitted_classes: [Date], aliases: true)
        end

        def failure(path, message)
          {"path" => path, "status" => "failed", "message" => message}
        end
      end
    end
  end
end
