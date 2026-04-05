# frozen_string_literal: true

require "date"
require "yaml"
require "ace/support/nav"
require "pathname"

module Ace
  module Handbook
    module Organisms
      class SkillInventory
        FRONTMATTER_PATTERN = /\A---\s*\n(.*?)\n---\s*\n?(.*)\z/m

        attr_reader :project_root

        def initialize(project_root: Ace::Handbook.project_root)
          @project_root = project_root
        end

        def all
          skill_paths.filter_map { |path| parse_skill(path) }
        end

        private

        def skill_paths
          index = {}

          source_directories.each do |directory|
            Dir.glob(File.join(directory, "**", "SKILL.md")).sort.each do |path|
              frontmatter = parse_frontmatter(File.read(path))
              name = frontmatter["name"]&.to_s
              next if name.nil? || name.empty? || index.key?(name)

              index[name] = path
            rescue
              next
            end
          end

          index.values
        end

        def source_directories
          registry = Ace::Support::Nav::Molecules::SourceRegistry.new(start_path: project_root)
          registry.sources_for_protocol("skill").filter_map do |source|
            next if source.config.is_a?(Hash) && source.config["enabled"] == false

            directory = resolve_source_directory(source)
            next unless File.directory?(directory)
            next if external_implicit_source?(source, directory)

            directory
          rescue
            nil
          end.uniq
        end

        def resolve_source_directory(source)
          candidate = source.full_path
          return candidate if File.directory?(candidate)

          relative_path = source.config&.dig("relative_path")&.to_s&.strip
          return nil if relative_path.nil? || relative_path.empty?

          return nil unless source.config_file&.include?("/.ace-defaults/")

          package_root = source.config_file.split("/.ace-defaults/").first
          fallback = File.expand_path(relative_path, package_root)
          File.directory?(fallback) ? fallback : nil
        end

        def external_implicit_source?(source, directory)
          return false if path_within_project?(directory)
          return false if explicit_registration?(source)

          true
        end

        def explicit_registration?(source)
          %w[project user].include?(source.origin.to_s)
        end

        def path_within_project?(path)
          candidate = Pathname.new(File.expand_path(path))
          root = Pathname.new(File.expand_path(project_root))
          candidate == root || candidate.to_s.start_with?("#{root}/")
        end

        def parse_frontmatter(content)
          match = content.match(FRONTMATTER_PATTERN)
          return {} unless match

          YAML.safe_load(match[1], permitted_classes: [Date, Time], aliases: true) || {}
        end

        def parse_skill(path)
          content = File.read(path)
          match = content.match(FRONTMATTER_PATTERN)
          return nil unless match

          frontmatter = YAML.safe_load(match[1], permitted_classes: [Date, Time], aliases: true) || {}
          return nil unless frontmatter.is_a?(Hash) && frontmatter["name"]

          Models::SkillDocument.new(
            source_path: path,
            frontmatter: frontmatter,
            body: match[2]
          )
        end
      end
    end
  end
end
