# frozen_string_literal: true

require "fileutils"
require "time"
require_relative "../atoms/idea_id_formatter"
require_relative "../atoms/idea_file_pattern"
require_relative "../atoms/idea_frontmatter_defaults"
require_relative "../atoms/slug_sanitizer_adapter"
require_relative "idea_loader"
require_relative "idea_llm_enhancer"
require_relative "idea_clipboard_reader"

module Ace
  module Idea
    module Molecules
      # Creates new ideas with b36ts IDs, folder/file creation.
      # Supports --clipboard, --llm-enhance, and --move-to options.
      class IdeaCreator
        # @param root_dir [String] Root directory for ideas
        # @param config [Hash] Configuration hash
        def initialize(root_dir:, config: {})
          @root_dir = root_dir
          @config = config
        end

        # Create a new idea
        # @param content [String] Raw idea content/text
        # @param title [String, nil] Optional title (extracted from content if nil)
        # @param tags [Array<String>] Tags for the idea
        # @param move_to [String, nil] Target folder for the idea
        # @param clipboard [Boolean] Capture from system clipboard
        # @param llm_enhance [Boolean] Enhance with LLM
        # @param time [Time] Creation time (default: now)
        # @return [Idea] Created idea object
        def create(content = nil, title: nil, tags: [], move_to: nil,
          clipboard: false, llm_enhance: false, time: Time.now.utc)
          # Step 1: Gather content
          body, attachments_to_save = gather_content(content, clipboard: clipboard)

          if body.nil? || body.strip.empty?
            raise ArgumentError, "No content provided. Provide text or use --clipboard."
          end

          # Step 2: Optionally enhance with LLM
          enhanced_body = if llm_enhance
            enhance_with_llm(body, config: @config)
          else
            body
          end

          # Step 3: Generate ID and slugs
          id = Atoms::IdeaIdFormatter.generate(time)
          slug_title = title || extract_title(enhanced_body)
          folder_slug = generate_folder_slug(slug_title)
          file_slug = generate_file_slug(slug_title)

          # Step 4: Determine target directory
          target_dir = determine_target_dir(move_to)
          FileUtils.mkdir_p(target_dir)

          # Step 5: Create idea folder (ensure unique name if ID collision occurs)
          folder_name, _ = unique_folder_name(id, folder_slug, target_dir)
          idea_dir = File.join(target_dir, folder_name)
          FileUtils.mkdir_p(idea_dir)

          # Step 6: Handle attachments
          if attachments_to_save.any?
            enhanced_body = save_attachments_and_inject_refs(attachments_to_save, idea_dir, enhanced_body)
          end

          # Step 7: Write spec file
          effective_title = title || extract_title(enhanced_body) || "Untitled Idea"
          frontmatter = Atoms::IdeaFrontmatterDefaults.build(
            id: id,
            title: effective_title,
            tags: tags,
            status: "pending",
            created_at: time
          )

          file_content = build_file_content(frontmatter, enhanced_body, effective_title)
          spec_filename = Atoms::IdeaFilePattern.spec_filename(id, file_slug)
          spec_file = File.join(idea_dir, spec_filename)
          File.write(spec_file, file_content)

          # Step 8: Load and return the created idea
          loader = IdeaLoader.new
          special_folder = Ace::Support::Items::Atoms::SpecialFolderDetector.detect_in_path(
            idea_dir, root: @root_dir
          )
          loader.load(idea_dir, id: id, special_folder: special_folder)
        end

        private

        def gather_content(content, clipboard: false)
          attachments = []

          if clipboard
            clipboard_result = IdeaClipboardReader.read
            unless clipboard_result[:success]
              raise ArgumentError, clipboard_result[:error]
            end

            clipboard_content = clipboard_result[:content]
            clipboard_attachments = clipboard_result[:attachments] || []

            # Merge clipboard content with provided content
            if content.nil? || content.strip.empty?
              content = clipboard_content
            elsif clipboard_content && !clipboard_content.strip.empty?
              content = "#{content}\n\n#{clipboard_content}"
            end

            attachments = clipboard_attachments
          end

          [content, attachments]
        end

        def enhance_with_llm(content, config: {})
          enhancer = IdeaLlmEnhancer.new(config: config)
          result = enhancer.enhance(content)

          if result[:success]
            result[:content]
          else
            # Fallback to original content on LLM failure
            content
          end
        end

        # Ensure unique folder name when the same b36ts ID is generated within the
        # same 2-second window. If the candidate folder already exists, appends a
        # numeric counter to the slug: {id}-{slug}-2, {id}-{slug}-3, etc.
        # @return [Array<String>] [folder_name, effective_slug]
        def unique_folder_name(id, slug, target_dir)
          folder_name = Atoms::IdeaFilePattern.folder_name(id, slug)
          candidate_dir = File.join(target_dir, folder_name)

          return [folder_name, slug] unless Dir.exist?(candidate_dir)

          counter = 2
          loop do
            unique_slug = "#{slug}-#{counter}"
            folder_name = Atoms::IdeaFilePattern.folder_name(id, unique_slug)
            candidate_dir = File.join(target_dir, folder_name)
            break [folder_name, unique_slug] unless Dir.exist?(candidate_dir)

            counter += 1
          end
        end

        def generate_folder_slug(title)
          sanitized = Ace::Support::Items::Atoms::SlugSanitizer.sanitize(title.to_s)
          words = sanitized.split("-")
          words.take(5).join("-").then { |s| s.empty? ? "idea" : s }
        end

        def generate_file_slug(title)
          sanitized = Ace::Support::Items::Atoms::SlugSanitizer.sanitize(title.to_s)
          words = sanitized.split("-")
          words.take(7).join("-").then { |s| s.empty? ? "idea" : s }
        end

        def extract_title(content)
          return nil if content.nil? || content.strip.empty?

          # Try to get first heading
          match = content.match(/^#\s+(.+)$/)
          return match[1].strip if match

          # Fall back to first line (max 50 chars)
          first_line = content.split("\n").first&.strip
          return nil if first_line.nil? || first_line.empty?

          (first_line.length > 50) ? first_line[0..49] : first_line
        end

        def determine_target_dir(move_to)
          if move_to
            if Ace::Support::Items::Atoms::SpecialFolderDetector.virtual_filter?(move_to)
              raise ArgumentError, "Cannot move to virtual filter '#{move_to}' — it is not a physical folder"
            end
            normalized = Ace::Support::Items::Atoms::SpecialFolderDetector.normalize(move_to)
            candidate = File.expand_path(File.join(@root_dir, normalized))
            root_real = File.expand_path(@root_dir)
            unless candidate.start_with?(root_real + File::SEPARATOR) || candidate == root_real
              raise ArgumentError, "Path traversal detected in --move-to option"
            end
            candidate
          else
            @root_dir
          end
        end

        def save_attachments_and_inject_refs(attachments, idea_dir, content)
          refs = []

          attachments.each do |attachment|
            next unless attachment[:source_path] || attachment[:data]

            raw_name = attachment[:filename] || File.basename(attachment[:source_path].to_s)
            filename = File.basename(raw_name.to_s)
            if filename.empty? || filename.include?("/") || filename.include?("\0")
              warn "Warning: Skipping attachment with unsafe filename: #{raw_name.inspect}"
              next
            end
            dest_path = File.join(idea_dir, filename)

            if attachment[:source_path] && File.exist?(attachment[:source_path])
              FileUtils.cp(attachment[:source_path], dest_path)
            elsif attachment[:data]
              File.binwrite(dest_path, attachment[:data])
            end

            # Add markdown reference based on type
            refs << case attachment[:type]
            when :image
              "![#{filename}](#{filename})"
            else
              "[#{filename}](#{filename})"
            end
          rescue => e
            warn "Warning: Failed to save attachment #{filename}: #{e.message}"
          end

          if refs.any?
            "#{content}\n\n## Attachments\n\n#{refs.join("\n")}"
          else
            content
          end
        end

        def build_file_content(frontmatter, body, title)
          fm_str = Atoms::IdeaFrontmatterDefaults.serialize(frontmatter)

          # Check if body already has a title heading
          if body.match?(/^#\s+/)
            "#{fm_str}\n\n#{body}\n"
          else
            "#{fm_str}\n\n# #{title}\n\n#{body}\n"
          end
        end
      end
    end
  end
end
