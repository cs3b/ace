# frozen_string_literal: true

require "yaml"
require "pathname"
require "ace/support/fs"
require_relative "../models/protocol_source"

module Ace
  module Support
    module Nav
      module Molecules
        # Discovers and manages protocol source registrations
        class SourceRegistry
          attr_reader :start_path

          def initialize(start_path: nil)
            @start_path = start_path
            @sources_cache = {}
          end

          # Get all sources for a protocol
          def sources_for_protocol(protocol)
            @sources_cache[protocol] ||= discover_sources(protocol)
          end

          # Clear the cache
          def clear_cache
            @sources_cache.clear
          end

          private

          def discover_sources(protocol)
            sources = []

            # Discover from user directory
            sources.concat(discover_user_sources(protocol))

            # Discover from project hierarchy
            sources.concat(discover_project_sources(protocol))

            # Sort by priority (lower number = higher priority)
            sources.sort_by(&:priority)
          end

          def discover_user_sources(protocol)
            sources = []
            user_sources_dir = File.expand_path("~/.ace/nav/protocols/#{protocol}-sources")

            return sources unless Dir.exist?(user_sources_dir)

            Dir.glob(File.join(user_sources_dir, "*.yml")).each do |source_file|
              source = load_source_file(source_file, "user")
              sources << source if source
            end

            sources
          end

          def discover_project_sources(protocol)
            sources = []

            # Use directory traverser to find all .ace directories up to project root
            traverser = Ace::Support::Fs::Molecules::DirectoryTraverser.new(start_path: start_path || Dir.pwd)
            config_dirs = traverser.find_config_directories

            # Check each .ace directory for protocol sources
            config_dirs.each do |config_dir|
              sources_dir = File.join(config_dir, "nav/protocols", "#{protocol}-sources")
              next unless Dir.exist?(sources_dir)

              Dir.glob(File.join(sources_dir, "*.yml")).each do |source_file|
                source = load_source_file(source_file, "project")
                sources << source if source
              end
            end

            sources
          end

          def load_source_file(file_path, origin)
            data = YAML.load_file(file_path)
            return nil unless data.is_a?(Hash)

            # Expand environment variables in path (only for non-gem types)
            path = (data["type"] == "gem") ? nil : expand_path(data["path"]) if data["path"]

            # Log warning if path is provided for gem type
            if data["type"] == "gem" && data["path"]
              warn "Warning: 'path' field is ignored for gem type sources (#{data["name"]})" if ENV["VERBOSE"]
            end

            Models::ProtocolSource.new(
              name: data["name"] || File.basename(file_path, ".yml"),
              type: data["type"] || "directory",
              path: path,
              priority: data["priority"] || default_priority(origin),
              description: data["description"],
              origin: origin,
              config_file: file_path,
              config_dir: file_path,  # Pass the config file path for relative resolution
              config: data["config"]  # Pass the config section
            )
          rescue => e
            warn "Failed to load source file #{file_path}: #{e.message}"
            nil
          end

          def expand_path(path)
            # Expand environment variables
            path = path.gsub(/\$(\w+)/) { ENV.fetch($1, "") }
            path = path.gsub("$HOME", ENV["HOME"]) if ENV["HOME"]
            path = path.gsub("$USER", ENV["USER"]) if ENV["USER"]

            # Don't expand relative paths for gem sources
            path
          end

          def default_priority(origin)
            case origin
            when "project"
              10  # Highest priority
            when "user"
              50  # Medium priority
            else
              100 # Lower priority for gems
            end
          end
        end
      end
    end
  end
end
