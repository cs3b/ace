# frozen_string_literal: true

module CodingAgentTools
  module Molecules
    module Claude
      # Infers metadata from workflow names
      # This is a behavior-oriented helper that encapsulates the logic
      # for deriving command metadata from workflow naming conventions
      class CommandMetadataInferrer
        # Infer metadata from workflow name
        # @param workflow_name [String] Name of the workflow
        # @return [Hash] Metadata with :description, :allowed_tools, :argument_hint, :model
        def infer(workflow_name)
          return {} if workflow_name.nil? || workflow_name.empty?

          metadata = {}

          # Generate description
          metadata[:description] = generate_description(workflow_name)

          # Infer allowed tools
          metadata[:allowed_tools] = infer_allowed_tools(workflow_name)

          # Add argument hints if needed
          argument_hint = infer_argument_hint(workflow_name)
          metadata[:argument_hint] = argument_hint if argument_hint

          # Select model for complex workflows
          model = infer_model(workflow_name)
          metadata[:model] = model if model

          metadata
        end

        private

        def generate_description(workflow_name)
          # Generate description from workflow name - more sophisticated
          description = workflow_name.gsub('-', ' ')
          description = description.split.map(&:capitalize).join(' ')

          # Special case handling for common abbreviations
          description.gsub!(/\bApi\b/, 'API')
          description.gsub!(/\bAdr\b/, 'ADR')
          description.gsub!(/\bLlm\b/, 'LLM')
          description.gsub!(/\bAi\b/, 'AI')

          description
        end

        def infer_allowed_tools(workflow_name)
          case workflow_name
          # Git operations
          when /^git-/, /commit/, /rebase/, /merge/
            'Bash(git *), Read, Write'
          # Task management workflows
          when /^draft-task/, /^plan-task/, /^work-on-task/, /^review-task/, /^complete-task/
            'Read, Write, TodoWrite, Bash(task-manager *)'
          # Creation workflows
          when /^create-adr/, /^create-api-docs/, /^create-user-docs/, /^create-reflection-note/
            'Read, Write, Grep, Glob'
          when /^create-test-cases/
            'Read, Write, Bash(bundle exec rspec), Grep'
          # Testing and fixing workflows
          when /^test-/, /^validate-/
            'Bash, Read, Grep'
          when /^fix-tests/, /^fix-linting-issue/
            'Read, Write, Edit, Bash(bundle exec *), Grep'
          # Research and analysis workflows
          when /^research/, /analyze/
            'Read, Grep, Glob, WebSearch'
          # Synthesis workflows
          when /^synthesize-reflection-notes/
            'Read, Write, Grep, TodoWrite'
          # Project context loading
          when /^load-project-context/
            'Read, LS'
          # Release workflows
          when /^draft-release/, /^release/
            'Read, Write, Bash(task-manager release *), Grep'
          # Update workflows
          when /^update-blueprint/
            'Read, Write, Edit, Grep'
          # Capture workflows
          when /^capture-idea/
            'Write, TodoWrite'
          # Default fallback for any uncategorized workflows
          else
            'Read, Write, Edit, Grep'
          end
        end

        def infer_argument_hint(workflow_name)
          case workflow_name
          when /work-on-task/, /review-task/, /plan-task/, /complete-task/
            '[task-id]'
          when /rebase-against/, /merge-from/
            '[branch-name]'
          when /fix-linting-issue-from/
            '[linter-output-file]'
          when /draft-release/, /release/
            '[version]'
          when /capture-idea/
            '[idea-description]'
          when /create-adr/
            '[decision-title]'
          else
            nil
          end
        end

        def infer_model(workflow_name)
          case workflow_name
          when /analyze/, /synthesize/, /research/
            'opus'
          when /fix-tests/, /fix-linting/
            'sonnet' # Fast iteration for fixes
          else
            nil
          end
        end
      end
    end
  end
end
