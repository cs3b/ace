# frozen_string_literal: true

require_relative "../test_helper"
require "ace/lab/atoms/protected_workspace_prune_input"
require "ace/lab/molecules/protected_service_policy"
require "ace/lab/organisms/protected_service_receiver"

class ProtectedWorkspacePruneInputTest < Minitest::Test
  INPUT = Ace::Lab::Atoms::ProtectedWorkspacePruneInput

  def request
    association = {"project_id" => "project", "mapping_id" => "builder", "assignment_id" => "assignment", "attempt_id" => "attempt"}
    {"schema" => "ace.protected-workspace-prune/v1", "maintenance" => association.merge("project_id" => "maintenance"),
     "target" => association.merge("resource" => "workspace:project:builder:assignment", "artifact_digest" => "a" * 64,
       "descriptor_sha256" => "b" * 64, "binding_event_digest" => "c" * 64, "release_event_digest" => "d" * 64,
       "journal_commit" => "e" * 40),
     "publication" => {"descriptor_sha256" => "f" * 64,
       "installation_ref" => {"path" => "/etc/lab/installation.json", "bytes" => 123, "sha256" => "0" * 64}},
     "preservation" => {"head" => "1" * 40, "branch" => "refs/heads/topic", "manifest_sha256" => "2" * 64,
       "destinations" => [{"repository_id" => "main", "ref" => "refs/heads/retained", "head" => "1" * 40}]}}
  end

  def parse(value) = INPUT.parse(JSON.generate(value))

  def test_exact_input_is_owned_and_recursively_immutable
    bytes = JSON.generate(request)
    result = INPUT.parse(bytes)
    bytes.replace("changed")
    assert_equal request, result
    assert result.frozen?
    assert result.fetch("maintenance").frozen?
    assert result.dig("preservation", "destinations", 0, "ref").frozen?
    assert_raises(FrozenError) { result.fetch("target")["resource"] = "other" }
  end

  def test_closed_nested_fields_and_types
    mutations = [
      ->(v) { v["command"] = "remove" },
      ->(v) { v["target"]["path"] = "/tmp/victim" },
      ->(v) { v["maintenance"]["attempt_id"] = 1.0 },
      ->(v) { v["publication"]["installation_ref"]["bytes"] = 1.0 },
      ->(v) { v["target"]["journal_commit"] = "e" * 41 },
      ->(v) { v["target"]["resource"] = "workspace:other:builder:assignment" },
      ->(v) { v["preservation"]["branch"] = "refs/tags/topic" },
      ->(v) { v["preservation"]["destinations"] = {} }
    ]
    mutations.each do |change|
      value = request
      change.call(value)
      assert_raises(ArgumentError) { parse(value) }
    end
  end

  def test_reference_and_git_ref_cannot_smuggle_paths_or_invalid_names
    %w[relative /etc//lab /etc/../lab /etc/./lab /etc/lab/].each do |path|
      value = request
      value["publication"]["installation_ref"]["path"] = path
      assert_raises(ArgumentError) { parse(value) }
    end
    ["HEAD", "refs/heads/../x", "refs/heads/x.lock", "refs/heads/x@{1}", "refs/heads/a b", "refs/heads/x/"].each do |ref|
      value = request
      value["preservation"]["destinations"][0]["ref"] = ref
      assert_raises(ArgumentError) { parse(value) }
    end
  end

  def test_duplicate_encoded_keys_and_invalid_wire_text_refuse
    json = JSON.generate(request)
    duplicate = json.sub('"schema":', '"sch\u0065ma":"duplicate","schema":')
    [duplicate, json + "{}", "\xff".b, "{\"x\":NaN}", "/*comment*/" + json,
     "[" * 17 + "0" + "]" * 17].each do |bytes|
      assert_raises(ArgumentError) { INPUT.parse(bytes) }
    end
  end

  def test_exact_byte_limit_and_first_excess
    bytes = JSON.generate(request)
    exact = bytes + " " * (INPUT::MAX_BYTES - bytes.bytesize)
    assert_equal request, INPUT.parse(exact)
    assert_raises(ArgumentError) { INPUT.parse(exact + " ") }
    [0, 65_537, true].each do |count|
      value = request
      value["publication"]["installation_ref"]["bytes"] = count
      assert_raises(ArgumentError) { parse(value) }
    end
  end

  def test_destination_order_duplicates_and_cardinality
    value = request
    row = value["preservation"]["destinations"].first
    rows = 64.times.map { |index| row.merge("repository_id" => "repo-%02d" % index) }
    value["preservation"]["destinations"] = rows
    assert_equal 64, parse(value).dig("preservation", "destinations").length
    [rows.reverse, rows + [rows.last], [rows.first, rows.first]].each do |invalid|
      value["preservation"]["destinations"] = invalid
      assert_raises(ArgumentError) { parse(value) }
    end
    value["preservation"]["branch"] = nil
    value["preservation"]["destinations"] = []
    assert_nil parse(value).dig("preservation", "branch")
  end

  def test_named_operation_checks_schema_before_policy_or_effect_admission
    policy = Ace::Lab::Molecules::ProtectedServicePolicy.new(
      proposal_resolver: ->(*) { flunk "must not reach proposal" },
      document_loader: -> { flunk "must not reach authorization" })
    value = request
    value["target"]["path"] = "/tmp/not-a-selection"
    binding = {"operation" => "prune-preserved-workspace",
      "input_digest" => Ace::Lab::Atoms::ServiceInput.digest(value),
      "target" => Ace::Lab::Atoms::ServiceInput.target(value)}
    assert_raises(ArgumentError) { policy.prepare!(binding, input_bytes: JSON.generate(value)) }
    valid = request
    admitted = policy.input_binding(JSON.generate(valid), operation: "prune-preserved-workspace",
      expected_digest: Ace::Lab::Atoms::ServiceInput.digest(valid), expected_target: Ace::Lab::Atoms::ServiceInput.target(valid))
    assert_equal valid, admitted.fetch(:input)
    assert admitted.frozen?
  end

  def test_actual_recovery_status_rejects_duplicate_input_matching_canonical_digest
    input = request
    params = {"assignment_id" => "maintenance-assignment", "attempt_id" => "maintenance-attempt",
      "request_id" => "cleanup", "head" => "a" * 40, "candidate_generation" => 1}
    record = Ace::Assign::Molecules::EvidenceJournal::TERMINAL_BINDING_FIELDS.to_h { |key| [key, "fixture"] }
    record.merge!(params.slice("assignment_id", "attempt_id", "request_id"),
      "project_id" => "maintenance", "executor_uid" => 13005, "transport" => "unix",
      "candidate_head" => params.fetch("head"), "operation" => "prune-preserved-workspace",
      "input_digest" => Ace::Lab::Atoms::ServiceInput.digest(input), "target" => Ace::Lab::Atoms::ServiceInput.target(input))
    execution = {"mapping_id" => "maintenance", "candidate_generation" => 1, "claim_binding" => "b" * 64,
      "dispatch_phase" => "dispatch_started", "head" => params.fetch("head")}
    data = {"state" => "uncertain", "request_id" => "cleanup", "service_id" => "executor",
      "settlement_context" => {"version" => 1, "request" => record, "execution" => execution, "challenge" => nil}}
    client = Object.new
    client.define_singleton_method(:call) do |operation, selected|
      raise "unexpected authority operation" unless operation == "service_status" && selected == params
      Ace::Assign::Authority::Client::Reply.new(data: data, replayed: false)
    end
    receiver = Ace::Lab::Organisms::ProtectedServiceReceiver.allocate
    {client: client, mapping_id: "maintenance", service_id: "executor", map: {"project_id" => "maintenance"},
     receiver: {"executor_uid" => 13005}, inputs: Ace::Lab::Molecules::ProtectedServicePolicy.new(proposal_resolver: ->(*) { flunk })}.each do |key, value|
      receiver.instance_variable_set("@#{key}", value)
    end
    bytes = JSON.generate(input)
    assert_equal input, receiver.send(:recovery_status!, params, bytes).last.fetch(:input)
    duplicate = bytes.sub('"schema":', '"sch\u0065ma":"duplicate","schema":')
    assert_raises(ArgumentError) { receiver.send(:recovery_status!, params, duplicate) }
  end
end
