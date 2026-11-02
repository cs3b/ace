# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lab-vm/gem-graph"
require "tmpdir"
require "fileutils"

class LabVmGemGraphTest < AceMonorepoE2eTestCase
  def setup
    @dir = Dir.mktmpdir("lab-vm-gem-graph")
  end

  def teardown
    FileUtils.remove_entry(@dir) if @dir && File.directory?(@dir)
  end

  def gem_archive(name, version, dependencies = [])
    spec = Gem::Specification.new do |gem|
      gem.name = name
      gem.version = version
      gem.summary = "Disposable test gem"
      gem.authors = ["ACE E2E"]
      gem.files = []
      dependencies.each { |dependency, requirement| gem.add_dependency(dependency, requirement) }
    end
    path = File.join(@dir, "#{name}-#{version}.gem")
    capture_io { Gem::Package.build(spec, true, false, path) }
    {"name" => name, "version" => version}
  end

  def test_accepts_reachable_pinned_dependencies_and_ruby_defaults
    root = gem_archive("vm-root", "1.0.0", [["vm-lib", "~> 1.0"], ["date", ">= 0"]])
    library = gem_archive("vm-lib", "1.2.0")
    assert_equal ["vm-root"], LabVmGemGraph.validate!({"gems" => [root, library]}, @dir, roots: ["vm-root"])
  end

  def test_rejects_a_pinned_dependency_that_does_not_satisfy_its_parent
    root = gem_archive("vm-root", "1.0.0", [["vm-lib", ">= 2"]])
    library = gem_archive("vm-lib", "1.2.0")
    error = assert_raises(ArgumentError) { LabVmGemGraph.validate!({"gems" => [root, library]}, @dir, roots: ["vm-root"]) }
    assert_includes error.message, "does not satisfy"
  end

  def test_rejects_a_missing_dependency_and_an_unreachable_extra_gem
    root = gem_archive("vm-root", "1.0.0", [["vm-lib", ">= 1"]])
    assert_raises(ArgumentError) { LabVmGemGraph.validate!({"gems" => [root]}, @dir, roots: ["vm-root"]) }
    library = gem_archive("vm-lib", "1.0.0")
    extra = gem_archive("vm-extra", "1.0.0")
    error = assert_raises(ArgumentError) { LabVmGemGraph.validate!({"gems" => [root, library, extra]}, @dir, roots: ["vm-root"]) }
    assert_includes error.message, "not covered"
  end

  def test_rejects_duplicate_pins_and_archive_metadata_mismatch
    root = gem_archive("vm-root", "1.0.0")
    assert_raises(ArgumentError) { LabVmGemGraph.validate!({"gems" => [root, root]}, @dir, roots: ["vm-root"]) }
    FileUtils.cp(File.join(@dir, "vm-root-1.0.0.gem"), File.join(@dir, "vm-root-2.0.0.gem"))
    assert_raises(ArgumentError) do
      LabVmGemGraph.validate!({"gems" => [{"name" => "vm-root", "version" => "2.0.0"}]}, @dir, roots: ["vm-root"])
    end
  end
end
