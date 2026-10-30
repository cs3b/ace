# frozen_string_literal: true

require "date"
require "yaml"
require "ace/support/cli/toolchain"

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
        # such as ace-wake that is NOT an integration package). The named
        # package resolves like every other package: the sibling package
        # directory in the local project first, the installed gem second
        # — so a monorepo checkout projects the working tree and an
        # installed lab projects the exact installed gem (task
        # 8xs.t.pu0.0). In auto mode an unresolvable package raises; in
        # installed mode the manifest's own package root is the fallback
        # (the installed-mode rule).
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
        # registry's own packages: the sibling directory inside the
        # local project first (monorepo checkout), the installed gem
        # second. In installed mode (ACE_TOOLCHAIN=installed) the
        # checkout directory is project DATA, never the runtime source:
        # the package must come from an installed gem, and only an
        # installed spec counts. Only a package that actually carries
        # handbook/extensions counts. In auto mode a configured package
        # that resolves nowhere is a hard error: an unresolvable
        # extensions_package must never be treated as "no extensions",
        # which would prune every receipt-owned file from the target.
        def resolve_named_package(name)
          return installed_package(name) if Ace::Support::Cli::Toolchain.installed?

          local = File.join(project_root, name)
          return local if File.directory?(File.join(local, "handbook", "extensions"))

          spec = Gem::Specification.find_by_name(name)
          return spec.full_gem_path if File.directory?(File.join(spec.full_gem_path, "handbook", "extensions"))

          raise_unresolvable_extensions_package(name,
            "the installed gem carries no handbook/extensions tree")
        rescue Gem::LoadError, ArgumentError => e
          raise_unresolvable_extensions_package(name, e.message)
        end

        def raise_unresolvable_extensions_package(name, detail)
          raise StandardError,
            "the configured extensions_package '#{name}' cannot be resolved (#{detail}): " \
            "neither a sibling package directory under #{project_root} nor an installed gem " \
            "carries the extension assets. Install the package or fix the provider manifest — " \
            "an unresolvable extensions_package must never be treated as 'no extensions'."
        end

        # Installed mode: the packaged extension source must be the
        # installed gem (max version), never the checkout directory.
        def installed_package(name)
          spec = Gem::Specification.find_all
            .select { |candidate| candidate.name == name && Ace::Support::Cli::Toolchain.installed_spec?(candidate) }
            .max_by(&:version)
          return nil if spec.nil? || !File.directory?(File.join(spec.full_gem_path, "handbook", "extensions"))

          spec.full_gem_path
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
