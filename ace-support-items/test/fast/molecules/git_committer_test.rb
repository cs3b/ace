# frozen_string_literal: true

require "test_helper"

class GitCommitterTest < AceSupportItemsTestCase
  Committer = Ace::Support::Items::Molecules::GitCommitter

  def test_commit_constructs_correct_command_with_single_path
    called_with = nil
    Committer.stub(:system, ->(*args) {
      called_with = args
      true
    }) do
      result = Committer.commit(paths: ["/tmp/task-dir"], intention: "create task abc")
      assert_equal true, result
      assert_equal ["ace-git-commit", "/tmp/task-dir", "-i", "create task abc"], called_with
    end
  end

  def test_commit_constructs_correct_command_with_multiple_paths
    called_with = nil
    Committer.stub(:system, ->(*args) {
      called_with = args
      true
    }) do
      Committer.commit(paths: ["/tmp/dir1", "/tmp/dir2"], intention: "move task")
      assert_equal ["ace-git-commit", "/tmp/dir1", "/tmp/dir2", "-i", "move task"], called_with
    end
  end

  def test_commit_returns_false_on_failure
    Committer.stub(:system, ->(*_args) { false }) do
      result = Committer.commit(paths: ["/tmp/task-dir"], intention: "create task abc")
      assert_equal false, result
    end
  end

  def test_commit_returns_nil_when_command_not_found
    Committer.stub(:system, ->(*_args) {}) do
      result = Committer.commit(paths: ["/tmp/task-dir"], intention: "create task abc")
      assert_nil result
    end
  end

  def test_commit_handles_intention_with_special_characters
    called_with = nil
    Committer.stub(:system, ->(*args) {
      called_with = args
      true
    }) do
      Committer.commit(paths: ["/tmp/dir"], intention: 'move task q7w to "archive"')
      assert_equal ["ace-git-commit", "/tmp/dir", "-i", 'move task q7w to "archive"'], called_with
    end
  end
end
