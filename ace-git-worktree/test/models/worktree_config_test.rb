# frozen_string_literal: true

require "test_helper"

class WorktreeConfigTest < AceGitWorktreeTestCase
  def test_initialization_with_defaults
    config = Ace::Git::Worktree::Models::WorktreeConfig.new

    assert_equal ".ace-wt", config.root_path
    assert_equal true, config.mise_trust_auto
    assert_equal 5, config.mise_trust_timeout
    assert_equal "task.{id}", config.task_directory_format
    assert_equal "{id}-{slug}", config.task_branch_format
    assert_equal 50, config.slug_max_length
    assert_equal "-", config.slug_separator
    assert_equal true, config.auto_mark_in_progress
    assert_equal true, config.auto_commit_task
    assert_equal "chore(task-{id}): mark as in-progress, creating worktree", config.commit_message_format
    assert_equal true, config.add_worktree_metadata
    assert_equal "-{count}", config.duplicate_suffix_format
    assert_equal false, config.cleanup_on_merge
    assert_equal true, config.cleanup_on_delete
    assert_equal false, config.cleanup_on_task_done
    assert_equal "table", config.default_output_format
    assert_equal true, config.show_absolute_paths
    assert_equal 30, config.git_timeout
    assert_equal false, config.auto_fetch
  end

  def test_initialization_with_custom_values
    custom_config = {
      root_path: ".worktrees",
      mise_trust_auto: false,
      task: {
        directory_format: "{id}",
        branch_format: "task-{id}",
        slug_max_length: 100,
        auto_mark_in_progress: false
      }
    }

    config = Ace::Git::Worktree::Models::WorktreeConfig.new(custom_config)

    assert_equal ".worktrees", config.root_path
    assert_equal false, config.mise_trust_auto
    assert_equal "{id}", config.task_directory_format
    assert_equal "task-{id}", config.task_branch_format
    assert_equal 100, config.slug_max_length
    assert_equal false, config.auto_mark_in_progress
    # Other values should be defaults
    assert_equal true, config.auto_commit_task
  end

  def test_validation_passes_for_valid_config
    config = Ace::Git::Worktree::Models::WorktreeConfig.new

    assert config.valid?
    assert_empty config.errors
  end

  def test_validation_fails_for_empty_root_path
    config = Ace::Git::Worktree::Models::WorktreeConfig.new(root_path: "")

    refute config.valid?
    assert_includes config.errors, "root_path cannot be empty"
  end

  def test_validation_fails_for_invalid_slug_max_length
    config = Ace::Git::Worktree::Models::WorktreeConfig.new(
      task: { slug_max_length: 0 }
    )

    refute config.valid?
    assert_includes config.errors, "slug_max_length must be positive"
  end

  def test_validation_fails_for_invalid_mise_trust_timeout
    config = Ace::Git::Worktree::Models::WorktreeConfig.new(
      mise_trust_timeout: -1
    )

    refute config.valid?
    assert_includes config.errors, "mise_trust_timeout must be positive"
  end

  def test_validation_fails_for_invalid_git_timeout
    config = Ace::Git::Worktree::Models::WorktreeConfig.new(
      git: { worktree_command_timeout: 0 }
    )

    refute config.valid?
    assert_includes config.errors, "git_timeout must be positive"
  end

  def test_validation_fails_for_invalid_output_format
    config = Ace::Git::Worktree::Models::WorktreeConfig.new(
      output: { default_format: "xml" }
    )

    refute config.valid?
    assert_includes config.errors, "default_output_format must be 'table' or 'json'"
  end

  def test_to_h_returns_structured_hash
    config = Ace::Git::Worktree::Models::WorktreeConfig.new

    hash = config.to_h

    assert_equal ".ace-wt", hash[:root_path]
    assert_equal true, hash[:mise_trust_auto]

    assert hash[:task].is_a?(Hash)
    assert_equal "task.{id}", hash[:task][:directory_format]
    assert_equal "{id}-{slug}", hash[:task][:branch_format]

    assert hash[:cleanup].is_a?(Hash)
    assert_equal false, hash[:cleanup][:on_merge]
    assert_equal true, hash[:cleanup][:on_delete]

    assert hash[:output].is_a?(Hash)
    assert_equal "table", hash[:output][:default_format]

    assert hash[:git].is_a?(Hash)
    assert_equal 30, hash[:git][:worktree_command_timeout]
  end

  def test_nested_configuration_flattening
    nested_config = {
      root_path: ".custom-wt",
      task: {
        directory_format: "custom-{id}",
        branch_format: "feature-{id}",
        slug_max_length: 75
      },
      cleanup: {
        on_merge: true,
        on_delete: false
      },
      output: {
        default_format: "json",
        show_absolute_paths: false
      },
      git: {
        worktree_command_timeout: 60,
        auto_fetch: true
      }
    }

    config = Ace::Git::Worktree::Models::WorktreeConfig.new(nested_config)

    assert_equal ".custom-wt", config.root_path
    assert_equal "custom-{id}", config.task_directory_format
    assert_equal "feature-{id}", config.task_branch_format
    assert_equal 75, config.slug_max_length
    assert_equal true, config.cleanup_on_merge
    assert_equal false, config.cleanup_on_delete
    assert_equal "json", config.default_output_format
    assert_equal false, config.show_absolute_paths
    assert_equal 60, config.git_timeout
    assert_equal true, config.auto_fetch
  end
end