# frozen_string_literal: true
require_relative "../test_helper"
require "digest"
require "tempfile"
require "ace/lab/molecules/protected_cleanup_owner_identity"

class ProtectedCleanupOwnerIdentityTest < Minitest::Test
  Owner = Ace::Lab::Molecules::ProtectedCleanupOwnerIdentity
  Unavailable = Ace::Runtime::RuntimeUnavailableError

  class Protection
    def root_path!(_path); end # Controlled temporary filesystem DAC only.
    def verify!(_path, handle, directory:)
      stat = handle.stat
      unless (directory ? [0, Process.uid].include?(stat.uid) && stat.directory? :
          stat.uid == Process.uid && stat.file? && (stat.mode & 0o222).zero?)
        raise Unavailable, "controlled held artifact protection differs"
      end
    end
  end

  def fixture
    Dir.mktmpdir("cleanup-owner-identity") do |temporary_root|
      root = File.realpath(temporary_root)
      refs = %w[entry.rb ruby-interpreter dependency.rb cleanup.service].map do |name|
        path = File.join(root, name)
        bytes = "immutable #{name}"
        File.binwrite(path, bytes)
        File.chmod(0o444, path)
        {"path" => path, "sha256" => Digest::SHA256.hexdigest(bytes), "bytes" => bytes.bytesize}
      end
      @refs = refs
      @identity = {"pid" => 77, "uid" => 0, "gid" => 0, "groups" => [0],
        "started_at" => "linux:boot:900", "host" => "host", "parent_pid" => 1}
      @handle = Tempfile.new("controlled-root-lifetime")
      @kernel = Object.new
      identity, handle = @identity, @handle
      @kernel.define_singleton_method(:capture) { |_pid| identity.dup }
      @kernel.define_singleton_method(:pin) { |_identity| handle }
      @kernel.define_singleton_method(:exited?) { |_handle| false }
      @kernel.define_singleton_method(:peer) { |_socket| [77, 0, 0] }
      @unit = {"Id" => "cleanup.service", "LoadState" => "loaded", "ActiveState" => "active", "SubState" => "running",
        "InvocationID" => "a" * 32, "FragmentPath" => refs.last.fetch("path"), "DropInPaths" => []}
      @service = Owner::EMPTY_COMMANDS.to_h { |key| [key, []] }.merge("Slice" => "cleanup.slice", "Type" => "exec", "MainPID" => 77, "ControlPID" => 0,
        "ExecStartEx" => [[refs[1].fetch("path"), [refs[1].fetch("path"), Owner::DISABLE, "-I", root, refs[0].fetch("path")],
          [], 1, 1, 0, 0, 77, 0, 0]])
      unit, service = @unit, @service
      service.merge!("Environment" => Owner::ENVIRONMENT.dup, "EnvironmentFiles" => [], "PassEnvironment" => [],
        "UnsetEnvironment" => [], "PAMName" => "")
      @manager = Object.new
      @manager.define_singleton_method(:manager_environment) { |**_| [] }
      @manager.define_singleton_method(:typed_properties) { |interface:, **_| interface == "Unit" ? unit.dup : service.dup }
      @manager.define_singleton_method(:unit_for_pidfd) do |handle:, **_|
        raise "original IO unexpectedly closed" if handle.closed?
        {"unit" => "cleanup.service", "invocation_id" => "a" * 32}
      end
      artifacts = Owner::Runtime::ProtectedArtifactSet.new(protection: Protection.new)
      @owner = Owner.new(unit: "cleanup.service", slice_unit: "cleanup.slice", entry: refs[0], interpreter: refs[1], closure: refs.drop(2),
        load_paths: [root], manager: @manager, kernel: @kernel, artifacts: artifacts)
      yield
    ensure
      @handle&.close!
    end
  end

  def test_same_original_peer_manager_lifetime_and_actual_held_bytes_produce_immutable_binding
    fixture do
      binding = @owner.observe!(socket: Object.new)
      assert_equal %w[entry_sha256 invocation_id process_binding unit], binding.keys.sort
      assert_equal @refs.first.fetch("sha256"), binding.fetch("entry_sha256")
      assert_equal @identity, binding.fetch("process_binding")
      assert binding.frozen?
      assert binding.fetch("process_binding").fetch("groups").frozen?
      assert @handle.closed?
    end
  end

  def test_complete_selected_load_path_graph_is_verified_and_bounded
    fixture do
      root = File.dirname(@refs.first.fetch("path"))
      paths = 64.times.map { |index| File.join(root, "library-#{index}") }
      dependencies = paths.map do |directory|
        FileUtils.mkdir_p(directory)
        path = File.join(directory, "source.rb")
        File.binwrite(path, "selected source")
        File.chmod(0o444, path)
        {"path" => path, "bytes" => 15, "sha256" => Digest::SHA256.hexdigest("selected source")}
      end
      build = lambda do |selected, refs = dependencies|
        Owner.new(unit: "cleanup.service", slice_unit: "cleanup.slice", entry: @refs[0], interpreter: @refs[1], closure: @refs.drop(2) + refs,
          load_paths: selected, manager: @manager, kernel: @kernel,
          artifacts: Owner::Runtime::ProtectedArtifactSet.new(protection: Protection.new))
      end
      @service["ExecStartEx"][0][1][3] = paths.join(":")
      assert_equal @identity, build.call(paths).observe!(socket: Object.new).fetch("process_binding")
      assert_raises(ArgumentError) { build.call(paths + [File.join(root, "extra")]) }
      assert_raises(ArgumentError) { build.call(paths.take(63) + [paths.first]) }
      assert_raises(ArgumentError) { build.call(paths, dependencies.drop(1)) }
      oversized = 64.times.map { |index| "/selected/#{index}/#{'x' * 300}" }
      refs = oversized.map { |path| {"path" => path + "/source.rb", "bytes" => 1, "sha256" => "a" * 64} }
      error = assert_raises(ArgumentError) { build.call(oversized, refs) }
      assert_match(/startup arguments exceed bound/, error.message)
    end
  end

  def test_concurrent_observation_refuses_before_shared_artifact_or_kernel_transaction
    fixture do
      entered, release = Queue.new, Queue.new
      calls = 0
      unit, service = @unit, @service
      @manager.define_singleton_method(:typed_properties) do |interface:, **_|
        calls += 1
        if calls == 1
          entered << true
          release.pop
        end
        interface == "Unit" ? unit.dup : service.dup
      end
      worker = Thread.new { @owner.observe!(socket: Object.new) }
      Timeout.timeout(2) { entered.pop }
      assert_raises(Unavailable) { @owner.observe!(socket: Object.new) }
      assert_raises(Unavailable) { @owner.observe_self! }
      assert_equal 1, calls
      refute @handle.closed?
      release << true
      assert worker.join(2), "original verification did not finish"
      assert_equal @identity, worker.value.fetch("process_binding")
      assert @handle.closed?
    ensure
      release << true if release && worker&.alive?
      worker&.join(2)
    end
  end

  def test_only_selected_dedicated_slice_can_produce_identity
    ["system.slice", "other.slice", nil].each do |slice|
      fixture do
        @service["Slice"] = slice
        assert_raises(Unavailable) { @owner.observe!(socket: Object.new) }
        refute @handle.closed?, "wrong slice must refuse before pin acquisition"
      end
    end
    fixture do
      ["system.slice", "user.slice", "machine.slice", "cleanup.service", "../cleanup.slice"].each do |slice|
        assert_raises(ArgumentError) do
          Owner.new(unit: "cleanup.service", slice_unit: slice, entry: @refs[0], interpreter: @refs[1],
            closure: @refs.drop(2), load_paths: [File.dirname(@refs.first.fetch("path"))], manager: @manager)
        end
      end
    end
  end

  def test_self_observation_joins_only_fixed_current_pid_and_never_receiver_peer
    fixture do
      @identity["pid"] = Process.pid
      @service["MainPID"] = Process.pid
      @service["ExecStartEx"][0][7] = Process.pid
      @kernel.define_singleton_method(:peer) { |_socket| raise "self observation must not inspect receiver peer" }
      binding = @owner.observe_self!
      assert_equal Process.pid, binding.fetch("process_binding").fetch("pid")
      assert binding.frozen?
      assert @handle.closed?
    end
    fixture do
      assert_raises(Unavailable) { @owner.observe_self! }
      assert @handle.closed?
    end
    fixture do
      @identity["pid"] = Process.pid
      @service["MainPID"] = Process.pid
      @service["ExecStartEx"][0][7] = Process.pid
      @manager.define_singleton_method(:unit_for_pidfd) { |**_| {"unit" => "cleanup.service", "invocation_id" => "b" * 32} }
      assert_raises(Unavailable) { @owner.observe_self! }
      assert @handle.closed?
    end
  end

  def test_wrong_peer_original_invocation_and_replaced_dependency_refuse_and_close_lifetime
    fixture do
      @kernel.define_singleton_method(:peer) { |_socket| [78, 0, 0] }
      assert_raises(Unavailable) { @owner.observe!(socket: Object.new) }
      assert @handle.closed?
    end
    fixture do
      @manager.define_singleton_method(:unit_for_pidfd) { |**_| {"unit" => "cleanup.service", "invocation_id" => "b" * 32} }
      assert_raises(Unavailable) { @owner.observe!(socket: Object.new) }
      assert @handle.closed?
    end
    fixture do
      path = @refs[2].fetch("path")
      File.chmod(0o644, path)
      File.binwrite(path, "changed bytes")
      File.chmod(0o444, path)
      assert_raises(Unavailable) { @owner.observe!(socket: Object.new) }
      assert @handle.closed?
    end
  end

  def test_unsupported_execution_start_profile_or_foreign_unit_file_cannot_become_image_proof
    ["simple", "forking"].each do |type|
      fixture do
        @service["Type"] = type
        assert_raises(Unavailable) { @owner.observe!(socket: Object.new) }
      end
    end
    fixture do
      @service["ExecStartPreEx"] = @service.fetch("ExecStartEx")
      assert_raises(Unavailable) { @owner.observe!(socket: Object.new) }
    end
    fixture do
      @unit["FragmentPath"] = "/foreign/unit.service"
      assert_raises(Unavailable) { @owner.observe!(socket: Object.new) }
      assert @handle.closed?
    end
    fixture do
      @service["ControlPID"] = 88
      assert_raises(Unavailable) { @owner.observe!(socket: Object.new) }
    end
  end

  def test_replacement_after_source_read_and_final_pin_join_refuse
    fixture do
      unit = @unit
      reads = 0
      @manager.define_singleton_method(:typed_properties) do |interface:, **_|
        if interface == "Unit"
          reads += 1
          unit.merge("InvocationID" => (reads == 1 ? "a" : "b") * 32)
        else
          @controlled_service
        end
      end
      @manager.instance_variable_set(:@controlled_service, @service)
      assert_raises(Unavailable) { @owner.observe!(socket: Object.new) }
      assert @handle.closed?
    end
    fixture do
      joins = 0
      @manager.define_singleton_method(:unit_for_pidfd) do |**_|
        joins += 1
        {"unit" => "cleanup.service", "invocation_id" => (joins == 1 ? "a" : "b") * 32}
      end
      assert_raises(Unavailable) { @owner.observe!(socket: Object.new) }
      assert @handle.closed?
    end
  end

  def test_fixed_root_kernel_policy_checks_actual_decoded_status_without_generic_capture
    kernel_class = Owner::Kernel
    kernel_class.const_set(:RUBY_PLATFORM, "linux-controlled")
    birth_reader = Object.new
    birth_reader.define_singleton_method(:native_birth) { |_pid| "linux:boot:900" }
    kernel = kernel_class.new(identity: birth_reader)
    status = "Uid:\t0 0 0 0\nGid:\t0 0 0 0\nGroups:\t0\nPPid:\t1\nNoNewPrivs:\t1\n" +
      "CapInh:\t0\nCapPrm:\t2\nCapEff:\t2\nCapBnd:\t2\nCapAmb:\t0\n"
    read = ->(path, _length) { path.end_with?("ptrace_scope") ? "2\n" : status }
    File.stub(:binread, read) { assert_equal 0, kernel.capture(77).fetch("uid") }
    [status.sub("CapEff:\t2", "CapEff:\t3"), status.sub("Groups:\t0", "Groups:\t0 1"),
      status.sub("NoNewPrivs:\t1", "NoNewPrivs:\t0"), status.sub("Uid:\t0 0 0 0", "Uid:\t0 0 1 0")].each do |bad|
      File.stub(:binread, ->(path, _length) { path.end_with?("ptrace_scope") ? "2\n" : bad }) do
        assert_raises(Unavailable) { kernel.capture(77) }
      end
    end
  ensure
    kernel_class.send(:remove_const, :RUBY_PLATFORM) if kernel_class&.const_defined?(:RUBY_PLATFORM, false)
  end
  def test_held_source_changed_during_peer_join_is_not_admitted
    fixture do
      path = @refs[2].fetch("path")
      @manager.define_singleton_method(:unit_for_pidfd) do |**_|
        File.chmod(0o644, path)
        File.binwrite(path, "replacement after original read")
        File.chmod(0o444, path)
        {"unit" => "cleanup.service", "invocation_id" => "a" * 32}
      end
      assert_raises(Unavailable) { @owner.observe!(socket: Object.new) }
      assert @handle.closed?
    end
  end

  def test_expired_observation_has_no_manager_kernel_or_source_effect
    fixture do
      @manager.define_singleton_method(:typed_properties) { |**_| raise "expired request reached manager" }
      assert_raises(Unavailable) { @owner.observe!(socket: Object.new, deadline: 0) }
      refute @handle.closed? # Pin acquisition never happened.
    end
  end

  def test_kernel_pin_rechecks_fixed_policy_and_closes_only_owned_lifetime_on_replacement
    identity = {"pid" => 77}
    Tempfile.create("controlled-pidfd-acquisition") do |held|
      kernel = Owner::Kernel.new(pidfd_open: ->(pid) { raise "wrong pin target" unless pid == 77; held })
      kernel.stub(:capture, identity) { assert_same held, kernel.pin(identity) }
      refute held.closed?
      kernel.stub(:capture, {"pid" => 78}) do
        assert_raises(Unavailable) { kernel.pin(identity) }
        assert held.closed?
      end
    end
  end

  def test_effective_startup_environment_is_closed_even_when_unit_masks_unsafe_manager_values
    %w[LD_PRELOAD RUBYOPT GEM_HOME BUNDLE_GEMFILE HOME CODEX_HOME HERDR_CONFIG_PATH SHELL TMPDIR].each do |key|
      fixture do
        @manager.define_singleton_method(:manager_environment) { |**_| ["#{key}=unsafe"] }
        assert_raises(Unavailable) { @owner.observe!(socket: Object.new) }
      end
    end
    fixture do
      @manager.define_singleton_method(:manager_environment) { |**_| ["PATH=/different", "LANGUAGE=pl", "LC_TIME=C"] }
      assert_equal "cleanup.service", @owner.observe!(socket: Object.new).fetch("unit")
    end
    {"Environment" => ["PATH=/usr/bin:/bin", "LANG=C", "LC_ALL=C", "HOME=/other"],
      "EnvironmentFiles" => [["/foreign", false]], "PassEnvironment" => ["HOME"],
      "UnsetEnvironment" => ["LD_PRELOAD"], "PAMName" => "login"}.each do |key, value|
      fixture do
        @service[key] = value
        assert_raises(Unavailable) { @owner.observe_self! }
      end
    end
    fixture do
      calls = 0
      @manager.define_singleton_method(:manager_environment) do |**_|
        calls += 1
        ["LANG=#{calls}"]
      end
      assert_raises(Unavailable) { @owner.observe!(socket: Object.new) }
      assert @handle.closed?
    end
  end

  def test_all_manager_reads_share_one_absolute_deadline_without_renewal
    fixture do
      clock = 100.0
      calls = []
      unit, service = @unit, @service
      @manager.define_singleton_method(:typed_properties) do |interface:, timeout:, **_|
        calls << timeout
        clock += 0.4
        interface == "Unit" ? unit.dup : service.dup
      end
      @manager.define_singleton_method(:manager_environment) do |timeout:|
        calls << timeout
        clock += 0.4
        []
      end
      @manager.define_singleton_method(:unit_for_pidfd) do |handle:, timeout:|
        raise "lost original lifetime" if handle.closed?
        calls << timeout
        clock += 0.4
        {"unit" => "cleanup.service", "invocation_id" => "a" * 32}
      end
      Process.stub(:clock_gettime, ->(*) { clock }) do
        assert_equal "cleanup.service", @owner.observe!(socket: Object.new, deadline: 200).fetch("unit")
      end
      assert_equal 8, calls.size
      calls.each_with_index { |timeout, index| assert_in_delta 5 - index * 0.4, timeout, 0.0001 }
      assert @handle.closed?
    end
    fixture do
      clock = 100.0
      unit, service = @unit, @service
      @manager.define_singleton_method(:typed_properties) do |interface:, **_|
        clock += 3
        interface == "Unit" ? unit.dup : service.dup
      end
      @kernel.define_singleton_method(:pin) { |_| raise "expired startup observation reached pidfd acquisition" }
      Process.stub(:clock_gettime, ->(*) { clock }) do
        assert_raises(Unavailable) { @owner.observe!(socket: Object.new, deadline: 105) }
      end
      refute @handle.closed?, "an unacquired controlled handle remains owned by the fixture"
    end
  end

end
