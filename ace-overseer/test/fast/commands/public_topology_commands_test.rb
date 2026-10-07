# frozen_string_literal: true
require_relative "../../test_helper"

class PublicTopologyCommandsTest < AceOverseerTestCase
  def topology(identity: ["verified"])
    config = YAML.safe_load_file(File.expand_path("../../../../ace-lab/test/fixtures/lab/sanitized_topology.yml", __dir__))
    loader = Ace::Lab::Molecules::TopologyLoader.new(config)
    authorizer = Ace::Lab::Molecules::CallerAuthorizer.new(principals: {"verified" => {"projects" => ["atlas"]}}, identity: identity)
    Ace::Lab::Organisms::TopologyService.new(loader: loader, authorizer: authorizer)
  end

  def test_actual_topology_filters_projects_and_agents_for_injected_verified_identity
    output, = capture_io { Ace::Overseer::CLI::Commands::Projects.new(topology: topology).call }
    assert_equal ["atlas"], JSON.parse(output).fetch("data").fetch("projects").map { |entry| entry.fetch("id") }
    output, = capture_io { Ace::Overseer::CLI::Commands::Agents.new(topology: topology).call(project: "atlas") }
    assert_equal %w[atlas-planner atlas-coder], JSON.parse(output).fetch("data").fetch("agents").map { |entry| entry.fetch("id") }
    refute_includes output, "secret"
  end

  def test_actual_unauthorized_topology_is_classified_and_nonzero
    output, = capture_io do
      error = assert_raises(Ace::Support::Cli::Error) { Ace::Overseer::CLI::Commands::Projects.new(topology: topology(identity: ["other"])).call }
      assert_match(/unauthorized/, error.message)
    end
    assert_equal "unauthorized", JSON.parse(output).dig("error", "code")
  end

  def test_removed_prepare_and_runtime_prune_refuse_without_effects
    output, = capture_io do
      assert_raises(Ace::Support::Cli::Error) { Ace::Support::Cli::Runner.new(Ace::Overseer::CLI).call(args: ["prepare"]) }
    end
    refute Ace::Overseer::Molecules.const_defined?(:LabClient)
    refute Ace::Overseer::Molecules.const_defined?(:LabPruneSafetyChecker)
    orchestrator = Object.new
    orchestrator.define_singleton_method(:call) { |**| raise "legacy prune reached cleanup" }
    command = Ace::Overseer::CLI::Commands::Prune.new(orchestrator: orchestrator)
    assert_raises(Ace::Support::Cli::Error) { command.call(runtime: "lab", dry_run: true) }
  end
end
