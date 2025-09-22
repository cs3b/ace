# frozen_string_literal: true

require "fileutils"
require "time"

module Ace
  module Taskflow
    module Organisms
      class IdeaWriter
        def initialize(config = nil)
          @config = config || load_config
        end

        def write(content, metadata = {})
          metadata = prepare_metadata(content, metadata)
          path = generate_path(metadata)
          ensure_directory_exists(path)

          formatted_content = format_idea(content, metadata)
          File.write(path, formatted_content)

          path
        end

        private

        def load_config
          require "yaml"

          # Try to load taskflow.yml directly from .ace directory
          config_paths = [
            File.join(Dir.pwd, ".ace", "taskflow.yml"),
            File.join(Dir.home, ".ace", "taskflow.yml")
          ]

          config_paths.each do |path|
            if File.exist?(path)
              config = YAML.load_file(path)
              if config && config["taskflow"] && config["taskflow"]["idea"]
                # Merge settings with idea config
                settings = config["taskflow"]["settings"] || {}
                idea_config = config["taskflow"]["idea"] || {}
                return settings.merge(idea_config)
              end
            end
          end

          # Fall back to default if no config found
          default_config
        rescue StandardError
          # Return default config if there's any error
          default_config
        end

        def default_config
          {
            "directory" => "./ideas",
            "template" => "# Idea\n\n%{content}\n\n---\nCaptured: %{timestamp}",
            "formatting" => {
              "timestamp_format" => "%Y-%m-%d %H:%M:%S"
            }
          }
        end

        def prepare_metadata(content, metadata)
          metadata = metadata.dup
          metadata[:timestamp] ||= Time.now.strftime(timestamp_format)
          metadata[:title] ||= extract_title(content)
          metadata
        end

        def extract_title(content)
          # Take first 50 chars or up to first newline, whichever is shorter
          title = content.split("\n").first || content
          title = title[0..49] if title.length > 50
          title.strip
        end

        def generate_path(metadata)
          require_relative "../molecules/file_namer"
          Molecules::FileNamer.new(@config).generate(metadata)
        end

        def ensure_directory_exists(path)
          dir = File.dirname(path)
          FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
        end

        def format_idea(content, metadata)
          template = @config["template"] ||
                     "# Idea\n\n%{content}\n\n---\nCaptured: %{timestamp}"

          # Get author from settings or environment
          author = metadata[:author] ||
                   @config.dig("author", "name") ||
                   ENV["USER"] ||
                   "unknown"

          # Support both %{var} and #{var} syntax for compatibility
          template.gsub(/%{(\w+)}|#\{(\w+)\}/) do |match|
            key = (Regexp.last_match[1] || Regexp.last_match[2]).to_sym
            case key
            when :content
              content
            when :timestamp
              metadata[:timestamp]
            when :title
              metadata[:title]
            when :tags
              metadata[:tags] || ""
            when :author
              author
            else
              match
            end
          end
        end

        def timestamp_format
          @config.dig("file_naming", "timestamp_format") ||
            @config.dig("formatting", "timestamp_format") ||
            "%Y-%m-%d %H:%M:%S"
        end
      end
    end
  end
end