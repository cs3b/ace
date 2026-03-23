# frozen_string_literal: true

require_relative "../atoms/gem_resolver"
require_relative "../atoms/path_normalizer"
require_relative "../atoms/extension_inferrer"
require_relative "../models/handbook_source"
require_relative "config_loader"

module Ace
  module Support
    module Nav
      module Molecules
        # Scans for protocol resources using registered sources
        class ProtocolScanner
          attr_reader :config_loader

          def initialize(gem_resolver: nil, path_normalizer: nil, config_loader: nil, extension_inferrer: nil)
            @gem_resolver = gem_resolver || Atoms::GemResolver.new
            @path_normalizer = path_normalizer || Atoms::PathNormalizer.new
            @config_loader = config_loader || ConfigLoader.new
            # extension_inferrer param kept for backwards compatibility but ignored
            # ExtensionInferrer now uses class methods
            @extension_inference_enabled = nil
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
            # Try exact match first
            resources = find_resources_with_extensions(source, protocol_config, pattern)

            # If no results and extension inference is enabled, try with inferred extensions
            if resources.empty? && extension_inference_enabled? && !pattern.include?("/") && pattern != "*"
              resources = find_resources_with_inference(source, protocol_config, pattern)
            end

            resources
          end

          # Find resources using pattern and extensions (original logic)
          def find_resources_with_extensions(source, protocol_config, pattern = "*")
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

            # Check if pattern contains directory structure
            if pattern.include?("/")
              # Handle subdirectory patterns
              if pattern.end_with?("/")
                # Pattern like "base/" has two interpretations:
                # 1. Files in a subdirectory named "base"
                # 2. Files that start with "base" prefix
                prefix = pattern.chomp("/")

                # First, try as a subdirectory
                subdir_path = File.join(search_path, prefix)
                has_subdir = Dir.exist?(subdir_path)

                if has_subdir
                  # Subdirectory exists, list files in it
                  found_subdir_paths = Set.new  # Track paths to avoid duplicates

                  if extensions.empty?
                    # Match any file in the subdirectory
                    glob_pattern = File.join(subdir_path, "*")
                    glob_pattern_nested = File.join(subdir_path, "**", "*")

                    [glob_pattern, glob_pattern_nested].each do |gp|
                      Dir.glob(gp).each do |file_path|
                        next unless File.file?(file_path)
                        next if found_subdir_paths.include?(file_path)  # Skip duplicates
                        found_subdir_paths.add(file_path)
                        resources << create_resource_info(file_path, search_path, source, protocol_config["protocol"])
                      end
                    end
                  else
                    # Match files with specified extensions in the subdirectory
                    extensions.each do |ext|
                      glob_pattern = File.join(subdir_path, "*#{ext}")
                      glob_pattern_nested = File.join(subdir_path, "**", "*#{ext}")

                      [glob_pattern, glob_pattern_nested].each do |gp|
                        Dir.glob(gp).each do |file_path|
                          next unless File.file?(file_path)
                          next if found_subdir_paths.include?(file_path)  # Skip duplicates
                          found_subdir_paths.add(file_path)
                          resources << create_resource_info(file_path, search_path, source, protocol_config["protocol"])
                        end
                      end
                    end
                  end
                end

                # Also try as a prefix pattern (files starting with prefix)
                found_paths = Set.new  # Track paths to avoid duplicates

                if extensions.empty?
                  # Match files starting with prefix
                  glob_patterns = [
                    File.join(search_path, "#{prefix}*"),
                    File.join(search_path, "**", "#{prefix}*")
                  ]

                  glob_patterns.each do |gp|
                    Dir.glob(gp).each do |file_path|
                      next unless File.file?(file_path)
                      next if found_paths.include?(file_path)  # Skip duplicates
                      found_paths.add(file_path)
                      resources << create_resource_info(file_path, search_path, source, protocol_config["protocol"])
                    end
                  end
                else
                  # Match files with specified extensions starting with prefix
                  extensions.each do |ext|
                    glob_patterns = [
                      File.join(search_path, "#{prefix}*#{ext}"),
                      File.join(search_path, "**", "#{prefix}*#{ext}")
                    ]

                    glob_patterns.each do |gp|
                      Dir.glob(gp).each do |file_path|
                        next unless File.file?(file_path)
                        next if found_paths.include?(file_path)  # Skip duplicates
                        found_paths.add(file_path)
                        resources << create_resource_info(file_path, search_path, source, protocol_config["protocol"])
                      end
                    end
                  end
                end
              elsif extensions.empty?
                # Pattern like "base/*" or "base/something" - use as-is but handle properly
                glob_pattern = File.join(search_path, pattern)
                glob_pattern += "*" unless pattern.end_with?("*") || pattern.include?("*")

                Dir.glob(glob_pattern).each do |file_path|
                  next unless File.file?(file_path)
                  resources << create_resource_info(file_path, search_path, source, protocol_config["protocol"])
                end
              else
                extensions.each do |ext|
                  glob_pattern = if pattern.end_with?(ext)
                    File.join(search_path, pattern)
                  else
                    File.join(search_path, "#{pattern}#{ext}")
                  end

                  Dir.glob(glob_pattern).each do |file_path|
                    next unless File.file?(file_path)
                    resources << create_resource_info(file_path, search_path, source, protocol_config["protocol"])
                  end
                end
              end
            elsif extensions.empty?
              # Original behavior for patterns without directory structure
              glob_pattern = File.join(search_path, "**", pattern)
              glob_pattern += "*" unless pattern.end_with?("*")

              Dir.glob(glob_pattern).each do |file_path|
                next unless File.file?(file_path)

                resources << create_resource_info(file_path, search_path, source, protocol_config["protocol"])
              end
            # If no extensions specified, match any file
            else
              # Match files with specified extensions
              extensions.each do |ext|
                # Check if pattern already ends with this extension
                glob_pattern = if pattern.end_with?(ext)
                  # Pattern already has extension, search as-is
                  File.join(search_path, "**", pattern)
                else
                  # Append extension to pattern
                  File.join(search_path, "**", "#{pattern}#{ext}")
                end

                Dir.glob(glob_pattern).each do |file_path|
                  next unless File.file?(file_path)

                  resources << create_resource_info(file_path, search_path, source, protocol_config["protocol"])
                end
              end
            end

            resources
          end

          # Find resources using extension inference when exact match fails
          def find_resources_with_inference(source, protocol_config, pattern)
            # Handle both ProtocolSource and HandbookSource objects
            if source.respond_to?(:full_path)
              return [] unless source.exists?
              search_path = source.full_path
            else
              return [] unless source.exists?
              search_path = source.handbook_path
            end

            # Get configuration for extension inference
            settings = @config_loader.load_settings
            inference_config = settings["extension_inference"] || {}
            enabled = inference_config["enabled"] != false  # Default true
            fallback_order = inference_config["fallback_order"]

            # Get protocol extensions
            protocol_extensions = protocol_config["extensions"] || []
            inferred_extensions = protocol_config["inferred_extensions"] || protocol_extensions

            # Generate candidate patterns using extension inferrer
            candidates = Atoms::ExtensionInferrer.infer_extensions(
              pattern,
              protocol_extensions: inferred_extensions,
              enabled: enabled,
              fallback_order: fallback_order
            )

            resources = []
            found_paths = Set.new  # Track paths to avoid duplicates

            # Try each candidate pattern in order
            candidates.each do |candidate|
              # For inference, we need to allow additional extensions after the inferred one
              # e.g., "mydoc.cst" should match "mydoc.cst.md"
              # Use brace expansion for tighter matching: exact match or with extension
              glob_pattern = File.join(search_path, "**", candidate + "{,.*}")

              Dir.glob(glob_pattern).each do |file_path|
                next unless File.file?(file_path)
                next if found_paths.include?(file_path)

                # Only match if basename equals candidate or has candidate as prefix with dot separator
                # This prevents "multi-ext.g" from matching "multi-ext.guide.md"
                basename = File.basename(file_path)
                basename_candidate = File.basename(candidate)
                next unless basename == basename_candidate ||
                  basename.start_with?(basename_candidate + ".")

                found_paths.add(file_path)
                resources << create_resource_info(file_path, search_path, source, protocol_config["protocol"])
              end

              # Stop at first match (DWIM: return first successful inference)
              break if resources.any?
            end

            resources
          end

          # Check if extension inference is enabled in settings (cached)
          def extension_inference_enabled?
            return @extension_inference_enabled unless @extension_inference_enabled.nil?

            settings = @config_loader.load_settings
            inference_config = settings["extension_inference"] || {}
            @extension_inference_enabled = inference_config["enabled"] != false  # Default true
          end

          # Reset extension inference cache (for testing)
          def reset_extension_inference_cache!
            @extension_inference_enabled = nil
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
            # Ensure search_path ends with a separator for proper substitution
            normalized_search_path = search_path.end_with?("/") ? search_path : "#{search_path}/"

            # Calculate relative path from the search path
            relative_path = if file_path.start_with?(normalized_search_path)
              file_path[normalized_search_path.length..]
            else
              # Fallback to original logic if path doesn't start with search_path
              file_path.sub("#{search_path}/", "")
            end

            # Remove extension for resource path
            protocol_config = @config_loader.load_protocol_config(protocol)
            extensions = protocol_config["extensions"] || []
            inferred_extensions = protocol_config["inferred_extensions"] || extensions

            # Combine both lists for extension stripping
            all_extensions = extensions | inferred_extensions

            resource_path = relative_path
            all_extensions.each do |ext|
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
        end
      end
    end
  end
end
