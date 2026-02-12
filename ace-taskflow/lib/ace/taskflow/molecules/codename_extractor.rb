# frozen_string_literal: true

module Ace
  module Taskflow
    module Molecules
      # Extract codename from release directory's main markdown file
      # Reads the first header (e.g., "# v.0.9.0 Mono-Repo Multiple Gems")
      # and extracts the descriptive part after the version
      #
      # This is a pure molecule for extracting codenames, enabling:
      # - Independent unit testing of regex and header parsing logic
      # - Reuse across different contexts (not just TaskflowContextLoader)
      #
      # Requirements:
      # - Release directory must contain a README.md file (case-insensitive)
      # - Other markdown files are ignored to prevent extracting from arbitrary sources
      # - The README.md should have a first-level header with version and codename
      #   Format: "# v.X.Y.Z Codename Here" (version prefix is optional)
      class CodenameExtractor
        # Extract codename from a release directory path
        # @param release_path [String] Path to release directory
        # @return [String, nil] Codename or nil if not found
        def self.extract(release_path)
          new.extract(release_path)
        end

        # Extract codename from a release directory path
        # @param release_path [String] Path to release directory
        # @return [String, nil] Codename or nil if not found
        def extract(release_path)
          return nil unless release_path && File.directory?(release_path)

          main_file = find_main_file(release_path)
          return nil unless main_file

          extract_from_file(main_file)
        end

        private

        # Find the main markdown file in a release directory
        # Prefers README.md but falls back to first .md file for consistency
        # with StatsFormatter.extract_codename_from_path
        # @param release_path [String] Path to release directory
        # @return [String, nil] Path to main .md file or nil if not found
        def find_main_file(release_path)
          # Use case-insensitive glob to match both .md and .MD extensions
          md_files = Dir.glob(File.join(release_path, "*.[mM][dD]"))
          return nil if md_files.empty?

          # Prefer README.md (case-insensitive), fall back to first .md file
          md_files.find { |f| File.basename(f).downcase == "readme.md" } || md_files.first
        end

        # Extract codename from file content
        # @param file_path [String] Path to the markdown file
        # @return [String, nil] Codename or nil if not found
        def extract_from_file(file_path)
          content = File.read(file_path, encoding: "UTF-8")
          # Strip UTF-8 BOM if present (some editors add this)
          content = content.sub(/\A\xEF\xBB\xBF/, "")
          header = extract_first_header(content)
          return nil unless header

          extract_codename_from_header(header)
        rescue Errno::ENOENT, Errno::EACCES
          # File not found or permission denied - graceful fallback
          nil
        end

        # Extract the first markdown header from content
        # @param content [String] Markdown content
        # @return [String, nil] Header text or nil if not found
        def extract_first_header(content)
          match = content.match(/^#\s+(.+)$/)
          match ? match[1] : nil
        end

        # Extract codename from a header line
        # @param header [String] Header text (e.g., "v.0.9.0 Mono-Repo Multiple Gems")
        # @return [String] Codename or full header if no version pattern
        def extract_codename_from_header(header)
          # Extract the descriptive part after the version
          # e.g., "v.0.9.0 Mono-Repo Multiple Gems" -> "Mono-Repo Multiple Gems"
          if header.match(/^v\.\d+\.\d+\.\d+\s+(.+)$/)
            $1
          else
            header
          end
        end
      end
    end
  end
end
