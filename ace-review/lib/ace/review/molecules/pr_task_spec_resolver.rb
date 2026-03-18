# frozen_string_literal: true

module Ace
  module Review
    module Molecules
      # Resolves a single task spec path from PR metadata when possible.
      class PrTaskSpecResolver
        def self.resolve_spec_path(pr_metadata)
          task_reference = extract_task_reference(pr_metadata)
          return nil unless task_reference

          require_relative "task_resolver"
          task_info = TaskResolver.resolve(task_reference)
          return nil unless task_info

          spec_path = task_info[:spec_path]
          return nil unless spec_path && File.exist?(spec_path)
          return nil unless spec_path.end_with?(".s.md")

          spec_path
        rescue StandardError => e
          warn "Warning: Failed to resolve PR task spec: #{e.message}" if Ace::Review.debug?
          nil
        end

        def self.extract_task_reference(pr_metadata)
          return nil unless pr_metadata.is_a?(Hash)

          from_branch = extract_from_branch(pr_metadata["headRefName"])
          return from_branch if from_branch

          extract_from_text(pr_metadata["body"]) || extract_from_text(pr_metadata["title"])
        end

        def self.extract_from_branch(branch_name)
          return nil unless branch_name && !branch_name.strip.empty?

          # Extract prefix before first hyphen as potential task reference
          prefix = branch_name.split("-", 2).first
          return nil if prefix.nil? || prefix.empty?
          return nil if prefix.include?("/")

          prefix
        end

        def self.extract_from_text(text)
          return nil unless text && !text.strip.empty?

          full_ref = text.match(/\b(v\.\d+\.\d+\.\d+\+task\.\d+(?:\.\d+)?)\b/i)
          return full_ref[1] if full_ref

          task_ref = text.match(/\btask[.\s:#-]+(\d+(?:\.\d+)?)\b/i)
          task_ref&.[](1)
        end
      end
    end
  end
end
