# frozen_string_literal: true

require "test_helper"

class WorktreeConfigTest < Minitest::Test
  include TestHelper

  def setup
    @project_root = "/test/project"
    @default_config = {
      "root_path" => ".ace-wt",
      "mise_trust_auto" => true,
      "task" => {
        "directory_format" => "task.{id}",
        "branch_format" => "{id}-{slug}",
        "auto_mark_in_progress" => true,
        "auto_commit_task" => true,
        "commit_message_format" => "chore(task-{id}): mark as in-progress, creating worktree",
        "add_worktree_metadata" => true
      },
      "cleanup" => {
        "on_merge" => false,
        "on_delete" => true
      }
    }
  end

  def test_initialization_with_default_config
    config = Ace::Git::Worktree::Models::WorktreeConfig.new({}, @project_root)

    assert_equal ".ace-wt", config.root_path
    assert_equal true, config.mise_trust_auto?
    assert_equal "task.{id}", config.directory_format
    assert_equal "{id}-{slug}", config.branch_format
    assert_equal true, config.auto_mark_in_progress?
    assert_equal true, config.auto_commit_task?
    assert_equal true, config.add_worktree_metadata?
    assert_equal false, config.cleanup_on_merge?
    assert_equal true, config.cleanup_on_delete?
  end

  def test_initialization_with_custom_config
    custom_config = {
      "git" => {
        "worktree" => {
          "root_path" => "~/worktrees",
          "mise_trust_auto" => false,
          "task" => {
            "directory_format" => "{id}",
            "branch_format" => "work/{id}-{slug}"
          }
        }
      }
    }

    config = Ace::Git::Worktree::Models::WorktreeConfig.new(custom_config, @project_root)

    assert_equal "~/worktrees", config.root_path
    assert_equal false, config.mise_trust_auto?
    assert_equal "{id}", config.directory_format
    assert_equal "work/{id}-{slug}", config.branch_format
  end

  def test_format_directory_with_task
    task_metadata = Ace::Git::Worktree::Models::TaskMetadata.new(
      id: "081",
      task_id: "task.081",
      title: "Fix authentication bug",
      status: "pending",
      release: "v.0.9.0"
    )

    config = Ace::Git::Worktree::Models::WorktreeConfig.new({}, @project_root)
    formatted = config.format_directory(task_metadata)

    assert_equal "task.081", formatted
  end

  def test_format_directory_with_counter
    task_metadata = Ace::Git::Worktree::Models::TaskMetadata.new(
      id: "081",
      task_id: "task.081",
      title: "Fix authentication bug",
      status: "pending"
    )

    config = Ace::Git::Worktree::Models::WorktreeConfig.new({}, @project_root)

    # Without counter
    formatted = config.format_directory(task_metadata)
    assert_equal "task.081", formatted

    # With counter
    formatted_with_counter = config.format_directory(task_metadata, 2)
    assert_equal "task.081-2", formatted_with_counter
  end

  def test_format_branch_with_task
    task_metadata = Ace::Git::Worktree::Models::TaskMetadata.new(
      id: "081",
      task_id: "task.081",
      title: "Fix authentication bug",
      status: "pending",
      release: "v.0.9.0"
    )

    config = Ace::Git::Worktree::Models::WorktreeConfig.new({}, @project_root)
    formatted = config.format_branch(task_metadata)

    assert_equal "081-fix-authentication-bug", formatted
  end

  def test_format_commit_message_with_task
    task_metadata = Ace::Git::Worktree::Models::TaskMetadata.new(
      id: "081",
      task_id: "task.081",
      title: "Fix authentication bug",
      status: "pending"
    )

    config = Ace::Git::Worktree::Models::WorktreeConfig.new({}, @project_root)
    formatted = config.format_commit_message(task_metadata)

    assert_equal "chore(task-081): mark as in-progress, creating worktree", formatted
  end

  def test_absolute_root_path
    config = Ace::Git::Worktree::Models::WorktreeConfig.new({}, @project_root)

    # The absolute path should expand relative paths
    expected_path = File.expand_path(".ace-wt", @project_root)
    assert_equal expected_path, config.absolute_root_path
  end

  def test_absolute_root_path_with_absolute_input
    config_data = {
      "git" => {
        "worktree" => {
          "root_path" => "/absolute/worktrees"
        }
      }
    }
    config = Ace::Git::Worktree::Models::WorktreeConfig.new(config_data, @project_root)

    assert_equal "/absolute/worktrees", config.absolute_root_path
  end

  def test_absolute_root_path_with_tilde
    config_data = {
      "git" => {
        "worktree" => {
          "root_path" => "~/worktrees"
        }
      }
    }
    config = Ace::Git::Worktree::Models::WorktreeConfig.new(config_data, @project_root)

    expected_path = File.expand_path("~/worktrees")
    assert_equal expected_path, config.absolute_root_path
  end

  def test_validate_valid_config
    config = Ace::Git::Worktree::Models::WorktreeConfig.new(@default_config, @project_root)
    errors = config.validate

    assert_empty errors
  end

  def test_validate_missing_root_path
    invalid_config = @default_config.dup
    invalid_config.delete("root_path")

    config = Ace::Git::Worktree::Models::WorktreeConfig.new(
      { "git" => { "worktree" => invalid_config } },
      @project_root
    )
    errors = config.validate

    assert_includes errors, "root_path must be a non-empty string"
  end

  def test_validate_empty_directory_format
    invalid_config = @default_config.dup
    invalid_config["task"]["directory_format"] = ""

    config = Ace::Git::Worktree::Models::WorktreeConfig.new(
      { "git" => { "worktree" => invalid_config } },
      @project_root
    )
    errors = config.validate

    assert_includes errors, "directory_format must be a non-empty string"
  end

  def test_validate_empty_branch_format
    invalid_config = @default_config.dup
    invalid_config["task"]["branch_format"] = ""

    config = Ace::Git::Worktree::Models::WorktreeConfig.new(
      { "git" => { "worktree" => invalid_config } },
      @project_root
    )
    errors = config.validate

    assert_includes errors, "branch_format must be a non-empty string"
  end

  def test_validate_missing_template_variables
    invalid_config = @default_config.dup
    invalid_config["task"]["branch_format"] = "just-text"  # No template variables

    config = Ace::Git::Worktree::Models::WorktreeConfig.new(
      { "git" => { "worktree" => invalid_config } },
      @project_root
    )
    errors = config.validate

    # Should warn about missing template variables
    assert errors.any? { |error| error.include?("should include") }
  end

  def test_to_h
    config = Ace::Git::Worktree::Models::WorktreeConfig.new({}, @project_root)
    hash = config.to_h

    assert_equal ".ace-wt", hash[:root_path]
    assert_equal true, hash[:mise_trust_auto]
    assert hash[:task].is_a?(Hash)
    assert hash[:cleanup].is_a?(Hash)
  end

  def test_config_accessors
    config = Ace::Git::Worktree::Models::WorktreeConfig.new({}, @project_root)

    # Test all the convenience methods
    assert_equal "task.{id}", config.directory_format
    assert_equal "{id}-{slug}", config.branch_format
    assert_equal true, config.mise_trust_auto?
    assert_equal true, config.auto_mark_in_progress?
    assert_equal true, config.auto_commit_task?
    assert_equal "chore(task-{id}): mark as in-progress, creating worktree", config.commit_message_format
    assert_equal true, config.add_worktree_metadata?
    assert_equal false, config.cleanup_on_merge?
    assert_equal true, config.cleanup_on_delete?
  end

  def test_custom_template_variables
    task_metadata = Ace::Git::Worktree::Models::TaskMetadata.new(
      id: "123",
      task_id: "task.123",
      title: "Test task with release",
      status: "pending",
      release: "v.1.0.0"
    )

    custom_config = {
      "git" => {
        "worktree" => {
          "task" => {
            "directory_format" => "work/{release}/{id}",
            "branch_format" => "{release}/{id}-{slug}"
          }
        }
      }
    }

    config = Ace::Git::Worktree::Models::WorktreeConfig.new(custom_config, @project_root)

    assert_equal "work/v.1.0.0/123", config.format_directory(task_metadata)
    assert_equal "v.1.0.0/123-test-task-with-release", config.format_branch(task_metadata)
  end

  def test_mise_trust_auto_false
    config_data = {
      "git" => {
        "worktree" => {
          "mise_trust_auto" => false
        }
      }
    }
    config = Ace::Git::Worktree::Models::WorktreeConfig.new(config_data, @project_root)

    assert_equal false, config.mise_trust_auto?
  end

  def test_auto_mark_in_progress_false
    config_data = {
      "git" => {
        "worktree" => {
          "task" => {
            "auto_mark_in_progress" => false
          }
        }
      }
    }
    config = Ace::Git::Worktree::Models::WorktreeConfig.new(config_data, @project_root)

    assert_equal false, config.auto_mark_in_progress?
  end

  def test_auto_commit_task_false
    config_data = {
      "git" => {
        "worktree" => {
          "task" => {
            "auto_commit_task" => false
          }
        }
      }
    }
    config = Ace::Git::Worktree::Models::WorktreeConfig.new(config_data, @project_root)

    assert_equal false, config.auto_commit_task?
  end

  def test_add_worktree_metadata_false
    config_data = {
      "git" => {
        "worktree" => {
          "task" => {
            "add_worktree_metadata" => false
          }
        }
      }
    }
    config = Ace::Git::Worktree::Models::WorktreeConfig.new(config_data, @project_root)

    assert_equal false, config.add_worktree_metadata?
  end
end