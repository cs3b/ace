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
          rescue StandardError
            return failure(path, "#{path} could not be read as the lab registry; refusing to overwrite")
          end

          if document.nil?
            document = {"schema_version" => SCHEMA_VERSION,
              "topology" => {"projects" => [], "agents" => [], "services" => []}}
            return write(path, document, project, dry_run)
          end

          if document.empty?
            return failure(path, "#{path} exists but is empty; " \
              "it is not this lab's registry — refusing to overwrite")
          end

          version = document["schema_version"]
          unless version == SCHEMA_VERSION
            return failure(path, "#{path} has schema_version #{version.inspect}; " \
              "it is not this lab's registry — refusing to overwrite")
          end

          # Pre-validate the loaded document (review 8xikzhvi): a
          # malformed entry (e.g. a non-mapping topology.projects item)
          # is a foreign document and must fail classification here,
          # never crash with a TypeError mid-iteration.
          begin
            Atoms::TopologySchema.normalize!(deep_copy(document))
          rescue Ace::Lab::InvalidConfigurationError
            return failure(path, "#{path} is not this lab's registry " \
              "(invalid lab configuration); refusing to overwrite")
          end

          conflict = conflicting_registration(document, project)
          return failure(path, conflict) if conflict

          existing = projects_in(document).find { |entry| entry["id"] == project["id"] }
          if existing
            # `label` is display data, not identity: a changed label on
            # re-add updates it in place (review 8xikzhvl). An absent
            # label leaves the recorded one untouched.
            return {"path" => path, "status" => "exists", "message" => nil} if !project["label"] || project["label"] == existing["label"]

            return relabel(path, document, project, dry_run)
          end

          write(path, document, project, dry_run)
        end

        private

        def write(path, document, project, dry_run)
          updated = deep_copy(document)
          updated["topology"] ||= {}
          updated["topology"]["projects"] ||= []
          entry = {"id" => project["id"]}
          entry["label"] = project["label"] if project["label"]
          entry["path"] = project["path"]
          entry["remote"] = project["remote"] if project["remote"]
          updated["topology"]["projects"] << entry
          persist(path, updated, project, dry_run, "would_create", "created")
        end

        def relabel(path, document, project, dry_run)
          updated = deep_copy(document)
          entry = projects_in(updated).find { |candidate| candidate["id"] == project["id"] }
          entry["label"] = project["label"]
          persist(path, updated, project, dry_run, "would_update", "updated")
        end

        # Validate the updated document BEFORE the dry-run branch
        # (review 8xikzhvj): a dry run predicts the wet run's
        # validation failures instead of a success the wet run cannot
        # deliver.
        def persist(path, updated, project, dry_run, dry_status, wet_status)
          begin
            Atoms::TopologySchema.normalize!(updated)
          rescue Ace::Lab::InvalidConfigurationError => e
            return failure(path,
              "registering project '#{project['id']}' would produce an invalid lab configuration: #{e.message}")
          end
          return {"path" => path, "status" => dry_status, "message" => nil} if dry_run

          begin
            require "fileutils"
            dir = File.dirname(path)
            unsafe = unsafe_symlink_reason(path)
            return failure(path, unsafe) if unsafe

            FileUtils.mkdir_p(dir)
            # Atomic write (review 8xikzhvk): a crash mid-write must
            # never leave a truncated cascade document behind. The
            # temporary file is created EXCLUSIVELY (O_CREAT|O_EXCL)
            # under an unguessable name: a pre-planted symlink at a
            # predictable `.tmp.<PID>` path must never redirect the
            # privileged write outside the project (LAB-1/F3) —
            # O_EXCL refuses to follow an existing symlink, and a
            # unique random name leaves nothing predictable to plant.
            tmp = write_exclusive(dir, YAML.dump(updated))
            File.rename(tmp, path)
          rescue SystemCallError, IOError => e
            File.delete(tmp) if defined?(tmp) && tmp && File.exist?(tmp)
            return failure(path, "writing #{path} failed: #{e.message}")
          end

          {"path" => path, "status" => wet_status, "message" => nil}
        end

        # A repository-controlled symlink among the registry's ancestor
        # directories (`.ace`, `.ace/lab`) must never be followed by a
        # privileged mkdir/write: refuse before any mutation.
        def unsafe_symlink_reason(registry_path)
          [File.dirname(registry_path), File.dirname(File.dirname(registry_path))].each do |ancestor|
            stat = File.lstat(ancestor)
            if stat.symlink?
              return "'#{ancestor}' is a symbolic link; refusing to follow it with installer " \
                "privileges (remove the link and rerun)"
            end
          rescue Errno::ENOENT, Errno::ENOTDIR
            nil
          end
          nil
        end

        # Create the temp file exclusively (never following a symlink),
        # write the payload, close, and return the path. Raises
        # SystemCallError/IOError on failure so the caller classifies.
        def write_exclusive(dir, payload)
          require "securerandom"
          100.times do
            candidate = File.join(dir, ".config.yml.tmp.#{Process.pid}.#{SecureRandom.hex(8)}")
            next if File.exist?(candidate) # includes symlinks (lstat)

            begin
              file = File.open(candidate, File::RDWR | File::CREAT | File::EXCL, 0o600)
            rescue Errno::EEXIST
              next
            end
            begin
              file.write(payload)
            ensure
              file.close
            end
            return candidate
          end
          raise SystemCallError.new("could not create an exclusive temporary file in '#{dir}'", 0)
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
