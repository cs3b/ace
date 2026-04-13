# frozen_string_literal: true

require_relative "../../test_helper"

class AssignmentDiscovererTest < AceAssignTestCase
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
      assert_equal :running, info.state
      assert_equal "init", info.current_step
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
