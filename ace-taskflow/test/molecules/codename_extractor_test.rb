# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/molecules/codename_extractor"

class CodenameExtractorTest < AceTaskflowTestCase
  def setup
    super
    @extractor = Ace::Taskflow::Molecules::CodenameExtractor.new
  end

  def test_extract_returns_nil_for_nil_path
    assert_nil @extractor.extract(nil)
  end

  def test_extract_returns_nil_for_nonexistent_directory
    assert_nil @extractor.extract("/nonexistent/path")
  end

  def test_extract_returns_nil_for_empty_directory
    Dir.mktmpdir do |tmpdir|
      assert_nil @extractor.extract(tmpdir)
    end
  end

  def test_extract_returns_codename_from_versioned_header
    Dir.mktmpdir do |tmpdir|
      File.write(File.join(tmpdir, "README.md"), "# v.0.9.0 Mono-Repo Multiple Gems\n\nContent here")
      result = @extractor.extract(tmpdir)
      assert_equal "Mono-Repo Multiple Gems", result
    end
  end

  def test_extract_returns_full_header_when_no_version_pattern
    Dir.mktmpdir do |tmpdir|
      File.write(File.join(tmpdir, "README.md"), "# Custom Release Name\n\nContent here")
      result = @extractor.extract(tmpdir)
      assert_equal "Custom Release Name", result
    end
  end

  def test_extract_prefers_readme_over_other_files
    Dir.mktmpdir do |tmpdir|
      # Create multiple files, README.md should be preferred
      File.write(File.join(tmpdir, "aaa.md"), "# First File\n")
      File.write(File.join(tmpdir, "README.md"), "# v.0.9.0 Expected Result\n")
      File.write(File.join(tmpdir, "zzz.md"), "# Last File\n")

      result = @extractor.extract(tmpdir)
      assert_equal "Expected Result", result
    end
  end

  def test_extract_returns_nil_when_no_readme
    Dir.mktmpdir do |tmpdir|
      # Non-README files should be ignored to avoid extracting from arbitrary sources
      File.write(File.join(tmpdir, "zzz.md"), "# v.0.9.0 Wrong File\n")
      File.write(File.join(tmpdir, "aaa.md"), "# v.0.9.0 Another File\n")

      result = @extractor.extract(tmpdir)
      assert_nil result
    end
  end

  def test_extract_handles_case_insensitive_readme
    Dir.mktmpdir do |tmpdir|
      File.write(File.join(tmpdir, "README.MD"), "# v.0.9.0 Case Insensitive\n")
      result = @extractor.extract(tmpdir)
      assert_equal "Case Insensitive", result
    end
  end

  def test_extract_returns_nil_when_no_header_found
    Dir.mktmpdir do |tmpdir|
      File.write(File.join(tmpdir, "README.md"), "No headers here, just content")
      result = @extractor.extract(tmpdir)
      assert_nil result
    end
  end

  def test_class_method_delegates_to_instance
    Dir.mktmpdir do |tmpdir|
      File.write(File.join(tmpdir, "README.md"), "# v.0.9.0 Class Method Test\n")
      result = Ace::Taskflow::Molecules::CodenameExtractor.extract(tmpdir)
      assert_equal "Class Method Test", result
    end
  end

  def test_extract_handles_utf8_bom
    # Test that files with UTF-8 BOM (Byte Order Mark) are handled correctly
    Dir.mktmpdir do |tmpdir|
      # UTF-8 BOM is: \xEF\xBB\xBF (write raw bytes with binary mode)
      bom_bytes = [0xEF, 0xBB, 0xBF].pack("C*")
      content = "#{bom_bytes}# v.0.9.0 BOM Test Content\n\nContent here"
      File.binwrite(File.join(tmpdir, "README.md"), content)

      result = @extractor.extract(tmpdir)
      # Should extract codename despite BOM prefix
      assert_equal "BOM Test Content", result
    end
  end

  def test_extract_handles_utf8_content
    # Test that UTF-8 content (non-ASCII characters) is handled correctly
    Dir.mktmpdir do |tmpdir|
      File.write(File.join(tmpdir, "README.md"), "# v.0.9.0 日本語テスト\n\nContent here", encoding: "UTF-8")
      result = @extractor.extract(tmpdir)
      assert_equal "日本語テスト", result
    end
  end
end
