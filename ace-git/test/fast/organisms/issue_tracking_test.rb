# frozen_string_literal: true

require "test_helper"

class IssueTrackingTest < AceGitTestCase
  class FakeProvider
    attr_reader :calls, :comments, :labels
    attr_accessor :state, :unknown_after_create

    def initialize
      @calls = []
      @comments = []
      @labels = []
      @state = :open
    end

    def issue_tracking(number:)
      {issue: Ace::Git::ProviderIssue.new(server_name: "lab", number: number, title: "Issue",
         state: state, author: "owner", url: "https://forge.example/owner/repo/issues/#{number}", labels: labels),
       comments: comments.map(&:dup), labels: labels.dup}
    end

    def create_issue_comment(number:, body:)
      calls << [:create, number]
      comments << {id: comments.length + 1, body: body}
      raise Ace::Git::ProviderUnknownOutcomeError, "timeout after send" if unknown_after_create
    end

    def update_issue_comment(number:, comment_id:, body:)
      calls << [:update, number]
      comments.find { |c| c[:id] == comment_id }[:body] = body
    end

    def delete_issue_comment(number:, comment_id:)
      calls << [:delete, number]
      comments.reject! { |c| c[:id] == comment_id }
    end

    def add_issue_label(number:, label:)
      calls << [:add_label, number]
      labels << label
    end

    def remove_issue_label(number:, label:)
      calls << [:remove_label, number]
      labels.delete(label)
    end

    def set_issue_state(number:, state:)
      calls << [:state, state]
      @state = state
    end
  end

  def setup
    @provider = FakeProvider.new
    @service = Ace::Git::Organisms::IssueTracking.new(provider: @provider)
  end

  def test_link_sync_close_reopen_and_clear_preserves_unrelated_content
    @provider.comments << {id: 99, body: "Unrelated conversation"}
    @provider.labels << "customer"
    @service.sync(number: 42, task_id: "8pp.t.q7w", task_link: "tasks/spec.md", task_status: "done")
    assert_equal :closed, @provider.state
    assert_equal ["customer", "ace:tracked"], @provider.labels
    assert_equal 2, @provider.comments.length
    @service.sync(number: 42, task_id: "8pp.t.q7w", task_link: "tasks/spec.md", task_status: "blocked")
    assert_equal :open, @provider.state
    @service.clear(number: 42, task_id: "8pp.t.q7w")
    assert_equal :open, @provider.state
    assert_equal ["customer"], @provider.labels
    assert_equal [{id: 99, body: "Unrelated conversation"}], @provider.comments
  end

  def test_conflicting_owner_rejects_without_mutation
    @provider.comments << {id: 1, body: "<!-- ace-task:tracked -->\nTracked in ace-task: [other](task.md)"}
    assert_raises(Ace::Git::ProviderIdentityMismatchError) do
      @service.sync(number: 42, task_id: "new", task_link: "new.md", task_status: "pending")
    end
    assert_empty @provider.calls
  end

  def test_timeout_after_create_reconciles_without_duplicate
    @provider.unknown_after_create = true
    @service.sync(number: 42, task_id: "8pp.t.q7w", task_link: "task.md", task_status: "pending")
    assert_equal 1, @provider.comments.length
    assert_equal 1, @provider.calls.count { |call| call.first == :create }
  end

  def test_sticky_comment_preserves_non_ace_lines
    @provider.comments << {id: 1, body: "Keep this note\n<!-- ace-task:tracked -->\n" \
      "Tracked in ace-task: [8pp.t.q7w](old.md)"}
    @service.sync(number: 42, task_id: "8pp.t.q7w", task_link: "task.md", task_status: "pending")
    assert_match(/Keep this note/, @provider.comments.first[:body])
    @service.clear(number: 42, task_id: "8pp.t.q7w")
    assert_equal "Keep this note", @provider.comments.first[:body]
  end

  def test_clear_refuses_ambiguous_marker_without_owner
    @provider.comments << {id: 1, body: "<!-- ace-task:tracked -->\nUnparseable marker body"}
    assert_raises(Ace::Git::ProviderMalformedOutputError) do
      @service.clear(number: 42, task_id: "8pp.t.q7w")
    end
    assert_empty @provider.calls
  end

  def test_clear_without_marker_is_idempotent
    @service.clear(number: 42, task_id: "8pp.t.q7w")
    assert_empty @provider.comments
    refute_includes @provider.labels, "ace:tracked"
  end
end
