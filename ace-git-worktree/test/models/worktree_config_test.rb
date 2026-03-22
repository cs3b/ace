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
        "directory_format" => "t.{id}",
        "branch_format" => "{id}-{slug}",
        "auto_mark_in_progress" => true,
        "auto_commit_task" => true,
        "commit_message_format" => "chore(task-{id}): mark as in-progress, creating worktree",
        "add_worktree_metadata" => true
      },
      "pr" => {
        "directory_format" => "ace-pr-{number}",
        "branch_format" => "pr-{number}-{slug}",
        "remote_name" => "origin",
        "fetch_before_create" => true,
        "configure_push_for_mismatch" => true
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
    assert_equal "t.{task_id}", config.directory_format
    assert_equal "{id}-{slug}", config.branch_format
    assert_equal true, config.auto_mark_in_progress?
    assert_equal true, config.auto_commit_task?
    assert_equal true, config.add_worktree_metadata?
    assert_equal false, config.cleanup_on_merge?
    assert_equal true, config.cleanup_on_delete?
  end

  def test_initialization_with_shortened_directory_format
    custom_config = {
      "git" => {
        "worktree" => {
          "task" => {
            "directory_format" => "t.{task_id}"
          }
        }
      }
    }

    config = Ace::Git::Worktree::Models::WorktreeConfig.new(custom_config, @project_root)

    assert_equal "t.{task_id}", config.directory_format
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
    task_data = {
      id: "t.081",
      task_number: "081",
      title: "Fix authentication bug",
      status: "pending"
    }

    config = Ace::Git::Worktree::Models::WorktreeConfig.new({}, @project_root)
    formatted = config.format_directory(task_data)

    assert_equal "t.081", formatted
  end

  def test_format_directory_with_counter
    task_data = {
      id: "task.081",
      task_number: "081",
      title: "Fix authentication bug",
      status: "pending"
    }

    config = Ace::Git::Worktree::Models::WorktreeConfig.new({}, @project_root)

    # Without counter
    formatted = config.format_directory(task_data)
    assert_equal "t.081", formatted

    # With counter
    formatted_with_counter = config.format_directory(task_data, 2)
    assert_equal "t.081-2", formatted_with_counter
  end

  def test_format_branch_with_task
    task_data = {
      id: "t.081",
      task_number: "081",
      title: "Fix authentication bug",
      status: "pending"
    }

    config = Ace::Git::Worktree::Models::WorktreeConfig.new({}, @project_root)
    formatted = config.format_branch(task_data)

    assert_equal "081-fix-authentication-bug", formatted
  end

  def test_format_commit_message_with_task
    task_data = {
      id: "task.081",
      task_number: "081",
      title: "Fix authentication bug",
      status: "pending"
    }

    config = Ace::Git::Worktree::Models::WorktreeConfig.new({}, @project_root)
    formatted = config.format_commit_message(task_data)

    assert_equal "chore(081): mark as in-progress, creating worktree for fix-authentication-bug", formatted
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
    invalid_config = {
      "git" => {
        "worktree" => {
          "root_path" => ""
        }
      }
    }

    config = Ace::Git::Worktree::Models::WorktreeConfig.new(invalid_config, @project_root)
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

    assert_includes errors, "task.directory_format must be a non-empty string"
  end

  def test_validate_empty_branch_format
    invalid_config = @default_config.dup
    invalid_config["task"]["branch_format"] = ""

    config = Ace::Git::Worktree::Models::WorktreeConfig.new(
      { "git" => { "worktree" => invalid_config } },
      @project_root
    )
    errors = config.validate

    assert_includes errors, "task.branch_format must be a non-empty string"
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
    assert_equal "t.{task_id}", config.directory_format
    assert_equal "{id}-{slug}", config.branch_format
    assert_equal true, config.mise_trust_auto?
    assert_equal true, config.auto_mark_in_progress?
    assert_equal true, config.auto_commit_task?
    assert_equal "chore({task_id}): mark as in-progress, creating worktree for {slug}", config.commit_message_format
    assert_equal true, config.add_worktree_metadata?
    assert_equal false, config.cleanup_on_merge?
    assert_equal true, config.cleanup_on_delete?
  end

  def test_custom_template_variables
    task_data = {
      id: "task.123",
      task_number: "123",
      title: "Test task with variables",
      status: "pending"
    }

    custom_config = {
      "git" => {
        "worktree" => {
          "task" => {
            "directory_format" => "work/{task_id}",
            "branch_format" => "{task_id}-{slug}"
          }
        }
      }
    }

    config = Ace::Git::Worktree::Models::WorktreeConfig.new(custom_config, @project_root)

    assert_equal "work/123", config.format_directory(task_data)
    assert_equal "123-test-task-with-variables", config.format_branch(task_data)
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

  def test_validate_invalid_task_template_variables
    invalid_config = @default_config.dup
    invalid_config["task"]["branch_format"] = "{id}-{invalid_var}-{slug}"

    config = Ace::Git::Worktree::Models::WorktreeConfig.new(
      { "git" => { "worktree" => invalid_config } },
      @project_root
    )
    errors = config.validate

    # Should detect invalid_var as invalid
    assert errors.any? { |error| error.include?("invalid_var") && error.include?("task.branch_format") }
  end

  def test_validate_invalid_pr_template_variables
    invalid_config = @default_config.dup
    invalid_config["pr"]["directory_format"] = "pr-{number}-{invalid_var}"

    config = Ace::Git::Worktree::Models::WorktreeConfig.new(
      { "git" => { "worktree" => invalid_config } },
      @project_root
    )
    errors = config.validate

    # Should detect invalid_var as invalid
    assert errors.any? { |error| error.include?("invalid_var") && error.include?("pr.directory_format") }
  end

  def test_validate_valid_pr_template_variables
    valid_config = @default_config.dup
    valid_config["pr"]["directory_format"] = "pr-{number}-{slug}"
    valid_config["pr"]["branch_format"] = "pr/{number}-{title}"

    config = Ace::Git::Worktree::Models::WorktreeConfig.new(
      { "git" => { "worktree" => valid_config } },
      @project_root
    )
    errors = config.validate

    # Should not have any errors about invalid variables
    refute errors.any? { |error| error.include?("pr.directory_format") && error.include?("invalid") }
    refute errors.any? { |error| error.include?("pr.branch_format") && error.include?("invalid") }
  end

  def test_validate_empty_pr_directory_format
    invalid_config = @default_config.dup
    invalid_config["pr"]["directory_format"] = ""

    config = Ace::Git::Worktree::Models::WorktreeConfig.new(
      { "git" => { "worktree" => invalid_config } },
      @project_root
    )
    errors = config.validate

    assert_includes errors, "pr.directory_format must be a non-empty string"
  end

  def test_validate_empty_pr_branch_format
    invalid_config = @default_config.dup
    invalid_config["pr"]["branch_format"] = ""

    config = Ace::Git::Worktree::Models::WorktreeConfig.new(
      { "git" => { "worktree" => invalid_config } },
      @project_root
    )
    errors = config.validate

    assert_includes errors, "pr.branch_format must be a non-empty string"
  end

  def test_find_invalid_template_variables
    config = Ace::Git::Worktree::Models::WorktreeConfig.new({}, @project_root)

    # Test with valid variables
    valid_template = "task-{id}-{slug}"
    invalid = config.send(:find_invalid_template_variables, valid_template, %w[id slug])
    assert_empty invalid

    # Test with invalid variables
    invalid_template = "task-{id}-{invalid}-{slug}"
    invalid = config.send(:find_invalid_template_variables, invalid_template, %w[id slug])
    assert_equal ["invalid"], invalid

    # Test with multiple invalid variables
    multi_invalid = "task-{id}-{bad1}-{bad2}-{slug}"
    invalid = config.send(:find_invalid_template_variables, multi_invalid, %w[id slug])
    assert_equal ["bad1", "bad2"], invalid.sort

    # Test with no variables
    no_vars = "just-text"
    invalid = config.send(:find_invalid_template_variables, no_vars, %w[id slug])
    assert_empty invalid
  end

  # Tests for upstream and PR automation config (task 125)

  def test_auto_setup_upstream_default_false
    config = Ace::Git::Worktree::Models::WorktreeConfig.new({}, @project_root)
    assert_equal false, config.auto_setup_upstream?
  end

  def test_auto_setup_upstream_can_be_enabled
    config_data = {
      "git" => {
        "worktree" => {
          "task" => {
            "auto_setup_upstream" => true
          }
        }
      }
    }
    config = Ace::Git::Worktree::Models::WorktreeConfig.new(config_data, @project_root)
    assert_equal true, config.auto_setup_upstream?
  end

  def test_auto_create_pr_default_false
    config = Ace::Git::Worktree::Models::WorktreeConfig.new({}, @project_root)
    assert_equal false, config.auto_create_pr?
  end

  def test_auto_create_pr_can_be_enabled
    config_data = {
      "git" => {
        "worktree" => {
          "task" => {
            "auto_create_pr" => true
          }
        }
      }
    }
    config = Ace::Git::Worktree::Models::WorktreeConfig.new(config_data, @project_root)
    assert_equal true, config.auto_create_pr?
  end

  def test_pr_title_format_default
    config = Ace::Git::Worktree::Models::WorktreeConfig.new({}, @project_root)
    assert_equal "{id} - {slug}", config.pr_title_format
  end

  def test_pr_title_format_custom
    config_data = {
      "git" => {
        "worktree" => {
          "task" => {
            "pr_title_format" => "[{id}] {slug}"
          }
        }
      }
    }
    config = Ace::Git::Worktree::Models::WorktreeConfig.new(config_data, @project_root)
    assert_equal "[{id}] {slug}", config.pr_title_format
  end

  def test_format_pr_title
    task_data = {
      id: "v.0.9.0+task.125",
      task_number: "125",
      title: "Upstream Setup and PR Creation",
      status: "pending"
    }

    config = Ace::Git::Worktree::Models::WorktreeConfig.new({}, @project_root)
    formatted = config.format_pr_title(task_data)

    assert_equal "125 - upstream-setup-and-pr-creation", formatted
  end

  def test_tmux_default_false
    config = Ace::Git::Worktree::Models::WorktreeConfig.new({}, @project_root)
    assert_equal false, config.tmux?
  end

  def test_tmux_can_be_enabled
    config_data = {
      "git" => {
        "worktree" => {
          "tmux" => true
        }
      }
    }
    config = Ace::Git::Worktree::Models::WorktreeConfig.new(config_data, @project_root)
    assert_equal true, config.tmux?
  end

  def test_format_pr_title_with_custom_template
    task_data = {
      id: "v.0.9.0+task.125",
      task_number: "125",
      title: "Fix Bug",
      status: "pending"
    }

    config_data = {
      "git" => {
        "worktree" => {
          "task" => {
            "pr_title_format" => "task-{id}: {slug}"
          }
        }
      }
    }
    config = Ace::Git::Worktree::Models::WorktreeConfig.new(config_data, @project_root)
    formatted = config.format_pr_title(task_data)

    assert_equal "task-125: fix-bug", formatted
  end
end
