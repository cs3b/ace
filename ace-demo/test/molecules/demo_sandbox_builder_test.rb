# frozen_string_literal: true

require_relative "../test_helper"
require "tmpdir"
require "fileutils"

class DemoSandboxBuilderTest < AceDemoTestCase
  def setup
    super
    @tmp = Dir.mktmpdir("ace_demo_sandbox_builder")
    @sandbox_root = File.join(@tmp, "sandbox")
    @tape_path = File.join(@tmp, "demo.tape.yml")
    File.write(@tape_path, "description: test\n")
  end

  def teardown
    FileUtils.rm_rf(@tmp)
    super
  end

  def test_build_preserves_argument_error_and_cleans_failed_sandbox
    builder = Ace::Demo::Molecules::DemoSandboxBuilder.new(sandbox_dir: @sandbox_root, cwd: @tmp)

    Ace::B36ts.stub(:now, "abc123") do
      error = assert_raises(ArgumentError) do
        builder.build(source_tape_path: @tape_path, setup_steps: ["invalid-directive"])
      end

      assert_includes error.message, "Unknown setup directive"
      refute Dir.exist?(File.join(@sandbox_root, "abc123"))
    end
  end

  def test_build_wraps_runtime_error_and_cleans_failed_sandbox
    builder = Ace::Demo::Molecules::DemoSandboxBuilder.new(sandbox_dir: @sandbox_root, cwd: @tmp)

    Ace::B36ts.stub(:now, "def456") do
      error = assert_raises(RuntimeError) do
        builder.build(source_tape_path: @tape_path, setup_steps: [{"run" => "exit 2"}])
      end

      assert_includes error.message, "Sandbox setup failed for"
      refute Dir.exist?(File.join(@sandbox_root, "def456"))
    end
  end
end
