# frozen_string_literal: true

require "yaml"

module Ace
  module Assign
    module Atoms
      # Pure functions for loading and querying the phase catalog.
      #
      # The phase catalog is a directory of YAML files describing available
      # phase types, their prerequisites, artifacts, and metadata.
      #
      # @example Loading the catalog
      #   phases = CatalogLoader.load_all("/path/to/catalog/phases")
      #   # => [{ "name" => "onboard", "skill" => "onboard", ... }, ...]
      #
      # @example Finding a phase
      #   phase = CatalogLoader.find_by_name(phases, "work-on-task")
      #   # => { "name" => "work-on-task", "skill" => "ace:work-on-task", ... }
      module CatalogLoader
        # Load all phase definitions from a catalog directory.
        #
        # @param phases_dir [String] Path to catalog/phases/ directory
        # @return [Array<Hash>] Array of phase definition hashes
        def self.load_all(phases_dir)
          return [] unless File.directory?(phases_dir)

          Dir.glob(File.join(phases_dir, "*.phase.yml")).sort.filter_map do |path|
            parse_phase_file(path)
          end
        end

        # Find a phase definition by name.
        #
        # @param phases [Array<Hash>] Loaded phase definitions
        # @param name [String] Phase name to find
        # @return [Hash, nil] Phase definition or nil if not found
        def self.find_by_name(phases, name)
          phases.find { |p| p["name"] == name }
        end

        # Filter phases by tag.
        #
        # @param phases [Array<Hash>] Loaded phase definitions
        # @param tag [String] Tag to filter by
        # @return [Array<Hash>] Phases matching the tag
        def self.filter_by_tag(phases, tag)
          phases.select { |p| (p["tags"] || []).include?(tag) }
        end

        # Find phases that produce a given artifact.
        #
        # @param phases [Array<Hash>] Loaded phase definitions
        # @param artifact [String] Artifact name (e.g., "code-changes")
        # @return [Array<Hash>] Phases that produce the artifact
        def self.producers_of(phases, artifact)
          phases.select { |p| (p["produces"] || []).include?(artifact) }
        end

        # Validate that prerequisites are satisfied for a selection of phases.
        #
        # @param selected [Array<String>] Names of selected phases
        # @param catalog [Array<Hash>] Full phase catalog
        # @return [Array<Hash>] Validation issues, each with :phase, :prerequisite, :strength, :reason
        def self.validate_prerequisites(selected, catalog)
          issues = []

          selected.each do |phase_name|
            phase_def = find_by_name(catalog, phase_name)
            next unless phase_def

            (phase_def["prerequisites"] || []).each do |prereq|
              next if selected.include?(prereq["name"])

              issues << {
                phase: phase_name,
                prerequisite: prereq["name"],
                strength: prereq["strength"] || "recommended",
                reason: prereq["reason"]
              }
            end
          end

          issues
        end

        # Parse a single phase YAML file.
        #
        # @param path [String] File path
        # @return [Hash, nil] Parsed phase definition or nil on error
        def self.parse_phase_file(path)
          YAML.safe_load_file(path, permitted_classes: [Date])
        rescue StandardError => e
          $stderr.puts "Warning: Failed to parse phase file #{path}: #{e.message}"
          nil
        end
        private_class_method :parse_phase_file
      end
    end
  end
end
