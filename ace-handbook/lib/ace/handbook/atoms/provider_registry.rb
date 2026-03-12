# frozen_string_literal: true

require "date"
require "yaml"

module Ace
  module Handbook
    module Atoms
      class ProviderRegistry
        LOCAL_MANIFEST_GLOB = File.join(
          "ace-handbook-integration-*",
          ".ace-defaults",
          "handbook",
          "providers",
          "*.yml"
        ).freeze

        attr_reader :project_root

        def initialize(project_root: Ace::Handbook.project_root)
          @project_root = project_root
        end

        def providers
          manifests.keys.sort
        end

        def known?(provider)
          manifests.key?(provider.to_s)
        end

        def manifest(provider)
          manifests.fetch(provider.to_s)
        end

        def output_dir(provider)
          manifest(provider).fetch("output_dir")
        end

        def manifests
          @manifests ||= begin
            all_paths = local_manifest_paths + installed_manifest_paths

            all_paths.each_with_object({}) do |path, manifests|
              data = YAML.safe_load_file(path, permitted_classes: [Date, Time], aliases: true) || {}
              provider = (data["provider"] || File.basename(path, ".yml")).to_s
              next if provider.empty?

              manifests[provider] ||= data.merge("_manifest_path" => path)
            end
          end
        end

        private

        def local_manifest_paths
          Dir.glob(File.join(project_root, LOCAL_MANIFEST_GLOB)).sort
        end

        def installed_manifest_paths
          Gem::Specification.find_all.filter_map do |spec|
            next unless spec.name.start_with?("ace-handbook-integration-")

            Dir.glob(File.join(spec.full_gem_path, ".ace-defaults", "handbook", "providers", "*.yml"))
          end.flatten.sort
        end
      end
    end
  end
end
