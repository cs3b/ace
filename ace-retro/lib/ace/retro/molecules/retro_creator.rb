# frozen_string_literal: true

require "fileutils"
require "time"
require_relative "../atoms/retro_id_formatter"
require_relative "../atoms/retro_file_pattern"
require_relative "../atoms/retro_frontmatter_defaults"
require_relative "retro_loader"

module Ace
  module Retro
    module Molecules
      # Creates new retros with b36ts IDs, folder+file creation.
      # Supports --type, --task-ref, and --move-to options.
      class RetroCreator
        # @param root_dir [String] Root directory for retros
        # @param config [Hash] Configuration hash
        def initialize(root_dir:, config: {})
          @root_dir = root_dir
          @config = config
        end

        # Create a new retro
        # @param title [String] Retro title
        # @param type [String] Retro type (standard, conversation-analysis, self-review)
        # @param tags [Array<String>] Tags for the retro
        # @param task_ref [String, nil] Optional task reference
        # @param move_to [String, nil] Target folder for the retro
        # @param time [Time] Creation time (default: now)
        # @return [Retro] Created retro object
        def create(title, type: nil, tags: [], task_ref: nil, move_to: nil, time: Time.now.utc)
          raise ArgumentError, "Title is required" if title.nil? || title.strip.empty?

          effective_type = type || @config.dig("retro", "default_type") || "standard"

          # Generate ID and slugs
          id = Atoms::RetroIdFormatter.generate(time)
          folder_slug = generate_folder_slug(title)
          file_slug = generate_file_slug(title)

          # Determine target directory
          target_dir = determine_target_dir(move_to)
          FileUtils.mkdir_p(target_dir)

          # Create retro folder (ensure unique name if ID collision occurs)
          folder_name, folder_slug = unique_folder_name(id, folder_slug, target_dir)
          retro_dir = File.join(target_dir, folder_name)
          FileUtils.mkdir_p(retro_dir)

          # Build frontmatter
          frontmatter = Atoms::RetroFrontmatterDefaults.build(
            id: id,
            title: title,
            type: effective_type,
            tags: tags,
            status: "active",
            created_at: time,
            task_ref: task_ref
          )

          # Write retro file
          file_content = build_file_content(frontmatter, title, effective_type)
          retro_filename = Atoms::RetroFilePattern.retro_filename(id, file_slug)
          retro_file = File.join(retro_dir, retro_filename)
          File.write(retro_file, file_content)

          # Load and return the created retro
          loader = RetroLoader.new
          special_folder = Ace::Support::Items::Atoms::SpecialFolderDetector.detect_in_path(
            retro_dir, root: @root_dir
          )
          loader.load(retro_dir, id: id, special_folder: special_folder)
        end

        private

        # Ensure unique folder name when the same b36ts ID is generated within the
        # same 2-second window. If the candidate folder already exists, appends a
        # numeric counter to the slug: {id}-{slug}-2, {id}-{slug}-3, etc.
        # @return [Array<String>] [folder_name, effective_slug]
        def unique_folder_name(id, slug, target_dir)
          folder_name = Atoms::RetroFilePattern.folder_name(id, slug)
          candidate_dir = File.join(target_dir, folder_name)

          return [folder_name, slug] unless Dir.exist?(candidate_dir)

          counter = 2
          loop do
            unique_slug = "#{slug}-#{counter}"
            folder_name = Atoms::RetroFilePattern.folder_name(id, unique_slug)
            candidate_dir = File.join(target_dir, folder_name)
            break [folder_name, unique_slug] unless Dir.exist?(candidate_dir)

            counter += 1
          end
        end

        def generate_folder_slug(title)
          sanitized = Ace::Support::Items::Atoms::SlugSanitizer.sanitize(title.to_s)
          words = sanitized.split("-")
          words.take(5).join("-").then { |s| s.empty? ? "retro" : s }
        end

        def generate_file_slug(title)
          sanitized = Ace::Support::Items::Atoms::SlugSanitizer.sanitize(title.to_s)
          words = sanitized.split("-")
          words.take(7).join("-").then { |s| s.empty? ? "retro" : s }
        end

        def determine_target_dir(move_to)
          if move_to
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

        def build_file_content(frontmatter, title, type)
          fm_str = Atoms::RetroFrontmatterDefaults.serialize(frontmatter)

          body = retro_template(type)

          "#{fm_str}\n\n# #{title}\n\n#{body}\n"
        end

        def retro_template(type)
          case type
          when "conversation-analysis"
            <<~BODY
              ## Context

              ## Key Observations

              ## Patterns Identified

              ## Action Items
            BODY
          when "self-review"
            <<~BODY
              ## What I Did Well

              ## What I Could Improve

              ## Key Learnings

              ## Action Items
            BODY
          else # standard
            <<~BODY
              ## What Went Well

              ## What Could Be Improved

              ## Action Items
            BODY
          end
        end
      end
    end
  end
end
