# frozen_string_literal: true

require_relative "../test_helper"
require "open3"
require "rbconfig"

class DependencyBoundaryTest < AceHitlContractTestCase
  ROOT = File.expand_path("../../..", __dir__)

  # L1 removed ace-hitl's runtime dependencies on the Assign authority/evidence
  # owner and on terminal adapters. The contract keeps that new boundary:
  # consumers may install the terminal adapters and the contract leaf, but the
  # HITL package must stay free of Assign and Herdr.
  CONSUMERS = %w[ace-assign ace-overseer ace-demo ace-git-worktree].freeze
  CONSUMER_CLOSURE_REQUIRED = %w[ace-runtime ace-tmux ace-herdr ace-hitl-contract].freeze
  HITL_FORBIDDEN_RUNTIME = %w[ace-assign ace-herdr].freeze

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

  def test_consumers_install_terminal_adapters_and_contract_without_pulling_hitl
    specs = source_specs
    CONSUMERS.each do |consumer|
      seen = dependency_closure(specs, consumer)
      CONSUMER_CLOSURE_REQUIRED.each do |name|
        assert_includes seen, name, "#{consumer} lost #{name} from its runtime install closure"
      end
      refute_includes seen, "ace-hitl",
        "#{consumer} pulled the HITL package into its runtime install closure"
    end
  end

  def test_hitl_depends_on_contract_but_not_on_assign_or_terminal_adapters
    specs = source_specs
    hitl_direct = specs.fetch("ace-hitl").runtime_dependencies.map(&:name)
    assert_includes hitl_direct, "ace-hitl-contract",
      "ace-hitl must declare the contract leaf as a direct runtime dependency"

    hitl_closure = dependency_closure(specs, "ace-hitl")
    assert_includes hitl_closure, "ace-hitl-contract",
      "ace-hitl's runtime closure must include the contract leaf"
    assert_includes hitl_closure, "ace-runtime",
      "ace-hitl's runtime closure must keep the runtime contract"

    HITL_FORBIDDEN_RUNTIME.each do |forbidden|
      refute_includes hitl_direct, forbidden,
        "ace-hitl must not directly depend on #{forbidden}: Assign owns execution evidence and " \
        "the terminal adapters are consumer transports, not HITL dependencies"
      refute_includes hitl_closure, forbidden,
        "ace-hitl's runtime closure must not include #{forbidden}: the privileged Assign authority " \
        "and terminal adapters are outside the HITL dependency boundary"
    end

    assert_empty specs.fetch("ace-hitl-contract").runtime_dependencies,
      "ace-hitl-contract must stay a dependency-free leaf"
  end

  private

  def source_specs
    Dir.glob(File.join(ROOT, "ace-*/*.gemspec")).to_h do |path|
      spec = load_source_gemspec(path)
      [spec.name, spec]
    end
  end

  def dependency_closure(specs, root)
    seen = Set.new
    visit = lambda do |name, stack|
      refute_includes stack, name, "runtime dependency cycle: #{(stack + [name]).join(" -> ")}"
      return unless specs[name] && seen.add?(name)

      specs[name].runtime_dependencies.each { |dep| visit.call(dep.name, stack + [name]) }
    end
    visit.call(root, [])
    seen
  end
end
