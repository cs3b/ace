# frozen_string_literal: true

require "test_helper"

class AceGitWorktreeTest < AceGitWorktreeTestCase
  def test_that_it_has_a_version_number
    refute_nil Ace::Git::Worktree::VERSION
    assert_match(/^\d+\.\d+\.\d+$/, Ace::Git::Worktree::VERSION)
  end

  def test_module_structure
    assert defined?(Ace::Git::Worktree)
    assert defined?(Ace::Git::Worktree::Atoms)
    assert defined?(Ace::Git::Worktree::Molecules)
    assert defined?(Ace::Git::Worktree::Organisms)
    assert defined?(Ace::Git::Worktree::Models)
    assert defined?(Ace::Git::Worktree::Commands)
  end

  def test_configuration_accessible
    config = Ace::Git::Worktree.configuration
    assert_instance_of Ace::Git::Worktree::Configuration, config
    assert config.config.valid?
  end

  def test_error_classes_defined
    assert defined?(Ace::Git::Worktree::Error)
    assert defined?(Ace::Git::Worktree::TaskNotFoundError)
    assert defined?(Ace::Git::Worktree::WorktreeExistsError)
    assert defined?(Ace::Git::Worktree::GitError)
    assert defined?(Ace::Git::Worktree::ConfigurationError)
  end

  def test_cli_responds_to_start
    assert Ace::Git::Worktree::CLI.respond_to?(:start)
  end

  def test_gem_root_path
    root = Ace::Git::Worktree.root
    assert File.exist?(File.join(root, "ace-git-worktree.gemspec"))
  end
end