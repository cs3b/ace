# frozen_string_literal: true
require_relative "../test_helper"
require "ace/herdr/molecules/protected_native_control"

class ProtectedNativeControlTest < Minitest::Test
  class Native < Ace::Herdr::Molecules::ProtectedNativeControl
    attr_reader :calls
    attr_accessor :lost_create, :replacement, :closed_workspace, :wrong_workspace
    def initialize(**options)
      super
      @calls = []
    end
    def request(method, params = {})
      @calls << [method, params]
      case method
      when "ping" then {"version" => "0.9.3", "protocol" => 22, "capabilities" => {"endpoint_protocol_generation" => 1}}
      when "workspace.get"
        raise Ace::Runtime::RuntimeUnavailableError, "workspace missing" if closed_workspace
        {"workspace" => {"workspace_id" => "w1"}}
      when "layout.apply"
        raise Ace::Runtime::RuntimeUnavailableError, "lost response" if lost_create
        {"layout" => {"workspace_id" => wrong_workspace ? "w2" : "w1", "tab_id" => "w1:t2", "root" => {"type" => "pane", "pane_id" => "w1:p2", "command" => params.fetch("root").fetch("command"), "cwd" => "/srv/worker"}}}
      when "pane.get" then {"pane" => {"workspace_id" => "w1", "tab_id" => "w1:t2", "pane_id" => "w1:p2", "terminal_id" => "term_ab"}}
      when "pane.process_info"
        pid = replacement ? 102 : 101
        {"process_info" => {"pane_id" => "w1:p2", "shell_pid" => pid, "guarded_prompt" => true, "guarded_input_drain" => true,
          "guarded_prompt_origin" => {"terminal_id" => "term_ab", "runtime_incarnation" => "12345678-1234-1234-1234-123456789abc",
            "child" => @kernel.capture(pid)}}}
      else raise "Unexpected native operation: #{method}"
      end
    end
  end

  def setup
    map = {"native" => {"workspace_id" => "w1", "server_identity" => {"pid" => 90}, "socket_identity" => [1, 2, 13001]},
      "worker_cwd" => "/srv/worker", "bootstrap" => "/usr/libexec/ace-worker-gate",
      "worker_uid" => 13001, "worker_gid" => 13001, "worker_groups" => [13001]}
    kernel = Object.new
    kernel.define_singleton_method(:capture) do |pid|
      {"pid" => pid, "uid" => 13001, "gid" => 13001, "groups" => [13001], "parent_pid" => 90,
        "host" => "host", "started_at" => "linux:12345678-1234-1234-1234-123456789abc:#{pid}"}
    end
    @native = Native.new(mapping: map, kernel: kernel)
  end

  def test_original_layout_reply_is_the_only_binding_source
    binding = @native.create(mapping_id: "otp", ticket: "ticket")
    assert_equal "w1:p2", binding.fetch("pane")
    assert_equal 101, binding.dig("process_identity", "pid")
    layout = @native.calls.find { |method, _| method == "layout.apply" }.last
    assert_equal ["/usr/libexec/ace-worker-gate", "otp", "ticket"], layout.dig("root", "command")
    assert_equal ["w1:p2", "w1:p2"], @native.calls.filter_map { |method, params| params["pane_id"] if method.start_with?("pane.") }
    refute @native.calls.any? { |method, _| method.include?("list") || method.include?("current") || method.include?("snapshot") }
    refute @native.calls.any? { |method, _| method == "workspace.create" || method == "layout.export" }
    @native.replacement = true
    assert_raises(Ace::Runtime::RuntimeUnavailableError) do
      @native.observe(binding.fetch("native_origin").merge("process_binding" => binding))
    end
  end

  def test_lost_native_creation_reply_never_repeats_creation
    @native.lost_create = true
    2.times do
      assert_raises(Ace::Runtime::RuntimeUnavailableError) { @native.create(mapping_id: "otp", ticket: "ticket") }
    end
    assert_equal 0, @native.calls.count { |method, _| method == "workspace.create" }
    assert_equal 1, @native.calls.count { |method, _| method == "layout.apply" }
  end
  def test_closed_installed_workspace_refuses_before_creation
    @native.closed_workspace = true
    assert_raises(Ace::Runtime::RuntimeUnavailableError) { @native.create(mapping_id: "otp", ticket: "ticket") }
    refute @native.calls.any? { |method, _| method == "layout.apply" }
  end

  def test_original_reply_must_echo_installed_workspace
    @native.wrong_workspace = true
    assert_raises(Ace::Runtime::RuntimeUnavailableError) { @native.create(mapping_id: "otp", ticket: "ticket") }
    refute @native.calls.any? { |method, _| method.start_with?("pane.") }
  end
  class PromptNative < Native
    attr_accessor :response
    def exchange(method, params = {}, **limits)
      @calls << [method, params, limits]
      raise response if response.is_a?(Exception)
      response.call(params.fetch("expected_origin"))
    end
    private :exchange
  end

  def prompt_native
    native = PromptNative.new(mapping: @native.instance_variable_get(:@mapping), kernel: @native.instance_variable_get(:@kernel))
    [native, native.guarded_binding!(native.create(mapping_id: "otp", ticket: "ticket"))]
  end

  def test_malformed_canonical_guard_refuses_without_issuing_or_origin_nil_evidence
    native, binding = prompt_native
    [nil, {}, "bad", binding.fetch("guarded_origin").merge("child" => nil)].each do |guard|
      assert_raises(Ace::Runtime::RuntimeUnavailableError) { native.prompt(binding: binding.merge("guarded_origin" => guard), text: "private prompt") }
    end
    assert_raises(Ace::Runtime::RuntimeUnavailableError) { native.prompt(binding: binding.reject { |key, _| key == "guarded_origin" }, text: "private prompt") }
    refute native.calls.any? { |method, _| method == "agent.prompt" }
  end

  def test_actual_native_guarded_success_shape_and_refusal_are_sanitized
    native, binding = prompt_native
    secret = "private prompt\nwith enter"
    native.response = ->(origin) { {"id" => "test", "result" => {"type" => "agent_prompted", "agent" => {"status" => secret}, "origin" => origin, "submission" => "submitted"}} }
    assert_equal({"outcome" => "submitted", "submission" => "submitted", "origin" => binding.fetch("guarded_origin")}, native.prompt(binding: binding, text: secret))
    call = native.calls.last
    assert_equal "agent.prompt", call[0]
    assert_equal %w[expected_origin target text], call[1].keys.sort
    assert_equal secret, call[1].fetch("text")
    assert_equal({write_limit: 131_072, read_limit: 16_384}, call[2])
    native.response = ->(_) { {"id" => "test", "error" => {"code" => "guard_mismatch", "phase" => "not_issued", "message" => secret}} }
    result = native.prompt(binding: binding, text: secret)
    assert_equal "not_issued", result.fetch("outcome")
    assert_equal "guard_mismatch", result.fetch("code")
    refute_includes JSON.generate(result), secret
  end

  def test_malformed_and_lost_native_ack_remain_bound_uncertain_without_second_send
    native, binding = prompt_native
    [->(origin) { {"id" => "test", "result" => {"type" => "agent_prompted", "agent" => {}, "origin" => origin.merge("terminal_id" => "term_cd"), "submission" => "submitted"}} },
      ->(_) { {"id" => "test", "error" => {"code" => "guard_mismatch", "phase" => "issued_or_unknown", "message" => "secret"}} },
      ->(_) { {"id" => "test", "error" => {"code" => "unknown", "phase" => "not_issued", "message" => "secret"}} },
      Ace::Runtime::RuntimeUnavailableError.new("secret lost reply")].each do |response|
      native.response = response
      before = native.calls.count { |method, _| method == "agent.prompt" }
      assert_equal({"outcome" => "uncertain", "origin" => binding.fetch("guarded_origin")}, native.prompt(binding: binding, text: "secret"))
      assert_equal before + 1, native.calls.count { |method, _| method == "agent.prompt" }
    end
  end

  def test_actual_drain_wire_shape_preserves_original_guard_without_child_reobservation
    native, binding = prompt_native
    native.response = ->(origin) { {"id" => "test", "result" => {"type" => "terminal_input_drained", "origin" => origin, "input_state" => "inhibited", "pending_input" => 0}} }
    native.replacement = true
    before = native.calls.count { |method, _| method == "pane.process_info" }
    result = native.inhibit_input(binding: binding)
    assert_equal({"outcome" => "inhibited", "origin" => binding.fetch("guarded_origin"), "input_state" => "inhibited", "pending_input" => 0}, result)
    assert_equal before, native.calls.count { |method, _| method == "pane.process_info" }
    assert_equal "terminal.inhibit_input", native.calls.last[0]
    assert_equal %w[expected_origin target], native.calls.last[1].keys.sort
    assert_equal({write_limit: 16_384, read_limit: 16_384}, native.calls.last[2])
  end

  def test_drain_wrong_origin_float_pending_extra_field_and_lost_ack_are_unconfirmed
    native, binding = prompt_native
    valid = {"type" => "terminal_input_drained", "origin" => binding.fetch("guarded_origin"), "input_state" => "inhibited", "pending_input" => 0}
    [valid.merge("pending_input" => 0.0), valid.merge("origin" => nil), valid.merge("secret" => "private"),
      valid.merge("input_state" => "accepting")].each do |result|
      native.response = ->(_) { {"id" => "test", "result" => result} }
      assert_equal({"outcome" => "unconfirmed", "origin" => binding.fetch("guarded_origin")}, native.inhibit_input(binding: binding))
    end
    native.response = Ace::Runtime::RuntimeUnavailableError.new("secret lost reply")
    assert_equal "unconfirmed", native.inhibit_input(binding: binding).fetch("outcome")
    native.response = ->(_) { {"id" => "test", "error" => {"code" => "guard_mismatch", "phase" => "unconfirmed"}} }
    assert_equal({"outcome" => "unconfirmed", "origin" => binding.fetch("guarded_origin"), "code" => "guard_mismatch", "phase" => "unconfirmed"}, native.inhibit_input(binding: binding))
    assert_raises(Ace::Runtime::RuntimeUnavailableError) { native.inhibit_input(binding: nil) }
  end

end
