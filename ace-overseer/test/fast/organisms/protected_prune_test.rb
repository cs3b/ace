# frozen_string_literal: true

require "tmpdir"
require "stringio"
require_relative "../../test_helper"

class ProtectedPruneTest < AceOverseerTestCase
  def test_default_command_protected_path_never_constructs_local_orchestrator
    calls = []
    protected = Object.new
    protected.define_singleton_method(:preview) { |**params| calls << params; {"kind" => "preview"} }
    Ace::Overseer::Organisms::PruneOrchestrator.stub(:new, -> { raise "local configuration must not load" }) do
      output = StringIO.new
      command = Ace::Overseer::CLI::Commands::Prune.new(protected_prune: protected, output: output)
      command.call(project: "ace", agent: "old", assignment: "a", attempt: "t", request: "intent.json", dry_run: true)
      assert_equal 1, calls.size
      assert_equal({"kind" => "preview"}, JSON.parse(output.string))
    end
  end

  def test_actual_command_reads_closed_intent_and_uses_installed_maintenance_receiver
    intent = {
      "schema" => "ace.protected-workspace-prune-preview/v1",
      "maintenance" => {"project_id" => "ace", "mapping_id" => "maint", "assignment_id" => "ma", "attempt_id" => "mt"},
      "target" => {"project_id" => "ace", "mapping_id" => "old", "assignment_id" => "a", "attempt_id" => "t",
        "resource" => "workspace:ace:old:a", "descriptor_sha256" => "a" * 64, "binding_event_digest" => "b" * 64,
        "release_event_digest" => "c" * 64, "journal_commit" => "d" * 40},
      "publication" => {"descriptor_sha256" => "e" * 64,
        "installation_ref" => {"path" => "/fixed/installation", "bytes" => 1, "sha256" => "f" * 64}}, "destinations" => []
    }
    deployment = Object.new
    deployment.define_singleton_method(:mapping) { |id| raise unless id == "maint"; {"project_id" => "ace"} }
    deployment.define_singleton_method(:project) { |_| {"service_receivers" => {"cleanup" => {}}} }
    selection = Object.new
    selection.define_singleton_method(:call) { |**_| [deployment] }
    calls = []
    submissions = []
    statuses = []
    client = Object.new
    client.define_singleton_method(:preview_workspace_prune) { |intent:| calls << intent; {"kind" => "preview"} }
    client.define_singleton_method(:submit) { |**params| submissions << params; {"type" => "service_claim_unconfirmed"} }
    authority = Object.new
    authority.define_singleton_method(:call) { |operation, params, **options| statuses << [operation, params, options]; Struct.new(:data).new({"state" => "uncertain"}) }
    owner = Ace::Overseer::Organisms::ProtectedPrune.new(selection: selection,
      document_loader: -> { {"operations" => {"prune-preserved-workspace" => {"project" => "ace", "service_id" => "cleanup"}}} },
      client_factory: ->(mapping, service, actual) { assert_equal ["maint", "cleanup", deployment], [mapping, service, actual]; client },
      authority_factory: ->(mapping, actual) { assert_equal ["maint", deployment], [mapping, actual]; authority })
    Dir.mktmpdir("prune-cli") do |dir|
      path = File.join(dir, "intent.json")
      File.write(path, JSON.generate(intent))
      output = StringIO.new
      command = Ace::Overseer::CLI::Commands::Prune.new(protected_prune: owner, output: output)
      args = {project: "ace", agent: "old", assignment: "a", attempt: "t", request: path, dry_run: true}
      command.call(**args)
      assert_equal({"kind" => "preview"}, JSON.parse(output.string))
      assert_equal 1, calls.size
      process = {"pid" => 1, "uid" => 10, "gid" => 10, "groups" => [10],
        "started_at" => "linux:11111111-1111-4111-8111-111111111111:100", "host" => "host", "parent_pid" => 2}
      context = {"journal_commit" => "1" * 40, "maintenance" => intent.fetch("maintenance"),
        "head" => "2" * 40, "candidate_generation" => 3, "worker_process_binding" => process,
        "caller_process_binding" => process.merge("pid" => 3)}
      preservation = {"head" => "4" * 40, "branch" => nil, "destinations" => [], "manifest_sha256" => "5" * 64}
      digest = Ace::Assign::Atoms::EvidenceDigest
      result = {"schema" => "ace.protected-workspace-prune-preview-result/v1", "kind" => "preview",
        "intent_digest" => digest.digest(intent), "maintenance" => intent.fetch("maintenance"),
        "publication" => intent.fetch("publication"), "maintenance_context" => context,
        "target" => intent.fetch("target").merge("artifact_digest" => digest.digest("target" => intent.fetch("target"), "preservation" => preservation)),
        "preservation" => preservation, "inventory_sha256" => preservation.fetch("manifest_sha256"), "file_count" => 0, "total_bytes" => 0}
      File.write(path, JSON.generate(result))
      apply = args.merge(dry_run: false, yes: true, mutation: "prune-001", authorization: "approval-001", expected_generation: 7)
      assert_raises(Ace::Support::Cli::Error) { command.call(**apply.merge(yes: false)) }
      assert_raises(Ace::Support::Cli::Error) { command.call(**apply.merge(authorization: nil)) }
      assert_raises(Ace::Support::Cli::Error) { command.call(**apply.merge(expected_generation: 7.0)) }
      assert_empty submissions
      result["inventory_sha256"] = "6" * 64
      File.write(path, JSON.generate(result))
      assert_raises(Ace::Support::Cli::Error) { command.call(**apply) }
      assert_empty submissions
      result["inventory_sha256"] = preservation.fetch("manifest_sha256")
      File.write(path, JSON.generate(result))
      command.call(**apply)
      assert_equal 1, submissions.size
      submitted = submissions.first
      assert_equal "prune-001", submitted.fetch(:mutation_id)
      assert_equal [7, 3, "2" * 40, "approval-001"], submitted.fetch(:submission).values_at(
        "expected_generation", "candidate_generation", "head", "authorization")
      assert_equal "prune-001", submitted.fetch(:submission).fetch("request_id")
      input = JSON.parse(submitted.fetch(:input_bytes))
      assert_equal %w[maintenance preservation publication schema target], input.keys.sort
      command.call(status: true, request: path, mutation: "prune-001")
      assert_raises(Ace::Support::Cli::Error) { command.call(status: true, request: path, mutation: "prune-001", agent: "wrong") }
      assert_equal ["service_status", {"assignment_id" => "ma", "attempt_id" => "mt", "head" => "2" * 40,
        "candidate_generation" => 3, "request_id" => "prune-001"}, {mutation_id: nil, timeout: 5}], statuses.first
      assert_equal 1, submissions.size
      result.fetch("maintenance_context")["candidate_generation"] = 3.0
      File.write(path, JSON.generate(result))
      assert_raises(Ace::Support::Cli::Error) { command.call(**apply) }
      assert_equal 1, submissions.size
      result.fetch("maintenance_context")["candidate_generation"] = 3
      result["intent_digest"] = "0" * 64
      File.write(path, JSON.generate(result))
      assert_raises(Ace::Support::Cli::Error) { command.call(**apply) }
      assert_equal 1, submissions.size
      assert calls.first.frozen?
      assert_raises(Ace::Support::Cli::Error) { command.call(**args.merge(agent: "wrong")) }
      File.write(path, JSON.generate(intent).sub('"destinations":[]', '"destinations":[],"destinations":[]'))
      assert_raises(Ace::Support::Cli::Error) { command.call(**args) }
      assert_equal 1, calls.size
      File.write(path, "x" * 65_537)
      assert_raises(Ace::Support::Cli::Error) { command.call(**args) }
      assert_equal 1, calls.size
    end
  end
end
