# frozen_string_literal: true

require "yaml"
require "pathname"
require "ace/core/molecules/directory_traverser"
require_relative "../models/protocol_source"

module Ace
  module Nav
    module Molecules
      # Discovers and manages protocol source registrations
      class SourceRegistry
        def initialize
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
          user_sources_dir = File.expand_path("~/.ace/protocols/#{protocol}-sources")

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
          traverser = Ace::Core::Molecules::DirectoryTraverser.new(start_path: Dir.pwd)
          config_dirs = traverser.find_config_directories

          # Check each .ace directory for protocol sources
          config_dirs.each do |config_dir|
            sources_dir = File.join(config_dir, "protocols", "#{protocol}-sources")
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

          # Expand environment variables in path
          path = expand_path(data["path"]) if data["path"]

          Models::ProtocolSource.new(
            name: data["name"] || File.basename(file_path, ".yml"),
            type: data["type"] || "directory",
            path: path,
            priority: data["priority"] || default_priority(origin),
            description: data["description"],
            origin: origin,
            config_file: file_path,
            config_dir: file_path  # Pass the config file path for relative resolution
          )
        rescue StandardError => e
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