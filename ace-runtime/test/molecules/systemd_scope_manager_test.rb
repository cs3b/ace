# frozen_string_literal: true

require_relative "../test_helper"
require "ace/runtime/molecules/systemd_scope_manager"

class SystemdScopeManagerTest < AceRuntimeTestCase
  Manager = Ace::Runtime::Molecules::SystemdScopeManager
  Unavailable = Ace::Runtime::RuntimeUnavailableError

  class Command
    attr_reader :calls
    attr_accessor :transform, :failure, :typed_response
    def initialize
      @calls = []
    end
    def call(argv, timeout:)
      @calls << [argv, timeout]
      raise failure if failure
      return typed_response if argv.include?("get-property")
      return "" unless argv.include?("show")
      unit = argv.last
      values = {"Id" => unit, "LoadState" => "loaded", "ActiveState" => "active", "SubState" => "running",
        "InvocationID" => "a" * 32, "ControlGroup" => "/ace-worker.slice",
        "MainPID" => unit.end_with?(".service") ? "99" : "0", "Slice" => "ace-worker.slice", "Job" => "",
        "FragmentPath" => "/etc/systemd/system/#{unit}", "DropInPaths" => ""}
      requested = argv.find { |arg| arg.start_with?("--property=") }.delete_prefix("--property=").split(",")
      bytes = values.select { |key, _| requested.include?(key) }.map { |key, value| "#{key}=#{value}\n" }.join
      transform ? transform.call(unit, bytes) : bytes
    end
  end

  def setup
    @command = Command.new
    @manager = Manager.new(slice_unit: "ace-worker.slice", service_unit: "ace-worker.service", command: @command)
  end

  def test_observation_requires_both_exact_loaded_units_and_installed_placement
    units = @manager.inspect_units
    assert_equal "ace-worker.slice", units.fetch("slice").fetch("Id")
    assert_equal "99", units.fetch("service").fetch("MainPID")
    assert_equal 2, @command.calls.size
    slice_properties = @command.calls.first.first.find { |arg| arg.start_with?("--property=") }
    refute_includes slice_properties, "MainPID"
    refute_includes slice_properties, "Slice"
    service_properties = @command.calls.last.first.find { |arg| arg.start_with?("--property=") }
    assert_includes service_properties, "MainPID"
    assert_includes service_properties, "Slice"
    @command.calls.each do |argv, timeout|
      assert_equal 5, timeout
      assert_includes argv, "--system"
      assert_includes argv, "--no-ask-password"
      assert_includes argv, "--all"
      assert_equal "--", argv[-2]
    end
    @command.transform = ->(_unit, bytes) { bytes.sub("LoadState=loaded", "LoadState=not-found") }
    assert_raises(Unavailable) { @manager.inspect_units }
    @command.transform = ->(_unit, bytes) { bytes.sub("Slice=ace-worker.slice", "Slice=system.slice") }
    assert_raises(Unavailable) { @manager.inspect_units }
  end

  def test_only_fixed_start_stop_targets_are_available_without_caller_arguments
    assert @manager.start_slice
    assert @manager.start_service
    assert @manager.stop_service
    assert @manager.stop_slice
    expected = [["start", "ace-worker.slice"], ["start", "ace-worker.service"],
      ["stop", "ace-worker.service"], ["stop", "ace-worker.slice"]]
    assert_equal expected, @command.calls.map { |argv, _| [argv[4], argv.last] }
    assert @command.calls.all? { |_, timeout| timeout == 30 }
    assert_raises(ArgumentError) { @manager.stop_service("unrelated.service") }
  end

  def test_lost_job_outcome_is_not_retried_or_turned_into_success
    @command.failure = Unavailable.new("lost response")
    assert_raises(Unavailable) { @manager.start_slice }
    assert_equal 1, @command.calls.size
    assert_equal "start", @command.calls.first.first[4]
  end

  def test_wrong_duplicate_missing_or_unknown_property_response_refuses
    [->(_unit, bytes) { bytes.sub(/Id=.*\n/, "Id=foreign.service\n") },
     ->(_unit, bytes) { bytes + "MainPID=99\n" },
     ->(_unit, bytes) { bytes.sub(/Job=.*\n/, "") },
     ->(_unit, bytes) { bytes + "Extra=value\n" },
     ->(_unit, _bytes) { "x" * 65_537 }].each do |transform|
      @command.transform = transform
      assert_raises(Unavailable) { @manager.inspect_units }
    end
  end

  def test_nonfixed_or_shared_manager_targets_are_rejected_without_io
    ["system.slice", "user.slice", "machine.slice", "../slot.slice", "slot.slice\nstop", nil].each do |slice|
      assert_raises(ArgumentError) do
        Manager.new(slice_unit: slice, service_unit: "ace-worker.service", command: @command)
      end
    end
    assert_raises(ArgumentError) do
      Manager.new(slice_unit: "ace-worker.slice", service_unit: "worker@.service", command: @command)
    end
    assert_empty @command.calls
  end

  def test_typed_property_reads_preserve_empty_arrays_and_command_argument_boundaries
    command = ["/usr/libexec/ace-ready", ["/usr/libexec/ace-ready", "argument with spaces"], [], 0, 0, 0, 0, 0, 0, 0]
    @command.typed_response = JSON.generate("type" => "a(sasasttttuii)", "data" => []) + "\n" +
      JSON.generate("type" => "a(sasasttttuii)", "data" => [command]) + "\n"
    signatures = {"ExecConditionEx" => "a(sasasttttuii)", "ExecStartPostEx" => "a(sasasttttuii)"}
    result = @manager.typed_properties(unit: "ace-worker.service", interface: "Service", signatures: signatures)
    assert_equal [], result.fetch("ExecConditionEx")
    assert_equal [command], result.fetch("ExecStartPostEx")
    argv = @command.calls.last.first
    assert_equal Manager::BUSCTL, argv.first
    assert_includes argv, "--auto-start=no"
    assert_includes argv, "--allow-interactive-authorization=no"
    assert_includes argv, "/org/freedesktop/systemd1/unit/ace_2dworker_2eservice"
    ["{}\n", "{bad\n", JSON.generate("type" => "s", "data" => "") + "\n", "x" * 65_537].each do |bytes|
      @command.typed_response = bytes
      assert_raises(Unavailable) do
        @manager.typed_properties(unit: "ace-worker.service", interface: "Service", signatures: signatures)
      end
    end
    assert_raises(ArgumentError) do
      @manager.typed_properties(unit: "foreign.service", interface: "Service", signatures: signatures)
    end
  end

  def test_typed_signature_is_not_enough_without_matching_primitive_data
    [["Delegate", "b", "false"], ["RestrictNamespaces", "t", -1], ["Environment", "as", [12]],
     ["BindPaths", "a(ssbt)", [["/a", "/b", "no", 0]]],
     ["ExecStartEx", "a(sasasttttuii)", [["/bin/app", ["/bin/app"], [], -1, 0, 0, 0, 1, 0, 0]]]].each do |key, signature, data|
      @command.typed_response = JSON.generate("type" => signature, "data" => data) + "\n"
      assert_raises(Unavailable, key) do
        @manager.typed_properties(unit: "ace-worker.service", interface: "Service", signatures: {key => signature})
      end
    end
    before = @command.calls.size
    assert_raises(ArgumentError) do
      @manager.typed_properties(unit: "ace-worker.service", interface: "Service", signatures: {"TriggeredBy" => "as"})
    end
    assert_equal before, @command.calls.size
  end

  def test_native_command_refuses_unsupported_platform_before_spawning
    command = Manager::Command
    command.const_set(:RUBY_PLATFORM, "unsupported-fixture")
    spawned = false
    Process.stub(:spawn, ->(*) { spawned = true }) do
      assert_raises(Unavailable) do
        command.new.call([Manager::SYSTEMCTL, "--system", "show"], timeout: 5)
      end
    end
    refute spawned
  ensure
    command.send(:remove_const, :RUBY_PLATFORM) if command&.const_defined?(:RUBY_PLATFORM, false)
  end
end
