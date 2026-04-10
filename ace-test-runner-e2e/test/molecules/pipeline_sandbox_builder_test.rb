# frozen_string_literal: true

require_relative "../test_helper"

class PipelineSandboxBuilderTest < Minitest::Test
  SandboxBuilder = Ace::Test::EndToEndRunner::Molecules::PipelineSandboxBuilder
  TestScenario = Ace::Test::EndToEndRunner::Models::TestScenario
  TestCase = Ace::Test::EndToEndRunner::Models::TestCase

  def test_build_creates_required_layout_and_provider_link
    Dir.mktmpdir do |tmpdir|
      project_root = File.join(tmpdir, "repo")
      sandbox_path = File.join(tmpdir, "sandbox")
      package_name = "ace-test"
      FileUtils.mkdir_p(File.join(project_root, ".ace", "llm", "providers"))
      create_fake_package(project_root, package_name)
      FileUtils.mkdir_p(File.join(project_root, "bin"))

      write_fake_tool(File.join(project_root, "bin"), "fake-tool")
      original_path = ENV["PATH"]
      ENV["PATH"] = "#{File.join(project_root, "bin")}:#{original_path}"

      builder = SandboxBuilder.new(config_root: project_root)
      env = builder.build(
        scenario: build_scenario(tmpdir, package_name: package_name),
        sandbox_path: sandbox_path
      )

      assert Dir.exist?(File.join(sandbox_path, ".git")), "sandbox should be git repo"
      assert File.symlink?(File.join(sandbox_path, ".ace", "llm", "providers")), "providers should be symlinked"
      assert Dir.exist?(File.join(sandbox_path, "results", "tc", "01")), "result dir 01 should exist"
      assert Dir.exist?(File.join(sandbox_path, "results", "tc", "02")), "result dir 02 should exist"
      assert_equal File.expand_path(sandbox_path), env["PROJECT_ROOT_PATH"]
      assert_equal File.expand_path(project_root), env["ACE_E2E_SOURCE_ROOT"]
      assert_equal "copied by sandbox builder", File.read(File.join(sandbox_path, package_name, "copied.txt"))
    ensure
      ENV["PATH"] = original_path
    end
  end

  def test_build_copies_package_into_sandbox
    Dir.mktmpdir do |tmpdir|
      project_root = File.join(tmpdir, "repo")
      sandbox_path = File.join(tmpdir, "sandbox")
      package_name = "ace-search"
      create_fake_package(project_root, package_name)
      FileUtils.mkdir_p(File.join(project_root, "bin"))
      write_fake_tool(File.join(project_root, "bin"), "fake-tool")
      original_path = ENV["PATH"]
      ENV["PATH"] = "#{File.join(project_root, "bin")}:#{original_path}"

      builder = SandboxBuilder.new(config_root: project_root)
      builder.build(
        scenario: build_scenario(tmpdir, package_name: package_name),
        sandbox_path: sandbox_path
      )

      assert Dir.exist?(File.join(sandbox_path, package_name))
      assert_equal "copied by sandbox builder", File.read(File.join(sandbox_path, package_name, "copied.txt"))
    ensure
      ENV["PATH"] = original_path
    end
  end

  def test_build_does_not_override_existing_package_in_sandbox
    Dir.mktmpdir do |tmpdir|
      project_root = File.join(tmpdir, "repo")
      sandbox_path = File.join(tmpdir, "sandbox")
      package_name = "ace-bundled"
      FileUtils.mkdir_p(File.join(project_root, package_name))
      write_fake_package_file(project_root, package_name, "source.txt", "from_project")
      FileUtils.mkdir_p(File.join(sandbox_path, package_name))
      write_fake_package_file(sandbox_path, package_name, "preloaded.txt", "preloaded value")
      FileUtils.mkdir_p(File.join(project_root, "bin"))
      write_fake_tool(File.join(project_root, "bin"), "fake-tool")
      original_path = ENV["PATH"]
      ENV["PATH"] = "#{File.join(project_root, "bin")}:#{original_path}"

      builder = SandboxBuilder.new(config_root: project_root)
      builder.build(
        scenario: build_scenario(tmpdir, package_name: package_name),
        sandbox_path: sandbox_path
      )

      assert_equal "preloaded value", File.read(File.join(sandbox_path, package_name, "preloaded.txt"))
      refute File.exist?(File.join(sandbox_path, package_name, "source.txt"))
    ensure
      ENV["PATH"] = original_path
    end
  end

  private

  def build_scenario(tmpdir, package_name: "ace-test")
    TestScenario.new(
      test_id: "TS-TEST-001",
      title: "Goal",
      area: "test",
      package: package_name,
      file_path: File.join(tmpdir, "scenario.yml"),
      content: "",
      tool_under_test: "fake-tool",
      sandbox_layout: {
        "results/tc/01/" => "first",
        "results/tc/02/" => "second"
      },
      test_cases: [
        TestCase.new(tc_id: "TC-001", title: "One", content: "", file_path: "one.runner.md", goal_format: "standalone"),
        TestCase.new(tc_id: "TC-002", title: "Two", content: "", file_path: "two.runner.md", goal_format: "standalone")
      ]
    )
  end

  def write_fake_tool(bin_dir, name)
    path = File.join(bin_dir, name)
    File.write(path, <<~SH)
      #!/usr/bin/env bash
      if [ "$1" = "--help" ]; then
        echo "help ok"
        exit 0
      fi
      exit 1
    SH
    FileUtils.chmod(0o755, path)
  end

  def create_fake_package(project_root, package_name)
    package_dir = File.join(project_root, package_name)
    FileUtils.mkdir_p(package_dir)
    write_fake_package_file(project_root, package_name, "copied.txt", "copied by sandbox builder")
  end

  def write_fake_package_file(root, package_name, name, value)
    File.write(File.join(root, package_name, name), value)
  end
end
