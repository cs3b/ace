# frozen_string_literal: true

module Ace
  module Nav
    module Atoms
      # Normalizes and expands paths
      class PathNormalizer
        def normalize(path)
          return nil if path.nil? || path.empty?

          # Expand home directory
          path = File.expand_path(path) if path.start_with?("~")

          # Resolve relative paths
          path = File.expand_path(path) unless path.start_with?("/")

          path
        end

        def join_paths(*parts)
          File.join(*parts.compact)
        end

        def dirname(path)
          File.dirname(path)
        end

        def basename(path, suffix = nil)
          suffix ? File.basename(path, suffix) : File.basename(path)
        end

        def extname(path)
          File.extname(path)
        end

        def exists?(path)
          File.exist?(path)
        end

        def directory?(path)
          File.directory?(path)
        end

        def file?(path)
          File.file?(path)
        end
      end
    end
  end
end