# frozen_string_literal: true

require_relative "../test_helper"
require "open3"
require "rbconfig"
require "rubygems/package"
require "set"

# This builds the current source and installs one public consumer at a time
# into an empty GEM_HOME, without Bundler or repository load paths.
class InstalledConsumersTest < AceHitlContractTestCase
  ROOT = File.expand_path("../../..", __dir__)
  CONSUMERS = %w[ace-assign ace-overseer ace-demo ace-git-worktree].freeze

  def test_each_standalone_consumer_installs_and_loads_both_adapters
    skip "requires explicit ACE_INSTALL_GRAPH fixture override" unless ENV["ACE_INSTALL_GRAPH"] == "1"
    @scratch = Dir.mktmpdir("ace-install", "/tmp")
    pool = File.join(@scratch, "packages")
    FileUtils.mkdir_p(pool)
    specs = Dir.glob(File.join(ROOT, "ace-*/*.gemspec")).to_h do |path|
      spec = Dir.chdir(File.dirname(path)) { Gem::Specification.load(path) }
      [spec.name, spec]
    end
    closure = Set.new
    collect = lambda do |name|
      return unless closure.add?(name)
      spec = specs[name] || Gem::Specification.find_by_name(name)
      spec.runtime_dependencies.each { |dep| collect.call(dep.name) }
    end
    (CONSUMERS + ["ace-herdr"]).each { |name| collect.call(name) }
    closure.each do |name|
      if specs[name]
        spec = specs.fetch(name)
        Dir.chdir(File.join(ROOT, name)) do
          Gem::Package.build(spec, false, false, File.join(pool, "#{spec.full_name}.gem"))
        end
      else
        spec = Gem::Specification.find_by_name(name)
        cache = spec.cache_file
        assert File.file?(cache), "missing local dependency archive #{spec.full_name}; no network fallback"
        FileUtils.cp(cache, pool)
      end
    end
    (CONSUMERS + ["ace-herdr"]).each do |consumer|
      home = File.join(@scratch, consumer)
      env = {"GEM_HOME" => home, "GEM_PATH" => home, "BUNDLE_GEMFILE" => nil,
             "BUNDLE_BIN_PATH" => nil, "RUBYOPT" => nil, "RUBYLIB" => nil}
      archive = File.join(pool, "#{specs.fetch(consumer).full_name}.gem")
      out, status = Open3.capture2e(env, RbConfig.ruby, "-S", "gem", "install", "--local",
        "--no-document", "--install-dir", home, archive, chdir: pool)
      assert status.success?, "#{consumer} clean install failed: #{out}"
      script = <<~RUBY
        require #{consumer.sub('ace-', 'ace/').tr('-', '/').inspect}
        require "ace/runtime"
        Ace::Runtime.resolve("tmux")
        Ace::Runtime.resolve("herdr")
        names = Gem.loaded_specs.keys
        raise "full HITL activated" if names.include?("ace-hitl")
        raise "assignment activated by adapter" if #{consumer == "ace-herdr"} && names.include?("ace-assign")
        raise "full HITL loaded" if $LOADED_FEATURES.any? { |path| path.include?("/ace/hitl/providers/providers.rb") }
        puts names.sort.join("\\n")
      RUBY
      # Adapter-only install intentionally has no tmux dependency.
      script = script.sub('Ace::Runtime.resolve("tmux")', '') if consumer == "ace-herdr"
      out, status = Open3.capture2e(env, RbConfig.ruby, "-e", script, chdir: @scratch)
      assert status.success?, "#{consumer} installed load failed: #{out}"
      %w[ace-runtime ace-herdr ace-hitl-contract].each { |name| assert_includes out.lines.map(&:strip), name }
      assert_includes out.lines.map(&:strip), "ace-tmux" unless consumer == "ace-herdr"
    end
  ensure
    FileUtils.remove_entry(@scratch) if @scratch && File.exist?(@scratch)
  end
end
