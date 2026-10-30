# frozen_string_literal: true

require "yaml"

module Ace
  module Lab
    module Molecules
      # INTERNAL project-location read for the lab-level overseer start
      # (task 8xs.t.pu0.a): the project list and their CANONICAL
      # locations come from the raw topology configuration
      # (`topology.projects`: id/path) read at the lab root — the schema
      # normalization and the public projection deliberately strip paths,
      # so this reader goes to the raw cascade document and takes only
      # what the start needs. Locations are never derived from a public
      # id/label or a repo name. The public CLI keeps its allowlisted
      # projection; only the start operation consumes locations,
      # in-process.
      class ProjectLocations
        # @param lab_root [String] lab coordination directory whose
        #   cascade lists the configured projects
        # @return [Array<Hash>] {"id" =>, "path" =>} sorted by id; a
        #   project entry without a usable path is returned with a nil
        #   path so its OWN start reports the concrete error
        # @raise [Ace::Lab::InvalidConfigurationError] the topology
        #   configuration could not be read or has no project list
        def self.read(lab_root)
          config_path = File.join(lab_root, ".ace/lab/config.yml")
          document = YAML.safe_load_file(config_path,
            permitted_classes: [Date], aliases: true)
          unless document.is_a?(Hash)
            raise Ace::Lab::InvalidConfigurationError, ".ace/lab/config.yml must be a mapping"
          end

          raw = document.dig("topology", "projects")
          unless raw.is_a?(Array)
            raise Ace::Lab::InvalidConfigurationError,
              "topology.projects must be a list in .ace/lab/config.yml"
          end

          raw.map do |entry|
            next {"id" => nil, "path" => nil} unless entry.is_a?(Hash)

            # A nil/blank path encoding is returned as a nil path (the
            # project's OWN start reports the concrete error) — never a
            # bogus empty-string path, never an exception. The config is
            # read by explicit path: no global cwd mutation.
            path = entry["path"]
            path = nil unless path.is_a?(String) && !path.strip.empty?
            {"id" => entry["id"].to_s, "path" => path}
          end.sort_by { |project| project["id"].to_s }
        rescue Errno::ENOENT
          raise Ace::Lab::InvalidConfigurationError,
            "no lab configuration at #{lab_root}/.ace/lab/config.yml; run " \
              "ace-lab project add or fix the lab root"
        rescue Psych::SyntaxError => e
          raise Ace::Lab::InvalidConfigurationError,
            "lab configuration could not be parsed: #{e.message}"
        end
      end
    end
  end
end
