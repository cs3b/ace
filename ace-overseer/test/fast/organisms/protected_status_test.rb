# frozen_string_literal: true

require_relative "../../test_helper"

class ProtectedStatusTest < AceOverseerTestCase
  def row(id, attempt = nil)
    {"assignment_id" => id, "task_id" => "09j", "definition_digest" => "d" * 64,
      "definition_generation" => 1, "attempt_id" => attempt, "scope" => attempt ? "010" : nil,
      "prepared_bundle_ref" => "execution/prepared/#{id}-#{'e' * 64}.bundle", "prepared_bundle_bytes" => 123,
      "prepared_bundle_sha256" => "e" * 64, "selection_sha256" => "f" * 64,
      "reservation_mutation_id" => attempt ? "invocation-reserve" : nil, "base_head" => attempt ? "a" * 40 : nil,
      "reservation_generation" => attempt ? 1 : nil, "generation" => attempt ? 3 : nil,
      "canonical_state" => attempt ? "running" : nil, "original_binding_digest" => attempt ? "b" * 64 : nil,
      "terminal_event_id" => nil, "reservation_release_event_id" => nil}
  end

  def collector(visible: %w[one two], &pages)
    topology = Object.new
    topology.define_singleton_method(:agents) do |project:|
      Ace::Lab::Models::QueryResult.ok("agents" => visible.map { |id| {"id" => id, "project" => project} })
    end
    deployment = Object.new
    deployment.define_singleton_method(:data) { {"launch_mappings" => %w[one two].to_h { |id| [id, {"project_id" => "project"}] }} }
    factory = lambda do |id, _deployment|
      client = Object.new
      client.define_singleton_method(:call) do |operation, params, **|
        raise "unexpected operation" unless operation == "assignment_inventory"
        Ace::Assign::Authority::Client::Reply.new(data: pages.call(id, params), replayed: false)
      end
      client
    end
    Ace::Overseer::Organisms::ProtectedStatus.new(topology: topology, deployment_loader: -> { deployment }, client_factory: factory)
  end

  def page(id, rows, following = nil, commit = "a" * 40)
    {"project_id" => "project", "mapping_id" => id, "journal_commit" => commit, "items" => rows, "next_after" => following}
  end

  def test_pagination_pins_revision_and_partial_visibility_is_not_capacity
    first, second = row("first"), row("second", "attempt")
    requests = []
    status = collector(visible: ["one"]) do |id, params|
      requests << params
      params.fetch("after") ? page(id, [second]) : page(id, [first], first.slice("assignment_id", "attempt_id"))
    end
    value = status.collect(project: "project")
    assert_equal 2, value.fetch("provisioned_capacity")
    assert_equal 1, value.fetch("visible_capacity")
    assert_equal "partial", value.fetch("visibility")
    assert_equal [first, second], value.fetch("agents").first.fetch("inventory").fetch("items")
    assert_nil requests.first.fetch("journal_commit")
    assert_equal "a" * 40, requests.last.fetch("journal_commit")
    assert_equal first.slice("assignment_id", "attempt_id"), requests.last.fetch("after")
  end

  def test_failed_continuation_discards_partial_mapping_but_keeps_other_mapping
    first = row("first")
    status = collector do |id, params|
      if id == "one"
        params.fetch("after") ? page(id, [], nil, "c" * 40) : page(id, [first], first.slice("assignment_id", "attempt_id"))
      else
        page(id, [row("other")])
      end
    end
    value = status.collect(project: "project")
    assert_equal "unavailable", value.fetch("agents").first.fetch("status")
    assert_nil value.fetch("agents").first.fetch("inventory")
    assert_equal "ok", value.fetch("agents").last.fetch("status")
    assert_equal "other", value.fetch("agents").last.fetch("inventory").fetch("items").first.fetch("assignment_id")
  end

  def test_malformed_generation_and_false_release_never_become_canonical_success
    [row("first", "attempt").merge("generation" => 3.0),
      row("first", "attempt").merge("reservation_release_event_id" => "f" * 64),
      row("first").merge("prepared_bundle_bytes" => 64 * 1024 * 1024 + 1),
      row("first").merge("prepared_bundle_ref" => "execution/prepared/other-#{'e' * 64}.bundle"),
      row("first").merge("selection_sha256" => "invalid")].each do |malformed|
      status = collector(visible: ["one"]) { |id, _params| page(id, [malformed]) }
      value = status.collect(project: "project")
      assert_equal "unavailable", value.fetch("agents").first.fetch("status")
      assert_nil value.fetch("agents").first.fetch("inventory")
    end
  end

  def test_visibility_must_match_literal_protected_mapping
    status = collector(visible: ["unprovisioned"]) { raise "must not query authority" }
    assert_raises(Ace::Overseer::Error) { status.collect(project: "project") }
    status = collector(visible: ["one"]) { raise "must not query authority" }
    assert_raises(Ace::Overseer::Error) { status.collect(project: "project", agent: "two") }
  end
end
