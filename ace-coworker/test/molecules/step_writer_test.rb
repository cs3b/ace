# frozen_string_literal: true

require_relative "../test_helper"

class StepWriterTest < AceCoworkerTestCase
  def test_create_step
    with_temp_cache do |cache_dir|
      jobs_dir = File.join(cache_dir, "jobs")
      FileUtils.mkdir_p(jobs_dir)

      writer = Ace::Coworker::Molecules::StepWriter.new
      file_path = writer.create(
        jobs_dir: jobs_dir,
        number: "010",
        name: "init-project",
        instructions: "Create the project.",
        status: :pending
      )

      assert File.exist?(file_path)
      assert_equal "010-init-project.md", File.basename(file_path)

      content = File.read(file_path)
      assert_includes content, "name: init-project"
      assert_includes content, "status: pending"
      assert_includes content, "Create the project."
    end
  end

  def test_create_step_with_added_by
    with_temp_cache do |cache_dir|
      jobs_dir = File.join(cache_dir, "jobs")
      FileUtils.mkdir_p(jobs_dir)

      writer = Ace::Coworker::Molecules::StepWriter.new
      file_path = writer.create(
        jobs_dir: jobs_dir,
        number: "041",
        name: "fix-bug",
        instructions: "Fix it.",
        status: :pending,
        added_by: "dynamic"
      )

      content = File.read(file_path)
      assert_includes content, "added_by: dynamic"
    end
  end

  def test_mark_in_progress
    with_temp_cache do |cache_dir|
      jobs_dir = File.join(cache_dir, "jobs")
      FileUtils.mkdir_p(jobs_dir)

      writer = Ace::Coworker::Molecules::StepWriter.new
      file_path = writer.create(
        jobs_dir: jobs_dir,
        number: "010",
        name: "init",
        instructions: "Do it.",
        status: :pending
      )

      writer.mark_in_progress(file_path)

      content = File.read(file_path)
      assert_includes content, "status: in_progress"
      assert_includes content, "started_at:"
    end
  end

  def test_mark_done_with_report
    with_temp_cache do |cache_dir|
      jobs_dir = File.join(cache_dir, "jobs")
      FileUtils.mkdir_p(jobs_dir)

      writer = Ace::Coworker::Molecules::StepWriter.new
      file_path = writer.create(
        jobs_dir: jobs_dir,
        number: "010",
        name: "init",
        instructions: "Do it.",
        status: :in_progress
      )

      writer.mark_done(file_path, report_content: "All done!")

      content = File.read(file_path)
      assert_includes content, "status: done"
      assert_includes content, "completed_at:"
      assert_includes content, "# Report"
      assert_includes content, "All done!"
    end
  end

  def test_mark_failed
    with_temp_cache do |cache_dir|
      jobs_dir = File.join(cache_dir, "jobs")
      FileUtils.mkdir_p(jobs_dir)

      writer = Ace::Coworker::Molecules::StepWriter.new
      file_path = writer.create(
        jobs_dir: jobs_dir,
        number: "040",
        name: "tests",
        instructions: "Run tests.",
        status: :in_progress
      )

      writer.mark_failed(file_path, error_message: "2 tests failed")

      content = File.read(file_path)
      assert_includes content, "status: failed"
      assert_includes content, "error: 2 tests failed"
    end
  end

  def test_update_frontmatter
    with_temp_cache do |cache_dir|
      jobs_dir = File.join(cache_dir, "jobs")
      FileUtils.mkdir_p(jobs_dir)

      writer = Ace::Coworker::Molecules::StepWriter.new
      file_path = writer.create(
        jobs_dir: jobs_dir,
        number: "010",
        name: "init",
        instructions: "Do it.",
        status: :pending
      )

      writer.update_frontmatter(file_path, { "status" => "in_progress", "custom" => "value" })

      content = File.read(file_path)
      assert_includes content, "status: in_progress"
      assert_includes content, "custom: value"
    end
  end
end
