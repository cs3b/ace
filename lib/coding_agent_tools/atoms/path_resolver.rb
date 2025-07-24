# frozen_string_literal: true

module CodingAgentTools::Atoms
  # Atom for resolving file paths from relative links
  # Handles both absolute and relative path resolution
  class PathResolver
    # Remove anchor fragment from link
    def remove_anchor(link)
      link.split("#").first
    end

    # Check if path is absolute (starts with /)
    def absolute_path?(path)
      path.start_with?("/")
    end

    # Resolve a link relative to a base file path
    def resolve_link(from_file, link)
      # Remove anchors first
      clean_link = remove_anchor(link)

      # Handle absolute paths from root by removing leading slash
      if absolute_path?(clean_link)
        return clean_link.sub(/^\//, "")
      end

      # Handle relative paths
      from_dir = File.dirname(from_file)
      resolved = File.expand_path(clean_link, from_dir)

      # Convert back to relative path from current working directory
      resolved.sub("#{Dir.pwd}/", "")
    end

    # Normalize path by removing redundant elements
    def normalize_path(path)
      File.expand_path(path).sub("#{Dir.pwd}/", "")
    end

    # Check if a file exists at the given path
    def file_exists?(path)
      return false unless path
      File.exist?(path) && File.file?(path)
    end

    # Get relative path from project root
    def relative_from_root(path)
      File.expand_path(path).sub("#{Dir.pwd}/", "")
    end
  end
end
