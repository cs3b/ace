# frozen_string_literal: true

require_relative "../test_helper"

class SkillAssignSourceResolverTest < AceAssignTestCase
  def test_resolve_assign_config_from_skill_source
    with_temp_cache do |cache_dir|
      project_root = File.join(cache_dir, "project")
      FileUtils.mkdir_p(File.join(project_root, ".claude", "skills", "ace_work-on-task"))
      FileUtils.mkdir_p(File.join(project_root, "ace-taskflow", "handbook", "workflow-instructions"))

      File.write(File.join(project_root, ".claude", "skills", "ace_work-on-task", "SKILL.md"), <<~MD)
        ---
        name: ace:work-on-task
        assign:
          source: wfi://work-on-task
        ---
      MD

      File.write(File.join(project_root, "ace-taskflow", "handbook", "workflow-instructions", "work-on-task.wf.md"), <<~MD)
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
      config = resolver.resolve_assign_config("ace:work-on-task")

      assert_equal %w[onboard plan-task work-on-task], config[:sub_phases]
      assert_equal "fork", config[:context]
    end
  end

  def test_resolve_assign_config_returns_nil_without_source
    with_temp_cache do |cache_dir|
      project_root = File.join(cache_dir, "project")
      FileUtils.mkdir_p(File.join(project_root, ".claude", "skills", "ace_work-on-task"))

      File.write(File.join(project_root, ".claude", "skills", "ace_work-on-task", "SKILL.md"), <<~MD)
        ---
        name: ace:work-on-task
        ---
      MD

      resolver = Ace::Assign::Molecules::SkillAssignSourceResolver.new(project_root: project_root)

      assert_nil resolver.resolve_assign_config("ace:work-on-task")
    end
  end

  def test_resolve_assign_config_raises_for_unresolvable_wfi_source
    with_temp_cache do |cache_dir|
      project_root = File.join(cache_dir, "project")
      FileUtils.mkdir_p(File.join(project_root, ".claude", "skills", "ace_work-on-task"))

      File.write(File.join(project_root, ".claude", "skills", "ace_work-on-task", "SKILL.md"), <<~MD)
        ---
        name: ace:work-on-task
        assign:
          source: wfi://missing-workflow
        ---
      MD

      resolver = Ace::Assign::Molecules::SkillAssignSourceResolver.new(project_root: project_root)

      error = assert_raises(Ace::Assign::Error) do
        resolver.resolve_assign_config("ace:work-on-task")
      end
      assert_includes error.message, "Could not resolve assign.source"
    end
  end
end
