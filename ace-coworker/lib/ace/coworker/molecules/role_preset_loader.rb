# frozen_string_literal: true

require "yaml"

module Ace
  module Coworker
    module Molecules
      # Discovers role presets from the shipped gem defaults
      # (.ace-defaults/coworker/roles/*.yml) merged shallow-by-filename with
      # project overrides (.ace/coworker/roles/*.yml, project wins). Every
      # loaded preset is schema-validated; presets are convenience defaults,
      # never a role allowlist (ADR-034: the overseer decides roles).
      class RolePresetLoader
        GEM_ROLES_DIR = File.join(".ace-defaults", "coworker", "roles")
        PROJECT_ROLES_DIR = File.join(".ace", "coworker", "roles")

        # @param project_root [String] absolute project root
        # @param gem_roles_dir [String, nil] explicit gem roles dir (tests)
        def initialize(project_root:, gem_roles_dir: nil, schema: Atoms::RolePresetSchema)
          @project_root = project_root
          @gem_roles_dir = gem_roles_dir || File.join(gem_root, GEM_ROLES_DIR)
          @schema = schema
        end

        # @return [Array<Hash>] sorted presets, each with "name" and
        #   "source" ("gem"|"project") plus the normalized preset fields
        def list
          presets.values.sort_by { |preset| preset["name"] }
        end

        # @return [Hash] the preset for name (with "source")
        # @raise [Error] when the name is unknown
        def fetch(name)
          key = name.to_s.strip
          preset = presets[key]
          raise Error, "unknown role '#{key}' (available: #{presets.keys.sort.join(', ')})" if preset.nil?

          preset
        end

        private

        def presets
          @presets ||= begin
            merged = {}
            load_dir(@gem_roles_dir, "gem", merged)
            load_dir(project_roles_dir, "project", merged)
            merged
          end
        end

        def project_roles_dir
          File.join(@project_root, PROJECT_ROLES_DIR)
        end

        def load_dir(dir, source, merged)
          Dir.glob(File.join(dir, "*.yml")).sort.each do |path|
            preset = read_preset(path)
            preset["source"] = source
            merged[preset["name"]] = preset
          end
        end

        def read_preset(path)
          raw = YAML.safe_load_file(path, permitted_classes: [Date], aliases: true)
          errors = @schema.errors(raw)
          unless errors.empty?
            raise Error, "invalid role preset '#{relative(path)}': #{errors.join('; ')}"
          end

          @schema.normalize(raw)
        end

        def relative(path)
          path.start_with?(@project_root) ? path.delete_prefix("#{@project_root}/") : path
        end

        def gem_root
          ::Gem.loaded_specs["ace-coworker"]&.gem_dir || File.expand_path("../../../..", __dir__)
        end
      end
    end
  end
end
