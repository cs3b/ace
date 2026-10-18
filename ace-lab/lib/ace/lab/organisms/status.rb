# frozen_string_literal: true

module Ace
  module Lab
    module Organisms
      # Read-only lab status snapshot: configuration tri-state (configured /
      # not_configured / error), file-based lab state locations, and the
      # worktree pointer. Writes nothing, starts nothing, guesses nothing.
      class Status
        STATE_PATHS = [
          [".ace-tasks", nil],
          [File.join(".ace-tasks", "_overseer"), "private overseer list not prepared"],
          [File.join(".ace-local", "assign"), nil],
          [File.join(".ace-local", "coworker"), "coworker start/status is planned (L3)"],
          [File.join(".ace-local", "hitl"), nil],
          [".ace-wt", nil]
        ].freeze

        def initialize(project_dir: nil, documents: nil, config: nil)
          @project_dir = project_dir || Dir.pwd
          @documents = documents
          @config = config
        end

        # @return [Hash] snapshot with configuration, state_files, worktree_view
        def snapshot
          {
            "configuration" => configuration_section,
            "state_files" => state_files_section,
            "worktree_view" => "ace-git-worktree list"
          }
        end

        private

        def configuration_section
          explicit = explicit_documents
          return not_configured if explicit.empty?

          begin
            merged = @config || Ace::Lab.config
            normalized = Atoms::TopologySchema.normalize!(merged)
          rescue InvalidConfigurationError => e
            return {"state" => "error", "sources" => explicit, "error" => e.message, "topology" => nil}
          end

          topology = normalized["topology"] || {}
          {
            "state" => "configured",
            "sources" => explicit,
            "error" => nil,
            "topology" => {
              "projects" => topology["projects"].to_a.size,
              "agents" => topology["agents"].to_a.size,
              "services" => topology["services"].to_a.size
            }
          }
        rescue InvalidConfigurationError => e
          # explicit_documents itself failed (e.g. malformed YAML document)
          {"state" => "error", "sources" => [], "error" => e.message, "topology" => nil}
        end

        def not_configured
          {"state" => "not_configured", "sources" => [], "error" => nil, "topology" => nil}
        end

        def explicit_documents
          docs = @documents || Ace::Lab.cascade_documents
          docs.reject { |doc| doc[:defaults] }.map { |doc| doc[:path] }
        end

        def state_files_section
          STATE_PATHS.map do |relative, absence_note|
            path = File.join(@project_dir, relative)
            present = File.directory?(path)
            entry = {"path" => relative, "present" => present, "entries" => nil, "note" => nil}
            if present
              entry["entries"] = Dir.children(path).size
            elsif absence_note
              entry["note"] = absence_note
            end
            entry
          end
        end
      end
    end
  end
end
