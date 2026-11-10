# frozen_string_literal: true

require_relative "../../test_helper"

class AssignmentDiscovererTest < AceAssignTestCase
  def test_explicit_project_inventory_preserves_worktree_config_and_process_context
    Dir.mktmpdir do |base|
      original_cwd = Dir.pwd
      original_config = Ace::Assign.config
      roots = %w[a b].map do |name|
        root = File.join(base, name)
        FileUtils.mkdir_p(File.join(root, ".ace", "assign"))
        File.write(File.join(root, ".git"), "")
        File.write(File.join(root, ".ace", "assign", "config.yml"), "cache_dir: records-#{name}\n")
        cache = File.join(root, "records-#{name}")
        FileUtils.mkdir_p(cache)
        executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache)
        executor.start(create_test_config(cache, name: name))
        root
      end
      seen = [0, 1, 0].map do |index|
        inventory = Ace::Assign::Molecules::AssignmentDiscoverer.for_project(project_root: roots[index], env: {})
        rows = inventory.find_all(include_completed: true)
        assert_equal 1, rows.length
        assert_equal :paused, rows.first.state
        assert_equal original_cwd, Dir.pwd
        assert_same original_config, Ace::Assign.config
        rows.first.name
      end
      assert_equal seen[0], seen[2]
      refute_equal seen[0], seen[1]
      assert_equal File.join(roots[0], "override"), Ace::Assign.cache_dir_for(
        project_root: roots[0], env: {"CACHE_BASE" => "override", "PROJECT_ROOT_PATH" => roots[1]})
    end
  end

  def test_find_all_returns_enriched_assignments
    with_temp_cache do |cache_dir|
      # Create two assignments with steps
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)

      config_path = create_test_config(cache_dir)
      executor.start(config_path)

      discoverer = Ace::Assign::Molecules::AssignmentDiscoverer.new(cache_base: cache_dir)
      results = discoverer.find_all

      assert_equal 1, results.size
      info = results.first
      assert_instance_of Ace::Assign::Models::AssignmentInfo, info
      assert_equal :paused, info.state
      assert_equal "-", info.current_step
      assert_equal "next: init", info.step_focus
    end
  end

  def test_find_all_excludes_completed_by_default
    with_temp_cache do |cache_dir|
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)

      # Create and complete an assignment
      config_path = create_test_config(cache_dir, steps: [
        {"name" => "only-step", "instructions" => "Do it"}
      ])
      executor.start(config_path)
      report_path = create_report(cache_dir, "Done!")
      executor.start_step
      executor.advance(report_path)

      discoverer = Ace::Assign::Molecules::AssignmentDiscoverer.new(cache_base: cache_dir)

      # Without include_completed, should be empty
      results = discoverer.find_all
      assert_equal 0, results.size

      # With include_completed, should find it
      results = discoverer.find_all(include_completed: true)
      assert_equal 1, results.size
      assert_equal :completed, results.first.state
    end
  end

  def test_find_all_with_multiple_assignments
    with_temp_cache do |cache_dir|
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)

      config1 = create_test_config(cache_dir)
      executor.start(config1)

      config2 = create_test_config(cache_dir)
      executor.start(config2)

      discoverer = Ace::Assign::Molecules::AssignmentDiscoverer.new(cache_base: cache_dir)
      results = discoverer.find_all

      assert_equal 2, results.size
      results.each do |info|
        assert_instance_of Ace::Assign::Models::AssignmentInfo, info
      end
    end
  end

  def test_find_by_task
    with_temp_cache do |cache_dir|
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)

      config_path = create_test_config(cache_dir)
      executor.start(config_path)

      discoverer = Ace::Assign::Molecules::AssignmentDiscoverer.new(cache_base: cache_dir)

      # Should find by matching name
      results = discoverer.find_by_task(task_ref: "test-session")
      assert_equal 1, results.size

      # Should not find with non-matching name
      results = discoverer.find_by_task(task_ref: "nonexistent")
      assert_equal 0, results.size
    end
  end

  def test_find_all_returns_empty_for_no_assignments
    with_temp_cache do |cache_dir|
      discoverer = Ace::Assign::Molecules::AssignmentDiscoverer.new(cache_base: cache_dir)
      results = discoverer.find_all

      assert_equal 0, results.size
    end
  end
end
