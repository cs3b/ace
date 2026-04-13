# frozen_string_literal: true

require_relative "../../test_helper"

class FixtureCopierTest < Minitest::Test
  def setup
    @copier = Ace::Test::EndToEndRunner::Molecules::FixtureCopier.new
  end

  def test_copy_flat_files
    Dir.mktmpdir do |tmpdir|
      source = File.join(tmpdir, "fixtures")
      target = File.join(tmpdir, "sandbox")
      FileUtils.mkdir_p(source)
      File.write(File.join(source, "file1.rb"), "puts 'hello'")
      File.write(File.join(source, "file2.rb"), "puts 'world'")

      @copier.copy(source_dir: source, target_dir: target)

      assert File.exist?(File.join(target, "file1.rb"))
      assert File.exist?(File.join(target, "file2.rb"))
    end
  end

  def test_copy_nested_directories
    Dir.mktmpdir do |tmpdir|
      source = File.join(tmpdir, "fixtures")
      target = File.join(tmpdir, "sandbox")
      FileUtils.mkdir_p(File.join(source, "lib", "helpers"))
      File.write(File.join(source, "lib", "helpers", "util.rb"), "module Util; end")
      File.write(File.join(source, "lib", "main.rb"), "require 'helpers/util'")

      @copier.copy(source_dir: source, target_dir: target)

      assert File.exist?(File.join(target, "lib", "helpers", "util.rb"))
      assert File.exist?(File.join(target, "lib", "main.rb"))
    end
  end

  def test_copy_preserves_content
    Dir.mktmpdir do |tmpdir|
      source = File.join(tmpdir, "fixtures")
      target = File.join(tmpdir, "sandbox")
      FileUtils.mkdir_p(source)
      content = "# frozen_string_literal: true\n\nclass Foo\n  def bar\n    42\n  end\nend\n"
      File.write(File.join(source, "foo.rb"), content)

      @copier.copy(source_dir: source, target_dir: target)

      assert_equal content, File.read(File.join(target, "foo.rb"))
    end
  end

  def test_missing_source_raises
    Dir.mktmpdir do |tmpdir|
      target = File.join(tmpdir, "sandbox")

      error = assert_raises(ArgumentError) do
        @copier.copy(source_dir: "/nonexistent/fixtures", target_dir: target)
      end
      assert_match(/not found/, error.message)
    end
  end

  def test_auto_creates_target_dir
    Dir.mktmpdir do |tmpdir|
      source = File.join(tmpdir, "fixtures")
      target = File.join(tmpdir, "deep", "nested", "sandbox")
      FileUtils.mkdir_p(source)
      File.write(File.join(source, "test.txt"), "hello")

      refute Dir.exist?(target)
      @copier.copy(source_dir: source, target_dir: target)
      assert Dir.exist?(target)
      assert File.exist?(File.join(target, "test.txt"))
    end
  end

  def test_returns_copied_paths
    Dir.mktmpdir do |tmpdir|
      source = File.join(tmpdir, "fixtures")
      target = File.join(tmpdir, "sandbox")
      FileUtils.mkdir_p(File.join(source, "lib"))
      File.write(File.join(source, "file.rb"), "code")
      File.write(File.join(source, "lib", "helper.rb"), "helper")

      result = @copier.copy(source_dir: source, target_dir: target)

      assert_includes result, "file.rb"
      assert_includes result, "lib"
      assert_includes result, "lib/helper.rb"
    end
  end
end
