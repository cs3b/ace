# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lab-vm/gem-graph"
require "tmpdir"
require "fileutils"
require "open3"
require "rbconfig"

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

  def test_bootstrap_installs_a_pinned_prerelease_transitive_dependency
    gem_archive("ace-lab", "1.0.1.pre.test", [["vm-task", ">= 1.0.0"]])
    gem_archive("vm-task", "1.0.1.pre.test")
    gem_archive("vm-other", "1.0.0")
    home = File.join(@dir, "home")
    FileUtils.mkdir_p(home)
    env = {"HOME" => home, "GEM_HOME" => File.join(@dir, "gems"), "GEM_PATH" => "",
      "RUBYOPT" => nil, "BUNDLE_GEMFILE" => nil, "BUNDLE_BIN_PATH" => nil}
    helper = File.expand_path("../../lab-vm/gem-graph.rb", __dir__)
    program = <<~RUBY
      require ARGV.fetch(0)
      manifest = {"gems" => [
        {"name" => "ace-lab", "version" => "1.0.1.pre.test"},
        {"name" => "vm-task", "version" => "1.0.1.pre.test"},
        {"name" => "vm-other", "version" => "1.0.0"}]}
      LabVmGemGraph.bootstrap!(manifest, ARGV.fetch(1), roots: ["ace-lab", "vm-other"], bootstrap_roots: ["ace-lab"])
      Gem.clear_paths
      gem "ace-lab", "= 1.0.1.pre.test"
    RUBY
    out, err, status = Open3.capture3(env, RbConfig.ruby, "-e", program, helper, @dir, chdir: @dir, unsetenv_others: true)
    assert status.success?, "#{out}#{err}"
    assert File.file?(File.join(env.fetch("GEM_HOME"), "specifications", "vm-task-1.0.1.pre.test.gemspec"))
    refute File.exist?(File.join(env.fetch("GEM_HOME"), "specifications", "vm-other-1.0.0.gemspec"))
  end

  def test_install_plan_orders_every_pin_before_its_consumers
    root = gem_archive("vm-root", "1.0.0", [["vm-lib", ">= 1"]])
    library = gem_archive("vm-lib", "1.1.0.pre.test")
    other = gem_archive("vm-other", "1.0.0")
    plan = LabVmGemGraph.install_order({"gems" => [root, other, library]}, @dir,
      roots: ["vm-root", "vm-other"]).map(&:name)
    assert_equal %w[vm-lib vm-other vm-root], plan.sort
    assert_operator plan.index("vm-lib"), :<, plan.index("vm-root")
  end

  def test_bootstrap_rejects_cycles_before_installing_any_archive
    root = gem_archive("vm-root", "1.0.0", [["vm-lib", ">= 1"]])
    library = gem_archive("vm-lib", "1.0.0", [["vm-root", ">= 1"]])
    assert_raises(Gem::TSort::Cyclic) do
      LabVmGemGraph.bootstrap!({"gems" => [root, library]}, @dir, roots: ["vm-root"])
    end
  end

end
