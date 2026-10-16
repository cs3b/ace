# frozen_string_literal: true
require_relative "../test_helper"
require "rubygems/package"
require "rubygems/installer"
require "open3"
require "timeout"
require "fileutils"
require "tmpdir"
require "rbconfig"

# Real package/registry resolution, with no host registration, network, or
# provider execution. Non-ACE runtime dependencies are copied already built.
class InstalledDesignTest < DesignTest
  ROOT = File.expand_path("../../..", __dir__)

  def test_installed_cli_protocols_and_explicit_project_skill_projection
    Dir.mktmpdir("design-installed") do |temporary|
      @root = File.realpath(temporary)
      @gems = File.join(@root, "gems")
      @installed = {}
      %w[home cwd tmp artifacts].each { |part| FileUtils.mkdir_p(File.join(@root, part)) }
      %w[ace-design ace-bundle ace-handbook].each { |name| install(name) }
      output, error, status = probe("ace-design", "validate", "--json")
      assert status.success?, output + error
      assert_equal 12, JSON.parse(output)["cards"]
      output, error, status = probe("ace-design", "--help")
      assert status.success?, error
      %w[profile preset explore recreate reimagine revise resume status select doctor preview inspect validate].each { |command| assert_includes output, command }
      output, error, status = probe("ace-design", "explore", "--json", "--surface", "app", "--prompt", "Support workspace", "--kind", "component",
        "--prompt-append", "Clear focus", "--prompt-append=Keep actions visible",
        "--variant-prompt", "a=Fast, clear queue", "--variant-prompt", "b=History = context", "--dry-run")
      assert status.success?, output + error
      assert_equal "Support workspace\n\nClear focus\n\nKeep actions visible", JSON.parse(output).fetch("brief")
      saved = JSON.parse(output).fetch("resolved")
      assert_equal ["Clear focus", "Keep actions visible"], saved.dig("brief_inputs", "append")
      assert_equal "Fast, clear queue", saved.fetch("variants")[0].fetch("prompt")
      assert_equal "History = context", saved.fetch("variants")[1].fetch("prompt")
      assert_equal "component", saved.fetch("kind")
      assert_equal "app/component", saved.fetch("profile").fetch("id")
      refute File.directory?(File.join(@root, "cwd/.ace-local/design"))
      output, error, status = probe("ace-design", "profile", "show", "--surface", "site", "--kind", "component")
      assert status.success?, output + error
      assert_includes output, "Website component"
      output, error, status = probe("ace-design", "profile", "adjust", "--help")
      assert status.success?, output + error
      assert_includes output, "--[no-]propose"
      assert_includes output, "--profile"
      output, error, status = probe("ace-design", "preset", "list", "--json")
      assert status.success?, output + error
      assert_includes JSON.parse(output).fetch("presets").map { |entry| entry.fetch("name") }, "taste-v2"
      %w[wfi://design/adjust wfi://design/explore wfi://design/implement wfi://design/audit wfi://design/look-for-inspiration skill://as-design-site-adjust skill://as-design-app-adjust skill://as-design-site skill://as-design-app guide://design/process tmpl://design/brief tmpl://design/feedback tmpl://design/proposal tmpl://design/source-ledger tmpl://design/benchmark-result].each do |uri|
        output, error, status = probe("ace-nav", "resolve", uri)
        assert status.success?, "#{uri}: #{output} #{error}"
        assert output.strip.start_with?(File.join(@gems, "gems", "ace-design-")), output
        assert File.file?(output.strip)
      end
      registration = File.join(@root, "cwd/.ace/nav/protocols/skill-sources")
      FileUtils.mkdir_p(registration)
      FileUtils.cp(File.join(ROOT, "ace-design/.ace-defaults/nav/protocols/skill-sources/ace-design.yml"), registration)
      output, error, status = probe("ace-handbook", "sync", "--provider", "agents")
      assert status.success?, output + error
      skills = Dir.glob(File.join(@root,"cwd/.agents/skills/as-design-*/SKILL.md"))
      assert_equal 9, skills.length, output
      assert_includes File.read(skills.find { |p| p.include?("as-design-app/SKILL") }), "surface=app"
      refute File.exist?(File.join(@root,"cwd/.codex/skills"))
      catalog = File.join(@root, "invalid-catalog")
      FileUtils.mkdir_p(catalog)
      File.write(File.join(catalog, "invalid.md"), "not a card")
      output, error, status = probe("ace-design", "validate", "--json", "--catalog", catalog)
      assert_equal 1, status.exitstatus, error
      refute_empty JSON.parse(output)["errors"]
      output, error, status = probe("ace-design", "preview", "missing-session", "--port", "-1")
      assert_equal 1, status.exitstatus, output + error
      assert_includes error, "port must be"
      config_dir = File.join(@root, "cwd/.ace/design")
      FileUtils.mkdir_p(config_dir)
      File.write(File.join(config_dir, "config.yml"), "design:\n  node: /missing/design-test-node\n")
      output, error, status = probe("ace-design", "doctor", "--json")
      refute status.success?
      assert_includes JSON.parse(output)["error"], "/missing/design-test-node", error
      output, error, status = probe("ace-design", "inspect", "file:///secret", "--surface", "site")
      assert_equal 2, status.exitstatus, output + error
      assert_match(/http/, error)

    end
  end

  private

  def install(name, requirement = Gem::Requirement.default)
    if (installed = @installed[name])
      raise "dependency mismatch #{name}" unless requirement.satisfied_by?(installed.version)
      return
    end
    source = File.join(ROOT, name)
    spec = if name.start_with?("ace-")
      Dir.chdir(source) { Gem::Specification.load("#{name}.gemspec") }
    else
      Gem::Specification.find_by_name(name, requirement)
    end
    raise "missing/mismatched dependency #{name}" unless spec && requirement.satisfied_by?(spec.version)
    @installed[name] = spec
    spec.runtime_dependencies.each { |dependency| install(dependency.name, dependency.requirement) }
    if name.start_with?("ace-")
      artifact = File.join(@root, "artifacts", "#{spec.full_name}.gem")
      Dir.chdir(source) { Gem::Package.build(spec, true, false, artifact) }
      Gem::Installer.at(artifact, install_dir: @gems, document: [], ignore_dependencies: true).install
    elsif !spec.default_gem?
      # Copy the complete already-installed dependency, including its native
      # extension directory. No extension compilation or host GEM_PATH fallback.
      FileUtils.mkdir_p(File.join(@gems, "gems"))
      FileUtils.cp_r(spec.full_gem_path, File.join(@gems, "gems", spec.full_name))
      FileUtils.mkdir_p(File.join(@gems, "specifications"))
      File.write(File.join(@gems, "specifications", "#{spec.full_name}.gemspec"), spec.to_ruby)
      if File.directory?(spec.extension_dir)
        destination = File.join(@gems, "extensions", Gem::Platform.local.to_s, Gem.extension_api_version, spec.full_name)
        FileUtils.mkdir_p(File.dirname(destination))
        FileUtils.cp_r(spec.extension_dir, destination)
      end
    end
  end

  def probe(command, *arguments)
    environment = {"HOME" => File.join(@root, "home"), "GEM_HOME" => @gems, "GEM_PATH" => @gems,
      "GEM_SPEC_CACHE" => File.join(@root, "spec-cache"), "TMPDIR" => File.join(@root, "tmp"),
      "PATH" => "#{File.dirname(RbConfig.ruby)}:/usr/bin:/bin"}
    Timeout.timeout(30) do
      Open3.capture3(environment, File.join(@gems, "bin", command), *arguments,
        chdir: File.join(@root, "cwd"), unsetenv_others: true)
    end
  end
end
