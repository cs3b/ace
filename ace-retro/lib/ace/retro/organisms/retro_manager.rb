# frozen_string_literal: true

require "yaml"
require_relative "../atoms/retro_frontmatter_defaults"
require_relative "../molecules/retro_config_loader"
require_relative "../molecules/retro_scanner"
require_relative "../molecules/retro_resolver"
require_relative "../molecules/retro_loader"
require_relative "../molecules/retro_creator"
require_relative "../molecules/retro_mover"

module Ace
  module Retro
    module Organisms
      # Orchestrates all retro CRUD operations.
      # Entry point for retro management with config-driven root directory.
      class RetroManager
        attr_reader :last_list_total, :last_folder_counts

        # @param root_dir [String, nil] Override root directory for retros
        # @param config [Hash, nil] Override configuration
        def initialize(root_dir: nil, config: nil)
          @config = config || load_config
          @root_dir = root_dir || resolve_root_dir
        end

        # Create a new retro
        # @param title [String] Retro title
        # @param type [String, nil] Retro type (standard, conversation-analysis, self-review)
        # @param tags [Array<String>] Tags
        # @param move_to [String, nil] Target folder
        # @return [Retro] Created retro
        def create(title, type: nil, tags: [], move_to: nil)
          ensure_root_dir
          creator = Molecules::RetroCreator.new(root_dir: @root_dir, config: @config)
          creator.create(title, type: type, tags: tags, move_to: move_to)
        end

        # Show (load) a single retro by reference
        # @param ref [String] Full ID (6 chars) or suffix shortcut (3 chars)
        # @return [Retro, nil] Loaded retro or nil if not found
        def show(ref)
          resolver = Molecules::RetroResolver.new(@root_dir)
          scan_result = resolver.resolve(ref)
          return nil unless scan_result

          loader = Molecules::RetroLoader.new
          loader.load(scan_result.dir_path,
            id: scan_result.id,
            special_folder: scan_result.special_folder)
        end

        # List retros with optional filtering
        # @param status [String, nil] Filter by status
        # @param type [String, nil] Filter by type
        # @param in_folder [String, nil] Filter by special folder (default: "next" = root items only)
        # @param tags [Array<String>] Filter by tags (any match)
        # @return [Array<Retro>] List of retros
        def list(status: nil, type: nil, in_folder: "next", tags: [])
          scanner = Molecules::RetroScanner.new(@root_dir)
          scan_results = scanner.scan_in_folder(in_folder)
          @last_list_total = scanner.last_scan_total
          @last_folder_counts = scanner.last_folder_counts

          loader = Molecules::RetroLoader.new
          retros = scan_results.filter_map do |sr|
            loader.load(sr.dir_path, id: sr.id, special_folder: sr.special_folder)
          end

          retros = retros.select { |r| r.status == status } if status
          retros = retros.select { |r| r.type == type } if type
          retros = filter_by_tags(retros, tags) if tags.any?

          retros
        end

        # Update a retro's fields and optionally move to a folder.
        # @param ref [String] Retro reference
        # @param set [Hash] Fields to set (key => value)
        # @param add [Hash] Fields to add to (for arrays like tags)
        # @param remove [Hash] Fields to remove from (for arrays)
        # @param move_to [String, nil] Target folder to move to (archive, maybe, next/root//)
        # @return [Retro, nil] Updated retro or nil if not found
        def update(ref, set: {}, add: {}, remove: {}, move_to: nil)
          scan_result = resolve_scan_result(ref)
          return nil unless scan_result

          loader = Molecules::RetroLoader.new
          retro = loader.load(scan_result.dir_path,
            id: scan_result.id,
            special_folder: scan_result.special_folder)
          return nil unless retro

          # Apply field updates if any
          has_field_updates = [set, add, remove].any? { |h| h && !h.empty? }
          update_retro_file(retro, set: set, add: add, remove: remove) if has_field_updates

          # Apply move if requested
          current_path = retro.path
          current_special = retro.special_folder
          if move_to
            mover = Molecules::RetroMover.new(@root_dir)
            new_path = if Ace::Support::Items::Atoms::SpecialFolderDetector.move_to_root?(move_to)
              mover.move_to_root(retro)
            else
              archive_date = parse_archive_date(retro)
              mover.move(retro, to: move_to, date: archive_date)
            end
            current_path = new_path
            current_special = Ace::Support::Items::Atoms::SpecialFolderDetector.detect_in_path(
              new_path, root: @root_dir
            )
          end

          # Reload and return updated retro
          loader.load(current_path, id: retro.id, special_folder: current_special)
        end

        # Get the root directory
        # @return [String] Absolute path to retros root
        attr_reader :root_dir

        private

        def load_config
          gem_root = File.expand_path("../../../..", __dir__)
          # lib/ace/retro/organisms/ → 4 levels up to gem root
          Molecules::RetroConfigLoader.load(gem_root: gem_root)
        end

        def resolve_root_dir
          Molecules::RetroConfigLoader.root_dir(@config)
        end

        def ensure_root_dir
          require "fileutils"
          FileUtils.mkdir_p(@root_dir) unless Dir.exist?(@root_dir)
        end

        def resolve_scan_result(ref)
          resolver = Molecules::RetroResolver.new(@root_dir)
          resolver.resolve(ref)
        end

        def filter_by_tags(retros, tags)
          return retros if tags.empty?

          retros.select do |retro|
            tags.any? { |tag| retro.tags.include?(tag) }
          end
        end

        def update_retro_file(retro, set:, add:, remove:)
          content = File.read(retro.file_path)
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
          tmp_path = "#{retro.file_path}.tmp.#{Process.pid}"
          File.write(tmp_path, new_content)
          File.rename(tmp_path, retro.file_path)
        ensure
          begin
            File.unlink(tmp_path) if tmp_path && File.exist?(tmp_path)
          rescue
            nil
          end
        end

        # Extract archive date from retro frontmatter, falling back to Time.now
        def parse_archive_date(retro)
          raw = retro.metadata["completed_at"] || retro.created_at
          return nil unless raw

          case raw
          when Time then raw
          when DateTime then raw.to_time
          else begin
            Time.parse(raw.to_s)
          rescue
            nil
          end
          end
        end
      end
    end
  end
end
