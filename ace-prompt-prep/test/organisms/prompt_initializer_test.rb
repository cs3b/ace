# frozen_string_literal: true

require "test_helper"

class PromptInitializerTest < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
    @template_file = File.join(@tmpdir, "template.md")
    File.write(@template_file, "---\ntest: true\n---\n\n# Template")
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  # setup tests
  def test_setup_creates_prompt_from_template
    # Stub template resolver to return our test template
    Ace::PromptPrep::Molecules::TemplateResolver.stub(:call, ->(**_) { { success: true, path: @template_file } }) do
      result = Ace::PromptPrep::Organisms::PromptInitializer.setup(
        target_dir: @tmpdir,
        force: false
      )

      assert result[:success]
      assert result[:path]
      refute result[:skipped]
      assert File.exist?(result[:path])
      assert_equal "---\ntest: true\n---\n\n# Template", File.read(result[:path])
    end
  end

  def test_setup_archives_existing_file
    # Create existing file
    target_file = File.join(@tmpdir, "the-prompt.md")
    FileUtils.mkdir_p(File.dirname(target_file))
    File.write(target_file, "Existing content")

    Ace::PromptPrep::Molecules::TemplateResolver.stub(:call, ->(**_) { { success: true, path: @template_file } }) do
      result = Ace::PromptPrep::Organisms::PromptInitializer.setup(
        target_dir: @tmpdir,
        force: false
      )

      assert result[:success]
      assert result[:archive_path], "Should have archived existing file"
      assert_equal "---\ntest: true\n---\n\n# Template", File.read(result[:path])
      assert_equal "Existing content", File.read(result[:archive_path])
    end
  end

  def test_setup_overwrites_with_force
    # Create existing file
    target_file = File.join(@tmpdir, "the-prompt.md")
    FileUtils.mkdir_p(File.dirname(target_file))
    File.write(target_file, "Existing content")

    Ace::PromptPrep::Molecules::TemplateResolver.stub(:call, ->(**_) { { success: true, path: @template_file } }) do
      result = Ace::PromptPrep::Organisms::PromptInitializer.setup(
        target_dir: @tmpdir,
        force: true
      )

      assert result[:success]
      assert_nil result[:archive_path], "Should not archive with force"
      assert_equal "---\ntest: true\n---\n\n# Template", File.read(result[:path])
    end
  end

  def test_setup_handles_template_resolution_failure
    Ace::PromptPrep::Molecules::TemplateResolver.stub(:call, ->(**_) { { success: false, error: "Template not found" } }) do
      result = Ace::PromptPrep::Organisms::PromptInitializer.setup(
        target_dir: @tmpdir,
        force: false
      )

      refute result[:success]
      assert_nil result[:path]
      assert_match(/Template not found/, result[:error])
    end
  end

  def test_setup_uses_custom_template_uri
    custom_uri = "tmpl://custom/template"

    # Capture the URI passed to resolver
    resolver_called_with = nil
    stub_resolver = lambda do |uri:, **_|
      resolver_called_with = uri
      { success: true, path: @template_file }
    end

    Ace::PromptPrep::Molecules::TemplateResolver.stub(:call, stub_resolver) do
      result = Ace::PromptPrep::Organisms::PromptInitializer.setup(
        template_uri: custom_uri,
        target_dir: @tmpdir,
        force: false
      )

      assert result[:success]
      assert_equal custom_uri, resolver_called_with
    end
  end

  def test_setup_creates_directory_structure
    nested_dir = File.join(@tmpdir, "nested", "path")

    Ace::PromptPrep::Molecules::TemplateResolver.stub(:call, ->(**_) { { success: true, path: @template_file } }) do
      result = Ace::PromptPrep::Organisms::PromptInitializer.setup(
        target_dir: nested_dir,
        force: false
      )

      assert result[:success]
      assert Dir.exist?(nested_dir)
      assert File.exist?(result[:path])
    end
  end

  # reset tests
  def test_reset_archives_and_restores
    # Create existing file
    target_file = File.join(@tmpdir, "the-prompt.md")
    FileUtils.mkdir_p(File.dirname(target_file))
    File.write(target_file, "Old content")

    Ace::PromptPrep::Molecules::TemplateResolver.stub(:call, ->(**_) { { success: true, path: @template_file } }) do
      result = Ace::PromptPrep::Organisms::PromptInitializer.reset(
        target_dir: @tmpdir,
        force: false
      )

      assert result[:success]
      assert result[:path]
      assert result[:archive_path]
      assert_equal "---\ntest: true\n---\n\n# Template", File.read(result[:path])
      assert_equal "Old content", File.read(result[:archive_path])
    end
  end

  def test_reset_skips_archive_with_force
    # Create existing file
    target_file = File.join(@tmpdir, "the-prompt.md")
    FileUtils.mkdir_p(File.dirname(target_file))
    File.write(target_file, "Old content")

    Ace::PromptPrep::Molecules::TemplateResolver.stub(:call, ->(**_) { { success: true, path: @template_file } }) do
      result = Ace::PromptPrep::Organisms::PromptInitializer.reset(
        target_dir: @tmpdir,
        force: true
      )

      assert result[:success]
      assert result[:path]
      assert_nil result[:archive_path]
      assert_equal "---\ntest: true\n---\n\n# Template", File.read(result[:path])
    end
  end

  def test_reset_creates_new_file_if_none_exists
    Ace::PromptPrep::Molecules::TemplateResolver.stub(:call, ->(**_) { { success: true, path: @template_file } }) do
      result = Ace::PromptPrep::Organisms::PromptInitializer.reset(
        target_dir: @tmpdir,
        force: false
      )

      assert result[:success]
      assert result[:path]
      assert_nil result[:archive_path]
      assert File.exist?(result[:path])
    end
  end

  def test_reset_handles_template_resolution_failure
    Ace::PromptPrep::Molecules::TemplateResolver.stub(:call, ->(**_) { { success: false, error: "Template not found" } }) do
      result = Ace::PromptPrep::Organisms::PromptInitializer.reset(
        target_dir: @tmpdir,
        force: false
      )

      refute result[:success]
      assert_nil result[:path]
      assert_match(/Template not found/, result[:error])
    end
  end

  def test_reset_uses_custom_template_uri
    custom_uri = "tmpl://custom/reset-template"

    # Capture the URI passed to resolver
    resolver_called_with = nil
    stub_resolver = lambda do |uri:, **_|
      resolver_called_with = uri
      { success: true, path: @template_file }
    end

    Ace::PromptPrep::Molecules::TemplateResolver.stub(:call, stub_resolver) do
      result = Ace::PromptPrep::Organisms::PromptInitializer.reset(
        template_uri: custom_uri,
        target_dir: @tmpdir,
        force: false
      )

      assert result[:success]
      assert_equal custom_uri, resolver_called_with
    end
  end

  def test_reset_handles_symlink_correctly
    # Create real file and symlink
    real_file = File.join(@tmpdir, "real-prompt.md")
    symlink_file = File.join(@tmpdir, "the-prompt.md")
    FileUtils.mkdir_p(File.dirname(real_file))
    File.write(real_file, "Symlinked content")
    File.symlink(real_file, symlink_file)

    Ace::PromptPrep::Molecules::TemplateResolver.stub(:call, ->(**_) { { success: true, path: @template_file } }) do
      result = Ace::PromptPrep::Organisms::PromptInitializer.reset(
        target_dir: @tmpdir,
        force: false
      )

      assert result[:success]
      # Should handle the symlink correctly
      assert File.exist?(symlink_file)
    end
  end

  def test_default_constants
    assert_equal "tmpl://the-prompt-base",
                 Ace::PromptPrep::Organisms::PromptInitializer::DEFAULT_TEMPLATE_URI
    assert_equal "the-prompt.md",
                 Ace::PromptPrep::Organisms::PromptInitializer::DEFAULT_PROMPT_FILE
  end

  def test_default_prompt_dir_uses_project_root
    # Should use ProjectRootFinder, not Dir.home
    default_dir = Ace::PromptPrep::Organisms::PromptInitializer.default_prompt_dir
    refute_nil default_dir
    assert default_dir.end_with?(".ace-local/prompt-prep/prompts")
  end
end
