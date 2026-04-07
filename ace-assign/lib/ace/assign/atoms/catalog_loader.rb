# frozen_string_literal: true

require "yaml"

module Ace
  module Assign
    module Atoms
      # Pure functions for loading and querying the step catalog.
      #
      # The step catalog is a directory of YAML files describing available
      # step types, their prerequisites, artifacts, and metadata.
      #
      # @example Loading the catalog
      #   steps = CatalogLoader.load_all("/path/to/catalog/steps")
      #   # => [{ "name" => "onboard", "skill" => "onboard", ... }, ...]
      #
      # @example Finding a step
      #   step = CatalogLoader.find_by_name(steps, "work-on-task")
      #   # => { "name" => "work-on-task", "skill" => "ace:work-on-task", ... }
      module CatalogLoader
        # Load all step definitions from a catalog directory.
        #
        # @param steps_dir [String] Path to catalog/steps/ directory
        # @param canonical_steps [Array<Hash>, Symbol, Boolean, nil] Canonical
        #   step metadata to merge. `:auto` (default) loads from skill sources.
        #   `false` disables canonical merge and returns raw YAML definitions.
        # @return [Array<Hash>] Array of step definition hashes
        def self.load_all(steps_dir, canonical_steps: :auto)
          return [] unless File.directory?(steps_dir)

          yaml_steps = Dir.glob(File.join(steps_dir, "*.step.yml")).sort.filter_map do |path|
            parse_step_file(path)
          end
          return [] if yaml_steps.empty?

          merge_step_catalog(yaml_steps, resolve_canonical_steps(canonical_steps))
        end

        # Find a step definition by name.
        #
        # @param steps [Array<Hash>] Loaded step definitions
        # @param name [String] Step name to find
        # @return [Hash, nil] Step definition or nil if not found
        def self.find_by_name(steps, name)
          steps.find { |p| p["name"] == name }
        end

        # Filter steps by tag.
        #
        # @param steps [Array<Hash>] Loaded step definitions
        # @param tag [String] Tag to filter by
        # @return [Array<Hash>] Steps matching the tag
        def self.filter_by_tag(steps, tag)
          steps.select { |p| (p["tags"] || []).include?(tag) }
        end

        # Find steps that produce a given artifact.
        #
        # @param steps [Array<Hash>] Loaded step definitions
        # @param artifact [String] Artifact name (e.g., "code-changes")
        # @return [Array<Hash>] Steps that produce the artifact
        def self.producers_of(steps, artifact)
          steps.select { |p| (p["produces"] || []).include?(artifact) }
        end

        # Validate that prerequisites are satisfied for a selection of steps.
        #
        # @param selected [Array<String>] Names of selected steps
        # @param catalog [Array<Hash>] Full step catalog
        # @return [Array<Hash>] Validation issues, each with :step, :prerequisite, :strength, :reason
        def self.validate_prerequisites(selected, catalog)
          issues = []

          selected.each do |step_name|
            step_def = find_by_name(catalog, step_name)
            next unless step_def

            (step_def["prerequisites"] || []).each do |prereq|
              next if selected.include?(prereq["name"])

              issues << {
                step: step_name,
                prerequisite: prereq["name"],
                strength: prereq["strength"] || "recommended",
                reason: prereq["reason"]
              }
            end
          end

          issues
        end

        # Parse a single step YAML file.
        #
        # @param path [String] File path
        # @return [Hash, nil] Parsed step definition or nil on error
        def self.parse_step_file(path)
          YAML.safe_load_file(path, permitted_classes: [Date])
        rescue => e
          warn "Warning: Failed to parse step file #{path}: #{e.message}"
          nil
        end

        def self.resolve_canonical_steps(canonical_steps)
          case canonical_steps
          when false
            []
          when :auto, nil
            begin
              require_relative "../molecules/skill_assign_source_resolver"
              Molecules::SkillAssignSourceResolver.new.assign_step_catalog
            rescue LoadError, StandardError
              []
            end
          when Array
            canonical_steps
          else
            []
          end
        end
        private_class_method :resolve_canonical_steps

        def self.merge_step_catalog(base_steps, override_steps)
          index = {}
          order = []

          Array(base_steps).each do |step|
            name = step["name"]
            next if name.nil? || name.empty?

            index[name] = step
            order << name
          end

          Array(override_steps).each do |step|
            name = step["name"]
            next if name.nil? || name.empty?

            order << name unless index.key?(name)
            index[name] = deep_merge_step_definition(index[name], step)
          end

          order.map { |name| index[name] }.compact
        end
        private_class_method :merge_step_catalog

        def self.deep_merge_step_definition(base, override)
          return override unless base.is_a?(Hash)
          return base unless override.is_a?(Hash)

          merged = base.dup
          override.each do |key, value|
            merged[key] =
              if merged[key].is_a?(Hash) && value.is_a?(Hash)
                deep_merge_step_definition(merged[key], value)
              else
                value
              end
          end
          merged
        end
        private_class_method :deep_merge_step_definition

        private_class_method :parse_step_file
      end
    end
  end
end
