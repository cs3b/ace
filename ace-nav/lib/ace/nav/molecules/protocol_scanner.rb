# frozen_string_literal: true

require_relative "../atoms/gem_resolver"
require_relative "../atoms/path_normalizer"
require_relative "../models/handbook_source"
require_relative "config_loader"

module Ace
  module Nav
    module Molecules
      # Scans for protocol resources using registered sources
      class ProtocolScanner
        def initialize(gem_resolver: nil, path_normalizer: nil, config_loader: nil)
          @gem_resolver = gem_resolver || Atoms::GemResolver.new
          @path_normalizer = path_normalizer || Atoms::PathNormalizer.new
          @config_loader = config_loader || ConfigLoader.new
        end

        # Get all sources for a protocol
        def sources_for_protocol(protocol)
          @config_loader.sources_for_protocol(protocol)
        end

        # Find resources in all sources for a protocol
        def find_resources(protocol, pattern = "*")
          sources = sources_for_protocol(protocol)
          protocol_config = @config_loader.load_protocol_config(protocol)

          resources = []

          sources.each do |source|
            next unless source.exists?

            resources.concat(find_resources_in_source_internal(source, protocol_config, pattern))
          end

          resources
        end

        # Find resources in a specific source (internal implementation)
        def find_resources_in_source_internal(source, protocol_config, pattern = "*")
          # Handle both ProtocolSource and HandbookSource objects
          if source.respond_to?(:full_path)
            return [] unless source.exists?
            search_path = source.full_path
          else
            # Legacy HandbookSource
            return [] unless source.exists?
            search_path = source.handbook_path
          end

          # Get extensions from protocol config
          extensions = protocol_config["extensions"] || []

          resources = []

          if extensions.empty?
            # If no extensions specified, match any file
            glob_pattern = File.join(search_path, "**", pattern)
            glob_pattern += "*" unless pattern.end_with?("*")

            Dir.glob(glob_pattern).each do |file_path|
              next unless File.file?(file_path)

              resources << create_resource_info(file_path, search_path, source, protocol_config["protocol"])
            end
          else
            # Match files with specified extensions
            extensions.each do |ext|
              # Check if pattern already ends with this extension
              if pattern.end_with?(ext)
                # Pattern already has extension, search as-is
                glob_pattern = File.join(search_path, "**", pattern)
              else
                # Append extension to pattern
                glob_pattern = File.join(search_path, "**", "#{pattern}#{ext}")
              end

              Dir.glob(glob_pattern).each do |file_path|
                next unless File.file?(file_path)

                resources << create_resource_info(file_path, search_path, source, protocol_config["protocol"])
              end
            end
          end

          resources
        end

        # Legacy wrapper method for HandbookScanner compatibility
        def find_resources_in_source(source, protocol, pattern = "*")
          # If second param is a string (protocol name), load its config
          if protocol.is_a?(String)
            protocol_config = @config_loader.load_protocol_config(protocol)
            find_resources_in_source_internal(source, protocol_config, pattern)
          else
            # Already a protocol config
            find_resources_in_source_internal(source, protocol, pattern)
          end
        end

        # Legacy method for compatibility - get all sources across all protocols
        def scan_all_sources
          sources = []
          protocols = @config_loader.valid_protocols

          protocols.each do |protocol|
            protocol_sources = sources_for_protocol(protocol)

            # Convert to legacy HandbookSource format for compatibility
            protocol_sources.each do |source|
              # The path already points to the handbook directory
              # HandbookSource will append /handbook if needed
              base_path = source.full_path

              # Remove /handbook from the path if present since HandbookSource adds it
              if base_path.end_with?("/handbook")
                base_path = File.dirname(base_path)
              end

              sources << Models::HandbookSource.new(
                name: source.name,
                path: base_path,
                alias_name: "@#{source.name}",
                type: source.type.to_sym,
                priority: source.priority
              )
            end
          end

          # Remove duplicates by alias_name
          sources.uniq { |s| s.alias_name }
        end

        # Legacy method - scan source by alias
        def scan_source_by_alias(alias_name)
          # Remove @ prefix if present
          name = alias_name.start_with?("@") ? alias_name[1..] : alias_name

          # Handle special aliases
          case name
          when "project", "local"
            return scan_project_source
          when "user", "global"
            return scan_user_source
          end

          # Find in registered sources
          protocols = @config_loader.valid_protocols

          protocols.each do |protocol|
            source = sources_for_protocol(protocol).find { |s| s.name == name }
            if source
              return Models::HandbookSource.new(
                name: source.name,
                path: File.dirname(source.full_path),
                alias_name: "@#{source.name}",
                type: source.type.to_sym,
                priority: source.priority
              )
            end
          end

          nil
        end

        private

        def create_resource_info(file_path, search_path, source, protocol)
          relative_path = file_path.sub("#{search_path}/", "")

          # Remove extension for resource path
          protocol_config = @config_loader.load_protocol_config(protocol)
          extensions = protocol_config["extensions"] || []

          resource_path = relative_path
          extensions.each do |ext|
            resource_path = resource_path.sub(ext, "") if resource_path.end_with?(ext)
          end

          {
            path: file_path,
            relative_path: resource_path,
            source: source,
            protocol: protocol
          }
        end

        def scan_project_source
          project_path = File.expand_path("./.ace")
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
          user_path = File.expand_path("~/.ace")
          return nil unless Dir.exist?(user_path)

          Models::HandbookSource.new(
            name: "user",
            path: user_path,
            alias_name: "@user",
            type: :user,
            priority: 20
          )
        end
      end
    end
  end
end