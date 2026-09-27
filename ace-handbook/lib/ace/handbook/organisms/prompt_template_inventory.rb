# frozen_string_literal: true

require "yaml"

module Ace
  module Handbook
    module Organisms
      # Discovers canonical provider prompt templates shipped by integration packages.
      #
      # Each integration package owns its provider's prompt templates in
      # handbook/prompts/*.md; they project into the provider manifest's prompts_dir.
      class PromptTemplateInventory
        FRONTMATTER_PATTERN = /\A---\s*\n(.*?)\n---\s*\n?(.*)\z/m
        PACKAGE_GLOB = "ace-handbook-integration-*"
        GEM_NAME_PREFIX = "ace-handbook-integration-"

        attr_reader :project_root

        def initialize(project_root: Ace::Handbook.project_root, gem_roots: nil)
          @project_root = project_root
          @gem_roots = gem_roots
        end

        def all
          package_roots.filter_map { |root, provider| parse_templates(root, provider) }
                       .each_with_object({}) do |(provider, templates), index|
            index[provider] = (index[provider] || []).concat(templates)
          end
        end

        def for_provider(provider)
          all.fetch(provider.to_s, [])
        end

        private

        def package_roots
          (local_package_roots + installed_package_roots).sort.uniq.filter_map do |root|
            provider = package_provider(root)
            next if provider.nil? || provider.empty?

            [root, provider]
          end
        end

        def local_package_roots
          Dir.glob(File.join(project_root, PACKAGE_GLOB)).select { |path| File.directory?(path) }
        end

        def installed_package_roots
          return @gem_roots unless @gem_roots.nil?

          Gem::Specification.find_all
                            .select { |spec| spec.name.start_with?(GEM_NAME_PREFIX) }
                            .map(&:full_gem_path)
        end

        def package_provider(root)
          manifests = Dir.glob(File.join(root, ".ace-defaults", "handbook", "providers", "*.yml")).sort
          return nil if manifests.empty?

          data = YAML.safe_load_file(manifests.first, permitted_classes: [Date, Time], aliases: true) || {}
          data["provider"].to_s
        rescue StandardError
          nil
        end

        def parse_templates(root, provider)
          templates = Dir.glob(File.join(root, "handbook", "prompts", "*.md")).sort.filter_map do |path|
            match = File.read(path).match(FRONTMATTER_PATTERN)
            frontmatter = match ? parse_frontmatter(match[1]) : {}
            Models::PromptTemplate.new(provider: provider, source_path: path, frontmatter: frontmatter, content: File.read(path))
          end
          [provider, templates]
        end

        def parse_frontmatter(raw)
          YAML.safe_load(raw, permitted_classes: [Date, Time], aliases: true) || {}
        rescue StandardError
          {}
        end
      end
    end
  end
end
