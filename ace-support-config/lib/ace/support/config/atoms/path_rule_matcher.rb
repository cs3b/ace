# frozen_string_literal: true

module Ace
  module Support
    module Config
      module Atoms
        # Match file paths against path-based config rules
        class PathRuleMatcher
          MatchResult = Struct.new(:name, :config, keyword_init: true)

          # @param path_rules [Hash] Path rules with optional _config_root metadata
          # @param project_root [String, nil] Project root for relative path calculation
          def initialize(path_rules, project_root: nil)
            @path_rules = path_rules || {}
            @project_root = project_root
          end

          # Match file path against configured rules
          # @param file_path [String] File path relative to project root
          # @return [MatchResult, nil] Match result or nil
          def match(file_path)
            return nil if @path_rules.nil? || @path_rules.empty?
            return nil if file_path.nil? || file_path.to_s.empty?

            normalized = normalize_path(file_path)

            @path_rules.each do |name, rule|
              next unless rule.is_a?(Hash)

              glob = rule["glob"] || rule[:glob]
              globs = Array(glob).compact.map(&:to_s).reject(&:empty?)
              next if globs.empty?

              # Calculate path relative to rule's config root
              # Returns nil if file is outside config root's scope
              path_to_match = path_relative_to_config(normalized, rule)
              next if path_to_match.nil?

              globs.each do |glob_pattern|
                next unless File.fnmatch?(glob_pattern, path_to_match, match_flags(glob_pattern))

                return MatchResult.new(
                  name: name.to_s,
                  config: extract_config(rule)
                )
              end
            end

            nil
          end

          private

          def normalize_path(path)
            path.to_s.sub(%r{\A\./}, "")
          end

          # Convert file path to be relative to the rule's config root
          # @param file_path [String] Path relative to project root
          # @param rule [Hash] Rule with optional _config_root
          # @return [String, nil] Path relative to config root, or nil if file is outside scope
          def path_relative_to_config(file_path, rule)
            config_root = rule["_config_root"]
            return file_path unless config_root && @project_root

            # Config root is absolute, project root is absolute
            # File path is relative to project root
            # We need to make file path relative to config root
            project_root_normalized = normalize_directory(@project_root)
            config_root_normalized = normalize_directory(config_root)

            # If config root equals project root, no adjustment needed
            return file_path if config_root_normalized == project_root_normalized

            # Get config root as relative path from project root
            config_relative = relative_path(config_root_normalized, project_root_normalized)
            return file_path if config_relative.nil? || config_relative.empty?

            # If file path starts with config relative, strip it
            # Otherwise, file is outside this config's scope - return nil to skip this rule
            prefix = config_relative + "/"
            if file_path.start_with?(prefix)
              file_path.sub(prefix, "")
            end
          end

          # Get relative path from base to target
          def relative_path(target, base)
            return nil if target == base
            return nil unless target.start_with?(base + "/")

            target.sub("#{base}/", "")
          end

          def normalize_directory(path)
            File.expand_path(path.to_s)
          end

          def extract_config(rule)
            rule.each_with_object({}) do |(key, value), acc|
              # Skip internal metadata and glob
              next if key.to_s == "glob"
              next if key.to_s.start_with?("_")

              acc[key.to_s] = value
            end
          end

          def match_flags(glob)
            flags = File::FNM_DOTMATCH | File::FNM_EXTGLOB
            flags |= File::FNM_PATHNAME unless glob.to_s.include?("**")
            flags
          end
        end
      end
    end
  end
end
