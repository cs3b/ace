# frozen_string_literal: true

require_relative "../test_helper"
require "open3"
require "json"
require "rubygems/package"

class LabVmBuildGemTest < AceMonorepoE2eTestCase
  PACKAGES = {"ace-llm-providers-cli" => "llm/providers/cli",
    "ace-test-runner-e2e" => "test/end_to_end_runner"}.freeze

  def setup
    @root = Dir.mktmpdir("gem-build-fixture-")
    @bin = File.join(@root, "ace-monorepo-e2e/bin")
    FileUtils.mkdir_p([@bin, File.join(@root, ".ace-local/lab-vm")])
    FileUtils.cp(File.expand_path("../../bin/lab-vm-build-gem", __dir__), @bin)
    File.write(File.join(@bin, "lab-vm"), <<~RUBY)
      module LabVm
        ROOT = #{ @root.inspect }
        def self.local_dir = File.join(ROOT, ".ace-local/lab-vm")
      end
    RUBY
    PACKAGES.each do |name, namespace|
      directory = File.join(@root, name)
      FileUtils.mkdir_p(File.join(directory, "lib/ace", namespace))
      File.write(File.join(directory, "lib/ace", namespace, "version.rb"), "VERSION = \"1.2.3\"\n")
      File.write(File.join(directory, "#{name}.gemspec"), <<~RUBY)
        require_relative "lib/ace/#{namespace}/version"
        Gem::Specification.new do |spec|
          spec.name = #{name.inspect}
          spec.version = VERSION
          spec.summary = "Local deterministic build fixture"
          spec.authors = ["ACE test"]
          spec.files = Dir["lib/**/*"]
          spec.date = Time.now.utc.strftime("%Y-%m-%d")
        end
      RUBY
    end
    command("git", "init", "-q")
    command("git", "add", ".")
    command("git", "-c", "user.name=ACE Test", "-c", "user.email=test@example.invalid", "commit", "-qm", "fixture")
    @commit = command("git", "rev-parse", "HEAD").strip
  end

  def teardown
    FileUtils.remove_entry(@root) if @root && File.directory?(@root)
  end

  def command(*argv)
    out, err, status = Open3.capture3(*argv, chdir: @root)
    raise "fixture command failed: #{err}" unless status.success?
    out
  end

  def build(name, version)
    out, err, status = Open3.capture3("ruby", File.join(@bin, "lab-vm-build-gem"), name, @commit, version)
    assert status.success?, err
    JSON.parse(out)
  end

  def test_committed_release_versions_build_reproducibly_without_source_mutation
    PACKAGES.each_key do |name|
      first = build(name, "1.2.3")
      assert_equal @commit, first.fetch("source_commit")
      spec = Gem::Package.new(first.fetch("artifact")).spec
      assert_equal "1.2.3", spec.version.to_s
      assert_equal Time.at(first.fetch("source_date_epoch")).utc.strftime("%Y-%m-%d"), spec.date.strftime("%Y-%m-%d")
      File.unlink(first.fetch("artifact"))
      assert_equal first.fetch("sha256"), build(name, "1.2.3").fetch("sha256")
    end
    assert_empty command("git", "status", "--porcelain", "--", *PACKAGES.keys)
  end

  def test_explicit_test_version_remains_supported
    result = build(PACKAGES.keys.first, "1.2.4.pre.test")
    assert_equal "1.2.4.pre.test", Gem::Package.new(result.fetch("artifact")).spec.version.to_s
  end
end
