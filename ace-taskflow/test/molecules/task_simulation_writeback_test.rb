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
          unresolved_gaps: ["Gap1"]
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
        synthesis: { questions: ["New question"], refinements: ["New refinement"] }
      )

      content = File.read(path)
      assert_equal 1, content.scan("## Simulation Review (Next-Phase)").length
      refute_includes content, "Old question"
      assert_includes content, "New question"
      assert_includes content, "New refinement"
    end
  end
end
