# frozen_string_literal: true

require_relative "../atoms/gem_resolver"
require_relative "../atoms/path_normalizer"
require_relative "../models/handbook_source"
require_relative "config_loader"

module Ace
  module Support
    module Nav
      module Molecules
        # Scans and indexes available handbooks
        class HandbookScanner
          def initialize(gem_resolver: nil, path_normalizer: nil, config_loader: nil)
            @gem_resolver = gem_resolver || Atoms::GemResolver.new
            @path_normalizer = path_normalizer || Atoms::PathNormalizer.new
            @config_loader = config_loader || ConfigLoader.new
            @settings = @config_loader.load_settings
          end

          def scan_all_sources
            sources = []

            # Priority 1: Project overrides
            sources << scan_project_source

            # Priority 2: User overrides
            sources << scan_user_source

            # Priority 3: Gem handbooks
            sources.concat(scan_gem_sources)

            # Priority 4: Custom configured paths
            sources.concat(scan_custom_sources)

            # Filter out non-existent sources unless specifically configured
            sources.compact.select { |s| s.exists? || s.custom? }
          end

          def scan_source_by_alias(alias_name)
            return scan_project_source if alias_name == "@project"
            return scan_user_source if alias_name == "@user"

            # Check if it's a gem source
            if alias_name.start_with?("@ace-")
              gem_name = alias_name[1..] # Remove @
              return scan_gem_source(gem_name)
            end

            # Check custom sources
            scan_custom_source(alias_name)
          end

          def find_resources_in_source(source, protocol, pattern = "*")
            return [] unless source&.exists?

            handbook_path = source.handbook_path
            protocol_dir = protocol_to_directory(protocol)
            search_path = File.join(handbook_path, protocol_dir)

            return [] unless Dir.exist?(search_path)

            # Find matching files
            extension = protocol_to_extension(protocol)
            glob_pattern = File.join(search_path, "**", "#{pattern}#{extension}")

            Dir.glob(glob_pattern).map do |file_path|
              relative_path = file_path.sub("#{search_path}/", "").sub(extension, "")
              {
                path: file_path,
                relative_path: relative_path,
                source: source,
                protocol: protocol
              }
            end
          end

          private

          def scan_project_source
            project_path = File.expand_path("./.ace-handbook")
            return nil unless Dir.exist?(project_path)

            Models::HandbookSource.new(
              name: "project",
              path: project_path,
              alias_name: "@project",
              type: :project,
              priority: 10
            )
          end

          def scan_user_source
            user_path = File.expand_path("~/.ace-handbook")
            return nil unless Dir.exist?(user_path)

            Models::HandbookSource.new(
              name: "user",
              path: user_path,
              alias_name: "@user",
              type: :user,
              priority: 20
            )
          end

          def scan_gem_sources
            @gem_resolver.find_ace_gems.map.with_index do |gem_info, index|
              next unless gem_info[:has_handbook]

              Models::HandbookSource.new(
                name: gem_info[:name],
                path: gem_info[:path],
                alias_name: "@#{gem_info[:name]}",
                type: :gem,
                priority: 100 + index
              )
            end.compact
          end

          def scan_gem_source(gem_name)
            gem_info = @gem_resolver.find_gem_by_name(gem_name)
            return nil unless gem_info
            return nil unless gem_info[:has_handbook]

            Models::HandbookSource.new(
              name: gem_info[:name],
              path: gem_info[:path],
              alias_name: "@#{gem_info[:name]}",
              type: :gem,
              priority: 100
            )
          end

          def scan_custom_sources
            sources = []
            config_sources = @settings.dig("handbooks", "sources") || []

            config_sources.each do |source_config|
              next if source_config["gem"] # Skip gem sources (handled elsewhere)

              if source_config["path"]
                path = File.expand_path(source_config["path"])
                next unless Dir.exist?(path)

                sources << Models::HandbookSource.new(
                  name: source_config["alias"] || File.basename(path),
                  path: path,
                  alias_name: "@#{source_config["alias"] || File.basename(path)}",
                  type: :custom,
                  priority: 200
                )
              end
            end

            sources
          end

          def scan_custom_source(alias_name)
            config_sources = @settings.dig("handbooks", "sources") || []

            # Remove @ prefix if present
            search_alias = alias_name.start_with?("@") ? alias_name[1..] : alias_name

            config_sources.each do |source_config|
              next unless source_config["alias"] == search_alias

              path = File.expand_path(source_config["path"])
              return nil unless Dir.exist?(path)

              return Models::HandbookSource.new(
                name: source_config["alias"],
                path: path,
                alias_name: "@#{source_config["alias"]}",
                type: :custom,
                priority: 200
              )
            end

            nil
          end

          def protocol_to_directory(protocol)
            config = @config_loader.load_protocol_config(protocol)
            return protocol unless config

            # Use the directory specified in the protocol config
            config["directory"] || protocol
          end

          def protocol_to_extension(protocol)
            config = @config_loader.load_protocol_config(protocol)
            return ".md" unless config

            # Use the extensions specified in the protocol config
            extensions = config["extensions"]
            return "" if extensions.nil? || extensions.empty?

            extensions.first
          end
        end
      end
    end
  end
end
