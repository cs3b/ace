# frozen_string_literal: true
require_relative "../test_helper"
require "ace/overseer/organisms/protected_steering"

class ProtectedSteeringTest < AceOverseerTestCase
  def setup
    super
    @calls = []
    @rows = [{"assignment_id" => "A", "attempt_id" => "old", "generation" => 90, "original_binding_digest" => "a" * 64},
      {"assignment_id" => "A", "attempt_id" => "new", "generation" => 99, "original_binding_digest" => "b" * 64}]
    selection = Object.new
    selection.define_singleton_method(:call) { |**| [Object.new, ["builder"], ["builder"]] }
    owner = self
    status = Object.new
    status.define_singleton_method(:collect) do |**|
      {"project_id" => "project", "agents" => [{"agent_id" => "builder", "status" => "ok", "inventory" => {"items" => owner.instance_variable_get(:@rows)}}]}
    end
    @client = Object.new
    @client.define_singleton_method(:call) do |operation, params, **options|
      owner.instance_variable_get(:@calls) << [operation, params, options]
      Struct.new(:data).new({"outcome" => "uncertain"})
    end
    @steering = Ace::Overseer::Organisms::ProtectedSteering.new(selection: selection, status: status,
      client_factory: ->(*) { @client })
    @target = {project: "project", agent: "builder", assignment: "A", attempt: "old", mutation: "original"}
  end

  def test_exact_old_attempt_and_original_generation_are_forwarded_without_refresh
    result = @steering.prompt(**@target, expected_generation: 12, text: "exact\n")
    assert_equal "uncertain", result.fetch("outcome")
    operation, params, options = @calls.fetch(0)
    assert_equal "prompt_attempt", operation
    assert_equal({"assignment_id" => "A", "attempt_id" => "old", "expected_generation" => 12}, params)
    assert_equal "original", options.fetch(:mutation_id)
    assert_equal ["exact\n"], options.fetch(:upload_parts)
    assert_equal :prompt_text, options.fetch(:purpose)
    assert_equal 1, @calls.size
  end

  def test_prompt_status_has_no_mutation_or_transfer
    @steering.prompt(**@target, status: true)
    assert_equal ["prompt_status", {"assignment_id" => "A", "attempt_id" => "old", "mutation_id" => "original"},
      {mutation_id: nil, timeout: 30}], @calls.fetch(0)
    assert_raises(Ace::Overseer::Error) { @steering.prompt(**@target, status: true, text: "forbidden") }
    assert_raises(Ace::Overseer::Error) { @steering.prompt(**@target, status: true, expected_generation: 12) }
    assert_equal 1, @calls.size
  end

  def test_missing_ambiguous_or_unbound_exact_attempt_refuses_before_dispatch
    original = @rows.first.dup
    [[], [original, original], [original.merge("original_binding_digest" => nil)]].each do |rows|
      @rows = rows
      assert_raises(Ace::Overseer::Error) { @steering.stop(**@target, expected_generation: 12) }
    end
    assert_empty @calls
  end

  def test_bad_generation_and_prompt_bytes_refuse_before_dispatch
    [0, 1.0, "1"].each do |value|
      assert_raises(Ace::Overseer::Error) { @steering.stop(**@target, expected_generation: value) }
    end
    [" \n", "x" * 16_385, "\xff".b].each do |text|
      assert_raises(Ace::Overseer::Error) { @steering.prompt(**@target, expected_generation: 12, text: text) }
    end
    assert_empty @calls
  end
  def test_public_status_rejects_input_before_touching_inherited_stream
    input = Object.new
    input.define_singleton_method(:read) { |*| raise "inherited input was touched" }
    command = Ace::Overseer::CLI::Commands::Prompt.new(steering: @steering, input: input)
    output, = capture_io { command.call(**@target, status: true) }
    assert_equal "uncertain", JSON.parse(output).fetch("outcome")
    [{stdin: true}, {file: "/not/read"}, {expected_generation: 1}].each do |extra|
      assert_raises(Ace::Support::Cli::Error) { command.call(**@target, status: true, **extra) }
    end
    assert_equal 1, @calls.size
  end

  def test_public_prompt_requires_explicit_input_and_preserves_exact_bytes
    command = Ace::Overseer::CLI::Commands::Prompt.new(steering: @steering, input: StringIO.new("exact\n"))
    assert_raises(Ace::Support::Cli::Error) { command.call(**@target, expected_generation: 12) }
    assert_raises(Ace::Support::Cli::Error) { command.call(**@target, expected_generation: 12, stdin: true, file: "/not/read") }
    assert_empty @calls
    capture_io { command.call(**@target, expected_generation: 12, stdin: true) }
    assert_equal ["exact\n"], @calls.fetch(0).last.fetch(:upload_parts)
  end

  def test_public_command_selects_fixed_stop_and_original_tuple
    command = Ace::Overseer::CLI::Commands::Stop.new(steering: @steering)
    capture_io { command.call(**@target, expected_generation: 12) }
    assert_equal ["stop_attempt", {"assignment_id" => "A", "attempt_id" => "old", "expected_generation" => 12},
      {mutation_id: "original"}], @calls.fetch(0)
    assert_raises(Ace::Support::Cli::Error) { command.call(**@target, expected_generation: 12, work: "legacy") }
  end

end
