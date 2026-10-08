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
class InstalledNeutralPrResolutionTest < Ace::Handbook::TestCase
  ROOT = File.expand_path("../../..", __dir__)

  def test_fresh_installed_consumer_resolves_new_names_and_refuses_obsolete_names
    Dir.mktmpdir("neutral-pr-installed") do |temporary|
      @root = File.realpath(temporary)
      @gems = File.join(@root, "gems")
      @installed = {}
      %w[home cwd tmp artifacts].each { |part| FileUtils.mkdir_p(File.join(@root, part)) }
      %w[ace-support-nav ace-bundle ace-git].each { |name| install(name) }
      %w[wfi://git/pr/create wfi://git/pr/update skill://as-git-pr-create skill://as-git-pr-update].each do |uri|
        output, error, status = probe("ace-nav", "resolve", uri)
        assert status.success?, "#{uri}: #{error}"
        path = output.strip
        assert path.start_with?(File.join(@gems, "gems", "ace-git-")), path
        assert File.file?(path), path
        bundle, error, status = probe("ace-bundle", uri)
        assert status.success?, "#{uri}: #{error}"
        if bundle.include?("Bundle saved") && bundle.include?("output file:")
          bundle = File.read(bundle.lines.last.strip)
        end
        assert_includes bundle, "git/pr/"
      end
      %w[wfi://github/pr/create wfi://github/pr/update skill://as-github-pr-create skill://as-github-pr-update].each do |uri|
        %w[ace-nav ace-bundle].each do |command|
          arguments = command == "ace-nav" ? ["resolve", uri] : [uri]
          output, error, status = probe(command, *arguments)
          refute status.success?, "obsolete #{uri} resolved: #{output}"
          assert_match(/Resource not found|Failed to resolve protocol/, output + error)
        end
      end
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
