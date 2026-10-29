# frozen_string_literal: true

require "date"
require "yaml"

module Ace
  module Handbook
    module Atoms
      class ProviderRegistry
        LOCAL_MANIFEST_GLOBS = [
          File.join("ace-handbook", ".ace-defaults", "handbook", "providers", "*.yml"),
          File.join("ace-handbook-integration-*", ".ace-defaults", "handbook", "providers", "*.yml")
        ].freeze

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

        def prompts_dir(provider)
          manifest(provider)["prompts_dir"]
        end

        def extensions_dir(provider)
          manifest(provider)["extensions_dir"]
        end

        # Source root for a provider's extension assets: the package the
        # manifest names through `extensions_package` (an asset package
        # such as ace-wake that is NOT an integration package), falling
        # back to the manifest's own package. The named package resolves
        # like every other package: the sibling package directory in the
        # local project first, the installed gem second — so a monorepo
        # checkout projects the working tree and an installed lab
        # projects the exact installed gem (task 8xs.t.pu0.0).
        def extensions_source_root(provider)
          package = manifest(provider)["extensions_package"]
          return package_root(provider) if package.nil? || package.to_s.strip.empty?

          resolve_named_package(package.to_s.strip) || package_root(provider)
        end

        def package_root(provider)
          manifest_dir = File.dirname(manifest(provider).fetch("_manifest_path"))
          File.expand_path("../../..", manifest_dir)
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

        # A package named through `extensions_package` resolves like the
        # registry's own packages: the sibling directory inside the local
        # project first (monorepo checkout), the installed gem second.
        # Only a package that actually carries handbook/extensions counts.
        def resolve_named_package(name)
          local = File.join(project_root, name)
          return local if File.directory?(File.join(local, "handbook", "extensions"))

          spec = Gem::Specification.find_by_name(name)
          return nil unless File.directory?(File.join(spec.full_gem_path, "handbook", "extensions"))

          spec.full_gem_path
        rescue Gem::LoadError, ArgumentError
          nil
        end

        def local_manifest_paths
          LOCAL_MANIFEST_GLOBS.flat_map do |glob|
            Dir.glob(File.join(project_root, glob))
          end.sort
        end

        def installed_manifest_paths
          Gem::Specification.find_all.filter_map do |spec|
            next unless spec.name == "ace-handbook" || spec.name.start_with?("ace-handbook-integration-")

            Dir.glob(File.join(spec.full_gem_path, ".ace-defaults", "handbook", "providers", "*.yml"))
          end.flatten.sort
        end
      end
    end
  end
end
