# frozen_string_literal: true

require_relative "../test_helper"
require "ace/runtime/molecules/systemd_scope_manager"

class SystemdScopeManagerTest < AceRuntimeTestCase
  Manager = Ace::Runtime::Molecules::SystemdScopeManager
  Unavailable = Ace::Runtime::RuntimeUnavailableError

  class Command
    attr_reader :calls
    attr_accessor :transform, :failure
    def initialize
      @calls = []
    end
    def call(argv, timeout:)
      @calls << [argv, timeout]
      raise failure if failure
      return "" unless argv.include?("show")
      unit = argv.last
      values = {"Id" => unit, "LoadState" => "loaded", "ActiveState" => "active", "SubState" => "running",
        "InvocationID" => "a" * 32, "ControlGroup" => "/ace-worker.slice",
        "MainPID" => unit.end_with?(".service") ? "99" : "0", "Slice" => "ace-worker.slice", "Job" => "",
        "FragmentPath" => "/etc/systemd/system/#{unit}", "DropInPaths" => ""}
      bytes = values.map { |key, value| "#{key}=#{value}\n" }.join
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
    @command.calls.each do |argv, timeout|
      assert_equal 5, timeout
      assert_includes argv, "--system"
      assert_includes argv, "--no-ask-password"
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
