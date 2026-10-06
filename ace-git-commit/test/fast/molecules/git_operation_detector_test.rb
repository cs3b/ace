# frozen_string_literal: true

require_relative "../../test_helper"
require "minitest/mock"

class GitOperationDetectorTest < TestCase
  def test_clear_state_checks_each_git_resolved_marker
    git = Minitest::Mock.new
    paths = Ace::GitCommit::Molecules::GitOperationDetector::MARKERS.keys.map { |m| "/metadata/#{m}" }
    paths.each do |path|
      git.expect :execute, path, ["rev-parse", "--git-path", File.basename(path)]
    end
    File.stub :stat, ->(_path) { raise Errno::ENOENT } do
      assert_nil Ace::GitCommit::Molecules::GitOperationDetector.new(git).detect
    end
    git.verify
  end

  def test_git_resolved_path_preserves_leading_and_trailing_whitespace
    git = Minitest::Mock.new
    path = " metadata /rebase-merge "
    git.expect :execute, "#{path}\n", ["rev-parse", "--git-path", "rebase-merge"]
    inspected = []
    File.stub :stat, ->(actual) { inspected << actual; Object.new } do
      assert_equal ["rebase", "git rebase --continue"],
        Ace::GitCommit::Molecules::GitOperationDetector.new(git).detect
    end
    assert_equal [path], inspected
    git.verify
  end

  def test_precedence_and_git_am_guidance
    [false, true].each do |applying|
      git = Minitest::Mock.new
      git.expect :execute, "/metadata/rebase-merge", ["rev-parse", "--git-path", "rebase-merge"]
      git.expect :execute, "/metadata/rebase-apply", ["rev-parse", "--git-path", "rebase-apply"]
      stat = lambda do |path|
        raise Errno::ENOENT if path.end_with?("rebase-merge") || (!applying && path.end_with?("applying"))
        Object.new
      end
      File.stub :stat, stat do
        operation = Ace::GitCommit::Molecules::GitOperationDetector.new(git).detect
        assert_equal applying ? ["git-am", "git am --continue"] : ["rebase", "git rebase --continue"], operation
      end
      git.verify
    end
  end

  def test_inspection_errors_fail_closed
    [Errno::EACCES, Errno::ENOTDIR, Errno::ELOOP].each do |error|
      git = Object.new
      git.define_singleton_method(:execute) { |*| "/metadata/rebase-merge" }
      File.stub :stat, ->(*) { raise error } do
        exception = assert_raises(Ace::GitCommit::GitError) do
          Ace::GitCommit::Molecules::GitOperationDetector.new(git).detect
        end
        assert_match(/Cannot inspect.*rebase-merge/, exception.message)
      end
    end
  end

  def test_failed_or_empty_git_resolution_fails_closed
    ["", :failure].each do |result|
      git = Object.new
      git.define_singleton_method(:execute) do |*|
        raise Ace::GitCommit::GitError, "resolution failed" if result == :failure
        result
      end
      error = assert_raises(Ace::GitCommit::GitError) do
        Ace::GitCommit::Molecules::GitOperationDetector.new(git).detect
      end
      assert_match(/git status/, error.message)
    end
  end
end
