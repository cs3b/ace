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
      when "pane.get" then {"pane" => {"workspace_id" => "w1", "tab_id" => "w1:t2", "pane_id" => "w1:p2", "terminal_id" => 3}}
      when "pane.process_info" then {"process_info" => {"pane_id" => "w1:p2", "shell_pid" => replacement ? 102 : 101}}
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
        "host" => "host", "started_at" => "linux:boot:#{pid}"}
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
end
