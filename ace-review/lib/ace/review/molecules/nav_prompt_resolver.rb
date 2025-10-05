# frozen_string_literal: true

require "pathname"

module Ace
  module Review
    module Molecules
      # Resolves prompt:// URIs using ace-nav NavigationEngine
      class NavPromptResolver
        PROTOCOL_PREFIX = "prompt://"

        def initialize
          begin
            require "ace/nav"
            require "ace/nav/organisms/navigation_engine"
            @engine = Ace::Nav::Organisms::NavigationEngine.new
          rescue LoadError
            # Fall back to basic resolution if ace-nav is not available
            @engine = nil
          end

          @project_root = find_project_root
        end

        # Resolve a prompt reference to actual content
        def resolve(reference, config_dir: nil)
          return nil unless reference

          if reference.start_with?(PROTOCOL_PREFIX)
            # Use ace-nav for prompt:// URIs
            resolve_via_nav(reference)
          else
            # Keep existing file resolution for relative/absolute paths
            resolve_file_path(reference, config_dir)
          end
        end

        # List available prompt modules in a category
        def list_available(category = nil)
          return {} unless @engine

          begin
            if category
              # List resources in specific category
              # Use the category as part of the path
              uri = "#{PROTOCOL_PREFIX}#{category}/"
              resources = @engine.list(uri)
            else
              # List all prompt resources
              resources = @engine.list(PROTOCOL_PREFIX)
            end

            parse_listing(resources, category)
          rescue StandardError => e
            warn "Error listing prompts: #{e.message}" if ENV["DEBUG"]
            {}
          end
        end

        private

        def resolve_via_nav(reference)
          return nil unless @engine

          begin
            # Use ace-nav to resolve and get content
            @engine.resolve(reference, content: true)
          rescue StandardError => e
            warn "Error resolving #{reference}: #{e.message}" if ENV["DEBUG"]
            nil
          end
        end

        def resolve_file_path(reference, config_dir)
          # Handle relative and absolute file paths
          if reference.start_with?("./", "../")
            # Relative to config directory
            resolve_relative_path(reference, config_dir)
          elsif reference.start_with?("/")
            # Absolute path
            File.exist?(reference) ? File.read(reference) : nil
          else
            # Relative to project root
            path = File.join(@project_root, reference)
            File.exist?(path) ? File.read(path) : nil
          end
        rescue StandardError => e
          warn "Error reading file #{reference}: #{e.message}" if ENV["DEBUG"]
          nil
        end

        def resolve_relative_path(reference, config_dir)
          return nil unless config_dir

          path = File.expand_path(reference, config_dir)
          File.exist?(path) ? File.read(path) : nil
        end

        def parse_listing(resources, category)
          # Convert ace-nav output to expected format
          # Expected format is nested hash: { "category" => { "name" => "path" } }
          prompts = {}

          if resources.is_a?(Array)
            resources.each do |resource|
              # Parse resource string format: "prompt://category/name → /path (@source)"
              if resource.is_a?(String) && resource.include?("→")
                parts = resource.split("→").first.strip
                uri_parts = parts.sub(PROTOCOL_PREFIX, "").split("/")

                if uri_parts.length >= 1
                  cat = uri_parts[0]
                  name = uri_parts[1..-1].join("/") if uri_parts.length > 1

                  prompts[cat] ||= {}
                  prompts[cat][name || cat] = resource.split("→").last.strip.split(" ").first
                end
              end
            end
          end

          # If specific category requested, return just that category
          category ? prompts[category] || {} : prompts
        end

        def find_project_root
          # Try to find project root using various methods
          if defined?(Ace::Core) && Ace::Core.respond_to?(:root)
            Ace::Core.root
          elsif Dir.exist?(".git")
            Dir.pwd
          else
            # Search upward for .git directory
            current = Pathname.new(Dir.pwd)
            until current.root?
              return current.to_s if (current + ".git").exist?
              current = current.parent
            end
            Dir.pwd
          end
        end
      end
    end
  end
end