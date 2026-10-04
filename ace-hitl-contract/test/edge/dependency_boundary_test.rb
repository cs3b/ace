# frozen_string_literal: true

require_relative "../test_helper"
require "open3"
require "rbconfig"
require "set"

class DependencyBoundaryTest < AceHitlContractTestCase
  ROOT = File.expand_path("../../..", __dir__)

  def test_contract_loads_without_rubygems_or_consumer_packages
    script = <<~RUBY
      require "ace/hitl/contract"
      raise unless Ace::Hitl::Providers::Ref.new(session: "s", pane: "p").to_h[:schema] == "ace.hitl.ref/v1"
      raise unless Ace::Hitl::Providers::AskResult.new(event_id: "e", request_id: "r").event_id == "e"
      raise unless Ace::Hitl::Providers::DeliverResult.new(ref: "r", state: "sent").state == "sent"
      raise if defined?(Ace::Assign) || defined?(Ace::Hitl::Providers::Registry) || defined?(Ace::Hitl::Lifecycle)
    RUBY
    out, status = Open3.capture2e({"RUBYOPT" => nil}, RbConfig.ruby, "--disable-gems", "-I",
      File.join(ROOT, "ace-hitl-contract/lib"), "-e", script)
    assert status.success?, out
  end

  def test_hitl_and_contract_ship_disjoint_require_paths
    paths = %w[ace-hitl ace-hitl-contract].map do |package|
      Dir.glob(File.join(ROOT, package, "lib/**/*.rb")).map { |path| path.split("/lib/", 2).last }
    end
    assert_empty paths[0] & paths[1]
  end

  def test_consumers_install_both_adapters_without_an_authority_cycle
    specs = Dir.glob(File.join(ROOT, "ace-*/*.gemspec")).to_h do |path|
      spec = load_source_gemspec(path)
      [spec.name, spec]
    end
    visit = lambda do |name, stack, seen|
      refute_includes stack, name, "runtime dependency cycle: #{(stack + [name]).join(' -> ')}"
      return unless specs[name] && seen.add?(name)
      specs[name].runtime_dependencies.each { |dep| visit.call(dep.name, stack + [name], seen) }
    end
    %w[ace-assign ace-overseer ace-demo ace-git-worktree].each do |consumer|
      seen = Set.new
      visit.call(consumer, [], seen)
      %w[ace-runtime ace-tmux ace-herdr ace-hitl-contract].each { |name| assert_includes seen, name }
      refute_includes seen, "ace-hitl", "#{consumer} pulled privileged HITL authority into its install"
    end
    assert_empty specs.fetch("ace-hitl-contract").runtime_dependencies
    assert_includes specs.fetch("ace-hitl").runtime_dependencies.map(&:name), "ace-assign"
  end
end
