# frozen_string_literal: true

require_relative "../../test_helper"

class StageResultTest < TestCase
  def test_successful_result
    result = Ace::GitCommit::Models::StageResult.new(
      file_path: "test.rb",
      success: true
    )

    assert result.success?
    assert_equal "✓", result.status_indicator
  end

  def test_failed_result
    result = Ace::GitCommit::Models::StageResult.new(
      file_path: "test.rb",
      success: false,
      error_message: "Permission denied"
    )

    refute result.success?
    assert_equal "✗", result.status_indicator
    assert_equal "Permission denied", result.error_message
  end

  def test_large_file_detection
    result = Ace::GitCommit::Models::StageResult.new(
      file_path: "large.mp4",
      success: true,
      file_size: 51 * 1024 * 1024 # 51MB
    )

    assert result.large_file?
  end

  def test_small_file_not_large
    result = Ace::GitCommit::Models::StageResult.new(
      file_path: "small.txt",
      success: true,
      file_size: 1024 # 1KB
    )

    refute result.large_file?
  end

  def test_human_file_size_bytes
    result = Ace::GitCommit::Models::StageResult.new(
      file_path: "tiny.txt",
      success: true,
      file_size: 500
    )

    assert_equal "500 B", result.human_file_size
  end

  def test_human_file_size_kilobytes
    result = Ace::GitCommit::Models::StageResult.new(
      file_path: "medium.txt",
      success: true,
      file_size: 5 * 1024 # 5KB
    )

    assert_equal "5.0 KB", result.human_file_size
  end

  def test_human_file_size_megabytes
    result = Ace::GitCommit::Models::StageResult.new(
      file_path: "large.zip",
      success: true,
      file_size: 25.67 * 1024 * 1024 # 25.67MB
    )

    assert_equal "25.67 MB", result.human_file_size
  end

  def test_human_file_size_gigabytes
    result = Ace::GitCommit::Models::StageResult.new(
      file_path: "huge.iso",
      success: true,
      file_size: 2 * 1024 * 1024 * 1024 # 2GB
    )

    assert_equal "2.0 GB", result.human_file_size
  end

  def test_to_h_includes_all_fields
    result = Ace::GitCommit::Models::StageResult.new(
      file_path: "test.rb",
      success: true,
      error_message: nil,
      file_size: 1024,
      status: :modified
    )

    hash = result.to_h

    assert_equal "test.rb", hash[:file_path]
    assert_equal true, hash[:success]
    assert_nil hash[:error_message]
    assert_equal 1024, hash[:file_size]
    assert_equal :modified, hash[:status]
  end

  def test_status_field
    result = Ace::GitCommit::Models::StageResult.new(
      file_path: "new.rb",
      success: true,
      status: :new
    )

    assert_equal :new, result.status
  end
end
