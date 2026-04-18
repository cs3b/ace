# frozen_string_literal: true

require_relative "../../test_helper"

class PipelineSandboxBuilderTest < Minitest::Test
  SandboxBuilder = Ace::Test::EndToEndRunner::Molecules::PipelineSandboxBuilder
  TestScenario = Ace::Test::EndToEndRunner::Models::TestScenario
  TestCase = Ace::Test::EndToEndRunner::Models::TestCase
  FakeRuntimeBuilder = Struct.new(:calls, :extra_env) do
    def prepare(sandbox_root:, env:, tool_names: nil)
      calls << {sandbox_root: sandbox_root, env: env, tool_names: tool_names}
      {runtime_root: File.join(sandbox_root, ".ace-local", "e2e-runtime"), env: env.merge(extra_env || {})}
    end
  end

  def test_build_creates_required_layout_and_provider_link
    Dir.mktmpdir do |tmpdir|
      project_root = File.join(tmpdir, "repo")
      sandbox_path = File.join(tmpdir, "sandbox")
      package_name = "ace-test"
      FileUtils.mkdir_p(File.join(project_root, ".ace", "llm", "providers"))
      create_fake_package(project_root, package_name)
      create_protocol_source_package(project_root, "ace-bundle", protocol: "skill",
        relative_path: "handbook/skills", source_file: "as-onboard/SKILL.md", source_content: "---\nname: as-onboard\n---\n")
      create_protocol_source_package(project_root, "ace-bundle", protocol: "wfi",
        relative_path: "handbook/workflow-instructions", source_file: "onboard.wf.md", source_content: "---\nname: onboard\n---\n")
      FileUtils.mkdir_p(File.join(project_root, "bin"))

      write_fake_tool(File.join(project_root, "bin"), "fake-tool")
      original_path = ENV["PATH"]
      ENV["PATH"] = "#{File.join(project_root, "bin")}:#{original_path}"

      runtime_builder = FakeRuntimeBuilder.new([], {"SANDBOX_RUNTIME" => "1"})
      builder = SandboxBuilder.new(config_root: project_root, runtime_builder: runtime_builder)
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
      assert_equal "1", env["SANDBOX_RUNTIME"]
      assert_equal "copied by sandbox builder", File.read(File.join(sandbox_path, package_name, "copied.txt"))
      assert File.exist?(File.join(sandbox_path, "ace-bundle", ".ace-defaults", "nav", "protocols",
        "skill-sources", "ace-bundle.yml"))
      assert File.exist?(File.join(sandbox_path, "ace-bundle", "handbook", "skills", "as-onboard", "SKILL.md"))
      assert File.exist?(File.join(sandbox_path, "ace-bundle", ".ace-defaults", "nav", "protocols",
        "wfi-sources", "ace-bundle.yml"))
      assert File.exist?(File.join(sandbox_path, "ace-bundle", "handbook", "workflow-instructions", "onboard.wf.md"))
      assert_equal ["fake-tool"], runtime_builder.calls.first[:tool_names]
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

      builder = SandboxBuilder.new(
        config_root: project_root,
        runtime_builder: FakeRuntimeBuilder.new([], {})
      )
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

      builder = SandboxBuilder.new(
        config_root: project_root,
        runtime_builder: FakeRuntimeBuilder.new([], {})
      )
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

  def test_prepare_existing_sandbox_only_creates_runner_layout
    Dir.mktmpdir do |tmpdir|
      project_root = File.join(tmpdir, "repo")
      sandbox_path = File.join(tmpdir, "sandbox")
      runtime_builder = FakeRuntimeBuilder.new([], {})
      providers_dir = File.join(sandbox_path, ".ace", "llm", "providers")
      FileUtils.mkdir_p(providers_dir)
      File.write(File.join(providers_dir, "anthropic.yml"), "provider: anthropic\n")

      builder = SandboxBuilder.new(config_root: project_root, runtime_builder: runtime_builder)
      env = builder.prepare_existing_sandbox(
        scenario: build_scenario(tmpdir),
        sandbox_path: sandbox_path
      )

      assert_equal({}, env)
      assert_equal [], runtime_builder.calls
      assert Dir.exist?(File.join(sandbox_path, ".ace-local", "e2e"))
      assert Dir.exist?(File.join(sandbox_path, "reports"))
      assert Dir.exist?(File.join(sandbox_path, "results", "tc", "01"))
      assert Dir.exist?(File.join(sandbox_path, "results", "tc", "02"))
      refute File.symlink?(providers_dir), "existing provider directory should not be replaced"
      assert_equal "provider: anthropic\n", File.read(File.join(providers_dir, "anthropic.yml"))
    end
  end

  def test_sync_protocol_sources_into_copies_manifest_backed_files_without_runtime_mutation
    Dir.mktmpdir do |tmpdir|
      project_root = File.join(tmpdir, "repo")
      sandbox_path = File.join(tmpdir, "sandbox")
      create_protocol_source_package(project_root, "ace-bundle", protocol: "skill",
        relative_path: "handbook/skills", source_file: "as-onboard/SKILL.md", source_content: "---\nname: as-onboard\n---\n")
      create_protocol_source_package(project_root, "ace-bundle", protocol: "wfi",
        relative_path: "handbook/workflow-instructions", source_file: "onboard.wf.md", source_content: "---\nname: onboard\n---\n")

      builder = SandboxBuilder.new(
        config_root: project_root,
        runtime_builder: FakeRuntimeBuilder.new([], {})
      )

      builder.sync_protocol_sources_into(sandbox_path)

      assert File.exist?(File.join(sandbox_path, "ace-bundle", ".ace-defaults", "nav", "protocols",
        "skill-sources", "ace-bundle.yml"))
      assert File.exist?(File.join(sandbox_path, "ace-bundle", "handbook", "skills", "as-onboard", "SKILL.md"))
      assert File.exist?(File.join(sandbox_path, "ace-bundle", ".ace-defaults", "nav", "protocols",
        "wfi-sources", "ace-bundle.yml"))
      assert File.exist?(File.join(sandbox_path, "ace-bundle", "handbook", "workflow-instructions", "onboard.wf.md"))
    end
  end

  private

  def build_scenario(tmpdir, package_name: "ace-test", sandbox_profile: "custom")
    TestScenario.new(
      test_id: "TS-TEST-001",
      title: "Goal",
      area: "test",
      package: package_name,
      file_path: File.join(tmpdir, "scenario.yml"),
      content: "",
      tool_under_test: "fake-tool",
      requires: {"tools" => ["fake-tool"]},
      sandbox_profile: sandbox_profile,
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

  def create_protocol_source_package(project_root, package_name, protocol:, relative_path:, source_file:, source_content:)
    package_root = File.join(project_root, package_name)
    manifest_path = File.join(package_root, ".ace-defaults", "nav", "protocols", "#{protocol}-sources", "#{package_name}.yml")
    source_path = File.join(package_root, relative_path, source_file)

    FileUtils.mkdir_p(File.dirname(manifest_path))
    FileUtils.mkdir_p(File.dirname(source_path))
    File.write(manifest_path, <<~YAML)
      ---
      config:
        relative_path: #{relative_path}
    YAML
    File.write(source_path, source_content)
  end

  def write_fake_package_file(root, package_name, name, value)
    File.write(File.join(root, package_name, name), value)
  end
end
