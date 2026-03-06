# frozen_string_literal: true

require_relative "../test_helper"

class SkillAssignSourceResolverTest < AceAssignTestCase
  def test_resolve_assign_config_from_skill_source
    with_temp_cache do |cache_dir|
      project_root = File.join(cache_dir, "project")
      FileUtils.mkdir_p(File.join(project_root, ".claude", "skills", "as-task-work"))
      FileUtils.mkdir_p(File.join(project_root, "ace-taskflow", "handbook", "workflow-instructions", "task"))

      File.write(File.join(project_root, ".claude", "skills", "as-task-work", "SKILL.md"), <<~MD)
        ---
        name: as-task-work
        assign:
          source: wfi://task/work
        ---
      MD

      File.write(File.join(project_root, "ace-taskflow", "handbook", "workflow-instructions", "task", "work.wf.md"), <<~MD)
        ---
        assign:
          sub-phases:
            - onboard
            - plan-task
            - work-on-task
          context: fork
        ---
      MD

      resolver = Ace::Assign::Molecules::SkillAssignSourceResolver.new(project_root: project_root)
      config = resolver.resolve_assign_config("as-task-work")

      assert_equal %w[onboard plan-task work-on-task], config[:sub_phases]
      assert_equal "fork", config[:context]
    end
  end

  def test_resolve_assign_config_returns_nil_without_source
    with_temp_cache do |cache_dir|
      project_root = File.join(cache_dir, "project")
      FileUtils.mkdir_p(File.join(project_root, ".claude", "skills", "as-task-work"))

      File.write(File.join(project_root, ".claude", "skills", "as-task-work", "SKILL.md"), <<~MD)
        ---
        name: as-task-work
        ---
      MD

      resolver = Ace::Assign::Molecules::SkillAssignSourceResolver.new(project_root: project_root)

      assert_nil resolver.resolve_assign_config("as-task-work")
    end
  end

  def test_resolve_assign_config_raises_for_unresolvable_wfi_source
    with_temp_cache do |cache_dir|
      project_root = File.join(cache_dir, "project")
      FileUtils.mkdir_p(File.join(project_root, ".claude", "skills", "as-task-work"))

      File.write(File.join(project_root, ".claude", "skills", "as-task-work", "SKILL.md"), <<~MD)
        ---
        name: as-task-work
        assign:
          source: wfi://missing-workflow
        ---
      MD

      resolver = Ace::Assign::Molecules::SkillAssignSourceResolver.new(project_root: project_root)

      error = assert_raises(Ace::Assign::Error) do
        resolver.resolve_assign_config("as-task-work")
      end
      assert_includes error.message, "Could not resolve assign.source"
    end
  end
end
