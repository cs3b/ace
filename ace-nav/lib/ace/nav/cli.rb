# frozen_string_literal: true

require "optparse"
require "fileutils"
require_relative "organisms/navigation_engine"

module Ace
  module Nav
    # CLI interface for ace-nav
    class Cli
      def initialize
        @engine = Organisms::NavigationEngine.new
        @options = {}
      end

      def run(argv)
        parse_options(argv)

        # Check for standalone options that don't require a path/URI
        if @options[:help]
          show_help
          return
        elsif @options[:sources]
          show_sources
          return
        end

        # Get the path/URI argument
        path_or_uri = argv.first

        unless path_or_uri
          show_help
          return
        end

        # Execute based on options
        execute(path_or_uri)
      rescue StandardError => e
        puts "Error: #{e.message}"
        puts e.backtrace if @options[:verbose]
        exit 1
      end

      private

      def parse_options(argv)
        @parser = OptionParser.new do |opts|
          opts.banner = "Usage: ace-nav <path-or-uri> [options]"
          opts.separator ""
          opts.separator "Options:"

          opts.on("--content", "Display resource content") do
            @options[:content] = true
          end

          opts.on("--create [PATH]", "Create resource from template") do |path|
            @options[:create] = path || true
          end

          opts.on("--list", "List matching resources") do
            @options[:list] = true
          end

          opts.on("--tree", "Display resources in tree format") do
            @options[:tree] = true
            @options[:list] = true
          end

          opts.on("--verbose", "Show detailed information") do
            @options[:verbose] = true
          end

          opts.on("--sources", "Show available sources") do
            @options[:sources] = true
          end

          opts.on("-h", "--help", "Show this help message") do
            @options[:help] = true
          end

          opts.on("-v", "--version", "Show version") do
            puts "ace-nav #{VERSION}"
            exit
          end
        end

        @parser.parse!(argv)
      end

      def execute(path_or_uri)
        # Check if it's a protocol-only URI (e.g., "tmpl://")
        # and automatically treat it as a list operation with wildcard
        if path_or_uri.match?(/^\w+:\/\/$/)
          # Protocol-only URI, add wildcard and force list mode
          path_or_uri = "#{path_or_uri}*"
          @options[:list] = true
        end

        if @options[:create]
          create_resource(path_or_uri)
        elsif @options[:list]
          list_resources(path_or_uri)
        else
          resolve_resource(path_or_uri)
        end
      end

      def show_help
        puts @parser
        puts
        puts "Examples:"
        puts "  ace-nav wfi://setup                         # Find first matching workflow"
        puts "  ace-nav wfi://@ace-git/setup               # From specific source"
        puts "  ace-nav wfi://setup --content              # Show content"
        puts "  ace-nav 'wfi://*' --list                   # List all workflows"
        puts "  ace-nav wfi://setup --create               # Create from template"
        puts "  ace-nav task://018                         # Find task by number"
        puts "  ace-nav --sources                          # Show available sources"
        puts
        puts "Available Protocols:"

        protocols = @engine.discovered_protocols
        if protocols.empty?
          puts "  No protocols discovered. Check your configuration."
        else
          protocols.sort.each do |key, protocol|
            name = protocol["name"] || key.capitalize
            desc = protocol["description"] || ""
            if desc.empty?
              puts "  #{key}://   - #{name}"
            else
              puts "  #{key}://   - #{name}"
              puts "           #{desc}"
            end
          end
        end
        puts
        puts "Sources (use @ prefix):"
        puts "  @project - Project overrides (./.ace/handbook)"
        puts "  @user    - User overrides (~/.ace/handbook)"
        puts "  @ace-*   - Specific ace gem"
      end

      def show_sources
        sources = @engine.sources(verbose: @options[:verbose])

        if @options[:verbose]
          require "json"
          puts JSON.pretty_generate(sources)
        else
          puts "Available sources:"
          sources.each { |source| puts "  #{source}" }
        end
      end

      def create_resource(uri)
        target = @options[:create] == true ? nil : @options[:create]
        result = @engine.create(uri, target)

        if result[:error]
          puts "Error: #{result[:error]}"
          exit 1
        else
          puts "Created: #{result[:created]}"
          puts "From: #{result[:from]}" if @options[:verbose]
        end
      end

      def list_resources(pattern)
        resources = @engine.list(pattern, tree: @options[:tree], verbose: @options[:verbose])

        if resources.empty?
          puts "No resources found matching: #{pattern}"
        elsif @options[:verbose]
          require "json"
          puts JSON.pretty_generate(resources)
        else
          resources.each { |resource| puts resource }
        end
      end

      def resolve_resource(uri)
        result = @engine.resolve(uri, content: @options[:content], verbose: @options[:verbose])

        if result.nil?
          puts "Resource not found: #{uri}"
          exit 1
        elsif @options[:verbose] && result.is_a?(Hash)
          require "json"
          puts JSON.pretty_generate(result)
        else
          puts result
        end
      end
    end
  end
end