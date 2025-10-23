# frozen_string_literal: true

module Ace
  module GitDiff
    module Organisms
      # Helpers for integrating ace-git-diff with other ACE gems
      class IntegrationHelper
        class << self
          # Generate diff for ace-docs document
          # @param document [Object] Document object with subject configuration
          # @return [Models::DiffResult] Diff result for the document
          def for_ace_docs(document)
            # Extract diff configuration from document
            config = extract_docs_config(document)

            # Generate diff
            DiffOrchestrator.from_config(config)
          end

          # Generate diff for ace-review preset
          # @param preset [Hash] Review preset configuration
          # @return [Models::DiffResult] Diff result for the review
          def for_ace_review(preset)
            # Extract diff configuration from preset
            config = extract_review_config(preset)

            # Generate diff
            DiffOrchestrator.from_config(config)
          end

          # Generate diff for ace-context configuration
          # @param context_config [Hash] Context configuration
          # @return [Models::DiffResult] Diff result for context
          def for_ace_context(context_config)
            # Extract diff configuration
            config = Molecules::ConfigLoader.extract_diff_config(context_config)

            # Generate diff (may want raw output for context)
            options = config.merge(exclude_patterns: config.fetch(:exclude_patterns, []))
            DiffOrchestrator.generate(options)
          end

          # Generate diff for ace-git-commit
          # Returns raw command execution result for commit message generation
          # @param options [Hash] Diff options
          # @return [String] Raw diff content
          def for_ace_git_commit(options = {})
            # ace-git-commit typically wants minimal filtering
            # Default to staged changes or working changes
            if Atoms::CommandExecutor.has_staged_changes?
              result = DiffOrchestrator.staged(options)
            elsif Atoms::CommandExecutor.has_unstaged_changes?
              result = DiffOrchestrator.working(options)
            else
              # Branch diff
              result = DiffOrchestrator.smart(options)
            end

            result.content
          end

          private

          # Extract diff configuration from ace-docs document
          def extract_docs_config(document)
            return {} unless document.respond_to?(:frontmatter)

            frontmatter = document.frontmatter || {}
            docs_config = frontmatter["ace-docs"] || frontmatter[:ace_docs] || {}
            subject = docs_config["subject"] || docs_config[:subject] || {}

            Molecules::ConfigLoader.extract_diff_config(subject)
          end

          # Extract diff configuration from ace-review preset
          def extract_review_config(preset)
            return {} if preset.nil? || preset.empty?

            subject = preset["subject"] || preset[:subject] || {}
            Molecules::ConfigLoader.extract_diff_config(subject)
          end
        end
      end
    end
  end
end
