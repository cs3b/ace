# frozen_string_literal: true

require_relative "../test_helper"

class SkillAssignSourceResolverTest < AceAssignTestCase
  def test_resolve_assign_config_from_skill_source
    with_temp_cache do |cache_dir|
      project_root = File.join(cache_dir, "project")
      FileUtils.mkdir_p(File.join(project_root, "ace-task", ".ace-defaults", "nav", "protocols", "skill-sources"))
      FileUtils.mkdir_p(File.join(project_root, "ace-taskflow", ".ace-defaults", "nav", "protocols", "wfi-sources"))
      FileUtils.mkdir_p(File.join(project_root, "ace-task", "handbook", "skills", "as-task-work"))
      FileUtils.mkdir_p(File.join(project_root, "ace-taskflow", "handbook", "workflow-instructions", "task"))

      File.write(File.join(project_root, "ace-task", ".ace-defaults", "nav", "protocols", "skill-sources", "ace-task.yml"), <<~YAML)
        name: ace-task
        config:
          relative_path: handbook/skills
      YAML

      File.write(File.join(project_root, "ace-taskflow", ".ace-defaults", "nav", "protocols", "wfi-sources", "ace-taskflow.yml"), <<~YAML)
        name: ace-taskflow
        config:
          relative_path: handbook/workflow-instructions
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
          sub-steps:
            - onboard
            - plan-task
            - work-on-task
          context: fork
        ---
      MD

      resolver = Ace::Assign::Molecules::SkillAssignSourceResolver.new(project_root: project_root)
      config = resolver.resolve_assign_config("as-task-work")

      assert_equal %w[onboard plan-task work-on-task], config[:sub_steps]
      assert_equal "fork", config[:context]
    end
  end

  def test_assign_capable_skill_names_only_includes_public_workflow_or_orchestration_with_workflow_binding
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
        user-invocable: true
        skill:
          kind: workflow
          execution:
            workflow: wfi://task/plan
        assign:
          steps: []
        ---
      MD

      File.write(File.join(project_root, "ace-assign", "handbook", "skills", "as-assign-start", "SKILL.md"), <<~MD)
        ---
        name: as-assign-start
        user-invocable: false
        skill:
          kind: orchestration
          execution:
            workflow: wfi://assign/start
        assign:
          steps: []
        ---
      MD

      File.write(File.join(project_root, "ace-b36ts", "handbook", "skills", "as-b36ts", "SKILL.md"), <<~MD)
        ---
        name: as-b36ts
        user-invocable: true
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

      assert_equal %w[as-task-plan], skill_names.sort
    end
  end

  def test_assign_step_catalog_uses_canonical_step_metadata_from_skills
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
        user-invocable: true
        skill:
          kind: workflow
          execution:
            workflow: wfi://task/plan
        assign:
          steps:
            - name: plan-task
              description: Canonical step description
              context:
                default: fork
        ---
      MD

      resolver = Ace::Assign::Molecules::SkillAssignSourceResolver.new(project_root: project_root)
      steps = resolver.assign_step_catalog

      assert_equal 1, steps.length
      assert_equal "plan-task", steps.first["name"]
      assert_equal "skill://as-task-plan", steps.first["source"]
      assert_equal "as-task-plan", steps.first["skill"]
      assert_equal "Canonical step description", steps.first["description"]
      assert_equal({"default" => "fork"}, steps.first["context"])
    end
  end

  def test_assign_step_catalog_excludes_internal_non_user_invocable_skills
    with_temp_cache do |cache_dir|
      project_root = File.join(cache_dir, "project")
      FileUtils.mkdir_p(File.join(project_root, "ace-assign", "handbook", "skills", "as-task-load-internal"))
      FileUtils.mkdir_p(File.join(project_root, "ace-assign", ".ace-defaults", "nav", "protocols", "skill-sources"))

      File.write(File.join(project_root, "ace-assign", ".ace-defaults", "nav", "protocols", "skill-sources", "ace-assign.yml"), <<~YAML)
        name: ace-assign
        config:
          relative_path: handbook/skills
      YAML

      File.write(File.join(project_root, "ace-assign", "handbook", "skills", "as-task-load-internal", "SKILL.md"), <<~MD)
        ---
        name: as-task-load-internal
        user-invocable: false
        skill:
          kind: workflow
        assign:
          source: wfi://assign/task-load-internal
          steps:
            - name: task-load
              description: Internal helper step
        ---
      MD

      resolver = Ace::Assign::Molecules::SkillAssignSourceResolver.new(project_root: project_root)
      steps = resolver.assign_step_catalog

      assert_equal [], steps
    end
  end

  def test_resolve_skill_rendering_returns_body_and_workflow_metadata
    with_temp_cache do |cache_dir|
      project_root = File.join(cache_dir, "project")
      FileUtils.mkdir_p(File.join(project_root, "ace-task", "handbook", "skills", "as-task-plan"))
      FileUtils.mkdir_p(File.join(project_root, "ace-task", "handbook", "workflow-instructions", "task"))
      FileUtils.mkdir_p(File.join(project_root, "ace-task", ".ace-defaults", "nav", "protocols", "skill-sources"))
      FileUtils.mkdir_p(File.join(project_root, "ace-task", ".ace-defaults", "nav", "protocols", "wfi-sources"))

      File.write(File.join(project_root, "ace-task", ".ace-defaults", "nav", "protocols", "skill-sources", "ace-task.yml"), <<~YAML)
        name: ace-task
        config:
          relative_path: handbook/skills
      YAML

      File.write(File.join(project_root, "ace-task", ".ace-defaults", "nav", "protocols", "wfi-sources", "ace-task.yml"), <<~YAML)
        name: ace-task
        config:
          relative_path: handbook/workflow-instructions
      YAML

      File.write(File.join(project_root, "ace-task", "handbook", "skills", "as-task-plan", "SKILL.md"), <<~MD)
        ---
        name: as-task-plan
        skill:
          kind: workflow
          execution:
            workflow: wfi://task/plan
        ---

        Load and run `ace-bundle wfi://task/plan`
      MD

      File.write(File.join(project_root, "ace-task", "handbook", "workflow-instructions", "task", "plan.wf.md"), <<~MD)
        ---
        ---
      MD

      resolver = Ace::Assign::Molecules::SkillAssignSourceResolver.new(project_root: project_root)
      rendering = resolver.resolve_skill_rendering("as-task-plan")

      assert_equal "as-task-plan", rendering["skill"]
      assert_equal "skill://as-task-plan", rendering["source"]
      assert_equal "wfi://task/plan", rendering["workflow"]
      assert_includes rendering["body"], "ace-bundle wfi://task/plan"
      assert_match(%r{task/plan\.wf\.md\z}, rendering["workflow_path"])
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
      assert_includes error.message, "Could not resolve workflow binding"
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
      assert_includes error.message, "Missing workflow binding"
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
      FileUtils.mkdir_p(File.join(project_root, "ace-taskflow", ".ace-defaults", "nav", "protocols", "wfi-sources"))
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

      File.write(File.join(project_root, "ace-taskflow", ".ace-defaults", "nav", "protocols", "wfi-sources", "ace-taskflow.yml"), <<~YAML)
        name: ace-taskflow
        config:
          relative_path: handbook/workflow-instructions
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
          sub-steps:
            - gem-step
        ---
      MD

      File.write(File.join(workflow_dir, "project-work.wf.md"), <<~MD)
        ---
        assign:
          sub-steps:
            - project-step
        ---
      MD

      Dir.chdir(project_root) do
        resolver = Ace::Assign::Molecules::SkillAssignSourceResolver.new(project_root: project_root)
        config = resolver.resolve_assign_config("as-task-work")

        assert_equal ["project-step"], config[:sub_steps]
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
          sub-steps:
            - fallback-step
        ---
      MD

      resolver = Ace::Assign::Molecules::SkillAssignSourceResolver.new(
        project_root: project_root,
        skill_paths: [File.join(project_root, "custom-skills")],
        workflow_paths: [File.join(project_root, "ace-taskflow", "handbook", "workflow-instructions")]
      )
      config = resolver.resolve_assign_config("as-task-work")

      assert_equal ["fallback-step"], config[:sub_steps]
    end
  end

  def test_resolve_assign_config_uses_project_registered_wfi_source_before_gem_default
    with_temp_cache do |cache_dir|
      project_root = File.join(cache_dir, "project")
      gem_skills = File.join(project_root, "ace-task", "handbook", "skills", "as-task-work")
      gem_workflows = File.join(project_root, "ace-taskflow", "handbook", "workflow-instructions", "task")
      project_workflows = File.join(project_root, ".ace", "workflows", "task")

      FileUtils.mkdir_p(File.join(project_root, "ace-task", ".ace-defaults", "nav", "protocols", "skill-sources"))
      FileUtils.mkdir_p(File.join(project_root, "ace-taskflow", ".ace-defaults", "nav", "protocols", "wfi-sources"))
      FileUtils.mkdir_p(File.join(project_root, ".ace", "nav", "protocols", "wfi-sources"))
      FileUtils.mkdir_p(gem_skills)
      FileUtils.mkdir_p(gem_workflows)
      FileUtils.mkdir_p(project_workflows)

      File.write(File.join(project_root, "ace-task", ".ace-defaults", "nav", "protocols", "skill-sources", "ace-task.yml"), <<~YAML)
        name: ace-task
        config:
          relative_path: handbook/skills
      YAML

      File.write(File.join(project_root, "ace-taskflow", ".ace-defaults", "nav", "protocols", "wfi-sources", "ace-taskflow.yml"), <<~YAML)
        name: ace-taskflow
        type: gem
        priority: 50
        config:
          relative_path: handbook/workflow-instructions
      YAML

      File.write(File.join(project_root, ".ace", "nav", "protocols", "wfi-sources", "local.yml"), <<~YAML)
        name: local-workflow-overrides
        type: directory
        path: .ace/workflows
        priority: 5
      YAML

      File.write(File.join(gem_skills, "SKILL.md"), <<~MD)
        ---
        name: as-task-work
        assign:
          source: wfi://task/work
        ---
      MD

      File.write(File.join(gem_workflows, "work.wf.md"), <<~MD)
        ---
        assign:
          sub-steps:
            - gem-step
        ---
      MD

      File.write(File.join(project_workflows, "work.wf.md"), <<~MD)
        ---
        assign:
          sub-steps:
            - project-step
        ---
      MD

      Dir.chdir(project_root) do
        resolver = Ace::Assign::Molecules::SkillAssignSourceResolver.new(project_root: project_root)
        config = resolver.resolve_assign_config("as-task-work")

        assert_equal ["project-step"], config[:sub_steps]
      end
    end
  end

  def test_resolve_assign_config_requires_registered_wfi_source
    with_temp_cache do |cache_dir|
      project_root = File.join(cache_dir, "project")
      skill_dir = File.join(project_root, "ace-task", "handbook", "skills", "as-task-work")
      unregistered_workflows = File.join(project_root, "ace-taskflow", "handbook", "workflow-instructions", "task")

      FileUtils.mkdir_p(File.join(project_root, "ace-task", ".ace-defaults", "nav", "protocols", "skill-sources"))
      FileUtils.mkdir_p(skill_dir)
      FileUtils.mkdir_p(unregistered_workflows)

      File.write(File.join(project_root, "ace-task", ".ace-defaults", "nav", "protocols", "skill-sources", "ace-task.yml"), <<~YAML)
        name: ace-task
        config:
          relative_path: handbook/skills
      YAML

      File.write(File.join(skill_dir, "SKILL.md"), <<~MD)
        ---
        name: as-task-work
        assign:
          source: wfi://task/work
        ---
      MD

      File.write(File.join(unregistered_workflows, "work.wf.md"), <<~MD)
        ---
        assign:
          sub-steps:
            - stray-step
        ---
      MD

      resolver = Ace::Assign::Molecules::SkillAssignSourceResolver.new(project_root: project_root)
      error = assert_raises(Ace::Assign::Error) { resolver.resolve_assign_config("as-task-work") }

      assert_includes error.message, "Could not resolve workflow binding"
    end
  end

  def test_resolve_step_rendering_preserves_step_level_description
    with_temp_cache do |cache_dir|
      project_root = File.join(cache_dir, "project")
      skill_dir = File.join(project_root, "ace-test", "handbook", "skills", "as-test-verify-suite")
      workflow_dir = File.join(project_root, "ace-test", "handbook", "workflow-instructions", "test")

      FileUtils.mkdir_p(File.join(project_root, "ace-test", ".ace-defaults", "nav", "protocols", "skill-sources"))
      FileUtils.mkdir_p(File.join(project_root, "ace-test", ".ace-defaults", "nav", "protocols", "wfi-sources"))
      FileUtils.mkdir_p(skill_dir)
      FileUtils.mkdir_p(workflow_dir)

      File.write(File.join(project_root, "ace-test", ".ace-defaults", "nav", "protocols", "skill-sources", "ace-test.yml"), <<~YAML)
        name: ace-test
        config:
          relative_path: handbook/skills
      YAML

      File.write(File.join(project_root, "ace-test", ".ace-defaults", "nav", "protocols", "wfi-sources", "ace-test.yml"), <<~YAML)
        name: ace-test
        config:
          relative_path: handbook/workflow-instructions
      YAML

      File.write(File.join(skill_dir, "SKILL.md"), <<~MD)
        ---
        name: as-test-verify-suite
        description: Broad skill description
        user-invocable: true
        skill:
          kind: workflow
          execution:
            workflow: wfi://test/verify-suite
        assign:
          steps:
            - name: verify-test-suite
              description: Specific step description
        ---
      MD

      File.write(File.join(workflow_dir, "verify-suite.wf.md"), <<~MD)
        ---
        ---

        Workflow body.
      MD

      resolver = Ace::Assign::Molecules::SkillAssignSourceResolver.new(project_root: project_root)
      rendering = resolver.resolve_step_rendering("verify-test-suite")

      assert_equal "verify-test-suite", rendering["name"]
      assert_equal "Specific step description", rendering["description"]
      assert_equal "skill://as-test-verify-suite", rendering["source"]
      assert_includes rendering["body"], "Workflow body"
    end
  end

  def test_resolve_source_rendering_supports_skill_protocol
    with_temp_cache do |cache_dir|
      project_root = File.join(cache_dir, "project")
      FileUtils.mkdir_p(File.join(project_root, "ace-task", "handbook", "skills", "as-task-plan"))
      FileUtils.mkdir_p(File.join(project_root, "ace-task", "handbook", "workflow-instructions", "task"))
      FileUtils.mkdir_p(File.join(project_root, "ace-task", ".ace-defaults", "nav", "protocols", "skill-sources"))
      FileUtils.mkdir_p(File.join(project_root, "ace-task", ".ace-defaults", "nav", "protocols", "wfi-sources"))

      File.write(File.join(project_root, "ace-task", ".ace-defaults", "nav", "protocols", "skill-sources", "ace-task.yml"), <<~YAML)
        name: ace-task
        config:
          relative_path: handbook/skills
      YAML
      File.write(File.join(project_root, "ace-task", ".ace-defaults", "nav", "protocols", "wfi-sources", "ace-task.yml"), <<~YAML)
        name: ace-task
        config:
          relative_path: handbook/workflow-instructions
      YAML
      File.write(File.join(project_root, "ace-task", "handbook", "skills", "as-task-plan", "SKILL.md"), <<~MD)
        ---
        name: as-task-plan
        skill:
          kind: workflow
          execution:
            workflow: wfi://task/plan
        ---
      MD
      File.write(File.join(project_root, "ace-task", "handbook", "workflow-instructions", "task", "plan.wf.md"), <<~MD)
        ---
        ---
      MD

      resolver = Ace::Assign::Molecules::SkillAssignSourceResolver.new(project_root: project_root)
      rendering = resolver.resolve_source_rendering("skill://as-task-plan")
      assert_equal "skill://as-task-plan", rendering["source"]
      assert_equal "as-task-plan", rendering["skill"]
    end
  end
end
