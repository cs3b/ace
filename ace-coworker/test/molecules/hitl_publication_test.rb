# frozen_string_literal: true
require_relative "../test_helper"
require "ace/coworker/molecules/hitl_reporter"
require "json"

class HitlPublicationTest < AceCoworkerTestCase
  Status = Struct.new(:success?)
  Config = Struct.new(:task, :assignment, :overseer)

  def check(events, success: true, schema: "ace.hitl.observation/v1")
    @calls = []
    reporter = Ace::Coworker::Molecules::HitlReporter.new(project_root: Dir.pwd,
      runner: ->(argv, _cwd) {
        @calls << argv
        [JSON.generate("schema" => schema, "events" => events), "", Status.new(success)]
      })
    reporter.publication_matches?("abc123", Config.new("8xh.t.aaa", "assign1", "lab-overseer"), result: "success")
  end

  def event
    {"id" => "abc123", "type" => "report", "task" => "8xh.t.aaa",
      "assignment" => "assign1", "result" => "success"}
  end

  def test_publication_is_checked_through_owner_including_archived_events
    assert check([event])
    assert_equal ["observe", "--scope", "current", "--owner", "lab-overseer", "--in", "all", "--limit", "2000"], @calls.first.drop(1)
  end

  def test_missing_mismatched_or_ambiguous_publications_are_not_success
    refute check([])
    {"id" => "other1", "type" => "question", "task" => "other", "assignment" => "other", "result" => "error"}.each do |key, value|
      refute check([event.merge(key => value)]), key
    end
    assert_raises(Ace::Coworker::Error) { check([{}]) }
    assert_raises(Ace::Coworker::Error) { check([event, event]) }
  end

  def test_failed_or_unknown_owner_projection_is_not_success
    assert_raises(Ace::Coworker::Error) { check([event], success: false) }
    assert_raises(Ace::Coworker::Error) { check([event], schema: "unexpected") }
  end
end
