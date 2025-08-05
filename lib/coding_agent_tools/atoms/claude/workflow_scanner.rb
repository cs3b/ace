# frozen_string_literal: true

require 'pathname'

module CodingAgentTools
  module Atoms
    module Claude
      # Scans workflow directory for .wf.md files
      # This is a pure utility with no dependencies on other components
      class WorkflowScanner
        # Scan workflow directory for .wf.md files
        # @param workflow_dir [Pathname] Directory to scan
        # @param pattern [String, nil] Optional glob pattern (e.g., "create-*")
        # @return [Array<String>] List of workflow names (without .wf.md extension)
        def self.scan(workflow_dir, pattern = nil)
          return [] unless workflow_dir.exist? && workflow_dir.directory?

          glob_pattern = if pattern
                           # Support glob patterns
            if pattern.include?('*')
              File.join(workflow_dir, "#{pattern}.wf.md")
            else
              # Single workflow name
              File.join(workflow_dir, "#{pattern}.wf.md")
            end
          else
                           # All workflows
            File.join(workflow_dir, '*.wf.md')
          end

          # If pattern is specific and file doesn't exist, return empty
          if pattern && !pattern.include?('*')
            path = workflow_dir / "#{pattern}.wf.md"
            return [] unless path.exist?
            return [pattern]
          end

          # Scan for matching files
          Dir.glob(glob_pattern).map do |path|
            File.basename(path, '.wf.md')
          end.sort
        end
      end
    end
  end
end
