# frozen_string_literal: true

module Ace
  module GitCommit
    module Molecules
      # CommitGrouper groups files by effective configuration
      class CommitGrouper
        # Reference the default scope name constant
        DEFAULT_SCOPE_NAME = Ace::Support::Config::Models::ConfigGroup::DEFAULT_SCOPE_NAME
        def initialize(file_config_resolver: nil)
          @file_config_resolver = file_config_resolver || default_config_resolver
        end

        # Group files by scope name and config signature
        # Files with the same scope name but different configs are kept separate
        # @param files [Array<String>] File paths (relative)
        # @param project_root [String, nil] Project root path for scope name derivation
        # @return [Array<Models::CommitGroup>] Grouped commits
        def group(files, project_root: nil)
          groups = {}

          Array(files).each do |file|
            resolved = @file_config_resolver.resolve(file, namespace: "git", filename: "commit", project_root: project_root)
            # .ace/ config files always group into "ace-config" scope
            scope_name = if ace_config_file?(file)
              "ace-config"
            else
              # Derive scope name: use path-based derivation for distributed configs,
              # otherwise keep the resolved name (path rule name or DEFAULT_SCOPE_NAME)
              derive_scope_name(resolved.source, resolved.name, project_root)
            end
            # Group by scope_name AND config signature to prevent merging scopes with different configs
            # Exception: DEFAULT_SCOPE_NAME always groups together regardless of config (to avoid duplicates)
            # For path rules: use rule_config for grouping (ignores cascade differences like per-package model)
            # For distributed configs: use full config (package-specific configs matter)
            grouping_config = resolved.rule_config || resolved.config
            config_sig = Models::CommitGroup.signature_for(grouping_config)
            key = (scope_name == DEFAULT_SCOPE_NAME) ? scope_name : "#{scope_name}::#{config_sig}"

            group = groups[key] ||= Models::CommitGroup.new(
              scope_name: scope_name,
              source: resolved.source,
              config: resolved.config,
              files: []
            )

            group.add_file(file)
          end

          groups.values.each { |group| group.files.sort! }
          groups.values.sort_by { |group| sort_key(group) }
        end

        # Derive scope name from config source path
        # For distributed configs (package/.ace/), derive from path
        # For path rules or root config, keep the resolved name
        # @param source_path [String, nil] Full path to config file (may be compound "path1 -> path2")
        # @param resolved_name [String] Name from FileConfigResolver (path rule name or DEFAULT_SCOPE_NAME)
        # @param project_root [String, nil] Project root path
        # @return [String] Scope name
        def derive_scope_name(source_path, resolved_name, project_root)
          # Path rule names take precedence over distributed config derivation
          # This ensures inherited rules like "ace-config" are preserved
          return resolved_name if resolved_name && resolved_name != DEFAULT_SCOPE_NAME

          return resolved_name unless source_path && project_root

          # Filter to only .ace/ paths (ignore .ace-defaults completely for scope derivation)
          # .ace-defaults provides default VALUES only, not SCOPE
          ace_sources = source_path.split(" -> ").reject { |p| p.include?(".ace-defaults") }
          return resolved_name if ace_sources.empty?

          primary_source = ace_sources.first

          # Remove project root prefix to get relative path
          relative = primary_source.sub("#{project_root}/", "")

          # If still absolute or unchanged, keep resolved name
          return resolved_name if relative == primary_source || relative.start_with?("/")

          # Check if this is a distributed config (package/.ace/)
          # "ace-bundle/.ace/git/commit.yml" → ["ace-bundle", "git/commit.yml"]
          # ".ace/git/commit.yml" → ["", "git/commit.yml"] (root config)
          parts = relative.split("/.ace/")
          package_name = parts.first

          # If empty or starts with .ace, it's root config - keep resolved name (path rule or default)
          return resolved_name if package_name.nil? || package_name.empty? || package_name.start_with?(".ace")

          # This is a distributed config - derive scope from package path
          package_name
        end

        # Check if a file path is inside a .ace/ directory
        def ace_config_file?(file)
          file.include?("/.ace/") || file.start_with?(".ace/")
        end

        private

        def default_config_resolver
          gem_root = Gem.loaded_specs["ace-git-commit"]&.gem_dir ||
            File.expand_path("../../../..", __dir__)

          Ace::Support::Config::Molecules::FileConfigResolver.new(
            config_dir: ".ace",
            defaults_dir: ".ace-defaults",
            gem_path: gem_root
          )
        end

        def sort_key(group)
          name = group.scope_name.to_s
          if name.empty? || name == DEFAULT_SCOPE_NAME || name == "no package"
            [1, name]
          else
            [0, name]
          end
        end
      end
    end
  end
end
