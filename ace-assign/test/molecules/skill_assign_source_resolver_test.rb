# frozen_string_literal: true

require_relative "../test_helper"

class SkillAssignSourceResolverTest < AceAssignTestCase
  def test_resolve_assign_config_from_skill_source
    with_temp_cache do |cache_dir|
      project_root = File.join(cache_dir, "project")
      FileUtils.mkdir_p(File.join(project_root, "ace-task", ".ace-defaults", "nav", "protocols", "skill-sources"))
      FileUtils.mkdir_p(File.join(project_root, "ace-task", "handbook", "skills", "as-task-work"))
      FileUtils.mkdir_p(File.join(project_root, "ace-taskflow", "handbook", "workflow-instructions", "task"))

      File.write(File.join(project_root, "ace-task", ".ace-defaults", "nav", "protocols", "skill-sources", "ace-task.yml"), <<~YAML)
        name: ace-task
        config:
          relative_path: handbook/skills
      YAML

      File.write(File.join(project_root, "ace-task", "handbook", "skills", "as-task-work", "SKILL.md"), <<~MD)
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

  def test_assign_capable_skill_names_only_includes_workflow_or_orchestration_with_assign_source
    with_temp_cache do |cache_dir|
      project_root = File.join(cache_dir, "project")
      FileUtils.mkdir_p(File.join(project_root, "ace-task", "handbook", "skills", "as-task-plan"))
      FileUtils.mkdir_p(File.join(project_root, "ace-assign", "handbook", "skills", "as-assign-start"))
      FileUtils.mkdir_p(File.join(project_root, "ace-b36ts", "handbook", "skills", "as-b36ts"))
      FileUtils.mkdir_p(File.join(project_root, "ace-task", "handbook", "workflow-instructions", "task"))
      FileUtils.mkdir_p(File.join(project_root, "ace-assign", "handbook", "workflow-instructions", "assign"))
      FileUtils.mkdir_p(File.join(project_root, "ace-task", ".ace-defaults", "nav", "protocols", "skill-sources"))
      FileUtils.mkdir_p(File.join(project_root, "ace-assign", ".ace-defaults", "nav", "protocols", "skill-sources"))
      FileUtils.mkdir_p(File.join(project_root, "ace-b36ts", ".ace-defaults", "nav", "protocols", "skill-sources"))

      File.write(File.join(project_root, "ace-task", ".ace-defaults", "nav", "protocols", "skill-sources", "ace-task.yml"), <<~YAML)
        name: ace-task
        config:
          relative_path: handbook/skills
      YAML

      File.write(File.join(project_root, "ace-assign", ".ace-defaults", "nav", "protocols", "skill-sources", "ace-assign.yml"), <<~YAML)
        name: ace-assign
        config:
          relative_path: handbook/skills
      YAML

      File.write(File.join(project_root, "ace-b36ts", ".ace-defaults", "nav", "protocols", "skill-sources", "ace-b36ts.yml"), <<~YAML)
        name: ace-b36ts
        config:
          relative_path: handbook/skills
      YAML

      File.write(File.join(project_root, "ace-task", "handbook", "skills", "as-task-plan", "SKILL.md"), <<~MD)
        ---
        name: as-task-plan
        skill:
          kind: workflow
        assign:
          source: wfi://task/plan
        ---
      MD

      File.write(File.join(project_root, "ace-assign", "handbook", "skills", "as-assign-start", "SKILL.md"), <<~MD)
        ---
        name: as-assign-start
        skill:
          kind: orchestration
        assign:
          source: wfi://assign/start
        ---
      MD

      File.write(File.join(project_root, "ace-b36ts", "handbook", "skills", "as-b36ts", "SKILL.md"), <<~MD)
        ---
        name: as-b36ts
        skill:
          kind: capability
        assign:
          source: wfi://b36ts
        ---
      MD

      File.write(File.join(project_root, "ace-task", "handbook", "workflow-instructions", "task", "plan.wf.md"), <<~MD)
        ---
        ---
      MD
      File.write(File.join(project_root, "ace-assign", "handbook", "workflow-instructions", "assign", "start.wf.md"), <<~MD)
        ---
        ---
      MD

      resolver = Ace::Assign::Molecules::SkillAssignSourceResolver.new(project_root: project_root)
      skill_names = resolver.assign_capable_skill_names

      assert_equal %w[as-assign-start as-task-plan], skill_names.sort
    end
  end

  def test_assign_phase_catalog_uses_canonical_phase_metadata_from_skills
    with_temp_cache do |cache_dir|
      project_root = File.join(cache_dir, "project")
      FileUtils.mkdir_p(File.join(project_root, "ace-task", "handbook", "skills", "as-task-plan"))
      FileUtils.mkdir_p(File.join(project_root, "ace-task", ".ace-defaults", "nav", "protocols", "skill-sources"))

      File.write(File.join(project_root, "ace-task", ".ace-defaults", "nav", "protocols", "skill-sources", "ace-task.yml"), <<~YAML)
        name: ace-task
        config:
          relative_path: handbook/skills
      YAML

      File.write(File.join(project_root, "ace-task", "handbook", "skills", "as-task-plan", "SKILL.md"), <<~MD)
        ---
        name: as-task-plan
        description: Plan the task
        skill:
          kind: workflow
        assign:
          source: wfi://task/plan
          phases:
            - name: plan-task
              description: Canonical phase description
              context:
                default: fork
        ---
      MD

      resolver = Ace::Assign::Molecules::SkillAssignSourceResolver.new(project_root: project_root)
      phases = resolver.assign_phase_catalog

      assert_equal 1, phases.length
      assert_equal "plan-task", phases.first["name"]
      assert_equal "as-task-plan", phases.first["skill"]
      assert_equal "Canonical phase description", phases.first["description"]
      assert_equal({ "default" => "fork" }, phases.first["context"])
    end
  end

  def test_assign_capable_skill_names_excludes_assign_capable_skill_without_assign_source
    with_temp_cache do |cache_dir|
      project_root = File.join(cache_dir, "project")
      FileUtils.mkdir_p(File.join(project_root, "ace-task", "handbook", "skills", "as-task-plan"))
      FileUtils.mkdir_p(File.join(project_root, "ace-task", ".ace-defaults", "nav", "protocols", "skill-sources"))

      File.write(File.join(project_root, "ace-task", ".ace-defaults", "nav", "protocols", "skill-sources", "ace-task.yml"), <<~YAML)
        name: ace-task
        config:
          relative_path: handbook/skills
      YAML

      File.write(File.join(project_root, "ace-task", "handbook", "skills", "as-task-plan", "SKILL.md"), <<~MD)
        ---
        name: as-task-plan
        skill:
          kind: workflow
        ---
      MD

      resolver = Ace::Assign::Molecules::SkillAssignSourceResolver.new(project_root: project_root)

      assert_equal [], resolver.assign_capable_skill_names
    end
  end

  def test_resolve_assign_config_returns_nil_without_source
    with_temp_cache do |cache_dir|
      project_root = File.join(cache_dir, "project")
      FileUtils.mkdir_p(File.join(project_root, "ace-task", ".ace-defaults", "nav", "protocols", "skill-sources"))
      FileUtils.mkdir_p(File.join(project_root, "ace-task", "handbook", "skills", "as-task-work"))

      File.write(File.join(project_root, "ace-task", ".ace-defaults", "nav", "protocols", "skill-sources", "ace-task.yml"), <<~YAML)
        name: ace-task
        config:
          relative_path: handbook/skills
      YAML

      File.write(File.join(project_root, "ace-task", "handbook", "skills", "as-task-work", "SKILL.md"), <<~MD)
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
      FileUtils.mkdir_p(File.join(project_root, "ace-task", ".ace-defaults", "nav", "protocols", "skill-sources"))
      FileUtils.mkdir_p(File.join(project_root, "ace-task", "handbook", "skills", "as-task-work"))

      File.write(File.join(project_root, "ace-task", ".ace-defaults", "nav", "protocols", "skill-sources", "ace-task.yml"), <<~YAML)
        name: ace-task
        config:
          relative_path: handbook/skills
      YAML

      File.write(File.join(project_root, "ace-task", "handbook", "skills", "as-task-work", "SKILL.md"), <<~MD)
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

  def test_resolve_assign_config_raises_for_assign_capable_skill_with_empty_assign_source
    with_temp_cache do |cache_dir|
      project_root = File.join(cache_dir, "project")
      FileUtils.mkdir_p(File.join(project_root, "ace-task", "handbook", "skills", "as-task-plan"))

      File.write(File.join(project_root, "ace-task", "handbook", "skills", "as-task-plan", "SKILL.md"), <<~MD)
        ---
        name: as-task-plan
        skill:
          kind: workflow
        assign:
          source:
        ---
      MD

      resolver = Ace::Assign::Molecules::SkillAssignSourceResolver.new(
        project_root: project_root,
        skill_paths: [File.join(project_root, "ace-task", "handbook", "skills")]
      )

      error = assert_raises(Ace::Assign::Error) do
        resolver.resolve_assign_config("as-task-plan")
      end
      assert_includes error.message, "Missing assign.source"
    end
  end

  def test_project_skill_source_override_takes_priority_over_gem_default
    with_temp_cache do |cache_dir|
      project_root = File.join(cache_dir, "project")
      gem_skills = File.join(project_root, "ace-task", "handbook", "skills", "as-task-work")
      project_skills = File.join(project_root, ".ace", "skills", "as-task-work")
      workflow_dir = File.join(project_root, "ace-taskflow", "handbook", "workflow-instructions", "task")

      FileUtils.mkdir_p(File.join(project_root, "ace-task", ".ace-defaults", "nav", "protocols", "skill-sources"))
      FileUtils.mkdir_p(File.join(project_root, ".ace", "nav", "protocols", "skill-sources"))
      FileUtils.mkdir_p(gem_skills)
      FileUtils.mkdir_p(project_skills)
      FileUtils.mkdir_p(workflow_dir)

      File.write(File.join(project_root, "ace-task", ".ace-defaults", "nav", "protocols", "skill-sources", "ace-task.yml"), <<~YAML)
        name: ace-task
        type: gem
        priority: 50
        config:
          relative_path: handbook/skills
      YAML

      File.write(File.join(project_root, ".ace", "nav", "protocols", "skill-sources", "local.yml"), <<~YAML)
        name: local-skill-overrides
        type: directory
        path: .ace/skills
        priority: 5
      YAML

      File.write(File.join(gem_skills, "SKILL.md"), <<~MD)
        ---
        name: as-task-work
        assign:
          source: wfi://task/gem-work
        ---
      MD

      File.write(File.join(project_skills, "SKILL.md"), <<~MD)
        ---
        name: as-task-work
        assign:
          source: wfi://task/project-work
        ---
      MD

      File.write(File.join(workflow_dir, "gem-work.wf.md"), <<~MD)
        ---
        assign:
          sub-phases:
            - gem-phase
        ---
      MD

      File.write(File.join(workflow_dir, "project-work.wf.md"), <<~MD)
        ---
        assign:
          sub-phases:
            - project-phase
        ---
      MD

      Dir.chdir(project_root) do
        resolver = Ace::Assign::Molecules::SkillAssignSourceResolver.new(project_root: project_root)
        config = resolver.resolve_assign_config("as-task-work")

        assert_equal ["project-phase"], config[:sub_phases]
      end
    end
  end

  def test_configured_skill_paths_remain_fallback_after_registry_sources
    with_temp_cache do |cache_dir|
      project_root = File.join(cache_dir, "project")
      workflow_dir = File.join(project_root, "ace-taskflow", "handbook", "workflow-instructions", "task")
      fallback_dir = File.join(project_root, "custom-skills", "as-task-work")

      FileUtils.mkdir_p(workflow_dir)
      FileUtils.mkdir_p(fallback_dir)

      File.write(File.join(fallback_dir, "SKILL.md"), <<~MD)
        ---
        name: as-task-work
        assign:
          source: wfi://task/fallback-work
        ---
      MD

      File.write(File.join(workflow_dir, "fallback-work.wf.md"), <<~MD)
        ---
        assign:
          sub-phases:
            - fallback-phase
        ---
      MD

      resolver = Ace::Assign::Molecules::SkillAssignSourceResolver.new(
        project_root: project_root,
        skill_paths: [File.join(project_root, "custom-skills")]
      )
      config = resolver.resolve_assign_config("as-task-work")

      assert_equal ["fallback-phase"], config[:sub_phases]
    end
  end
end
