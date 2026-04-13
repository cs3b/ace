# frozen_string_literal: true

require "test_helper"

class TemplateManagerTest < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
    @template_file = File.join(@tmpdir, "template.md")
    @target_file = File.join(@tmpdir, "target", "output.md")
    @archive_dir = File.join(@tmpdir, "archive")

    File.write(@template_file, "Template content")
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  # copy_template tests
  def test_copy_template_creates_target_directory
    result = Ace::PromptPrep::Molecules::TemplateManager.copy_template(
      template_path: @template_file,
      target_path: @target_file,
      force: false
    )

    assert result[:success]
    assert_equal @target_file, result[:path]
    refute result[:skipped]
    assert File.exist?(@target_file)
    assert_equal "Template content", File.read(@target_file)
  end

  def test_copy_template_skips_existing_without_force
    FileUtils.mkdir_p(File.dirname(@target_file))
    File.write(@target_file, "Existing content")

    result = Ace::PromptPrep::Molecules::TemplateManager.copy_template(
      template_path: @template_file,
      target_path: @target_file,
      force: false
    )

    assert result[:success]
    assert_equal @target_file, result[:path]
    assert result[:skipped]
    assert_equal "Existing content", File.read(@target_file)
  end

  def test_copy_template_overwrites_with_force
    FileUtils.mkdir_p(File.dirname(@target_file))
    File.write(@target_file, "Existing content")

    result = Ace::PromptPrep::Molecules::TemplateManager.copy_template(
      template_path: @template_file,
      target_path: @target_file,
      force: true
    )

    assert result[:success]
    assert_equal @target_file, result[:path]
    refute result[:skipped]
    assert_equal "Template content", File.read(@target_file)
  end

  def test_copy_template_handles_missing_template
    missing_template = File.join(@tmpdir, "missing.md")

    result = Ace::PromptPrep::Molecules::TemplateManager.copy_template(
      template_path: missing_template,
      target_path: @target_file,
      force: false
    )

    refute result[:success]
    assert_nil result[:path]
    refute result[:skipped]
    assert_match(/not found/, result[:error])
  end

  def test_copy_template_preserves_content
    template_content = "---\nfrontmatter: true\n---\n\n# Content\n\nWith unicode: 日本語"
    File.write(@template_file, template_content, encoding: "utf-8")

    result = Ace::PromptPrep::Molecules::TemplateManager.copy_template(
      template_path: @template_file,
      target_path: @target_file,
      force: false
    )

    assert result[:success]
    assert_equal template_content, File.read(@target_file, encoding: "utf-8")
  end

  # archive_file tests
  def test_archive_file_creates_archive_directory
    FileUtils.mkdir_p(File.dirname(@target_file))
    File.write(@target_file, "File to archive")

    result = Ace::PromptPrep::Molecules::TemplateManager.archive_file(
      source_path: @target_file,
      archive_dir: @archive_dir
    )

    assert result[:success]
    assert result[:archive_path]
    refute result[:skipped]
    assert Dir.exist?(@archive_dir)
    assert File.exist?(result[:archive_path])
    assert_equal "File to archive", File.read(result[:archive_path])
  end

  def test_archive_file_uses_timestamp_in_filename
    FileUtils.mkdir_p(File.dirname(@target_file))
    File.write(@target_file, "Content")

    result = Ace::PromptPrep::Molecules::TemplateManager.archive_file(
      source_path: @target_file,
      archive_dir: @archive_dir
    )

    assert result[:success]
    # Filename should include timestamp pattern YYYYMMDD-HHMMSS
    assert_match(/output-\d{8}-\d{6}\.md$/, result[:archive_path])
  end

  def test_archive_file_skips_missing_source
    missing_file = File.join(@tmpdir, "missing.md")

    result = Ace::PromptPrep::Molecules::TemplateManager.archive_file(
      source_path: missing_file,
      archive_dir: @archive_dir
    )

    assert result[:success]
    assert_nil result[:archive_path]
    assert result[:skipped]
  end

  def test_archive_file_preserves_content
    FileUtils.mkdir_p(File.dirname(@target_file))
    content = "Content with unicode: 日本語 🎉"
    File.write(@target_file, content, encoding: "utf-8")

    result = Ace::PromptPrep::Molecules::TemplateManager.archive_file(
      source_path: @target_file,
      archive_dir: @archive_dir
    )

    assert result[:success]
    assert_equal content, File.read(result[:archive_path], encoding: "utf-8")
  end

  # restore_template tests
  def test_restore_template_archives_existing_file
    FileUtils.mkdir_p(File.dirname(@target_file))
    File.write(@target_file, "Old content")

    result = Ace::PromptPrep::Molecules::TemplateManager.restore_template(
      template_path: @template_file,
      target_path: @target_file,
      archive_dir: @archive_dir,
      force: false
    )

    assert result[:success]
    assert_equal @target_file, result[:path]
    assert result[:archive_path]
    assert_equal "Template content", File.read(@target_file)
    assert_equal "Old content", File.read(result[:archive_path])
  end

  def test_restore_template_skips_archive_with_force
    FileUtils.mkdir_p(File.dirname(@target_file))
    File.write(@target_file, "Old content")

    result = Ace::PromptPrep::Molecules::TemplateManager.restore_template(
      template_path: @template_file,
      target_path: @target_file,
      archive_dir: @archive_dir,
      force: true
    )

    assert result[:success]
    assert_equal @target_file, result[:path]
    assert_nil result[:archive_path]
    assert_equal "Template content", File.read(@target_file)
    refute Dir.exist?(@archive_dir)
  end

  def test_restore_template_creates_new_file
    result = Ace::PromptPrep::Molecules::TemplateManager.restore_template(
      template_path: @template_file,
      target_path: @target_file,
      archive_dir: @archive_dir,
      force: false
    )

    assert result[:success]
    assert_equal @target_file, result[:path]
    assert_nil result[:archive_path]
    assert_equal "Template content", File.read(@target_file)
  end

  def test_restore_template_handles_missing_template
    missing_template = File.join(@tmpdir, "missing.md")

    result = Ace::PromptPrep::Molecules::TemplateManager.restore_template(
      template_path: missing_template,
      target_path: @target_file,
      archive_dir: @archive_dir,
      force: false
    )

    refute result[:success]
    assert_nil result[:path]
    assert_nil result[:archive_path]
    assert_match(/not found/, result[:error])
  end

  def test_restore_template_handles_archive_failure
    FileUtils.mkdir_p(File.dirname(@target_file))
    File.write(@target_file, "Content")

    # Stub archive_file to fail
    Ace::PromptPrep::Molecules::TemplateManager.stub(:archive_file, ->(**_) { {success: false, error: "Archive failed"} }) do
      result = Ace::PromptPrep::Molecules::TemplateManager.restore_template(
        template_path: @template_file,
        target_path: @target_file,
        archive_dir: @archive_dir,
        force: false
      )

      refute result[:success]
      assert_match(/Archive failed/, result[:error])
    end
  end
end
