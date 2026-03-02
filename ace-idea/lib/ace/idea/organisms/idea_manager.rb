# frozen_string_literal: true

require "yaml"
require_relative "../atoms/idea_frontmatter_defaults"
require_relative "../molecules/idea_config_loader"
require_relative "../molecules/idea_scanner"
require_relative "../molecules/idea_resolver"
require_relative "../molecules/idea_loader"
require_relative "../molecules/idea_creator"
require_relative "../molecules/idea_mover"

module Ace
  module Idea
    module Organisms
      # Orchestrates all idea CRUD operations.
      # Entry point for idea management with config-driven root directory.
      class IdeaManager
        attr_reader :last_list_total

        # @param root_dir [String, nil] Override root directory for ideas
        # @param config [Hash, nil] Override configuration
        def initialize(root_dir: nil, config: nil)
          @config = config || load_config
          @root_dir = root_dir || resolve_root_dir
        end

        # Create a new idea
        # @param content [String, nil] Idea content
        # @param title [String, nil] Optional explicit title
        # @param tags [Array<String>] Tags
        # @param move_to [String, nil] Target folder
        # @param clipboard [Boolean] Capture from clipboard
        # @param llm_enhance [Boolean] Enhance with LLM
        # @return [Idea] Created idea
        def create(content = nil, title: nil, tags: [], move_to: nil,
                   clipboard: false, llm_enhance: false)
          ensure_root_dir
          creator = Molecules::IdeaCreator.new(root_dir: @root_dir, config: @config)
          creator.create(content, title: title, tags: tags, move_to: move_to,
                         clipboard: clipboard, llm_enhance: llm_enhance)
        end

        # Create an idea from clipboard
        # @param llm_enhance [Boolean] Enhance with LLM after clipboard capture
        # @param move_to [String, nil] Target folder
        # @return [Idea] Created idea
        def create_from_clipboard(llm_enhance: false, move_to: nil)
          create(nil, clipboard: true, llm_enhance: llm_enhance, move_to: move_to)
        end

        # Show (load) a single idea by reference
        # @param ref [String] Full ID (6 chars) or suffix shortcut (3 chars)
        # @return [Idea, nil] Loaded idea or nil if not found
        def show(ref)
          resolver = Molecules::IdeaResolver.new(@root_dir)
          scan_result = resolver.resolve(ref)
          return nil unless scan_result

          loader = Molecules::IdeaLoader.new
          loader.load(scan_result.dir_path,
            id: scan_result.id,
            special_folder: scan_result.special_folder)
        end

        # List ideas with optional filtering
        # @param status [String, nil] Filter by status
        # @param in_folder [String, nil] Filter by special folder (default: "next" = root items only)
        # @param tags [Array<String>] Filter by tags (any match)
        # @param root [String, nil] Override root path (subpath within root_dir)
        # @param filters [Array<String>, nil] Generic filter strings (e.g., ["status:pending", "tags:ux|design"])
        # @return [Array<Idea>] List of ideas
        def list(status: nil, in_folder: "next", tags: [], root: nil, filters: nil)
          scan_root = if root
            candidate = File.expand_path(File.join(@root_dir, root))
            root_real = File.expand_path(@root_dir)
            unless candidate.start_with?(root_real + File::SEPARATOR) || candidate == root_real
              raise ArgumentError, "Path traversal detected in --root option"
            end
            candidate
          else
            @root_dir
          end
          scanner = Molecules::IdeaScanner.new(scan_root)
          scan_results = scanner.scan_in_folder(in_folder)
          @last_list_total = scanner.last_scan_total

          loader = Molecules::IdeaLoader.new
          ideas = scan_results.filter_map do |sr|
            loader.load(sr.dir_path, id: sr.id, special_folder: sr.special_folder)
          end

          # Apply legacy filters (backward-compatible)
          ideas = ideas.select { |i| i.status == status } if status
          ideas = filter_by_tags(ideas, tags) if tags.any?

          # Apply generic --filter specs via FilterApplier
          if filters && !filters.empty?
            filter_specs = Ace::Support::Items::Atoms::FilterParser.parse(filters)
            ideas = Ace::Support::Items::Molecules::FilterApplier.apply(ideas, filter_specs, value_accessor: method(:idea_value_accessor))
          end

          ideas
        end

        # Update an idea's fields
        # @param ref [String] Idea reference
        # @param set [Hash] Fields to set (key => value)
        # @param add [Hash] Fields to add to (for arrays like tags)
        # @param remove [Hash] Fields to remove from (for arrays)
        # @return [Idea, nil] Updated idea or nil if not found
        def update(ref, set: {}, add: {}, remove: {})
          scan_result = resolve_scan_result(ref)
          return nil unless scan_result

          loader = Molecules::IdeaLoader.new
          idea = loader.load(scan_result.dir_path,
            id: scan_result.id,
            special_folder: scan_result.special_folder)
          return nil unless idea

          update_idea_file(idea, set: set, add: add, remove: remove)
          # Reload and return updated idea
          loader.load(idea.path, id: idea.id, special_folder: idea.special_folder)
        end

        # Move an idea to a different folder
        # @param ref [String] Idea reference
        # @param to [String] Target folder
        # @return [Idea, nil] Moved idea or nil if not found
        def move(ref, to:)
          scan_result = resolve_scan_result(ref)
          return nil unless scan_result

          loader = Molecules::IdeaLoader.new
          idea = loader.load(scan_result.dir_path,
            id: scan_result.id,
            special_folder: scan_result.special_folder)
          return nil unless idea

          mover = Molecules::IdeaMover.new(@root_dir)
          new_path = if to == "root" || to == "/"
            mover.move_to_root(idea)
          else
            archive_date = parse_archive_date(idea)
            mover.move(idea, to: to, date: archive_date)
          end

          # Detect new special folder
          new_special = Ace::Support::Items::Atoms::SpecialFolderDetector.detect_in_path(
            new_path, root: @root_dir
          )
          loader.load(new_path, id: idea.id, special_folder: new_special)
        end

        # Get the root directory
        # @return [String] Absolute path to ideas root
        def root_dir
          @root_dir
        end

        private

        def load_config
          gem_root = File.expand_path("../../../..", __dir__)
          Molecules::IdeaConfigLoader.load(gem_root: gem_root)
        end

        def resolve_root_dir
          Molecules::IdeaConfigLoader.root_dir(@config)
        end

        def ensure_root_dir
          require "fileutils"
          FileUtils.mkdir_p(@root_dir) unless Dir.exist?(@root_dir)
        end

        def resolve_scan_result(ref)
          resolver = Molecules::IdeaResolver.new(@root_dir)
          resolver.resolve(ref)
        end

        def filter_by_tags(ideas, tags)
          return ideas if tags.empty?

          ideas.select do |idea|
            tags.any? { |tag| idea.tags.include?(tag) }
          end
        end

        def update_idea_file(idea, set:, add:, remove:)
          content = File.read(idea.file_path)
          frontmatter, body = Ace::Support::Items::Atoms::FrontmatterParser.parse(content)
          # Strip leading newline from body so rebuild doesn't double-space
          body = body.sub(/\A\n/, "")

          # Apply set operations
          set.each { |k, v| frontmatter[k.to_s] = v }

          # Apply add operations (for arrays)
          add.each do |k, v|
            key = k.to_s
            current = Array(frontmatter[key])
            values = Array(v)
            frontmatter[key] = (current + values).uniq
          end

          # Apply remove operations (for arrays)
          remove.each do |k, v|
            key = k.to_s
            next unless frontmatter[key].is_a?(Array)

            values = Array(v)
            frontmatter[key] = frontmatter[key] - values
          end

          # Write back atomically (temp + rename to avoid partial writes)
          new_content = Ace::Support::Items::Atoms::FrontmatterSerializer.rebuild(frontmatter, body)
          tmp_path = "#{idea.file_path}.tmp.#{Process.pid}"
          File.write(tmp_path, new_content)
          File.rename(tmp_path, idea.file_path)
        ensure
          File.unlink(tmp_path) if tmp_path && File.exist?(tmp_path) rescue nil
        end

        # Extract archive date from idea frontmatter, falling back to Time.now
        def parse_archive_date(idea)
          raw = idea.metadata["completed_at"] || idea.metadata["created_at"]
          return nil unless raw

          case raw
          when Time then raw
          when DateTime then raw.to_time
          else Time.parse(raw.to_s) rescue nil
          end
        end

        # Value accessor for FilterApplier — reads from Idea model attributes and metadata
        def idea_value_accessor(item, key)
          case key
          when "status" then item.status
          when "title" then item.title
          when "tags" then item.tags
          when "id" then item.id
          when "special_folder" then item.special_folder
          else
            item.metadata[key] || item.metadata[key.to_sym] if item.respond_to?(:metadata) && item.metadata
          end
        end
      end
    end
  end
end
