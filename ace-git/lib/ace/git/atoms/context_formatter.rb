# frozen_string_literal: true

module Ace
  module Git
    module Atoms
      # Pure functions for formatting repository context as various output formats
      # Extracted from Models::RepoContext.to_markdown for ATOM purity
      module ContextFormatter
        class << self
          # Format repository context as markdown
          # @param context [Models::RepoContext] Repository context
          # @return [String] Markdown-formatted output
          def to_markdown(context)
            lines = []
            lines << "# Repository Context"
            lines << ""
            lines << "**Branch:** #{context.branch}#{context.detached? ? ' (detached HEAD)' : ''}"

            if context.tracking?
              lines << "**Remote:** #{context.tracking} (#{context.tracking_status})"
            end

            if context.has_task_pattern?
              lines << "**Task Pattern:** #{context.task_pattern}"
            end

            lines << "**State:** #{context.repository_state}"

            if context.has_pr?
              lines.concat(format_pr_section(context.pr_metadata))
            end

            lines.join("\n")
          end

          private

          # Format PR metadata as compact header + key-value lines
          # @param pr_metadata [Hash] PR metadata
          # @return [Array<String>] Lines of markdown
          def format_pr_section(pr_metadata)
            lines = []
            lines << ""

            # Header line: ## PR #82: Title... [OPEN]
            header = "## PR ##{pr_metadata['number']}"
            header += ": #{pr_metadata['title']}" if pr_metadata['title']
            header += " [#{pr_metadata['state']}]" if pr_metadata['state']
            lines << header

            # Branch line: Target: main | Draft: No
            branch_parts = []
            branch_parts << "Target: #{pr_metadata['baseRefName']}" if pr_metadata['baseRefName']
            branch_parts << "Draft: #{pr_metadata['isDraft'] ? 'Yes' : 'No'}" if pr_metadata.key?('isDraft')
            lines << branch_parts.join(" | ") unless branch_parts.empty?

            # Author line
            if pr_metadata['author']
              author = pr_metadata.dig('author', 'login') || pr_metadata['author']
              lines << "Author: #{author}"
            end

            # URL line
            lines << "URL: #{pr_metadata['url']}" if pr_metadata['url']

            lines
          end
        end
      end
    end
  end
end
