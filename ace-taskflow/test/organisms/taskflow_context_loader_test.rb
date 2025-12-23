# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/organisms/taskflow_context_loader"

class TaskflowContextLoaderTest < AceTaskflowTestCase
  def setup
    super
    @loader = Ace::Taskflow::Organisms::TaskflowContextLoader.new
  end

  def test_load_returns_hash_with_expected_keys
    Ace::Taskflow::Molecules::ReleaseResolver.stub :new, mock_release_resolver do
      Ace::Taskflow::Molecules::TaskLoader.stub :new, mock_task_loader_no_task do
        @loader.stub :detect_task_pattern_from_branch, nil do
          context = @loader.load

          assert_kind_of Hash, context
          assert context.key?(:task)
          assert context.key?(:release)
          # No longer includes :repository - that's in ace-git context
        end
      end
    end
  end

  def test_load_resolves_task_from_branch_pattern
    mock_task = {
      id: "v.0.9.0+task.140",
      title: "Test Feature",
      status: "in-progress",
      path: "/path/to/task.s.md",
      priority: "high",
      estimate: "4h",
      is_orchestrator: false,
      subtask_ids: [],
      parent_id: nil
    }

    task_loader = mock_task_loader_with_task(mock_task)

    Ace::Taskflow::Molecules::ReleaseResolver.stub :new, mock_release_resolver do
      Ace::Taskflow::Molecules::TaskLoader.stub :new, task_loader do
        @loader.stub :detect_task_pattern_from_branch, "140" do
          context = @loader.load

          refute_nil context[:task]
          assert_equal "v.0.9.0+task.140", context[:task][:id]
          assert_equal "Test Feature", context[:task][:title]
          assert_equal "in-progress", context[:task][:status]
        end
      end
    end
  end

  def test_load_handles_no_task_pattern
    Ace::Taskflow::Molecules::ReleaseResolver.stub :new, mock_release_resolver do
      Ace::Taskflow::Molecules::TaskLoader.stub :new, mock_task_loader_no_task do
        @loader.stub :detect_task_pattern_from_branch, nil do
          context = @loader.load

          assert_nil context[:task]
        end
      end
    end
  end

  def test_load_includes_release_info
    Ace::Taskflow::Molecules::ReleaseResolver.stub :new, mock_release_resolver do
      Ace::Taskflow::Molecules::TaskLoader.stub :new, mock_task_loader_no_task do
        @loader.stub :detect_task_pattern_from_branch, nil do
          context = @loader.load

          refute_nil context[:release]
          assert_equal "v.0.9.0", context[:release][:name]
          assert_equal "0.9.0", context[:release][:version]
          assert_equal 10, context[:release][:total_tasks]
          assert_equal 7, context[:release][:done_tasks]
          assert_equal 70, context[:release][:progress]
        end
      end
    end
  end

  def test_load_includes_parent_for_subtasks
    mock_task = {
      id: "v.0.9.0+task.140.02",
      title: "Subtask Feature",
      status: "in-progress",
      path: "/path/to/subtask.s.md",
      priority: "high",
      estimate: "2h",
      is_orchestrator: false,
      subtask_ids: [],
      parent_id: "v.0.9.0+task.140"
    }

    task_loader = mock_task_loader_with_task(mock_task)

    Ace::Taskflow::Molecules::ReleaseResolver.stub :new, mock_release_resolver do
      Ace::Taskflow::Molecules::TaskLoader.stub :new, task_loader do
        @loader.stub :detect_task_pattern_from_branch, "140.02" do
          context = @loader.load

          refute_nil context[:task]
          assert_equal "v.0.9.0+task.140.02", context[:task][:id]
          assert_equal "140", context[:task][:parent]  # Extracted from parent_id
        end
      end
    end
  end

  def test_class_method_load
    Ace::Taskflow::Molecules::ReleaseResolver.stub :new, mock_release_resolver do
      Ace::Taskflow::Molecules::TaskLoader.stub :new, mock_task_loader_no_task do
        Ace::Taskflow::Organisms::TaskflowContextLoader.stub :new, @loader do
          @loader.stub :detect_task_pattern_from_branch, nil do
            context = Ace::Taskflow::Organisms::TaskflowContextLoader.load

            assert_kind_of Hash, context
            assert context.key?(:task)
            assert context.key?(:release)
          end
        end
      end
    end
  end

  def test_detect_task_pattern_from_branch
    mock_branch = "140.02-update-feature"
    mock_output = "#{mock_branch}\n"

    @loader.stub :`, mock_output do
      result = @loader.send(:detect_task_pattern_from_branch)
      assert_equal "140.02", result
    end
  end

  def test_detect_task_pattern_from_branch_returns_nil_for_main
    mock_output = "main\n"

    @loader.stub :`, mock_output do
      result = @loader.send(:detect_task_pattern_from_branch)
      assert_nil result
    end
  end

  private

  def mock_release_resolver
    resolver = Object.new
    def resolver.find_primary_active
      {
        name: "v.0.9.0",
        version: "0.9.0",
        path: "/path/to/.ace-taskflow/v.0.9.0",
        status: "active",
        statistics: {
          total: 10,
          statuses: { done: 5, completed: 2, :"in-progress" => 3 }
        }
      }
    end
    resolver
  end

  def mock_task_loader_no_task
    loader = Object.new
    def loader.find_task_by_reference(ref)
      nil
    end
    loader
  end

  def mock_task_loader_with_task(task)
    loader = Object.new
    loader.define_singleton_method(:find_task_by_reference) do |ref|
      task
    end
    loader
  end
end
