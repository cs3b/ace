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
        synthesis: { questions: ["Q1"], refinements: ["R1"] }
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
        synthesis: { questions: ["New question"], refinements: [] }
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
        synthesis: { questions: ["New question"], refinements: ["New refinement"] }
      )

      content = File.read(path)
      assert_equal 1, content.scan("## Simulation Review (Next-Phase)").length
      assert_includes content, "New question"
      refute_includes content, "Old question"
    end
  end
end
