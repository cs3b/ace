# frozen_string_literal: true

require_relative "../../test_helper"

class HitlInboxTest < AceOverseerTestCase
  FakeEvent = Struct.new(:id, :type, :status, :result, :metadata, :title, :created_at,
    keyword_init: true)

  # Mirrors the HitlManager#list surface the molecule depends on.
  class FakeManager
    attr_reader :lists

    def initialize(events)
      @events = events
      @lists = []
    end

    def list(status: nil, kind: nil, type: nil, delivery: nil, in_folder: "next", tags: [], scope: nil)
      @lists << {in_folder: in_folder, type: type, status: status}
      events = @events.select { |event| event.type == type }
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
        {in_folder: "next", type: "report", status: nil},
        {in_folder: "next", type: "question", status: "pending"}
      ],
      manager.lists
    )
  end

  def test_normalizes_events_to_the_keys_the_atom_matches_on
    manager = FakeManager.new([
      event("r1", "report", created_at: Time.at(1000),
        metadata: {"task" => "8xg.t.prj", "assignment" => "w1", "step" => "8xg.t.mgr.1"},
        title: "Worker finished")
    ])

    events = Ace::Overseer::Molecules::HitlInbox.new(manager: manager).incoming_events

    assert_equal ["id", "type", "result", "task", "assignment", "title"], events.first.keys
    assert_equal "r1", events.first["id"]
    assert_equal "report", events.first["type"]
    assert_equal "success", events.first["result"]
    assert_equal "8xg.t.prj", events.first["task"]
    assert_equal "w1", events.first["assignment"]
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
end
