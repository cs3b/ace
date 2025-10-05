# frozen_string_literal: true

require "pathname"

module Ace
  module Review
    module Molecules
      # Resolves prompt:// URIs and file paths with cascade lookup
      class PromptResolver
        PROTOCOL_PREFIX = "prompt://"

        attr_reader :project_root

        def initialize(project_root: nil)
          @project_root = project_root || find_project_root
          @cache = {}
        end

        # Resolve a prompt reference to actual content
        # Supports:
        # - prompt://category/path - cascade lookup
        # - prompt://project/path - project only
        # - prompt://gem/path - gem built-in only
        # - ./file.md - relative to config file directory
        # - file.md - relative to project root
        def resolve(reference, config_dir: nil)
          return nil unless reference

          # Check cache
          cache_key = "#{reference}:#{config_dir}"
          return @cache[cache_key] if @cache.key?(cache_key)

          content = if reference.start_with?(PROTOCOL_PREFIX)
                      resolve_protocol_uri(reference)
                    else
                      resolve_file_path(reference, config_dir)
                    end

          @cache[cache_key] = content
          content
        end

        # List available prompt modules in a category
        def list_available(category = nil)
          prompts = {}

          # Collect from all locations
          locations = [
            { path: project_prompt_dir, label: "project" },
            { path: user_prompt_dir, label: "user" },
            { path: gem_prompt_dir, label: "built-in" }
          ]

          locations.each do |location|
            next unless location[:path] && Dir.exist?(location[:path])

            if category
              category_dir = File.join(location[:path], category)
              next unless Dir.exist?(category_dir)

              prompts[category] ||= {}
              collect_prompts_from_dir(category_dir, prompts[category], location[:label])
            else
              Dir.glob("#{location[:path]}/*").select { |f| File.directory?(f) }.each do |cat_dir|
                cat_name = File.basename(cat_dir)
                prompts[cat_name] ||= {}
                collect_prompts_from_dir(cat_dir, prompts[cat_name], location[:label])
              end
            end
          end

          prompts
        end

        private

        def find_project_root
          if defined?(Ace::Core)
            require "ace/core"
            discovery = Ace::Core::ConfigDiscovery.new
            return discovery.project_root if discovery.project_root
          end
          Dir.pwd
        end

        def resolve_protocol_uri(uri)
          path = uri.sub(PROTOCOL_PREFIX, "")

          # Handle forced location prefixes
          if path.start_with?("project/")
            prompt_path = path.sub("project/", "")
            return read_prompt_file(File.join(project_prompt_dir, "#{prompt_path}.md"))
          elsif path.start_with?("user/")
            prompt_path = path.sub("user/", "")
            return read_prompt_file(File.join(user_prompt_dir, "#{prompt_path}.md"))
          elsif path.start_with?("gem/")
            prompt_path = path.sub("gem/", "")
            return read_prompt_file(File.join(gem_prompt_dir, "#{prompt_path}.md"))
          end

          # Default cascade: project → user → gem
          cascade_paths = [
            File.join(project_prompt_dir, "#{path}.md"),
            File.join(user_prompt_dir, "#{path}.md"),
            File.join(gem_prompt_dir, "#{path}.md")
          ].compact

          cascade_paths.each do |prompt_path|
            content = read_prompt_file(prompt_path)
            return content if content
          end

          nil
        end

        def resolve_file_path(path, config_dir)
          # Handle relative paths starting with ./
          if path.start_with?("./")
            base_dir = config_dir || project_root
            full_path = File.expand_path(path, base_dir)
            return read_prompt_file(full_path)
          end

          # Treat as relative to project root
          full_path = File.join(project_root, path)
          read_prompt_file(full_path)
        end

        def read_prompt_file(path)
          return nil unless path && File.exist?(path)

          File.read(path).strip
        rescue StandardError => e
          warn "Failed to read prompt file #{path}: #{e.message}" if Ace::Review.debug?
          nil
        end

        def project_prompt_dir
          @project_prompt_dir ||= File.join(project_root, ".ace/review/prompts")
        end

        def user_prompt_dir
          @user_prompt_dir ||= File.expand_path("~/.ace/review/prompts")
        end

        def gem_prompt_dir
          @gem_prompt_dir ||= File.expand_path("../prompts", __dir__)
        end

        def collect_prompts_from_dir(dir, collection, label)
          Dir.glob("#{dir}/**/*.md").each do |file|
            rel_path = file.sub("#{dir}/", "").sub(/\.md$/, "")

            # Handle nested directories
            parts = rel_path.split("/")
            if parts.length > 1
              # Nested prompt (e.g., architecture/atom)
              category = parts[0]
              name = parts[1..-1].join("/")
              collection[category] ||= []
              collection[category] << { name: name, source: label }
            else
              # Top-level prompt
              collection[rel_path] = label
            end
          end
        end
      end
    end
  end
end