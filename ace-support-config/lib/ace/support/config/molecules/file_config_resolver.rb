# frozen_string_literal: true

require "pathname"

module Ace
  module Support
    module Config
      module Molecules
        # Resolve effective config for a given file path using distributed configs and path rules
        class FileConfigResolver
          attr_reader :config_dir, :defaults_dir, :gem_path, :merge_strategy

          def initialize(
            config_dir: ".ace",
            defaults_dir: ".ace-defaults",
            gem_path: nil,
            merge_strategy: :replace
          )
            @config_dir = config_dir
            @defaults_dir = defaults_dir
            @gem_path = gem_path
            @merge_strategy = merge_strategy
          end

          # Resolve config for a file
          # @param file_path [String] File path (relative or absolute)
          # @param namespace [String] Config namespace (default: "git")
          # @param filename [String] Config filename without extension (default: "commit")
          # @param project_root [String, nil] Explicit project root (overrides auto-detection)
          # @return [Models::ConfigGroup] Resolved config group for the file
          def resolve(file_path, namespace: "git", filename: "commit", project_root: nil)
            raise ArgumentError, "file_path cannot be nil or empty" if file_path.nil? || file_path.to_s.empty?

            start_path = resolve_start_path(file_path)
            project_root = normalize_path(project_root || detect_project_root(start_path) || start_path)
            relative_path = to_relative_path(file_path, project_root)

            distributed_config_path = find_distributed_config(start_path, project_root, namespace, filename)
            if distributed_config_path && project_root
              root_config_dir = File.join(project_root, config_dir.to_s)
              root_prefix = normalize_path(root_config_dir) + File::SEPARATOR
              if normalize_path(distributed_config_path).start_with?(root_prefix)
                distributed_config_path = nil
              end
            end
            config = load_cascade_config(start_path, project_root, namespace, filename)
            base_data = extract_config_data(config)

            # Check path rules FIRST (before distributed config scope)
            matched = match_path_rule(base_data, relative_path, project_root)
            if matched
              resolved = merge_rule_overrides(strip_paths_section(base_data), matched.config)
              return Models::ConfigGroup.new(
                name: matched.name,
                source: primary_source_path(config, namespace, filename, start_path, project_root),
                config: resolved,
                rule_config: matched.config, # Raw rule config for grouping (ignores cascade differences)
                files: [relative_path]
              )
            end

            # Fall back to distributed config scope if present
            if distributed_config_path
              resolved = strip_paths_section(base_data)
              scope_name = scope_name_from_config_path(distributed_config_path, project_root)
              return Models::ConfigGroup.new(
                name: scope_name,
                source: distributed_config_path,
                config: resolved,
                files: [relative_path]
              )
            end

            Models::ConfigGroup.new(
              name: Models::ConfigGroup::DEFAULT_SCOPE_NAME,
              source: primary_source_path(config, namespace, filename, start_path, project_root),
              config: strip_paths_section(base_data),
              files: [relative_path]
            )
          end

          private

          def resolve_start_path(file_path)
            path = file_path.to_s
            absolute = Pathname.new(path).absolute? ? path : File.expand_path(path, Dir.pwd)
            File.directory?(absolute) ? absolute : File.dirname(absolute)
          end

          def to_relative_path(file_path, project_root)
            path = file_path.to_s.sub(%r{\A\./}, "")
            return path unless project_root

            absolute = Pathname.new(path).absolute? ? path : File.expand_path(path, project_root)
            root = File.expand_path(project_root)
            if absolute.start_with?(root + File::SEPARATOR)
              absolute.sub("#{root}/", "")
            else
              path
            end
          end

          def find_distributed_config(start_path, project_root, namespace, filename)
            patterns = config_patterns(namespace, filename)
            root = project_root || start_path
            current = File.expand_path(start_path.to_s)
            root = File.expand_path(root.to_s)

            loop do
              config_path = File.join(current, config_dir)
              if project_root
                root_config = File.join(File.expand_path(project_root.to_s), config_dir.to_s)
                config_path = nil if File.expand_path(config_path) == File.expand_path(root_config)
              end

              if config_path && Dir.exist?(config_path)
                patterns.each do |pattern|
                  candidate = File.join(config_path, pattern)
                  return candidate if File.exist?(candidate)
                end
              end

              break if current == root

              parent = File.dirname(current)
              break if parent == current

              current = parent
            end

            nil
          end

          def config_patterns(namespace, filename)
            [
              File.join(namespace, "#{filename}.yml"),
              File.join(namespace, "#{filename}.yaml")
            ]
          end

          def load_cascade_config(start_path, project_root, namespace, filename)
            patterns = config_patterns(namespace, filename)
            cascade_paths = find_cascade_paths(start_path, project_root, patterns)
            if cascade_paths.empty?
              return Models::Config.new({}, source: "no_config_found", merge_strategy: merge_strategy)
            end

            configs = cascade_paths.map do |path|
              Molecules::YamlLoader.load_file(path)
            end

            # Merge configs in reverse order (root first, then nested)
            merged_data = configs.reverse.reduce({}) do |result, config|
              Atoms::DeepMerger.merge(
                result,
                config.data,
                array_strategy: merge_strategy
              )
            end

            # Collect paths with source tracking
            # Process in reverse (root first) so more specific configs override
            paths_with_sources = collect_paths_with_sources(cascade_paths.reverse, project_root)
            if paths_with_sources.any?
              # Replace merged scopes/paths with source-tracked paths
              merged_data = merged_data.dup
              merged_data.delete("scopes")
              merged_data.delete(:scopes)
              merged_data.delete("paths")
              merged_data.delete(:paths)
              merged_data.delete("path_rules")
              merged_data.delete(:path_rules)

              # Check if scopes/paths were in git section
              if merged_data["git"].is_a?(Hash)
                merged_data["git"] = merged_data["git"].dup
                merged_data["git"].delete("scopes")
                merged_data["git"].delete(:scopes)
                merged_data["git"].delete("paths")
                merged_data["git"].delete(:paths)
                merged_data["git"].delete("path_rules")
                merged_data["git"].delete(:path_rules)
              end

              merged_data["scopes"] = paths_with_sources
            end

            sources = cascade_paths.join(" -> ")
            Models::Config.new(
              merged_data,
              source: sources,
              merge_strategy: merge_strategy
            )
          end

          # Collect path rules from all configs, tracking source directory
          # @param cascade_paths [Array<String>] Config paths from root to nested
          # @param project_root [String, nil] Project root directory
          # @return [Hash] Path rules with _config_root metadata
          def collect_paths_with_sources(cascade_paths, project_root)
            all_paths = {}

            cascade_paths.each do |config_path|
              config = Molecules::YamlLoader.load_file(config_path)
              data = config.data || {}

              # Config root is the directory containing the .ace/ folder
              # e.g., /project/ace-bundle/.ace/git/commit.yml → /project/ace-bundle
              config_root = config_root_from_path(config_path)

              # Look for scopes/paths in both git section and root
              paths = data.dig("git", "scopes") || data.dig("git", :scopes) ||
                data.dig("git", "paths") || data.dig("git", :paths) ||
                data["scopes"] || data[:scopes] ||
                data["paths"] || data[:paths] ||
                data.dig("git", "path_rules") || data.dig("git", :path_rules) ||
                data["path_rules"] || data[:path_rules]

              next unless paths.is_a?(Hash)

              paths.each do |name, rule|
                next unless rule.is_a?(Hash)

                # Clone rule and add source tracking
                tracked_rule = rule.dup
                tracked_rule["_config_root"] = config_root
                all_paths[name.to_s] = tracked_rule
              end
            end

            # All inherited rules should be relative to closest (most nested) config
            # This ensures inherited path rules like ".ace/**" match from the nested config's location
            if cascade_paths.any? && all_paths.any?
              closest_root = config_root_from_path(cascade_paths.last)
              all_paths.each_value { |rule| rule["_config_root"] = closest_root }
            end

            all_paths
          end

          # Extract config root directory from config file path
          # @param config_path [String] Path to config file (e.g., /project/.ace/git/commit.yml)
          # @return [String] Directory containing .ace/ folder
          def config_root_from_path(config_path)
            # Split on .ace/ and take the first part
            parts = config_path.to_s.split("#{File::SEPARATOR}#{config_dir}#{File::SEPARATOR}")
            if parts.length >= 2
              normalize_path(parts.first)
            else
              # Fallback: go up from config file
              normalize_path(File.dirname(config_path, 3))
            end
          end

          def extract_config_data(config)
            data = config.data || {}
            git_data = data["git"] || data[:git]
            return data unless git_data.is_a?(Hash)

            root_overrides = data.reject { |key, _| key.to_s == "git" }
            Atoms::DeepMerger.merge(
              git_data,
              root_overrides,
              array_strategy: merge_strategy
            )
          end

          def match_path_rule(base_data, relative_path, project_root)
            rules = base_data["scopes"] || base_data[:scopes] ||
              base_data["paths"] || base_data[:paths] ||
              base_data["path_rules"] || base_data[:path_rules]
            matcher = Atoms::PathRuleMatcher.new(normalize_path_rules(rules), project_root: project_root)
            matcher.match(relative_path)
          end

          def merge_rule_overrides(base_data, overrides)
            Atoms::DeepMerger.merge(
              base_data,
              overrides || {},
              array_strategy: merge_strategy
            )
          end

          def strip_paths_section(base_data)
            return {} if base_data.nil?

            stripped = base_data.dup
            stripped.delete("scopes")
            stripped.delete(:scopes)
            stripped.delete("paths")
            stripped.delete(:paths)
            stripped.delete("path_rules")
            stripped.delete(:path_rules)
            stripped
          end

          def normalize_path_rules(rules)
            return {} if rules.nil?
            return rules if rules.is_a?(Hash)

            Array(rules).each_with_index.each_with_object({}) do |(rule, index), acc|
              next unless rule.is_a?(Hash)

              name = rule["name"] || rule[:name] || "rule-#{index + 1}"
              acc[name.to_s] = rule
            end
          end

          def scope_name_from_config_path(config_path, project_root)
            config_path_str = config_path.to_s
            scope_root = config_path_str.split("#{File::SEPARATOR}#{config_dir}#{File::SEPARATOR}").first
            scope_root = File.dirname(config_path_str) if scope_root.nil? || scope_root.empty?

            if project_root
              root = File.expand_path(project_root.to_s)
              scope = File.expand_path(scope_root.to_s)
              return Models::ConfigGroup::DEFAULT_SCOPE_NAME if scope == root
              return scope.sub("#{root}/", "") if scope.start_with?(root + File::SEPARATOR)

              root_real = normalize_path(project_root)
              scope_real = normalize_path(scope_root)
              return Models::ConfigGroup::DEFAULT_SCOPE_NAME if scope_real == root_real
              return scope_real.sub("#{root_real}/", "") if scope_real.start_with?(root_real + File::SEPARATOR)
            end

            scope_root
          end

          def find_cascade_paths(start_path, project_root, patterns)
            paths = []
            root = project_root || start_path
            current = File.expand_path(start_path.to_s)
            root = File.expand_path(root.to_s)

            loop do
              config_path = File.join(current, config_dir)
              if Dir.exist?(config_path)
                patterns.each do |pattern|
                  candidate = File.join(config_path, pattern)
                  paths << candidate if File.exist?(candidate)
                end
              end

              break if current == root

              parent = File.dirname(current)
              break if parent == current

              current = parent
            end

            home_config = File.expand_path("~/#{config_dir}")
            if Dir.exist?(home_config)
              patterns.each do |pattern|
                candidate = File.join(home_config, pattern)
                paths << candidate if File.exist?(candidate)
              end
            end

            if gem_path
              defaults_path = File.join(gem_path, defaults_dir)
              if Dir.exist?(defaults_path)
                patterns.each do |pattern|
                  candidate = File.join(defaults_path, pattern)
                  paths << candidate if File.exist?(candidate)
                end
              end
            end

            paths
          end

          def normalize_path(path)
            File.realpath(path)
          rescue Errno::ENOENT, Errno::EACCES
            File.expand_path(path.to_s)
          end

          def detect_project_root(start_path)
            markers = Ace::Support::Fs::Molecules::ProjectRootFinder::DEFAULT_MARKERS
            current = File.expand_path(start_path.to_s)
            fallback_root = nil

            # .git is definitive - keep searching for it even after finding weaker markers
            loop do
              return current if File.exist?(File.join(current, ".git"))

              # Remember first match of any marker as fallback
              if fallback_root.nil?
                markers.each do |marker|
                  next if marker == ".git"
                  if File.exist?(File.join(current, marker))
                    fallback_root = current
                    break
                  end
                end
              end

              parent = File.dirname(current)
              break if parent == current

              current = parent
            end

            fallback_root
          end

          def primary_source_path(config, namespace, filename, start_path, project_root)
            return config.source if config.source && config.source != "no_config_found"

            patterns = config_patterns(namespace, filename)
            found = find_cascade_paths(start_path, project_root, patterns).first
            found || "no_config_found"
          end
        end
      end
    end
  end
end
