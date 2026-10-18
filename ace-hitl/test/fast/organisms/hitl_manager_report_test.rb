# frozen_string_literal: true

require_relative "../../test_helper"

class HitlManagerReportTest < AceHitlTestCase
  def test_create_report_via_manager
    with_hitl_dir do |root|
      manager = Ace::Hitl::Organisms::HitlManager.new(root_dir: root, config: {"hitl" => {"root_dir" => root}})
      event = manager.create("Work done",
        type: "report",
        result: "success",
        task: "8xg.t.sbz.1.0",
        body: ["Implemented the thing"],
        assignment: "abc123",
        step: "010")

      assert_equal "report", event.type
      assert_equal "success", event.result
      assert_equal "recorded", event.status
      assert event.report?
      refute event.question?
      refute event.answered?
      assert_equal "8xg.t.sbz.1.0", event.metadata["task"]
      assert_equal "abc123", event.metadata["assignment"]
      assert_equal "010", event.metadata["step"]
      assert_match(/\A[0-9a-z]{6}\z/, event.id)
    end
  end

  def test_create_question_still_works_with_explicit_type
    with_hitl_dir do |root|
      manager = Ace::Hitl::Organisms::HitlManager.new(root_dir: root, config: {"hitl" => {"root_dir" => root}})
      event = manager.create("Which DB?", type: "question", questions: ["Postgres?"])

      assert_equal "question", event.type
      assert_equal "pending", event.status
      assert event.question?
    end
  end

  def test_creator_validates_report_rules
    with_hitl_dir do |root|
      creator = Ace::Hitl::Molecules::HitlCreator.new(root_dir: root)

      error = assert_raises(ArgumentError) do
        creator.create("Bad", type: "report", result: "bogus")
      end
      assert_match(/Report requires result/, error.message)

      error = assert_raises(ArgumentError) do
        creator.create("Bad", type: "report", result: "success", questions: ["Q?"])
      end
      assert_match(/cannot include questions/, error.message)

      error = assert_raises(ArgumentError) do
        creator.create("Bad", type: "report", result: "success", resume_instructions: "/x")
      end
      assert_match(/resume instructions/, error.message)

      error = assert_raises(ArgumentError) do
        creator.create("Bad", result: "success")
      end
      assert_match(/only valid for reports/, error.message)

      error = assert_raises(ArgumentError) do
        creator.create("Bad", body: ["line"])
      end
      assert_match(/only valid for reports/, error.message)
    end
  end

  def test_list_filters_by_type
    with_hitl_dir do |root|
      create_hitl_fixture(root, id: "qqq111", slug: "question-one", type: "question")
      create_hitl_fixture(root, id: "rrr222", slug: "report-one", type: "report",
        result: "error", status: "recorded", body: ["failed"])

      manager = Ace::Hitl::Organisms::HitlManager.new(root_dir: root, config: {"hitl" => {"root_dir" => root}})
      reports = manager.list(in_folder: "all", type: "report")
      assert_equal ["rrr222"], reports.map(&:id)

      questions = manager.list(in_folder: "all", type: "question")
      assert_equal ["qqq111"], questions.map(&:id)

      assert_equal [], manager.list(status: "pending", type: "report", in_folder: "all")
    end
  end

  def test_update_answer_on_report_raises_before_mutation
    with_hitl_dir do |root|
      create_hitl_fixture(root, id: "rrr222", slug: "report-one", type: "report",
        result: "success", status: "recorded", body: ["done"])

      manager = Ace::Hitl::Organisms::HitlManager.new(root_dir: root, config: {"hitl" => {"root_dir" => root}})
      error = assert_raises(Ace::Hitl::Organisms::HitlManager::NotAnswerableError) do
        manager.update("rrr222", answer: "ok")
      end
      assert_match(/rrr222.*report/, error.message)

      reloaded = manager.show("rrr222")[:event]
      assert_equal "recorded", reloaded.status
      refute reloaded.answered?
      assert reloaded.answer.nil?

      moved = manager.update("rrr222", set: {"tags" => "processed"})
      assert_equal "rrr222", moved.id
    end
  end

  def test_wait_for_answer_on_report_returns_report_status_without_sleeping
    with_hitl_dir do |root|
      create_hitl_fixture(root, id: "rrr222", slug: "report-one", type: "report",
        result: "success", status: "recorded", body: ["done"])

      manager = Ace::Hitl::Organisms::HitlManager.new(root_dir: root, config: {"hitl" => {"root_dir" => root}})
      slept = 0
      result = manager.wait_for_answer("rrr222",
        poll_every: 1,
        timeout: 5,
        sleeper: ->(_seconds) { slept += 1 })

      assert_equal :report, result[:status]
      assert result[:event].report?
      assert_equal 0, slept
    end
  end

  def test_dispatch_resume_on_report_returns_report_status
    with_hitl_dir do |root|
      create_hitl_fixture(root, id: "rrr222", slug: "report-one", type: "report",
        result: "success", status: "recorded", body: ["done"])

      manager = Ace::Hitl::Organisms::HitlManager.new(root_dir: root, config: {"hitl" => {"root_dir" => root}})
      result = manager.dispatch_resume("rrr222")

      assert_equal :report, result[:status]
      assert result[:event].report?
    end
  end

  def test_legacy_files_without_type_load_as_questions
    with_hitl_dir do |root|
      create_hitl_fixture(root, id: "ooo333", slug: "old-question", type: "question")
      path = Dir.glob(File.join(root, "**", "ooo333-*.hitl.s.md")).first
      content = File.read(path)
      File.write(path, content.sub(/^type: question\n/, ""))

      manager = Ace::Hitl::Organisms::HitlManager.new(root_dir: root, config: {"hitl" => {"root_dir" => root}})
      event = manager.show("ooo333")[:event]
      assert_equal "question", event.type
      assert event.question?
    end
  end
end
