# frozen_string_literal: true

require "date"
require "yaml"
require "ace/support/nav"

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
          scanner.find_resources("skill").filter_map do |resource|
            parse_skill(resource.fetch(:path))
          end
        end

        private

        def scanner
          source_registry = Ace::Support::Nav::Molecules::SourceRegistry.new(start_path: project_root)
          config_loader = Ace::Support::Nav::Molecules::ConfigLoader.new(
            File.join(project_root, ".ace", "nav"),
            source_registry: source_registry
          )

          Ace::Support::Nav::Molecules::ProtocolScanner.new(config_loader: config_loader)
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
