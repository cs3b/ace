# frozen_string_literal: true

require "fileutils"
require "time"
require_relative "../molecules/git_executor"
require_relative "../molecules/idea_enhancer"
require_relative "../atoms/clipboard_reader"
require_relative "../molecules/attachment_manager"

module Ace
  module Taskflow
    module Organisms
      class IdeaWriter
        def initialize(config = nil)
          @config = config || load_config
          @debug = ENV["DEBUG"] == "true"
        end

        def write(content, options = {})
          # Merge options with config defaults
          options = merge_options_with_config(options)

          # Process clipboard if requested
          clipboard_result = process_clipboard(options)

          # Merge content with clipboard
          merged_content, attachment_files = merge_content_with_clipboard(
            content,
            clipboard_result,
            options
          )

          # Prepare initial metadata
          metadata = prepare_metadata(merged_content, options)
          metadata[:has_attachments] = attachment_files.any?
          debug_log("Initial metadata after prepare: #{metadata.inspect}")

          # Enhance content if requested (this may update metadata with suggested filename)
          enhanced_content = if should_enhance?(options)
                               enhance_idea(merged_content, metadata)
                             else
                               merged_content
                             end

          # If we have a suggested filename from LLM, use it as the title for file naming
          if metadata[:suggested_filename]
            metadata[:title] = metadata[:suggested_filename]
            debug_log("Using LLM suggested filename: #{metadata[:suggested_filename]}")
          elsif !metadata[:title]
            # Only extract title from content if no title was provided
            metadata[:title] = extract_title(enhanced_content)
          end

          debug_log("Final metadata title for filename: #{metadata[:title]}")

          # Generate file path (directory if attachments, file otherwise)
          path = generate_path(metadata)

          # Handle attachments if present
          if attachment_files.any?
            # Path is directory - create it and save attachments
            FileUtils.mkdir_p(path)

            # Use save_attachments for all types (handles images, files, RTF, HTML)
            attachment_result = Molecules::AttachmentManager.save_attachments(
              attachment_files,
              path
            )

            # Add file references to content
            enhanced_content += attachment_result[:references]

            # Warn about failed files
            attachment_result[:failed_files].each do |failure|
              puts "Warning: #{failure[:filename]} - #{failure[:error]}"
            end

            # Write idea.md in directory
            idea_file = File.join(path, "idea.md")
            formatted_content = format_idea(enhanced_content, metadata)
            File.write(idea_file, formatted_content)
          else
            # No attachments - write flat file
            ensure_directory_exists(path)
            formatted_content = format_idea(enhanced_content, metadata)
            File.write(path, formatted_content)
          end

          # Commit to git if requested
          if should_commit?(options)
            commit_idea(path, metadata)
          end

          path
        end

        private

        def process_clipboard(options)
          return { success: false } unless options[:clipboard]

          result = Atoms::ClipboardReader.read

          unless result[:success]
            puts "Error: #{result[:error]}"
            exit 1
          end

          result
        end

        def merge_content_with_clipboard(content, clipboard_result, options)
          # If clipboard wasn't requested or failed, return original content with no attachments
          return [content, []] unless clipboard_result[:success]

          clipboard_attachments = clipboard_result[:attachments] || []

          # Handle rich clipboard (macOS with images, files, RTF, etc.)
          if clipboard_result[:type] == :rich
            # Rich clipboard with attachments
            merged_text = if content.nil? || content.empty?
                            clipboard_result[:content] || ""
                          else
                            clipboard_result[:content] ? "#{content}\n\n#{clipboard_result[:content]}" : content
                          end
            return [merged_text, clipboard_attachments]
          end

          # Handle legacy file paths (text clipboard with file paths)
          if clipboard_result[:type] == :files
            # Convert file paths to attachment format for consistency
            file_attachments = clipboard_result[:files].map do |file_path|
              { type: :file, source_path: file_path, filename: File.basename(file_path) }
            end
            return [content, file_attachments]
          end

          # Clipboard has only text - merge with content
          if content.nil? || content.empty?
            # Use clipboard as sole content
            [clipboard_result[:content], []]
          else
            # Append clipboard text to content
            merged = "#{content}\n\n#{clipboard_result[:content]}"
            [merged, []]
          end
        end

        def load_config
          require "yaml"

          # Load taskflow config from .ace/taskflow directory
          config_paths = [
            File.join(Dir.pwd, ".ace", "taskflow", "config.yml"),
            File.join(Dir.home, ".ace", "taskflow", "config.yml")
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
          # Use suggested filename from LLM if available, otherwise extract from content
          if metadata[:suggested_filename] && !metadata[:title]
            metadata[:title] = metadata[:suggested_filename]
          end
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

        def merge_options_with_config(options)
          # Start with config defaults
          defaults = {
            git_commit: @config.dig("defaults", "git_commit") || false,
            llm_enhance: @config.dig("defaults", "llm_enhance") || false
          }

          # Merge with provided options (command-line flags override config)
          merged = defaults.dup
          merged[:git_commit] = options[:git_commit] unless options[:git_commit].nil?
          merged[:llm_enhance] = options[:llm_enhance] unless options[:llm_enhance].nil?
          merged[:clipboard] = options[:clipboard] unless options[:clipboard].nil?
          merged[:location] = options[:location] if options[:location]

          # Preserve metadata fields if provided
          merged[:title] = options[:title] if options[:title]
          merged[:timestamp] = options[:timestamp] if options[:timestamp]
          merged[:author] = options[:author] if options[:author]
          merged[:tags] = options[:tags] if options[:tags]
          merged[:note] = options[:note] if options[:note]

          merged
        end

        def should_commit?(options)
          options[:git_commit] == true
        end

        def should_enhance?(options)
          options[:llm_enhance] == true
        end

        def enhance_idea(content, metadata)
          enhancer = Molecules::IdeaEnhancer.new(debug: @debug, config: @config)
          context = {
            location: metadata[:location] || "active",
            timestamp: metadata[:timestamp],
            llm_model: @config.dig("defaults", "llm_model")
          }
          result = enhancer.enhance(content, context)

          # Return enhanced content or original if enhancement failed
          if result[:success]
            # Store filename suggestion in metadata if available
            metadata[:suggested_filename] = result[:filename] if result[:filename]
            result[:content]
          else
            debug_log("Enhancement failed, using original content: #{result[:error]}") if @debug
            content
          end
        end

        def commit_idea(path, metadata)
          executor = Molecules::GitExecutor.new(debug: @debug)

          # Build commit message
          title = metadata[:title] || "idea"
          location = determine_location_context(path)
          message = build_commit_message(title, location)

          # Execute commit
          result = executor.execute_commit(path, message)

          if result.success?
            puts "Git commit successful: #{result.message}" if @debug
          else
            puts "Warning: Git commit failed: #{result.error}"
          end

          result
        end

        def build_commit_message(title, location)
          # Format title for conventional commit subject line
          subject = title.strip
          subject = subject[0].downcase + subject[1..-1] if subject.length > 0
          subject = subject.length > 40 ? "#{subject[0..37]}..." : subject

          if location.include?("backlog")
            "docs(backlog): add idea - #{subject}"
          elsif location =~ /v\.\d+\.\d+\.\d+/
            # Extract version from location (works for both active and specific releases)
            version = location.match(/v\.\d+\.\d+\.\d+/)[0]
            "docs(#{version}): add idea - #{subject}"
          else
            # Fallback to backlog if we can't determine version (shouldn't happen)
            "docs(backlog): add idea - #{subject}"
          end
        end

        def determine_location_context(path)
          # Extract location from path
          if path.include?("/backlog/")
            "backlog"
          elsif match = path.match(/\/(v\.\d+\.\d+\.\d+)\//)
            match[1]
          else
            "active"
          end
        end

        def debug_log(message)
          puts "Debug [IdeaWriter]: #{message}" if @debug
        end
      end
    end
  end
end