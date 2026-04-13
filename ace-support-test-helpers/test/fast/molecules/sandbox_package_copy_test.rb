# frozen_string_literal: true

require "test_helper"

class SandboxPackageCopyTest < Minitest::Test
  def test_prepare_creates_named_sandbox_under_default_root
    Dir.mktmpdir do |tmpdir|
      create_package(tmpdir, "ace-demo")
      helper = Ace::TestSupport::SandboxPackageCopy.new(source_root: tmpdir)

      result = helper.prepare(package_name: "ace-demo", sandbox_name: "8r9j9x-demo-ts001")

      assert_equal File.join(tmpdir, ".ace-local", "test-e2e", "8r9j9x-demo-ts001"), result[:sandbox_root]
      assert_equal File.join(result[:sandbox_root], "ace-demo"), result[:package_root]
      assert_includes result[:env].keys, "PROJECT_ROOT_PATH"
      assert_includes result[:env].keys, "ACE_E2E_SOURCE_ROOT"
      assert_equal result[:sandbox_root], result[:env]["PROJECT_ROOT_PATH"]
      assert_equal tmpdir, result[:env]["ACE_E2E_SOURCE_ROOT"]
      assert_equal "copied", File.read(File.join(result[:package_root], "copied.txt"))
    end
  end

  def test_prepare_uses_explicit_sandbox_root
    Dir.mktmpdir do |tmpdir|
      create_package(tmpdir, "ace-demo")
      helper = Ace::TestSupport::SandboxPackageCopy.new(source_root: tmpdir)
      explicit_root = File.join(tmpdir, "custom-sandbox")

      result = helper.prepare(package_name: "ace-demo", sandbox_root: explicit_root)

      assert_equal explicit_root, result[:sandbox_root]
      assert Dir.exist?(result[:sandbox_root])
      assert_equal "copied", File.read(File.join(result[:package_root], "copied.txt"))
    end
  end

  def test_prepare_does_not_overwrite_existing_package_copy
    Dir.mktmpdir do |tmpdir|
      create_package(tmpdir, "ace-demo")
      helper = Ace::TestSupport::SandboxPackageCopy.new(source_root: tmpdir)
      sandbox_root = File.join(tmpdir, ".ace-local", "test-e2e", "existing")
      FileUtils.mkdir_p(File.join(sandbox_root, "ace-demo"))
      File.write(File.join(sandbox_root, "ace-demo", "preloaded.txt"), "preloaded")

      helper.prepare(package_name: "ace-demo", sandbox_root: sandbox_root)

      assert_equal "preloaded", File.read(File.join(sandbox_root, "ace-demo", "preloaded.txt"))
      refute File.exist?(File.join(sandbox_root, "ace-demo", "copied.txt"))
    end
  end

  def test_prepare_raises_when_package_missing
    Dir.mktmpdir do |tmpdir|
      helper = Ace::TestSupport::SandboxPackageCopy.new(source_root: tmpdir)

      error = assert_raises(ArgumentError) do
        helper.prepare(package_name: "ace-missing", sandbox_name: "8r9j9x-missing")
      end

      assert_match(/Package source directory not found/, error.message)
    end
  end

  private

  def create_package(root, name)
    dir = File.join(root, name)
    FileUtils.mkdir_p(dir)
    File.write(File.join(dir, "copied.txt"), "copied")
  end
end
