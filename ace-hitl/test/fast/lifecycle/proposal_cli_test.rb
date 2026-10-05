# frozen_string_literal: true
require "test_helper"
require "ace/hitl/cli"

class ProposalCliTest < AceHitlTestCase
  def with_boundary
    boundary = Object.new
    calls = []
    boundary.define_singleton_method(:proposal_create) { |**args| calls << args; {"proposal_id" => "p1", "state" => "awaiting-delivery"} }
    boundary.define_singleton_method(:proposal_show) { |id, **| calls << id; {"proposal_id" => id, "history" => []} }
    boundary.define_singleton_method(:proposal_revise) { |id, **args| calls << [id, args]; {"proposal_id" => id, "revision" => 2} }
    klass = Ace::Hitl::Providers::Lab
    original = klass.method(:boundary_client)
    klass.define_singleton_method(:boundary_client) { |**| boundary }
    yield calls
  ensure
    klass.define_singleton_method(:boundary_client, original)
  end

  def test_public_create_show_revise_are_scoped_boundary_calls
    Dir.mktmpdir do |dir|
      file = File.join(dir, "proposal.json")
      File.write(file, '{"operation":"deploy"}')
      with_boundary do |calls|
        result = run_cli(["proposal", "create", "--assignment", "a1", "--attempt", "t1", "--project", "ace", "--file", file])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_equal "awaiting-delivery", JSON.parse(result[:stdout])["state"]
        assert_equal "a1", calls.last[:assignment]
        result = run_cli(["proposal", "show", "p1", "--format", "json"])
        assert_equal 0, result[:exit_code]
        assert_equal "p1", JSON.parse(result[:stdout])["proposal_id"]
        result = run_cli(["proposal", "revise", "p1", "--file", file])
        assert_equal 0, result[:exit_code]
        assert_equal 2, JSON.parse(result[:stdout])["revision"]
      end
    end
  end

  def test_production_clock_override_and_missing_binding_are_rejected
    result = run_cli(["proposal", "resolve-due", "--now", "2026-10-06T00:00:00Z"])
    refute_equal 0, result[:exit_code]
    assert_includes result[:stderr], "trusted UTC"
    result = run_cli(["proposal", "create", "--file", "missing"])
    refute_equal 0, result[:exit_code]
    assert_includes result[:stderr], "--assignment required"
  end
end
