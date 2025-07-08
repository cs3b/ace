# frozen_string_literal: true

require "pathname"

module CodingAgentTools
  module Atoms
    module CodeQuality
      # Atom for resolving paths relative to project root
      # Enables running commands from any directory
      class PathResolver
        attr_reader :project_root

        def initialize(project_root: nil)
          @project_root = project_root || detect_project_root
        end

        def resolve(path)
          return path if Pathname.new(path).absolute?

          # Try relative to current directory first
          current_relative = File.expand_path(path)
          return current_relative if File.exist?(current_relative)

          # Try relative to project root
          root_relative = File.join(project_root, path)
          return root_relative if File.exist?(root_relative)

          # Return the path as-is if not found
          path
        end

        def relative_to_root(path)
          absolute_path = Pathname.new(File.expand_path(path))
          root_path = Pathname.new(project_root)

          begin
            absolute_path.relative_path_from(root_path).to_s
          rescue ArgumentError
            # If we can't create relative path, return absolute
            absolute_path.to_s
          end
        end

        def in_project?(path)
          absolute_path = File.expand_path(path)
          absolute_path.start_with?(project_root)
        end

        private

        def detect_project_root
          # Use ProjectRootDetector if available
          if defined?(CodingAgentTools::Atoms::ProjectRootDetector)
            detector = CodingAgentTools::Atoms::ProjectRootDetector.new
            return detector.root_path
          end

          # Fallback to manual detection
          markers = [".git", "Gemfile", ".coding-agent", "coding_agent_tools.gemspec"]

          current = Pathname.pwd
          until current.root?
            markers.each do |marker|
              if current.join(marker).exist?
                return current.to_s
              end
            end
            current = current.parent
          end

          Dir.pwd
        end
      end
    end
  end
end
