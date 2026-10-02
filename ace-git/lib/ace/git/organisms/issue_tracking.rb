# frozen_string_literal: true

module Ace
  module Git
    module Organisms
      # One ACE task owns at most one exact remote issue. The provider handles
      # transport; this service owns only the marker, label, and task lifecycle.
      class IssueTracking
        STICKY_MARKER = "<!-- ace-task:tracked -->"
        TRACKED_LABEL = "ace:tracked"
        TERMINAL_STATUSES = %w[done cancelled skipped].freeze

        def initialize(provider:)
          @provider = provider
        end

        def validate_link!(number:, task_id: nil, previous_task_id: nil)
          snapshot = fetch(number)
          owners = owned_task_ids(snapshot)
          if sticky_comment(snapshot) && owners.empty?
            raise ProviderMalformedOutputError, "Issue ##{number} has an ACE marker without a task owner"
          end
          accepted = [task_id, previous_task_id].compact.map(&:to_s).uniq
          return snapshot if owners.empty? || (!accepted.empty? && owners.all? { |owner| accepted.include?(owner) })

          raise ProviderIdentityMismatchError,
            "Issue ##{number} is already owned by ACE task #{owners.join(', ')}"
        end

        def sync(number:, task_id:, task_link:, task_status:, previous_task_id: nil)
          # Reparenting/promotion changes the local ID; the remote marker still
          # names the previous ID until this sync transfers ownership.
          snapshot = validate_link!(number: number, task_id: previous_task_id || task_id)
          sticky = sticky_comment(snapshot)
          desired_line = "Tracked in ace-task: [#{task_id}](#{task_link})"
          preserved = Array(sticky&.dig(:body).to_s.lines).map(&:rstrip).reject do |line|
            line == STICKY_MARKER || line.start_with?("Tracked in ace-task: ")
          end
          desired_body = (preserved + [STICKY_MARKER, desired_line]).join("\n")
          if sticky.nil?
            mutate_and_reconcile(number, desired_body: desired_body) do
              @provider.create_issue_comment(number: number, body: desired_body)
            end
          elsif sticky[:body] != desired_body
            mutate_and_reconcile(number, desired_body: desired_body) do
              @provider.update_issue_comment(number: number, comment_id: sticky[:id], body: desired_body)
            end
          end
          snapshot = fetch(number)
          unless snapshot[:labels].include?(TRACKED_LABEL)
            mutate_and_reconcile(number, label: TRACKED_LABEL) do
              @provider.add_issue_label(number: number, label: TRACKED_LABEL)
            end
          end
          desired_state = TERMINAL_STATUSES.include?(task_status.to_s) ? :closed : :open
          snapshot = fetch(number)
          unless snapshot[:issue].state == desired_state
            mutate_and_reconcile(number, state: desired_state) do
              @provider.set_issue_state(number: number, state: desired_state)
            end
          end
          verified = fetch(number)
          unless sticky_comment(verified)&.[](:body) == desired_body &&
              verified[:labels].include?(TRACKED_LABEL) && verified[:issue].state == desired_state
            raise ProviderMalformedOutputError, "Issue ##{number} did not reflect ACE tracking updates"
          end
          verified
        end

        # Clear only the task's marker/comment and ACE label. Issue state is
        # intentionally untouched, even when it was changed by prior sync.
        def clear(number:, task_id:, previous_task_id: nil)
          snapshot = fetch(number)
          owners = owned_task_ids(snapshot)
          sticky = sticky_comment(snapshot)
          if sticky && owners.empty?
            raise ProviderMalformedOutputError, "Issue ##{number} has an ACE marker without a task owner"
          end
          accepted = [task_id, previous_task_id].compact.map(&:to_s).uniq
          unless owners.empty? || (!accepted.empty? && owners.all? { |owner| accepted.include?(owner) })
            raise ProviderIdentityMismatchError, "Issue ##{number} is owned by another ACE task"
          end
          if sticky
            preserved = sticky[:body].to_s.lines.map(&:rstrip).reject do |line|
              line == STICKY_MARKER || line.start_with?("Tracked in ace-task: ")
            end
            mutate_and_reconcile(number, absent_comment: true) do
              if preserved.empty?
                @provider.delete_issue_comment(number: number, comment_id: sticky[:id])
              else
                @provider.update_issue_comment(number: number, comment_id: sticky[:id], body: preserved.join("\n"))
              end
            end
          end
          snapshot = fetch(number)
          if snapshot[:labels].include?(TRACKED_LABEL)
            mutate_and_reconcile(number, absent_label: TRACKED_LABEL) do
              @provider.remove_issue_label(number: number, label: TRACKED_LABEL)
            end
          end
          verified = fetch(number)
          if sticky_comment(verified) || verified[:labels].include?(TRACKED_LABEL)
            raise ProviderMalformedOutputError, "Issue ##{number} still contains ACE tracking artifacts"
          end
          verified
        end

        private

        def fetch(number)
          snapshot = @provider.issue_tracking(number: number)
          unless snapshot.is_a?(Hash) && snapshot[:issue]&.number.to_i == number.to_i &&
              snapshot[:comments].is_a?(Array) && snapshot[:labels].is_a?(Array)
            raise ProviderMalformedOutputError, "Incomplete issue tracking evidence for ##{number}"
          end
          snapshot
        end

        def sticky_comment(snapshot)
          matches = snapshot[:comments].select { |comment| comment[:body].to_s.include?(STICKY_MARKER) }
          if matches.length > 1
            raise ProviderIdentityMismatchError, "Multiple ACE tracking comments on issue ##{snapshot[:issue].number}"
          end
          matches.first
        end

        def owned_task_ids(snapshot)
          sticky = sticky_comment(snapshot)
          return [] unless sticky

          sticky[:body].to_s.lines.filter_map do |line|
            line[/\ATracked in ace-task: \[([^\]]+)\]\(/, 1]
          end.uniq
        end

        def mutate_and_reconcile(number, desired_body: nil, label: nil, state: nil,
          absent_comment: false, absent_label: nil)
          yield
        rescue ProviderUnknownOutcomeError
          snapshot = fetch(number)
          resolved = if desired_body
            sticky_comment(snapshot)&.[](:body) == desired_body
          elsif label
            snapshot[:labels].include?(label)
          elsif state
            snapshot[:issue].state == state
          elsif absent_comment
            sticky_comment(snapshot).nil?
          elsif absent_label
            !snapshot[:labels].include?(absent_label)
          end
          raise unless resolved
        end
      end
    end
  end
end
