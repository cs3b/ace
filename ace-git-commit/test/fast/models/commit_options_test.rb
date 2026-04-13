# frozen_string_literal: true

require_relative "../../test_helper"

class CommitOptionsTest < TestCase
  def test_initialize_with_defaults
    options = Ace::GitCommit::Models::CommitOptions.new

    assert_nil options.intention
    assert_nil options.message
    assert_nil options.model
    assert_equal [], options.files
    assert_equal false, options.only_staged
    assert_equal false, options.dry_run
    assert_equal false, options.debug
    assert_equal false, options.force
    assert_equal false, options.no_split
  end

  def test_initialize_with_values
    options = Ace::GitCommit::Models::CommitOptions.new(
      intention: "fix bug",
      message: "fix: resolve issue",
      model: "glite",
      files: ["file1.rb", "file2.rb"],
      only_staged: true,
      dry_run: true,
      debug: true,
      force: true,
      no_split: true
    )

    assert_equal "fix bug", options.intention
    assert_equal "fix: resolve issue", options.message
    assert_equal "glite", options.model
    assert_equal ["file1.rb", "file2.rb"], options.files
    assert_equal true, options.only_staged
    assert_equal true, options.dry_run
    assert_equal true, options.debug
    assert_equal true, options.force
    assert_equal true, options.no_split
  end

  def test_use_llm_when_no_message
    options = Ace::GitCommit::Models::CommitOptions.new
    assert options.use_llm?
  end

  def test_use_llm_false_when_message_provided
    options = Ace::GitCommit::Models::CommitOptions.new(message: "feat: add feature")
    refute options.use_llm?
  end

  def test_specific_files_when_files_provided
    options = Ace::GitCommit::Models::CommitOptions.new(files: ["file.rb"])
    assert options.specific_files?
  end

  def test_specific_files_false_when_no_files
    options = Ace::GitCommit::Models::CommitOptions.new
    refute options.specific_files?
  end

  def test_stage_all_true_by_default
    options = Ace::GitCommit::Models::CommitOptions.new
    assert options.stage_all?
  end

  def test_stage_all_false_when_only_staged
    options = Ace::GitCommit::Models::CommitOptions.new(only_staged: true)
    refute options.stage_all?
  end

  def test_stage_all_false_when_specific_files
    options = Ace::GitCommit::Models::CommitOptions.new(files: ["file.rb"])
    refute options.stage_all?
  end

  def test_to_h_returns_hash
    options = Ace::GitCommit::Models::CommitOptions.new(
      intention: "test",
      message: "test message"
    )

    hash = options.to_h
    assert_kind_of Hash, hash
    assert_equal "test", hash[:intention]
    assert_equal "test message", hash[:message]
  end
end
