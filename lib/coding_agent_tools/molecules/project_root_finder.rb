# frozen_string_literal: true

require 'pathname'
require_relative '../atoms/path_sanitizer'

module CodingAgentTools
  module Molecules
    # ProjectRootFinder locates the project root directory
    # This is a molecule - it performs a focused operation using atoms
    class ProjectRootFinder
      def initialize(path_sanitizer: Atoms::PathSanitizer)
        @path_sanitizer = path_sanitizer
      end

      # Find project root by looking for .claude/commands directory
      # @param start_path [String, Pathname] Starting directory (default: current)
      # @return [Pathname] Project root path
      def find(start_path: Dir.pwd)
        current = normalize_path(start_path)
        
        # Traverse up the directory tree
        while current.parent != current
          claude_dir = current / '.claude' / 'commands'
          return current if claude_dir.directory?
          
          current = current.parent
        end
        
        # Fallback to start directory if .claude/commands doesn't exist
        normalize_path(start_path)
      end

      # Find project root by looking for multiple possible markers
      # @param start_path [String, Pathname] Starting directory
      # @param markers [Array<String>] Directory/file markers to search for
      # @return [Pathname] Project root path
      def find_by_markers(start_path: Dir.pwd, markers: ['.claude/commands', '.git', 'Gemfile'])
        current = normalize_path(start_path)
        
        while current.parent != current
          markers.each do |marker|
            marker_path = current / marker
            return current if marker_path.exist?
          end
          
          current = current.parent
        end
        
        # Fallback to start directory if no markers found
        normalize_path(start_path)
      end

      # Check if a directory is a valid project root
      # @param path [String, Pathname] Directory to check
      # @return [Boolean] true if valid project root
      def valid_project_root?(path)
        return false unless @path_sanitizer.safe?(path)
        
        pathname = normalize_path(path)
        return false unless pathname.directory?
        
        # Check for .claude/commands directory
        claude_commands = pathname / '.claude' / 'commands'
        claude_commands.directory?
      end

      # Find the nearest parent directory that exists
      # @param path [String, Pathname] Starting path
      # @return [Pathname] Nearest existing parent directory
      def find_existing_parent(path)
        current = normalize_path(path)
        
        until current.exist? || current.root?
          current = current.parent
        end
        
        current.exist? ? current : Pathname.pwd
      end

      private

      def normalize_path(path)
        @path_sanitizer.normalize(path).expand_path
      end
    end
  end
end