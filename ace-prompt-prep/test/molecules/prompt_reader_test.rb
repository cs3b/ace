# frozen_string_literal: true

require "test_helper"

class PromptReaderTest < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
    @test_file = File.join(@tmpdir, "test-prompt.md")
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def test_reads_existing_file
    File.write(@test_file, "Test content")
    result = Ace::PromptPrep::Molecules::PromptReader.call(path: @test_file)

    assert result[:success]
    assert_equal "Test content", result[:content]
    assert_equal @test_file, result[:path]
    assert_nil result[:error]
  end

  def test_handles_missing_file
    missing_file = File.join(@tmpdir, "missing.md")
    result = Ace::PromptPrep::Molecules::PromptReader.call(path: missing_file)

    refute result[:success]
    assert_nil result[:content]
    assert_match(/not found/, result[:error])
  end

  def test_handles_empty_file
    File.write(@test_file, "")
    result = Ace::PromptPrep::Molecules::PromptReader.call(path: @test_file)

    assert result[:success]
    assert_equal "", result[:content]
  end

  def test_handles_whitespace_only_file
    File.write(@test_file, "   \n\n  \t  ")
    result = Ace::PromptPrep::Molecules::PromptReader.call(path: @test_file)

    assert result[:success]
    assert_equal "   \n\n  \t  ", result[:content]
  end

  def test_handles_unicode_content
    content = "日本語 Привет café 🎉"
    File.write(@test_file, content, encoding: "utf-8")
    result = Ace::PromptPrep::Molecules::PromptReader.call(path: @test_file)

    assert result[:success]
    assert_equal content, result[:content]
  end

  def test_handles_large_file
    content = "x" * 100_000
    File.write(@test_file, content)
    result = Ace::PromptPrep::Molecules::PromptReader.call(path: @test_file)

    assert result[:success]
    assert_equal content, result[:content]
  end

  def test_handles_windows_line_endings
    content = "line1\r\nline2\r\nline3"
    File.write(@test_file, content)
    result = Ace::PromptPrep::Molecules::PromptReader.call(path: @test_file)

    assert result[:success]
    assert_equal content, result[:content]
  end

  def test_handles_symlinked_file
    real_file = File.join(@tmpdir, "real.md")
    symlink_file = File.join(@tmpdir, "link.md")
    File.write(real_file, "Symlinked content")
    File.symlink(real_file, symlink_file)

    result = Ace::PromptPrep::Molecules::PromptReader.call(path: symlink_file)

    assert result[:success]
    assert_equal "Symlinked content", result[:content]
    assert_equal symlink_file, result[:path]
    assert_equal File.realpath(real_file), result[:actual_path]
  end

  def test_handles_utf8_bom
    # UTF-8 BOM bytes
    bom = "\xEF\xBB\xBF"
    content = "#{bom}Content with BOM"
    File.write(@test_file, content, encoding: "utf-8")
    result = Ace::PromptPrep::Molecules::PromptReader.call(path: @test_file)

    assert result[:success]
    # BOM is preserved in content
    assert result[:content].start_with?(bom)
  end
end
