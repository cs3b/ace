# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/overseer/organisms/launch_recovery"

class LaunchRecoveryTest < AceOverseerTestCase
  def setup
    super
    @request = {"project_id" => "project", "mapping_id" => "mapping", "assignment_id" => "assignment", "task_id" => "task",
      "scope" => "010", "base_head" => "a" * 40, "mutation_id" => "invocation", "definition_sha256" => "d" * 64,
      "definition_bytes" => JSON.generate("prepared_work" => {"selection_sha256" => "s" * 64}),
      "prepared_bundle" => {"filename" => "invocation.prepared.bundle", "bytes" => 123, "sha256" => "b" * 64}}
    @row = {"assignment_id" => "assignment", "task_id" => "task", "scope" => "010", "base_head" => "a" * 40,
      "reservation_mutation_id" => "invocation-reserve", "definition_digest" => "d" * 64, "selection_sha256" => "s" * 64,
      "prepared_bundle_bytes" => 123, "prepared_bundle_sha256" => "b" * 64,
      "prepared_bundle_ref" => "execution/prepared/assignment-#{'b' * 64}.bundle", "attempt_id" => "original"}
    @requests = []
    @owner = Object.new
    request = @request
    @owner.define_singleton_method(:load) { |_path| request }
    @owner.define_singleton_method(:bundle_availability) { |_request| "unavailable" }
    @status = Object.new
    requests = @requests
    test = self
    @status.define_singleton_method(:collect) do |**selectors|
      requests << selectors
      {"agents" => [{"agent_id" => "mapping", "status" => "ok", "inventory" => {"journal_commit" => "c" * 40, "items" => test.instance_variable_get(:@rows)}}]}
    end
    @rows = [@row]
    owner = @owner
    @recovery = Ace::Overseer::Organisms::LaunchRecovery.new(status: @status, request_factory: ->(_root) { owner })
  end

  def test_exact_original_reservation_survives_missing_local_bundle_and_newer_attempt
    @rows << @row.merge("reservation_mutation_id" => "other-reserve", "attempt_id" => "newer")
    result = @recovery.call(path: "/private/invocation.json")
    assert_equal "original_reservation", result.fetch("attribution")
    assert_equal "original", result.fetch("item").fetch("attempt_id")
    assert_equal "unavailable", result.fetch("local_bundle")
    assert_equal [{project: "project", agent: "mapping"}], @requests
  end

  def test_unattributed_is_not_a_zero_effect_or_replacement_claim
    @rows = [@row.merge("reservation_mutation_id" => nil, "attempt_id" => nil)]
    value = @recovery.call(path: "/private/invocation.json")
    assert_equal "unattributed", value.fetch("attribution")
    assert_nil value.fetch("item")
  end

  def test_mismatch_ambiguity_and_invalid_local_document_refuse
    %w[base_head scope definition_digest selection_sha256 prepared_bundle_sha256].each do |key|
      @rows = [@row.merge(key => "different")]
      assert_raises(Ace::Overseer::Error) { @recovery.call(path: "/private/invocation.json") }
    end
    @rows = [@row, @row.dup]
    assert_raises(Ace::Overseer::Error) { @recovery.call(path: "/private/invocation.json") }
    @owner.define_singleton_method(:load) { |_path| raise Ace::Overseer::Error, "invalid local input" }
    @requests.clear
    assert_raises(Ace::Overseer::Error) { @recovery.call(path: "/private/invocation.json") }
    assert_empty @requests
  end
end
