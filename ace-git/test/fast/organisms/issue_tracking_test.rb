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
    assert_equal "Keep this note\n", @provider.comments.first[:body]
  end

  def test_sync_preserves_unrelated_trailing_whitespace
    @provider.comments << {id: 1, body: "Note with trailing spaces  \n" \
      "<!-- ace-task:tracked -->\nTracked in ace-task: [8pp.t.q7w](old.md)"}
    @service.sync(number: 42, task_id: "8pp.t.q7w", task_link: "task.md", task_status: "pending")
    assert_includes @provider.comments.first[:body], "Note with trailing spaces  \n"
    refute_includes @provider.comments.first[:body], "Note with trailing spaces  \n\n"
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

  def test_reparent_replay_accepts_marker_already_on_new_id
    @provider.comments << {id: 1, body: "<!-- ace-task:tracked -->\nTracked in ace-task: [8pp.t.q7w.new](x.md)"}
    @service.sync(number: 42, task_id: "8pp.t.q7w.new", previous_task_id: "8pp.t.q7w.old",
                  task_link: "x.md", task_status: "pending")
    assert_match(/Tracked in ace-task: \[8pp.t.q7w\.new\]/, @provider.comments.first[:body])
    assert_includes @provider.labels, "ace:tracked"
  end

  def test_sync_separates_marker_from_trailing_note_without_newline
    @provider.comments << {id: 1, body: "Final note without newline<!-- ace-task:tracked -->\n" \
      "Tracked in ace-task: [8pp.t.q7w](old.md)"}
    @service.sync(number: 42, task_id: "8pp.t.q7w", task_link: "task.md", task_status: "pending")
    body = @provider.comments.first[:body]
    assert_includes body, "Final note without newline\n<!-- ace-task:tracked -->"
    # Clear can then remove the marker and keep the note verbatim.
    @service.clear(number: 42, task_id: "8pp.t.q7w")
    assert_equal "Final note without newline\n", @provider.comments.first[:body]
  end

  def test_clear_removes_inline_marker_without_prior_sync
    @provider.comments << {id: 1, body: "A historical note<!-- ace-task:tracked -->\n" \
      "Tracked in ace-task: [8pp.t.q7w](old.md)"}
    @service.clear(number: 42, task_id: "8pp.t.q7w")
    assert_equal "A historical note\n", @provider.comments.first[:body]
    refute_includes @provider.labels, "ace:tracked"
  end

  class DelayedCreateProvider < FakeProvider
    attr_reader :reads_after_unknown

    def initialize
      super
      @reads_after_unknown = 0
      @delayed = false
    end

    def arm_delayed_create
      @delayed = true
    end

    def issue_tracking(number:)
      if @delayed && @calls.count { |call| call.first == :create } > 0
        @reads_after_unknown += 1
        # First reconciliation read misses the still-committing write.
        return super if @reads_after_unknown == 1

        @delayed = false
      end
      super
    end
  end

  class LateCommitProvider < FakeProvider
    attr_reader :reads

    def initialize
      super
      @reads = 0
    end

    def issue_tracking(number:)
      @reads += 1
      # Simulate the forge committing the earlier unknown-outcome POST only
      # after several reconciliation reads.
      if @reads == 3
        comments << {id: 1, body: "<!-- ace-task:tracked -->\nTracked in ace-task: [8pp.t.q7w](task.md)"}
      end
      super
    end
  end

  def test_create_pending_replay_reconciles_without_second_create
    provider = LateCommitProvider.new
    service = Ace::Git::Organisms::IssueTracking.new(provider: provider)
    service.stub(:create_reconcile_interval, 0) do
      service.sync(number: 42, task_id: "8pp.t.q7w", task_link: "task.md", task_status: "pending",
        create_pending: true)
    end
    assert_equal 0, provider.calls.count { |call| call.first == :create }
    assert_equal 1, provider.comments.length
  end

  def test_before_create_fires_before_the_non_idempotent_post
    events = []
    provider = FakeProvider.new
    provider.define_singleton_method(:create_issue_comment) do |number:, body:|
      events << :post
      calls << [:create, number]
      comments << {id: comments.length + 1, body: body}
    end
    service = Ace::Git::Organisms::IssueTracking.new(provider: provider)
    service.sync(number: 42, task_id: "8pp.t.q7w", task_link: "task.md", task_status: "pending",
      before_create: -> { events << :guard })
    assert_equal %i[guard post], events
  end

  def test_unknown_create_reconciles_without_duplicate_after_delayed_commit
    provider = DelayedCreateProvider.new
    provider.arm_delayed_create
    service = Ace::Git::Organisms::IssueTracking.new(provider: provider)
    service.sync(number: 42, task_id: "8pp.t.q7w", task_link: "task.md", task_status: "pending")
    assert_equal 1, provider.calls.count { |call| call.first == :create }
    assert_equal 1, provider.comments.length
  end

  def test_sync_accepts_ownership_from_either_previous_or_current_id
    @provider.comments << {id: 1, body: "<!-- ace-task:tracked -->\nTracked in ace-task: [8pp.t.q7w.old](x.md)"}
    @service.sync(number: 42, task_id: "8pp.t.q7w.new", previous_task_id: "8pp.t.q7w.old",
                  task_link: "x.md", task_status: "pending")
    assert_match(/Tracked in ace-task: \[8pp\.t\.q7w\.new\]/, @provider.comments.first[:body])
  end
end
