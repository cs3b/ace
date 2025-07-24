# frozen_string_literal: true

require_relative "../atoms/directory_scanner"
require_relative "../molecules/tool_metadata_extractor"
require_relative "../molecules/tool_categorizer"
require_relative "../atoms/yaml_reader"

module CodingAgentTools
  module Organisms
    # ToolLister - Organism for discovering and listing available tools
    #
    # Responsibilities:
    # - Scan for available executable tools
    # - Extract metadata and descriptions from tools
    # - Apply blacklist filtering to exclude internal/dev tools
    # - Categorize tools by function
    # - Format tool listings for display
    class ToolLister
      DEFAULT_BLACKLIST = [
        "coding_agent_tools", # Main wrapper command
        "*-dev",              # Development tools
        "*-debug",            # Debug utilities
        "test-*"              # Test utilities
      ].freeze

      attr_reader :exe_directory, :blacklist

      def initialize(exe_directory = nil, blacklist: nil, config_path: nil)
        @exe_directory = File.expand_path(exe_directory || find_exe_directory)
        @config_path = config_path || find_config_path
        @blacklist = blacklist || load_blacklist_from_config
      end

      # Lists all available tools with metadata
      #
      # @param options [Hash] Listing options
      # @option options [Boolean] :categorized (true) Whether to group by category
      # @option options [Boolean] :descriptions (true) Whether to include descriptions
      # @return [Hash] Tool listing data
      def list_all_tools(options = {})
        categorized = options.fetch(:categorized, true)
        descriptions = options.fetch(:descriptions, true)

        # Scan for executable files
        tool_files = scan_tools

        # Extract metadata for each tool
        tools_with_metadata = extract_metadata(tool_files, descriptions)

        # Apply blacklist filtering
        filtered_tools = apply_blacklist_filter(tools_with_metadata)

        # Organize results
        if categorized
          categorize_tools(filtered_tools)
        else
          {tools: filtered_tools, total: filtered_tools.length}
        end
      end

      # Gets a simple list of tool names (for shell completion, etc.)
      #
      # @return [Array<String>] List of tool names
      def list_tool_names
        tool_files = scan_tools
        tools_with_metadata = extract_metadata(tool_files, false)
        filtered_tools = apply_blacklist_filter(tools_with_metadata)
        filtered_tools.map { |tool| tool[:name] }.sort
      end

      private

      def find_config_path
        # Look for tools.yml in XDG-compliant locations
        possible_paths = [
          # Project-specific .coding-agent directory (current working directory)
          File.join(Dir.pwd, ".coding-agent", "tools.yml"),
          # Project root .coding-agent directory (go up from dev-tools if we're in it)
          File.join(Dir.pwd, "..", ".coding-agent", "tools.yml"),
          # Explicit handbook-meta root .coding-agent directory
          File.expand_path("../../../../.coding-agent/tools.yml", __FILE__),
          # XDG_CONFIG_HOME or ~/.config fallback
          File.join(ENV.fetch("XDG_CONFIG_HOME", File.join(Dir.home, ".config")), "coding-agent-tools", "tools.yml"),
          # Legacy project root location (for backward compatibility)
          File.join(Dir.pwd, "tools.yml"),
          File.join(Dir.pwd, "..", "tools.yml")
        ]

        possible_paths.each do |path|
          return path if File.exist?(path)
        end

        nil # No config file found
      end

      def load_blacklist_from_config
        return DEFAULT_BLACKLIST unless @config_path && File.exist?(@config_path)

        begin
          config = CodingAgentTools::Atoms::YamlReader.read_file(@config_path)
          blacklist = config.dig("blacklist") || config.dig(:blacklist)

          if blacklist.is_a?(Array)
            blacklist
          else
            DEFAULT_BLACKLIST
          end
        rescue
          # If config loading fails, fall back to default
          DEFAULT_BLACKLIST
        end
      end

      def find_exe_directory
        # Try to find exe directory relative to this file
        lib_dir = File.dirname(__FILE__)

        # Navigate up from lib/coding_agent_tools/organisms to the gem root
        gem_root = File.expand_path("../../../..", lib_dir)
        exe_dir = File.join(gem_root, "exe")

        return exe_dir if File.directory?(exe_dir)

        # Fallback: look for exe directory in common locations
        possible_paths = [
          File.join(File.dirname(__FILE__), "../../../exe"),
          File.expand_path("exe", Dir.pwd),
          File.expand_path("../exe", Dir.pwd)
        ]

        possible_paths.each do |path|
          return path if File.directory?(path)
        end

        # Final fallback - use current directory exe
        File.join(Dir.pwd, "exe")
      end

      def scan_tools
        unless File.directory?(exe_directory)
          raise CodingAgentTools::Error, "Executable directory not found: #{exe_directory}"
        end

        CodingAgentTools::Atoms::DirectoryScanner.scan_files(
          exe_directory,
          pattern: "*",
          exclude_patterns: [".*", "*.tmp", "*.bak"]
        )
      end

      def extract_metadata(tool_files, include_descriptions)
        extractor = CodingAgentTools::Molecules::ToolMetadataExtractor.new

        tool_files.map do |file_path|
          tool_name = File.basename(file_path)
          metadata = {
            name: tool_name,
            path: file_path
          }

          if include_descriptions
            description = extractor.extract_description(file_path)
            metadata[:description] = description
          end

          metadata
        end
      end

      def apply_blacklist_filter(tools)
        return tools if blacklist.empty?

        tools.reject do |tool|
          blacklist.any? do |pattern|
            if pattern.include?("*")
              # Convert shell glob pattern to regex
              regex_pattern = pattern.gsub("*", ".*")
              tool[:name].match?(/^#{regex_pattern}$/)
            else
              tool[:name] == pattern
            end
          end
        end
      end

      def categorize_tools(tools)
        categorizer = CodingAgentTools::Molecules::ToolCategorizer.new
        categorized = categorizer.categorize_tools(tools)

        {
          categories: categorized,
          total: tools.length
        }
      end
    end
  end
end
