# frozen_string_literal: true

require_relative "../test_helper"
require "ace/runtime/molecules/systemd_scope_manager"

class SystemdScopeManagerTest < AceRuntimeTestCase
  Manager = Ace::Runtime::Molecules::SystemdScopeManager
  Unavailable = Ace::Runtime::RuntimeUnavailableError

  class Command
    attr_reader :calls
    attr_accessor :transform, :failure, :typed_response, :method_response
    attr_reader :pidfd
    def initialize
      @calls = []
    end
    def call(argv, timeout:, pidfd: nil)
      @calls << [argv, timeout]
      @pidfd = pidfd
      return method_response if argv.include?("GetUnitByPIDFD")
      raise failure if failure
      return typed_response.respond_to?(:call) ? typed_response.call(argv) : typed_response if argv.include?("get-property")
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
    assert_equal [30, 45, 30, 30], @command.calls.map(&:last)
    assert_raises(ArgumentError) { @manager.stop_service("unrelated.service") }
  end

  def test_activation_has_typed_control_pid_and_pending_job_without_slice_service_fields
    @command.typed_response = lambda do |argv|
      unit = argv[8].end_with?("_2eservice") ? "ace-worker.service" : "ace-worker.slice"
      interface = argv[9]
      signatures = interface.end_with?(".Service") ? Manager::ACTIVATION_SERVICE_SIGNATURES : Manager::ACTIVATION_UNIT_SIGNATURES
      values = {"Id" => unit, "LoadState" => "loaded", "ActiveState" => "activating", "SubState" => "start-post",
        "Job" => [17, "/org/freedesktop/systemd1/job/17"], "InvocationID" => [170] * 16,
        "ControlGroup" => "/ace-worker.slice/ace-worker.service", "MainPID" => 99, "ControlPID" => 100, "Slice" => "ace-worker.slice"}
      signatures.map { |key, signature| JSON.generate("type" => signature, "data" => values.fetch(key)) }.join("\n") + "\n"
    end
    observed = @manager.inspect_activation
    assert_equal "a" * 32, observed.fetch("service").fetch("InvocationID")
    assert_equal 100, observed.fetch("service").fetch("ControlPID")
    assert_equal 99, observed.fetch("service").fetch("MainPID")
    assert_equal [17, "/org/freedesktop/systemd1/job/17"], observed.fetch("service").fetch("Job")
    refute observed.fetch("slice").key?("ControlPID")
    calls = @command.calls.select { |argv, _| argv.include?("get-property") }
    assert_equal 3, calls.size
    refute_includes calls.first.first, "ControlPID"
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

  def test_effective_manager_environment_has_fixed_typed_owner_and_closed_bounds
    @command.typed_response = JSON.generate("type" => "as", "data" => ["PATH=/usr/bin", "LC_ALL="])
    assert_equal ["PATH=/usr/bin", "LC_ALL="], @manager.manager_environment
    argv, timeout = @command.calls.last
    assert_equal ["/org/freedesktop/systemd1", "org.freedesktop.systemd1.Manager", "Environment"], argv.last(3)
    assert_equal 5, timeout
    assert_includes argv, "--allow-interactive-authorization=no"
    [JSON.generate("type" => "s", "data" => "PATH=/usr/bin"), JSON.generate("type" => "as", "data" => ["PATH=a", "PATH=b"]),
      JSON.generate("type" => "as", "data" => ["PATH"]), JSON.generate("type" => "as", "data" => ["PATH=a\0b"]),
      JSON.generate("type" => "as", "data" => Array.new(257) { |index| "KEY_#{index}=value" }),
      '{"type":"as","data":[]}' + " " * 65_536, '{"type":"as","type":"as","data":[]}', "{"].each do |bytes|
      @command.typed_response = bytes
      assert_raises(Unavailable) { @manager.manager_environment }
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
  def test_actual_typed_invocation_refuses_nonbyte_shape_and_duplicate_json
    [[1] * 15, [1] * 17, [1.0] * 16, [-1] * 16, [256] * 16, "a" * 32].each do |value|
      @command.typed_response = JSON.generate("type" => "ay", "data" => value) + "\n"
      assert_raises(Unavailable) do
        @manager.typed_properties(unit: "ace-worker.service", interface: "Unit", signatures: {"InvocationID" => "ay"})
      end
    end
    @command.typed_response = '{"type":"ay","type":"ay","data":' + JSON.generate([1] * 16) + '}'
    assert_raises(Unavailable) do
      @manager.typed_properties(unit: "ace-worker.service", interface: "Unit", signatures: {"InvocationID" => "ay"})
    end
  end

  def test_pidfd_method_requires_exact_fixed_unit_and_original_held_descriptor
    require "tempfile"
    Tempfile.create("manager-held-fd") do |held|
      data = ["/org/freedesktop/systemd1/unit/ace_2dworker_2eservice", "ace-worker.service", [170] * 16]
      @command.method_response = JSON.generate("type" => "osay", "data" => data)
      assert_equal({"unit" => "ace-worker.service", "invocation_id" => "a" * 32}, @manager.unit_for_pidfd(handle: held))
      assert_same held, @command.pidfd
      assert_equal [Manager::PIDFD_ARGV, 5], @command.calls.last
      command = Manager::Command.new
      assert_equal({3 => held}, command.send(:inherited_descriptor_options, Manager::PIDFD_ARGV, held))
      assert_raises(ArgumentError) { command.send(:inherited_descriptor_options, Manager::PIDFD_ARGV, nil) }
      assert_raises(ArgumentError) { command.send(:inherited_descriptor_options, [Manager::BUSCTL, "other"], held) }
      refute held.closed?
      [["/foreign", data[1], data[2]], [data[0], "foreign.service", data[2]],
       [data[0], data[1], [0] * 16], [data[0], data[1], [1.0] * 16], data + [1]].each do |bad|
        @command.method_response = JSON.generate("type" => "osay", "data" => bad)
        assert_raises(Unavailable) { @manager.unit_for_pidfd(handle: held) }
      end
      @command.method_response = JSON.generate("type" => "osas", "data" => data)
      assert_raises(Unavailable) { @manager.unit_for_pidfd(handle: held) }
      held.close
      assert_raises(ArgumentError) { @manager.unit_for_pidfd(handle: held) }
    end
  end

  def test_native_command_passes_only_actual_held_io_into_fixed_child_fd_three
    require "tempfile"
    reached = Class.new(StandardError)
    command = Manager::Command
    command.const_set(:RUBY_PLATFORM, "linux-controlled-boundary")
    Tempfile.create("held-manager-lifetime") do |held|
      spawn = lambda do |environment, *args, **options|
        assert_equal Manager::PIDFD_ARGV, args
        assert_equal({"PATH" => "/usr/bin:/bin", "LANG" => "C", "LC_ALL" => "C"}, environment)
        assert_same held, options.fetch(3)
        assert_equal true, options.fetch(:close_others)
        assert_equal true, options.fetch(:unsetenv_others)
        assert_equal File::NULL, options.fetch(:in)
        refute held.closed?
        raise reached
      end
      File.stub(:directory?, true) do
        Ace::Runtime::Molecules::ProtectedSocket.stub(:root_path!, true) do
          File.stub(:executable?, true) do
            File.stub(:stat, Struct.new(:mode).new(0o755)) do
              Process.stub(:spawn, spawn) do
                assert_raises(reached) { command.new.call(Manager::PIDFD_ARGV, timeout: 5, pidfd: held) }
              end
            end
          end
        end
      end
      refute held.closed?
    end
  ensure
    command.send(:remove_const, :RUBY_PLATFORM) if command&.const_defined?(:RUBY_PLATFORM, false)
  end

  def test_manager_observation_timeout_cannot_renew_or_exceed_five_seconds
    require "tempfile"
    Tempfile.create("fixed-lifetime-budget") do |held|
      [0, -1, 6, Float::NAN, Float::INFINITY].each do |timeout|
        assert_raises(ArgumentError) { @manager.unit_for_pidfd(handle: held, timeout: timeout) }
        assert_raises(ArgumentError) do
          @manager.typed_properties(unit: "ace-worker.service", interface: "Unit",
            signatures: {"InvocationID" => "ay"}, timeout: timeout)
        end
      end
      assert_empty @command.calls
      @command.method_response = JSON.generate("type" => "osay", "data" =>
        ["/org/freedesktop/systemd1/unit/ace_2dworker_2eservice", "ace-worker.service", [170] * 16])
      @manager.unit_for_pidfd(handle: held, timeout: 0.4)
      assert_equal 0.4, @command.calls.last.last
    end
  end

end
