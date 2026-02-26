# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/molecules/task_simulation_writeback"

class TaskSimulationWritebackTest < AceTaskflowTestCase
  def setup
    super
    @writeback = Ace::Taskflow::Molecules::TaskSimulationWriteback.new
  end

  def test_apply_adds_simulation_review_section
    with_real_tmpdir do |dir|
      path = File.join(dir, "task.s.md")
      File.write(path, "# Task\n\n## Existing\n- Keep me\n")

      @writeback.apply(
        path: path,
        run_id: "i50jj3",
        modes: %w[plan],
        synthesis: {
          questions: ["Q1"],
          refinements: ["R1"],
          unresolved_gaps: ["Gap1"],
          artifacts: {}
        }
      )

      content = File.read(path)
      assert_includes content, "## Simulation Review (Next-Phase)"
      assert_includes content, "- Last run: `i50jj3`"
      assert_includes content, "- Q1"
      assert_includes content, "- R1"
      assert_includes content, "- Gap1"
    end
  end

  def test_apply_upserts_existing_section_without_duplication
    with_real_tmpdir do |dir|
      path = File.join(dir, "task.s.md")
      File.write(path, <<~MARKDOWN)
        # Task

        ## Simulation Review (Next-Phase)
        - Last run: `oldrun`
        - Modes: `plan`

        ### Questions
        - Old question
      MARKDOWN

      @writeback.apply(
        path: path,
        run_id: "newrun",
        modes: %w[plan],
        synthesis: { questions: ["New question"], refinements: ["New refinement"], artifacts: {} }
      )

      content = File.read(path)
      assert_equal 1, content.scan("## Simulation Review (Next-Phase)").length
      refute_includes content, "Old question"
      assert_includes content, "New question"
      assert_includes content, "New refinement"
    end
  end

  def test_apply_writes_plan_artifact_section_with_markers
    with_real_tmpdir do |dir|
      path = File.join(dir, "task.s.md")
      File.write(path, "# Task\n")

      plan_artifact = "# Plan: My Plan\n\n## Steps\n1. Do something\n2. Test it\n"
      @writeback.apply(
        path: path,
        run_id: "i50jj3",
        modes: %w[plan],
        synthesis: {
          questions: ["Q1"],
          refinements: ["R1"],
          artifacts: { "plan" => plan_artifact }
        }
      )

      content = File.read(path)
      assert_includes content, "<!-- sim-artifact:plan -->"
      assert_includes content, "<!-- /sim-artifact:plan -->"
      assert_includes content, "## Simulated Plan"
      assert_includes content, "# Plan: My Plan"
      assert_includes content, "1. Do something"
    end
  end

  def test_apply_upserts_artifact_section_without_duplication
    with_real_tmpdir do |dir|
      path = File.join(dir, "task.s.md")
      File.write(path, <<~MARKDOWN)
        # Task

        ## Simulation Review (Next-Phase)
        - Last run: `oldrun`

        <!-- sim-artifact:plan -->
        ## Simulated Plan

        # Plan: Old Plan

        ## Old Step
        Old content
        <!-- /sim-artifact:plan -->
      MARKDOWN

      plan_artifact = "# Plan: New Plan\n\n## New Step\nNew content\n"
      @writeback.apply(
        path: path,
        run_id: "newrun",
        modes: %w[plan],
        synthesis: {
          questions: [],
          refinements: [],
          artifacts: { "plan" => plan_artifact }
        }
      )

      content = File.read(path)
      assert_equal 1, content.scan("<!-- sim-artifact:plan -->").length
      assert_includes content, "# Plan: New Plan"
      refute_includes content, "# Plan: Old Plan"
    end
  end
end
