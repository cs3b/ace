# frozen_string_literal: true

require "time"
require "yaml"
require_relative "../atoms/retro_file_pattern"
require_relative "../atoms/retro_frontmatter_defaults"
require_relative "../models/retro"

# Shared atoms from ace-support-items
require "ace/support/items"

module Ace
  module Retro
    module Molecules
      # Loads a retro from its directory, parsing frontmatter + body,
      # and enumerating folder contents (reports, action-item files).
      class RetroLoader
        # Load a retro from a ScanResult
        # @param scan_result [ScanResult] Scan result pointing to the retro directory
        # @return [Retro, nil] Loaded retro or nil if load fails
        def self.from_scan_result(scan_result)
          new.load(scan_result.dir_path,
            id: scan_result.id,
            special_folder: scan_result.special_folder)
        end

        # Load a retro from a directory path
        # @param dir_path [String] Path to the retro directory
        # @param id [String, nil] Known ID (extracted from folder name if nil)
        # @param special_folder [String, nil] Known special folder
        # @return [Retro, nil] Loaded retro or nil
        def load(dir_path, id: nil, special_folder: nil)
          return nil unless Dir.exist?(dir_path)

          # Find the retro file
          retro_file = Dir.glob(File.join(dir_path, Atoms::RetroFilePattern::FILE_GLOB)).first
          return nil unless retro_file

          # Extract ID from folder name if not provided
          folder_name = File.basename(dir_path)
          id ||= extract_id(folder_name)

          # Parse the retro file
          content = File.read(retro_file)
          frontmatter, body = Ace::Support::Items::Atoms::FrontmatterParser.parse(content)

          # Enumerate folder contents (all non-.retro.md files in the directory)
          folder_contents = list_folder_contents(dir_path)

          # Extract title from frontmatter or body header
          title = frontmatter["title"] || Ace::Support::Items::Atoms::TitleExtractor.extract(body) || folder_name

          # Parse creation time
          created_at = parse_created_at(frontmatter["created_at"], id)

          # Extract known fields, preserve others in metadata
          known_keys = %w[id status title type tags created_at]
          extra_metadata = frontmatter.reject { |k, _| known_keys.include?(k) }

          Models::Retro.new(
            id: id || frontmatter["id"],
            status: frontmatter["status"] || "active",
            title: title,
            type: frontmatter["type"] || "standard",
            tags: Array(frontmatter["tags"]),
            content: body.to_s.strip,
            path: dir_path,
            file_path: retro_file,
            special_folder: special_folder,
            created_at: created_at,
            folder_contents: folder_contents,
            metadata: extra_metadata
          )
        rescue StandardError
          nil
        end

        private

        def extract_id(folder_name)
          match = folder_name.match(/^([0-9a-z]{6})/)
          match ? match[1] : nil
        end

        def list_folder_contents(dir_path)
          Dir.glob(File.join(dir_path, "*"))
            .select { |f| File.file?(f) }
            .reject { |f| f.end_with?(Atoms::RetroFilePattern::FILE_EXTENSION) }
            .map { |f| File.basename(f) }
            .reject { |name| name.start_with?(".") }
            .sort
        end

        def parse_created_at(value, id)
          return Time.now if value.nil?

          case value
          when Time then value
          when String
            begin
              Time.parse(value)
            rescue ArgumentError
              id ? decode_time_from_id(id) : Time.now
            end
          else
            Time.now
          end
        end

        def decode_time_from_id(id)
          require "ace/b36ts"
          Ace::B36ts.decode(id)
        rescue StandardError
          Time.now
        end
      end
    end
  end
end
