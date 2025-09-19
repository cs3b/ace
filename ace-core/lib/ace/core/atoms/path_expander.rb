# frozen_string_literal: true

require "pathname"

module Ace
  module Core
    module Atoms
      # Pure path expansion and manipulation functions
      module PathExpander
        module_function

        # Expand path with tilde and environment variables
        # @param path [String] Path to expand
        # @return [String] Expanded absolute path
        def expand(path)
          return nil if path.nil?

          expanded = path.to_s.dup

          # Expand environment variables
          expanded.gsub!(/\$([A-Z_][A-Z0-9_]*)/i) do |match|
            ENV[match[1..-1]] || match
          end

          # Expand tilde
          expanded = File.expand_path(expanded)

          expanded
        end

        # Join path components safely
        # @param parts [Array<String>] Path parts to join
        # @return [String] Joined path
        def join(*parts)
          parts = parts.flatten.compact.map(&:to_s)
          return "" if parts.empty?

          File.join(*parts)
        end

        # Get directory name from path
        # @param path [String] File path
        # @return [String] Directory path
        def dirname(path)
          return nil if path.nil?

          File.dirname(path.to_s)
        end

        # Get base name from path
        # @param path [String] File path
        # @return [String] Base name
        def basename(path, suffix = nil)
          return nil if path.nil?

          if suffix
            File.basename(path.to_s, suffix)
          else
            File.basename(path.to_s)
          end
        end

        # Check if path is absolute
        # @param path [String] Path to check
        # @return [Boolean] true if absolute path
        def absolute?(path)
          return false if path.nil?

          Pathname.new(path.to_s).absolute?
        end

        # Make path relative to base
        # @param path [String] Path to make relative
        # @param base [String] Base path
        # @return [String] Relative path
        def relative(path, base)
          return nil if path.nil? || base.nil?

          path_obj = Pathname.new(expand(path))
          base_obj = Pathname.new(expand(base))

          path_obj.relative_path_from(base_obj).to_s
        rescue ArgumentError
          # Paths are on different drives or one is relative
          path
        end

        # Normalize path (remove .., ., duplicates slashes)
        # @param path [String] Path to normalize
        # @return [String] Normalized path
        def normalize(path)
          return nil if path.nil?

          Pathname.new(path.to_s).cleanpath.to_s
        end
      end
    end
  end
end