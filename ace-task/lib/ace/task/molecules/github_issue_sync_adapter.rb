# frozen_string_literal: true

module Ace
  module Task
    module Molecules
      # Bridges ace-task lifecycle events to reusable ace-git issue sync primitives.
      class GithubIssueSyncAdapter
        UNAVAILABLE_MESSAGE = "GitHub issue sync primitives are unavailable. " \
          "Complete dependency task 8r4.t.ilo.2 or update ace-git."

        CANDIDATE_INTEGRATIONS = [
          ["Ace::Git::Molecules::GithubIssueSync", :validate_link!],
          ["Ace::Git::Molecules::IssueSync", :validate_link!],
          ["Ace::Git::Molecules::GithubIssueSync", :sync_task],
          ["Ace::Git::Molecules::IssueSync", :sync_task]
        ].freeze

        def validate_link!(issue_id:, previous_task: nil)
          return unless issue_id.to_i.positive?

          receiver, method_name = resolve_integration(:validate_link!)
          raise UNAVAILABLE_MESSAGE unless receiver && method_name

          receiver.public_send(
            method_name,
            issue_id: issue_id.to_i,
            task_id: previous_task&.id,
            previous_task_id: previous_task&.id
          )
        end

        def sync_task(task:, reason:, previous_task: nil)
          current_issue_ids = [task.metadata["github_issue"]].compact.map(&:to_i).uniq
          previous_issue_ids = [previous_task&.metadata&.[]("github_issue")].compact.map(&:to_i).uniq
          issue_ids = (current_issue_ids + previous_issue_ids).uniq
          return {synced: 0, issues: []} if issue_ids.empty?

          receiver, method_name = resolve_integration(:sync_task)
          raise UNAVAILABLE_MESSAGE unless receiver && method_name

          payload = {
            task_id: task.id,
            task_title: task.title,
            task_status: task.status,
            task_path: task.file_path || task.path,
            issue_ids: issue_ids,
            current_issue_ids: current_issue_ids,
            reason: reason,
            previous: previous_task ? {
              id: previous_task.id,
              title: previous_task.title,
              status: previous_task.status,
              path: previous_task.file_path || previous_task.path
            } : nil
          }
          receiver.public_send(method_name, **payload)
          {synced: issue_ids.length, issues: issue_ids}
        end

        private

        def resolve_integration(expected_method = nil)
          CANDIDATE_INTEGRATIONS.each do |constant_name, method_name|
            next if expected_method && method_name != expected_method

            klass = constant_name.split("::").reject(&:empty?).inject(Object) { |ctx, name| ctx.const_get(name) }
            return [klass, method_name] if klass.respond_to?(method_name)
          rescue NameError
            next
          end

          [nil, nil]
        end
      end
    end
  end
end
