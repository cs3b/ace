# frozen_string_literal: true

require_relative "../test_helper"

class AssignmentExecutorStepCatalogTest < AceAssignTestCase
  def test_step_catalog_prefers_canonical_skill_step_metadata_over_yaml
    executor = Ace::Assign::Organisms::AssignmentExecutor.new

    resolver = Minitest::Mock.new
    resolver.expect(:assign_step_catalog, [
      {
        "name" => "plan-task",
        "skill" => "as-task-plan",
        "description" => "Canonical description",
        "context" => {"default" => "fork"}
      }
    ])
    executor.instance_variable_set(:@skill_source_resolver, resolver)
    executor.instance_variable_set(:@step_catalog, nil)

    executor.stub(:merge_step_catalog, [
      {
        "name" => "plan-task",
        "skill" => "as-task-plan",
        "description" => "Canonical description",
        "context" => {"default" => "fork"}
      }
    ]) do
      catalog = executor.send(:step_catalog)
      definition = catalog.first

      assert_equal "Canonical description", definition["description"]
      assert_equal({"default" => "fork"}, definition["context"])
    end

    resolver.verify
  end

  def test_merge_step_catalog_overrides_existing_entries_and_keeps_local_render_metadata
    executor = Ace::Assign::Organisms::AssignmentExecutor.new

    base_catalog = [
      {
        "name" => "plan-task",
        "skill" => "as-task-plan",
        "description" => "Legacy YAML",
        "steps" => [{"description" => "Local step"}]
      },
      {"name" => "task-load", "description" => "Internal helper"}
    ]
    canonical_catalog = [
      {
        "name" => "plan-task",
        "skill" => "as-task-plan",
        "description" => "Canonical skill",
        "context" => {"default" => "fork"}
      },
      {"name" => "verify-test-suite", "skill" => "as-test-verify-suite", "description" => "Canonical suite"}
    ]

    merged = executor.send(:merge_step_catalog, base_catalog, canonical_catalog)

    assert_equal %w[plan-task task-load verify-test-suite], merged.map { |step| step["name"] }
    plan_task = merged.find { |step| step["name"] == "plan-task" }

    assert_equal "Canonical skill", plan_task["description"]
    assert_equal({"default" => "fork"}, plan_task["context"])
    assert_equal [{"description" => "Local step"}], plan_task["steps"]
    assert_equal "Internal helper", merged.find { |step| step["name"] == "task-load" }["description"]
  end

  def test_step_catalog_keeps_project_overrides_after_canonical_merge
    executor = Ace::Assign::Organisms::AssignmentExecutor.new
    executor.instance_variable_set(:@step_catalog, nil)

    resolver = Minitest::Mock.new
    resolver.expect(:assign_step_catalog, [
      {
        "name" => "work-on-task",
        "skill" => "as-task-work",
        "description" => "Canonical description",
        "context" => {"default" => "fork"}
      }
    ])
    executor.instance_variable_set(:@skill_source_resolver, resolver)

    default_steps = [{"name" => "work-on-task", "skill" => "as-task-work"}]
    project_steps = [{"name" => "work-on-task", "description" => "Project override"}]

    Dir.mktmpdir("assignment-executor-step-catalog") do |tmpdir|
      gem_root = File.join(tmpdir, "gem")
      project_root = File.join(tmpdir, "project")
      default_catalog = File.join(gem_root, ".ace-defaults", "assign", "catalog", "steps")
      project_catalog = File.join(project_root, ".ace", "assign", "catalog", "steps")
      FileUtils.mkdir_p(project_catalog)

      Ace::Support::Fs::Molecules::ProjectRootFinder.stub(:find_or_current, project_root) do
        Gem.stub(:loaded_specs, {"ace-assign" => Struct.new(:gem_dir).new(gem_root)}) do
          Ace::Assign::Atoms::CatalogLoader.stub(:load_all, lambda { |path, canonical_steps:|
            assert_equal false, canonical_steps
            if path == default_catalog
              default_steps
            elsif path == project_catalog
              project_steps
            else
              flunk("Unexpected catalog path: #{path}")
            end
          }) do
            catalog = executor.send(:step_catalog)
            definition = catalog.find { |step| step["name"] == "work-on-task" }

            assert_equal "Project override", definition["description"]
            assert_equal({"default" => "fork"}, definition["context"])
          end
        end
      end
    end

    resolver.verify
  end
end
