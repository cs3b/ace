# frozen_string_literal: true

require_relative "../test_helper"

class StepWriterTest < AceAssignTestCase
  def test_create_step
    with_temp_cache do |cache_dir|
      steps_dir = File.join(cache_dir, "steps")
      FileUtils.mkdir_p(steps_dir)

      writer = Ace::Assign::Molecules::StepWriter.new
      file_path = writer.create(
        steps_dir: steps_dir,
        number: "010",
        name: "init-project",
        instructions: "Create the project.",
        status: :pending
      )

      assert File.exist?(file_path)
      assert_equal "010-init-project.st.md", File.basename(file_path)

      content = File.read(file_path)
      assert_includes content, "name: init-project"
      assert_includes content, "status: pending"
      assert_includes content, "Create the project."
    end
  end

  def test_create_step_with_added_by
    with_temp_cache do |cache_dir|
      steps_dir = File.join(cache_dir, "steps")
      FileUtils.mkdir_p(steps_dir)

      writer = Ace::Assign::Molecules::StepWriter.new
      file_path = writer.create(
        steps_dir: steps_dir,
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

  def test_create_step_with_extra_fields
    with_temp_cache do |cache_dir|
      steps_dir = File.join(cache_dir, "steps")
      FileUtils.mkdir_p(steps_dir)

      writer = Ace::Assign::Molecules::StepWriter.new
      file_path = writer.create(
        steps_dir: steps_dir,
        number: "020",
        name: "work-on-task",
        instructions: "Implement the feature.",
        status: :pending,
        extra: { "skill" => "as-task-work", "context" => "task-229" }
      )

      content = File.read(file_path)
      assert_includes content, "skill: as-task-work"
      assert_includes content, "context: task-229"
    end
  end

  def test_mark_in_progress
    with_temp_cache do |cache_dir|
      steps_dir = File.join(cache_dir, "steps")
      FileUtils.mkdir_p(steps_dir)

      writer = Ace::Assign::Molecules::StepWriter.new
      file_path = writer.create(
        steps_dir: steps_dir,
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

  def test_mark_pending_clears_runtime_state
    with_temp_cache do |cache_dir|
      steps_dir = File.join(cache_dir, "steps")
      FileUtils.mkdir_p(steps_dir)

      writer = Ace::Assign::Molecules::StepWriter.new
      file_path = writer.create(
        steps_dir: steps_dir,
        number: "010",
        name: "init",
        instructions: "Do it.",
        status: :pending
      )

      writer.mark_in_progress(file_path)
      writer.update_frontmatter(file_path, {
        "completed_at" => Time.now.utc.iso8601,
        "error" => "stale error",
        "stall_reason" => "stale stall"
      })

      writer.mark_pending(file_path)

      content = File.read(file_path)
      assert_includes content, "status: pending"
      refute_includes content, "started_at:"
      refute_includes content, "completed_at:"
      refute_includes content, "error:"
      refute_includes content, "stall_reason:"
    end
  end

  def test_mark_done_with_report
    with_temp_cache do |cache_dir|
      steps_dir = File.join(cache_dir, "steps")
      reports_dir = File.join(cache_dir, "reports")
      FileUtils.mkdir_p(steps_dir)
      FileUtils.mkdir_p(reports_dir)

      writer = Ace::Assign::Molecules::StepWriter.new
      file_path = writer.create(
        steps_dir: steps_dir,
        number: "010",
        name: "init",
        instructions: "Do it.",
        status: :in_progress
      )

      writer.mark_done(file_path, report_content: "All done!", reports_dir: reports_dir)

      # Step file should have status done and completed_at, but no report content embedded
      step_content = File.read(file_path)
      assert_includes step_content, "status: done"
      assert_includes step_content, "completed_at:"
      refute_includes step_content, "All done!"
      refute_includes step_content, "# Report"

      # Report should be in separate file
      report_path = File.join(reports_dir, "010-init.r.md")
      assert File.exist?(report_path)
      report_content = File.read(report_path)
      assert_includes report_content, "step: '010'"
      assert_includes report_content, "name: init"
      assert_includes report_content, "All done!"
    end
  end

  def test_mark_failed
    with_temp_cache do |cache_dir|
      steps_dir = File.join(cache_dir, "steps")
      FileUtils.mkdir_p(steps_dir)

      writer = Ace::Assign::Molecules::StepWriter.new
      file_path = writer.create(
        steps_dir: steps_dir,
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
      steps_dir = File.join(cache_dir, "steps")
      FileUtils.mkdir_p(steps_dir)

      writer = Ace::Assign::Molecules::StepWriter.new
      file_path = writer.create(
        steps_dir: steps_dir,
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

  def test_append_report_creates_new_file
    with_temp_cache do |cache_dir|
      steps_dir = File.join(cache_dir, "steps")
      reports_dir = File.join(cache_dir, "reports")
      FileUtils.mkdir_p(steps_dir)
      FileUtils.mkdir_p(reports_dir)

      writer = Ace::Assign::Molecules::StepWriter.new
      file_path = writer.create(
        steps_dir: steps_dir,
        number: "010",
        name: "init",
        instructions: "Do it.",
        status: :in_progress
      )

      writer.append_report(file_path, "Partial report.", reports_dir: reports_dir)

      report_path = File.join(reports_dir, "010-init.r.md")
      assert File.exist?(report_path)
      report_content = File.read(report_path)
      assert_includes report_content, "Partial report."
    end
  end

  def test_append_report_appends_to_existing
    with_temp_cache do |cache_dir|
      steps_dir = File.join(cache_dir, "steps")
      reports_dir = File.join(cache_dir, "reports")
      FileUtils.mkdir_p(steps_dir)
      FileUtils.mkdir_p(reports_dir)

      writer = Ace::Assign::Molecules::StepWriter.new
      file_path = writer.create(
        steps_dir: steps_dir,
        number: "010",
        name: "init",
        instructions: "Do it.",
        status: :in_progress
      )

      # First append
      writer.append_report(file_path, "First report.\n", reports_dir: reports_dir)

      # Second append
      writer.append_report(file_path, "Second report.\n", reports_dir: reports_dir)

      report_path = File.join(reports_dir, "010-init.r.md")
      report_content = File.read(report_path)
      assert_includes report_content, "First report."
      assert_includes report_content, "Second report."
    end
  end

  def test_mark_done_with_empty_report_raises_error
    with_temp_cache do |cache_dir|
      steps_dir = File.join(cache_dir, "steps")
      reports_dir = File.join(cache_dir, "reports")
      FileUtils.mkdir_p(steps_dir)
      FileUtils.mkdir_p(reports_dir)

      writer = Ace::Assign::Molecules::StepWriter.new
      file_path = writer.create(
        steps_dir: steps_dir,
        number: "010",
        name: "init",
        instructions: "Do it.",
        status: :in_progress
      )

      # Empty content should raise error
      error = assert_raises(ArgumentError) do
        writer.mark_done(file_path, report_content: "", reports_dir: reports_dir)
      end
      assert_includes error.message, "cannot be empty"

      # Whitespace-only content should also raise error
      error = assert_raises(ArgumentError) do
        writer.mark_done(file_path, report_content: "   \n\t  ", reports_dir: reports_dir)
      end
      assert_includes error.message, "cannot be empty"
    end
  end

  def test_mark_done_with_nil_report_raises_error
    with_temp_cache do |cache_dir|
      steps_dir = File.join(cache_dir, "steps")
      reports_dir = File.join(cache_dir, "reports")
      FileUtils.mkdir_p(steps_dir)
      FileUtils.mkdir_p(reports_dir)

      writer = Ace::Assign::Molecules::StepWriter.new
      file_path = writer.create(
        steps_dir: steps_dir,
        number: "010",
        name: "init",
        instructions: "Do it.",
        status: :in_progress
      )

      error = assert_raises(ArgumentError) do
        writer.mark_done(file_path, report_content: nil, reports_dir: reports_dir)
      end
      assert_includes error.message, "cannot be nil"
    end
  end
end
