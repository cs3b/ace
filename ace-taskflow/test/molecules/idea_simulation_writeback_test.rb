# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/molecules/simulation_writeback_mixin"
require_relative "../../lib/ace/taskflow/molecules/idea_simulation_writeback"

class IdeaSimulationWritebackTest < AceTaskflowTestCase
  def test_apply_appends_section_when_missing
    with_real_tmpdir do |dir|
      path = File.join(dir, "idea.idea.s.md")
      File.write(path, "# Idea\n")

      writeback = Ace::Taskflow::Molecules::IdeaSimulationWriteback.new
      writeback.apply(
        path: path,
        run_id: "i50jj3",
        modes: %w[draft plan],
        synthesis: { questions: ["Q1"], refinements: ["R1"], artifacts: {} }
      )

      content = File.read(path)
      assert_includes content, "## Simulation Review (Next-Phase)"
      assert_includes content, "- Q1"
      assert_includes content, "- R1"
    end
  end

  def test_upsert_replaces_section_when_non_heading_content_follows
    with_real_tmpdir do |dir|
      path = File.join(dir, "idea.idea.s.md")
      initial = <<~MARKDOWN
        # Idea

        ## Simulation Review (Next-Phase)
        - Last run: `old123`

        ### Questions
        - Old question

        Some trailing text without a ## heading
      MARKDOWN
      File.write(path, initial)

      writeback = Ace::Taskflow::Molecules::IdeaSimulationWriteback.new
      writeback.apply(
        path: path,
        run_id: "i50jj3",
        modes: %w[draft plan],
        synthesis: { questions: ["New question"], refinements: [], artifacts: {} }
      )

      content = File.read(path)
      assert_equal 1, content.scan("## Simulation Review (Next-Phase)").length
      assert_includes content, "New question"
      refute_includes content, "Old question"
    end
  end

  def test_apply_updates_section_in_place_without_duplicates
    with_real_tmpdir do |dir|
      path = File.join(dir, "idea.idea.s.md")
      initial = <<~MARKDOWN
        # Idea

        ## Simulation Review (Next-Phase)
        - Last run: `old123`
        - Modes: `draft,plan`

        ### Questions
        - Old question
      MARKDOWN
      File.write(path, initial)

      writeback = Ace::Taskflow::Molecules::IdeaSimulationWriteback.new
      writeback.apply(
        path: path,
        run_id: "i50jj3",
        modes: %w[draft plan],
        synthesis: { questions: ["New question"], refinements: ["New refinement"], artifacts: {} }
      )

      content = File.read(path)
      assert_equal 1, content.scan("## Simulation Review (Next-Phase)").length
      assert_includes content, "New question"
      refute_includes content, "Old question"
    end
  end

  def test_apply_writes_draft_and_plan_artifact_sections
    with_real_tmpdir do |dir|
      path = File.join(dir, "idea.idea.s.md")
      File.write(path, "# Idea\n\n## Description\nCapture the idea.\n")

      draft_artifact = "# Task: Implement Feature\n\n## Description\nDo the feature.\n"
      plan_artifact = "# Plan: Implement Feature\n\n## Steps\n1. Write code\n"

      writeback = Ace::Taskflow::Molecules::IdeaSimulationWriteback.new
      writeback.apply(
        path: path,
        run_id: "i50jj3",
        modes: %w[draft plan],
        synthesis: {
          questions: ["Q1"],
          refinements: [],
          artifacts: { "draft" => draft_artifact, "plan" => plan_artifact }
        }
      )

      content = File.read(path)
      assert_includes content, "<!-- sim-artifact:draft -->"
      assert_includes content, "<!-- /sim-artifact:draft -->"
      assert_includes content, "## Simulated Draft"
      assert_includes content, "# Task: Implement Feature"
      assert_includes content, "<!-- sim-artifact:plan -->"
      assert_includes content, "<!-- /sim-artifact:plan -->"
      assert_includes content, "## Simulated Plan"
      assert_includes content, "# Plan: Implement Feature"
    end
  end

  def test_apply_writes_draft_review_artifact_section
    with_real_tmpdir do |dir|
      path = File.join(dir, "idea.idea.s.md")
      File.write(path, "# Idea\n\n## Description\nCapture the idea.\n")

      draft_artifact = "# Task: Implement Feature\n\n## Description\nDo the feature.\n"
      review_artifact = "## Readiness Review\n\n- [x] Has description\n- [ ] Missing AC\n"

      writeback = Ace::Taskflow::Molecules::IdeaSimulationWriteback.new
      writeback.apply(
        path: path,
        run_id: "i50jj3",
        modes: %w[draft plan],
        synthesis: {
          questions: ["Q1"],
          refinements: [],
          artifacts: { "draft" => draft_artifact, "draft_review" => review_artifact }
        }
      )

      content = File.read(path)
      assert_includes content, "<!-- sim-artifact:draft_review -->"
      assert_includes content, "<!-- /sim-artifact:draft_review -->"
      assert_includes content, "## Simulated Draft Review"
      assert_includes content, "## Readiness Review"
      assert_includes content, "- [x] Has description"
      # Also verify draft artifact is still present
      assert_includes content, "<!-- sim-artifact:draft -->"
      assert_includes content, "## Simulated Draft"
    end
  end

  def test_artifact_section_upsert_replaces_old_content
    with_real_tmpdir do |dir|
      path = File.join(dir, "idea.idea.s.md")
      File.write(path, <<~MARKDOWN)
        # Idea

        ## Simulation Review (Next-Phase)
        - Last run: `old123`

        <!-- sim-artifact:draft -->
        ## Simulated Draft

        # Task: Old Draft

        ## Old Description
        Old content here
        <!-- /sim-artifact:draft -->
      MARKDOWN

      new_draft = "# Task: New Draft\n\n## New Description\nNew content here\n"

      writeback = Ace::Taskflow::Molecules::IdeaSimulationWriteback.new
      writeback.apply(
        path: path,
        run_id: "newrun",
        modes: %w[draft plan],
        synthesis: {
          questions: [],
          refinements: [],
          artifacts: { "draft" => new_draft }
        }
      )

      content = File.read(path)
      assert_equal 1, content.scan("<!-- sim-artifact:draft -->").length
      assert_includes content, "# Task: New Draft"
      refute_includes content, "# Task: Old Draft"
    end
  end
end
