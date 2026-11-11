# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../support/prune_git_fixtures"

class HitlInboxTest < AceOverseerTestCase
  FakeEvent = Struct.new(:id, :type, :status, :result, :metadata, :title, :created_at,
    keyword_init: true) do
    def file_path = "/inbox/#{id}.md"
    def tags = []
    def recipient = {"machine" => "lab", "panel" => "overseer"}
    def reply_to = nil
    def question? = type == "question"
    def answered? = status == "answered"
  end

  # Mirrors the HitlManager#list surface the molecule depends on.
  class FakeManager
    attr_reader :lists

    def initialize(events)
      @events = events
      @lists = []
    end

    def root_dir = "/inbox"

    def config
      {"hitl" => {"machine" => "lab", "recipients" => {
        "overseer" => {"machine" => "lab", "panel" => "overseer"}
      }}}
    end

    def list(status: nil, kind: nil, type: nil, delivery: nil, in_folder: "next", tags: [], scope: nil, limit: nil, strict: false)
      @lists << {in_folder: in_folder, type: type, status: status}
      events = type ? @events.select { |event| event.type == type } : @events
      events = events.select { |event| event.status == status } if status
      events
    end
  end

  def event(id, type, status: "pending", created_at:, result: "success",
      metadata: {"task" => "8xg.t.prj", "assignment" => "w1"}, title: "Work done")
    FakeEvent.new(id: id, type: type, status: status, result: result,
      metadata: metadata, title: title, created_at: created_at)
  end

  def test_lists_reports_regardless_of_status_and_questions_only_pending
    manager = FakeManager.new([
      event("r1", "report", status: "recorded", created_at: Time.at(1000)),
      event("r2", "report", status: "pending", created_at: Time.at(2000)),
      event("q1", "question", status: "pending", created_at: Time.at(1500)),
      event("q2", "question", status: "answered", created_at: Time.at(500))
    ])

    events = Ace::Overseer::Molecules::HitlInbox.new(manager: manager).incoming_events

    assert_equal %w[r1 q1 r2], events.map { |event| event["id"] }
    assert_equal(
      [
        {in_folder: "next", type: nil, status: nil}
      ],
      manager.lists
    )
  end

  def test_normalizes_events_to_the_keys_the_atom_matches_on
    manager = FakeManager.new([
      event("r1", "report", created_at: Time.at(1000),
        metadata: {"task" => "8xg.t.prj", "assignment" => "w1", "role" => "bootstrap-worker", "step" => "8xg.t.mgr.1"},
        title: "Worker finished")
    ])

    events = Ace::Overseer::Molecules::HitlInbox.new(manager: manager).incoming_events

    assert_equal ["id", "type", "result", "task", "assignment", "role", "title"], events.first.keys
    assert_equal "r1", events.first["id"]
    assert_equal "report", events.first["type"]
    assert_equal "success", events.first["result"]
    assert_equal "8xg.t.prj", events.first["task"]
    assert_equal "w1", events.first["assignment"]
    assert_equal "bootstrap-worker", events.first["role"]
    assert_equal "Worker finished", events.first["title"]
  end

  def test_orders_events_oldest_first
    manager = FakeManager.new([
      event("late-report", "report", created_at: Time.at(9000)),
      event("early-question", "question", created_at: Time.at(1000)),
      event("mid-report", "report", created_at: Time.at(5000))
    ])

    events = Ace::Overseer::Molecules::HitlInbox.new(manager: manager).incoming_events

    assert_equal %w[early-question mid-report late-report], events.map { |event| event["id"] }
  end

  def test_events_without_timestamp_sort_last_in_delivery_order
    manager = FakeManager.new([
      event("undated", "report", created_at: nil),
      event("dated", "report", created_at: Time.at(1000))
    ])

    events = Ace::Overseer::Molecules::HitlInbox.new(manager: manager).incoming_events

    assert_equal %w[dated undated], events.map { |event| event["id"] }
  end
  def test_inbox_only_consumes_the_configured_coordinator_reports
    Dir.mktmpdir("scoped-inbox") do |root|
      config = {"hitl" => {"root_dir" => root, "machine" => "lab", "recipients" => {
        "overseer" => {"machine" => "lab", "folder" => "/lab/ace/.ace-local/hitl"},
        "lab-overseer" => {"machine" => "lab", "folder" => "/lab/.ace-local/hitl"}
      }}}
      manager = Ace::Hitl::Organisms::HitlManager.new(root_dir: root, config: config)
      lab = manager.create("Bootstrap result", to: "lab-overseer", type: "report", result: "success")
      project = manager.create("Product result", to: "overseer", type: "report", result: "success")
      project_inbox = Ace::Overseer::Molecules::HitlInbox.new(manager: manager)
      lab_inbox = Ace::Overseer::Molecules::HitlInbox.new(manager: manager, owner: "lab-overseer")
      assert_equal [project.id], project_inbox.incoming_events.map { |event| event["id"] }
      assert_equal [lab.id], lab_inbox.incoming_events.map { |event| event["id"] }
      assert_equal [project.id], project_inbox.incoming_events.map { |event| event["id"] },
        "re-reading does not take another coordinator's report"
      assert_raises(Ace::Hitl::Molecules::HitlAddressResolver::UnknownRecipientError) do
        Ace::Overseer::Molecules::HitlInbox.new(manager: manager, owner: "missing").incoming_events
      end
    end
  end

  def test_missing_owner_never_disables_filtering
    [nil, "", " "].each do |owner|
      assert_raises(ArgumentError) do
        Ace::Overseer::Molecules::HitlInbox.new(manager: FakeManager.new([]), owner: owner)
      end
    end
  end

  def test_unreadable_source_is_not_an_empty_inbox
    manager = FakeManager.new([])
    def manager.list(**)
      raise Errno::EACCES, "report source"
    end
    assert_raises(Errno::EACCES) do
      Ace::Overseer::Molecules::HitlInbox.new(manager: manager).incoming_events
    end
  end

  def test_canonical_inbox_keeps_reports_in_linked_worker_worktrees
    Dir.mktmpdir("inbox-worktrees") do |directory|
      repo = PruneGitFixtures::Repo.new(File.join(directory, "main")).init
      repo.write("base.txt", "base\n")
      repo.commit("base")
      worker = repo.add_worktree(File.join(directory, "worker"), "worker")
      address = {"machine" => "lab", "folder" => File.join(repo.path, ".ace-local/hitl")}
      config = {"hitl" => {"root_dir" => ".ace-local/hitl", "machine" => "lab",
        "recipients" => {"overseer" => address}}}
      report = Dir.chdir(worker.path) do
        manager = Ace::Hitl::Organisms::HitlManager.new(config: config)
        manager.create("Worker complete", to: "overseer", type: "report", result: "success")
      end
      Dir.chdir(repo.path) do
        manager = Ace::Hitl::Organisms::HitlManager.new(config: config)
        inbox = Ace::Overseer::Molecules::HitlInbox.new(manager: manager)
        assert_equal [report.id], inbox.incoming_events.map { |event| event["id"] }
        assert_empty Ace::Overseer::Molecules::HitlInbox.new(manager: manager, scope: "current").incoming_events
        assert_equal [report.id], Ace::Overseer::Molecules::HitlInbox.new(manager: manager, scope: "all")
          .incoming_events.map { |event| event["id"] }
      end
    end
  end

  def test_invalid_scope_cannot_hide_reports
    assert_raises(ArgumentError) do
      Ace::Overseer::Molecules::HitlInbox.new(manager: FakeManager.new([]), scope: "everything")
    end
  end

  def test_lab_consumes_project_report_from_the_same_projection_as_eyes
    report = {"id" => "worker-report", "type" => "report", "result" => "success",
      "assignment" => "worker", "task" => "8ya.t.tdu", "project_root" => "/lab/ace"}
    calls = []
    projects = Object.new
    projects.define_singleton_method(:call) do |**args|
      calls << args
      {"events" => [report, {"id" => "health", "type" => "source-health"}],
       "sources" => {"project:ace:hitl" => {"status" => "ok"}}}
    end
    inbox = Ace::Overseer::Molecules::HitlInbox.new(manager: FakeManager.new([]), projects: projects)
    assert_equal [report], inbox.incoming_events
    assert_equal [{owner: "overseer", scope: "all", limit: 500}], calls
  end

  def test_degraded_project_or_ambiguous_report_blocks_adoption
    projects = Object.new
    projects.define_singleton_method(:call) do |**|
      {"events" => [], "sources" => {"project:ace" => {"status" => "degraded"}}}
    end
    inbox = Ace::Overseer::Molecules::HitlInbox.new(manager: FakeManager.new([]), projects: projects)
    assert_raises(Ace::Overseer::Error) { inbox.incoming_events }
    projects.define_singleton_method(:call) do |**|
      {"events" => [{"id" => "same", "type" => "report"}] * 2, "sources" => {}}
    end
    assert_raises(Ace::Overseer::Error) { inbox.incoming_events }
  end

end
