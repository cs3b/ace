# frozen_string_literal: true

require_relative "../test_helper"
require "ace/runtime/molecules/execution_unit_installation"
require "ace/runtime/molecules/readiness_configuration"

require_relative "../support/execution_unit_installation_fixture"

class ExecutionUnitInstallationTest < AceRuntimeTestCase
  include ExecutionUnitInstallationFixture

  def test_context_native_closure_and_ipc_are_exact_members_of_full_installed_profile
    context_installation
    refs = %w[codex pi herdr].map do |role|
      path, bytes = "/opt/context/#{role}", "selected #{role} bytes"
      @files.bytes[path] = bytes
      ref = {"path" => path, "bytes" => bytes.bytesize, "sha256" => Digest::SHA256.hexdigest(bytes)}
      @artifacts << {"role" => "runtime_dependency", "host_path" => path, "view_path" => path, "sha256" => ref.fetch("sha256")}
      @profiles.fetch("ace-slot.service").fetch("BindReadOnlyPaths") << [path, path, false, 0]
      ref
    end
    resource = {"path" => "/run/native-client", "kind" => "directory", "access" => "read", "uid" => 13001, "gid" => 13001, "mode" => 0o700}
    @profiles.fetch("ace-slot.service").fetch("BindReadOnlyPaths") << [resource.fetch("path"), resource.fetch("path"), false, 0]
    boundary_ref = @context_selection.fetch("boundary_manifest")
    boundary = JSON.parse(@files.bytes.fetch(boundary_ref.fetch("path")))
    boundary.fetch("resources") << {"host_path" => resource.fetch("path"), "view_path" => resource.fetch("path"),
      "stage" => "parent", "worker_visible" => true, "read_only" => true}
    @files.bytes[boundary_ref.fetch("path")] = JSON.generate(boundary)
    boundary_ref["bytes"] = @files.bytes.fetch(boundary_ref.fetch("path")).bytesize
    boundary_ref["sha256"] = Digest::SHA256.hexdigest(@files.bytes.fetch(boundary_ref.fetch("path")))
    @artifacts.find { |artifact| artifact["role"] == "boundary_manifest" }["sha256"] = boundary_ref.fetch("sha256")
    @scope["boundary_manifest_sha256"] = boundary_ref.fetch("sha256")
    @manifest.fetch("properties").fetch("service")["BindReadOnlyPaths"] = @profiles.fetch("ace-slot.service").fetch("BindReadOnlyPaths")
    save_manifest
    @context_selection["unit_manifest"]["bytes"] = @files.bytes.fetch(@context_selection.fetch("unit_manifest").fetch("path")).bytesize
    @context_selection["unit_manifest"]["sha256"] = @scope.fetch("unit_manifest_sha256")
    configuration = @artifacts.find { |artifact| artifact["role"] == "context_configuration" }
    installation = Installation.for_inbox_context(service: @context_selection, configuration: {
      "path" => configuration.fetch("host_path"), "bytes" => @files.bytes.fetch(configuration.fetch("host_path")).bytesize, "sha256" => configuration.fetch("sha256")},
      load_paths: ["/usr/lib/ruby"], authority: {"socket_path" => "/run/authority/socket", "uid" => 13000},
      owner_credentials: {"uid" => 13001, "gid" => 13001, "groups" => [13002]}, files: @files)
    assert installation.verify_inbox_native_projection!(references: refs, resources: [resource], manager: @manager)
    bad = Marshal.load(Marshal.dump(refs))
    bad.first["sha256"] = "f" * 64
    assert_raises(Unavailable) { installation.verify_inbox_native_projection!(references: bad, resources: [resource], manager: @manager) }
    assert_raises(Unavailable) { installation.verify_inbox_native_projection!(references: refs, resources: [resource.merge("access" => "write")], manager: @manager) }
    assert_raises(Unavailable) { installation.verify_inbox_native_projection!(references: refs, resources: [resource.merge("path" => "/run/native-client/implicit")], manager: @manager) }
  end
  def test_context_profile_uses_exact_host_refs_and_actual_in_unit_commands
    installation = context_installation
    assert_equal @manifest, installation.verify!(manager: @manager)
    @context_selection.fetch("entry")["path"] = "/ignored/mutated"
    assert_equal @manifest, installation.verify!(manager: @manager)
    @profiles.fetch("ace-slot.service")["ExecStartEx"].first[1] << "caller-override"
    assert_raises(Unavailable) { installation.verify!(manager: @manager) }
  end

  def test_context_profile_requires_full_isolation_and_bounded_stop_without_worker_devpts
    %w[ProtectControlGroups Delegate TimeoutStopUSec].each do |key|
      installation = context_installation
      @profiles.fetch("ace-slot.service")[key] = key == "TimeoutStopUSec" ? 36_000_000 : !@profiles.fetch("ace-slot.service")[key]
      assert_raises(Unavailable) { installation.verify!(manager: @manager) }
      setup
    end
  end

  def test_staged_boundary_validation_does_not_replace_installed_socket_identity
    socket_calls = []
    @files.define_singleton_method(:authority_socket!) do |authority|
      socket_calls << authority
      raise Unavailable, "controlled missing original authority socket"
    end
    authority = {"socket_path" => "/run/authority/socket", "uid" => 13000}
    roles = @artifacts.group_by { |artifact| artifact.fetch("role") }
    assert_equal true, @installation.validate_staged_boundary_topology!(service: @manifest.fetch("properties").fetch("service"), artifacts: roles, authority: authority)
    assert_empty socket_calls
    error = assert_raises(Unavailable) { @installation.verify!(manager: @manager) }
    assert_equal "controlled missing original authority socket", error.message
    assert_equal 1, socket_calls.size
    assert_equal authority.fetch("socket_path"), socket_calls.first.fetch("socket_path")
  end

  def test_staged_boundary_validation_reuses_current_projection_refusals
    socket_calls = []
    @files.define_singleton_method(:authority_socket!) { |*| socket_calls << true; raise "unexpected live socket access" }
    authority = {"socket_path" => "/run/authority/socket", "uid" => 13000}
    roles = @artifacts.group_by { |artifact| artifact.fetch("role") }
    service = JSON.parse(JSON.generate(@manifest.fetch("properties").fetch("service")))
    service.fetch("BindPaths") << ["/foreign/host", "/foreign/view", false, 0]
    assert_raises(Unavailable) { @installation.validate_staged_boundary_topology!(service: service, artifacts: roles, authority: authority) }
    assert_empty socket_calls
  end

  def test_worker_entry_requires_exact_wrapper_and_unique_runtime_dependency_bytes
    assert @installation.verify!(manager: @manager)
    %w[wrapper interpreter].each do |key|
      original = @worker_entry.fetch(key).dup
      ["path", "sha256", "bytes"].each do |field|
        @worker_entry[key] = original.merge(field => (field == "bytes" ? original.fetch(field) + 1 : field == "path" ? "/other" : "0" * 64))
        assert_raises(Unavailable, "#{key}:#{field}") { @installation.verify!(manager: @manager) }
      end
      @worker_entry[key] = original
    end
    dependency = @artifacts.find { |item| item["role"] == "runtime_dependency" }
    duplicate = dependency.merge("host_path" => dependency.fetch("host_path") + "-alias")
    @files.bytes[duplicate.fetch("host_path")] = @files.bytes.fetch(dependency.fetch("host_path"))
    @artifacts << duplicate
    save_manifest
    assert_raises(Unavailable) { @installation.verify!(manager: @manager) }
  end

  def test_fixed_implicit_profile_refuses_private_tmp_ipc_writes_and_api_storage_aliases
    {"PrivateTmp" => true, "ProtectKernelTunables" => false, "DevicePolicy" => "auto",
      "DeviceAllow" => [["/dev/sda", "rw"]], "ReadOnlyPaths" => [],
      "BindPaths" => [["/host/storage", "/dev/storage", false, 0]],
      "ReadWritePaths" => ["/dev/shm"]}.each do |key, value|
      original = @profiles["ace-slot.service"].fetch(key)
      @profiles["ace-slot.service"][key] = value
      @manifest["properties"]["service"][key] = value
      save_manifest
      assert_raises(Unavailable, key) { @installation.verify!(manager: @manager) }
      @profiles["ace-slot.service"][key] = original
      @manifest["properties"]["service"][key] = original
    end
    save_manifest
    assert @installation.verify!(manager: @manager)
  end

  def test_effective_manager_environment_refuses_startup_code_inputs_and_pam
    assert @installation.verify!(manager: @manager)
    %w[LD_PRELOAD LD_LIBRARY_PATH DYLD_INSERT_LIBRARIES RUBYOPT RUBYLIB GEM_HOME GEM_PATH BUNDLE_GEMFILE NODE_OPTIONS BUN_OPTIONS LC_EXECUTE].each do |key|
      @command.manager_environment = ["PATH=/usr/bin:/bin", "#{key}=/worker/untrusted"]
      error = assert_raises(Unavailable, key) { @installation.verify!(manager: @manager) }
      assert_match(/effective manager environment changes/, error.message)
    end
    @command.manager_environment = ["PATH=/usr/bin:/bin", "LANG=C", "LC_ALL=", "LANGUAGE=en"]
    assert @installation.verify!(manager: @manager)
    @profiles["ace-slot.service"]["PAMName"] = "worker-login"
    @manifest["properties"]["service"]["PAMName"] = "worker-login"
    save_manifest
    assert_raises(Unavailable) { @installation.verify!(manager: @manager) }
  end

  def test_writable_tmp_requires_complete_original_backing_inventory
    @profiles["ace-slot.service"]["ReadWritePaths"] = ["/tmp"]
    @manifest["properties"]["service"]["ReadWritePaths"] = ["/tmp"]
    save_manifest
    assert_raises(Unavailable) { @installation.verify!(manager: @manager) }
    artifact = @artifacts.find { |entry| entry["role"] == "boundary_manifest" }
    boundary = JSON.parse(@files.bytes.fetch(artifact.fetch("host_path")))
    boundary["resources"] << {"host_path" => @scope.fetch("root_directory") + "/tmp", "view_path" => "/tmp",
      "stage" => "parent", "worker_visible" => true, "read_only" => false}
    bytes = JSON.generate(boundary)
    @files.bytes[artifact.fetch("host_path")] = bytes
    artifact["sha256"] = @scope["boundary_manifest_sha256"] = Digest::SHA256.hexdigest(bytes)
    save_manifest
    assert @installation.verify!(manager: @manager)
  end

  def test_exact_readonly_authority_projection_and_implicit_log_socket_refusal
    assert @installation.verify!(manager: @manager)
    invalid = [[], [["/run/authority/socket", "/alias", false, 0]],
      [["/other/socket", "/run/authority/socket", false, 0]],
      [["/run/authority", "/run/authority", false, 0]],
      [["/run/authority/socket", "/run/authority/socket", false, 0], ["/host/run", "/run", false, 0]]]
    original = @profiles["ace-slot.service"].fetch("BindReadOnlyPaths")
    invalid.each do |mounts|
      @profiles["ace-slot.service"]["BindReadOnlyPaths"] = mounts
      @manifest["properties"]["service"]["BindReadOnlyPaths"] = mounts
      save_manifest
      assert_raises(Unavailable) { @installation.verify!(manager: @manager) }
    end
    @profiles["ace-slot.service"]["BindReadOnlyPaths"] = original
    @manifest["properties"]["service"]["BindReadOnlyPaths"] = original
    %w[BindPaths ReadWritePaths BindLogSockets].each do |key|
      previous = @profiles["ace-slot.service"][key]
      value = {"BindPaths" => [["/run/authority/socket", "/run/authority/socket", false, 0]],
        "ReadWritePaths" => ["/run/authority/socket"], "BindLogSockets" => true}.fetch(key)
      @profiles["ace-slot.service"][key] = value
      @manifest["properties"]["service"][key] = value
      save_manifest
      assert_raises(Unavailable) { @installation.verify!(manager: @manager) }
      @profiles["ace-slot.service"][key] = previous
      @manifest["properties"]["service"][key] = previous
    end
    save_manifest
    assert @installation.verify!(manager: @manager)
  end

  def test_selected_endpoint_owner_rejects_actual_non_socket_type
    Dir.mktmpdir("ace-authority-socket-") do |root|
      path = File.join(root, "endpoint")
      endpoint = UNIXServer.new(path)
      authority = {"socket_path" => path, "uid" => Process.uid}
      Ace::Runtime::Molecules::ProtectedSocket.stub(:root_path!, ->(*_args, **_kwargs) { true }) do
        assert_equal Process.uid, Installation::Files.new.authority_socket!(authority).last
        endpoint.close
        File.unlink(path)
        File.write(path, "file")
        assert_raises(Unavailable) { Installation::Files.new.authority_socket!(authority) }
      end
    ensure
      endpoint&.close unless endpoint&.closed?
    end
  end

  def test_declared_writable_api_subtree_cannot_override_fixed_profile
    %w[/sys/storage /proc/storage /dev/shm/storage].each do |path|
      @profiles["ace-slot.service"]["ReadWritePaths"] = [path]
      @manifest["properties"]["service"]["ReadWritePaths"] = [path]
      artifact = @artifacts.find { |entry| entry["role"] == "boundary_manifest" }
      boundary = JSON.parse(@files.bytes.fetch(artifact.fetch("host_path")))
      boundary["resources"] << {"host_path" => @scope.fetch("root_directory") + path, "view_path" => path,
        "stage" => "parent", "worker_visible" => true, "read_only" => false}
      bytes = JSON.generate(boundary)
      @files.bytes[artifact.fetch("host_path")] = bytes
      artifact["sha256"] = @scope["boundary_manifest_sha256"] = Digest::SHA256.hexdigest(bytes)
      save_manifest
      assert_raises(Unavailable) { @installation.verify!(manager: @manager) }
    end
  end

  def test_verifies_actual_artifact_bytes_and_effective_manager_profile_without_claiming_runtime_proof
    value = @installation.verify!(manager: @manager)
    assert_equal @manifest, value
    assert_equal @artifacts.map { |a| a["host_path"] }, @files.digested
    assert_equal 16, @command.calls.size
    assert @command.calls.any? { |argv, _timeout| argv[-2..] == ["org.freedesktop.systemd1.Manager", "Environment"] }
    refute value.key?("proof_id")
    refute value.key?("boundary_verified")
    @files.bytes[@scope.fetch("root_directory") + "/usr/bin/herdr"] = "changed native artifact"
    assert_raises(Unavailable) { @installation.verify!(manager: @manager) }
  end

  def test_manifest_hash_and_closed_schema_cannot_be_asserted_without_matching_bytes
    @scope["unit_manifest_sha256"] = "a" * 64
    assert_raises(Unavailable) { @installation.verify!(manager: @manager) }
    @manifest["claimed_verified"] = true
    save_manifest
    assert_raises(Unavailable) { @installation.verify!(manager: @manager) }
  end

  def test_effective_change_refuses_even_when_root_manifest_retains_old_property
    @profiles["ace-slot.service"]["Restart"] = "always"
    assert_raises(Unavailable) { @installation.verify!(manager: @manager) }
    @profiles["ace-slot.service"]["Restart"] = "no"
    @profiles["ace-slot.service"]["DropInPaths"] = ["/etc/systemd/system/ace-slot.service.d/foreign.conf"]
    assert_raises(Unavailable) { @installation.verify!(manager: @manager) }
  end

  def test_declared_weaker_security_or_other_principal_never_qualifies
    {"Restart" => "always", "KillMode" => "process", "SendSIGKILL" => false, "NoNewPrivileges" => false,
     "RestrictNamespaces" => 18446744073709551615, "RootDirectory" => "/", "User" => "1",
     "Group" => "1", "RestrictAddressFamilies" => [false, ["AF_UNIX"]], "Sockets" => ["foreign.socket"]}.each do |key, value|
      previous = @profiles["ace-slot.service"][key]
      @profiles["ace-slot.service"][key] = value
      @manifest["properties"]["service"][key] = value
      save_manifest
      assert_raises(Unavailable, key) { @installation.verify!(manager: @manager) }
      @profiles["ace-slot.service"][key] = previous
      @manifest["properties"]["service"][key] = previous
    end
  end

  def test_privileged_failure_ignore_or_other_readiness_command_refuses
    %w[privileged no-setuid ignore-failure].each do |flags|
      @profiles["ace-slot.service"]["ExecStartPostEx"] = [command("/usr/libexec/ace-scope-ready", args: ["slot"], flags: [flags])]
      assert_raises(Unavailable) { @installation.verify!(manager: @manager) }
    end
    @profiles["ace-slot.service"]["ExecStartPostEx"] = [command("/usr/bin/other-hook", args: ["slot"])]
    assert_raises(Unavailable) { @installation.verify!(manager: @manager) }
  end

  def test_activation_edges_cannot_be_approved_by_manifest_and_slice_cannot_require_child
    %w[TriggeredBy OnFailure PartOf Upholds].each do |key|
      @profiles["ace-slot.slice"][key] = ["foreign.service"]
      @manifest["properties"]["slice"][key] = ["foreign.service"]
      save_manifest
      assert_raises(Unavailable, key) { @installation.verify!(manager: @manager) }
      @profiles["ace-slot.slice"][key] = []
      @manifest["properties"]["slice"][key] = []
    end
    @profiles["ace-slot.slice"]["Requires"] = [@scope.fetch("service_unit")]
    @manifest["properties"]["slice"]["Requires"] = [@scope.fetch("service_unit")]
    save_manifest
    assert_raises(Unavailable) { @installation.verify!(manager: @manager) }
  end
  def test_transitive_parent_dependency_and_unloaded_enablement_routes_refuse
    @profiles["ace.slice"]["Wants"] = ["hidden.target"]
    assert_raises(Unavailable) { @installation.verify!(manager: @manager) }
    @profiles["ace.slice"]["Wants"] = []
    @files.routes = ["/run/systemd/generator/boot.target.wants/ace-slot.service"]
    assert_raises(Unavailable) { @installation.verify!(manager: @manager) }
  end

  def test_complete_command_arguments_and_config_bytes_cannot_be_replaced_by_claimed_manifest
    @profiles["ace-slot.service"]["ExecStartEx"][0][1] << "--unexpected"
    @manifest["properties"]["service"]["ExecStartEx"][0][1] << "--unexpected"
    save_manifest
    assert_raises(Unavailable) { @installation.verify!(manager: @manager) }
    @profiles["ace-slot.service"]["ExecStartEx"][0][1].pop
    @manifest["properties"]["service"]["ExecStartEx"][0][1].pop
    save_manifest
    @files.bytes[@scope.fetch("root_directory") + "/etc/ace/herdr.json"] = "different config bytes"
    assert_raises(Unavailable) { @installation.verify!(manager: @manager) }
  end

  def test_unused_exec_hooks_or_external_incoming_service_activation_refuse
    @profiles["ace-slot.service"]["ExecStartPreEx"] = [command("/usr/libexec/pre", args: [])]
    @manifest["properties"]["service"]["ExecStartPreEx"] = @profiles["ace-slot.service"]["ExecStartPreEx"]
    save_manifest
    assert_raises(Unavailable) { @installation.verify!(manager: @manager) }
    @profiles["ace-slot.service"]["ExecStartPreEx"] = []
    @manifest["properties"]["service"]["ExecStartPreEx"] = []
    @profiles["ace-slot.service"]["WantedBy"] = ["multi-user.target"]
    @manifest["properties"]["service"]["WantedBy"] = ["multi-user.target"]
    save_manifest
    assert_raises(Unavailable) { @installation.verify!(manager: @manager) }
  end

  def test_environment_injection_cannot_be_approved_by_manifest
    @profiles["ace-slot.service"]["Environment"] << "LD_PRELOAD=/scratch/evil.so"
    @manifest["properties"]["service"]["Environment"] << "LD_PRELOAD=/scratch/evil.so"
    save_manifest
    assert_raises(Unavailable) { @installation.verify!(manager: @manager) }
  end

  def test_lookup_scanner_finds_unloaded_generator_routes_and_aliases_without_following_links
    stat = Struct.new(:uid, :kind) do
      def symlink? = kind == :link
      def directory? = kind == :directory
    end
    children = {"/installed" => ["other.service", "slot-alias.service", "boot.target.wants"],
      "/installed/boot.target.wants" => ["ace-slot.service"]}
    kinds = {"/installed/other.service" => :file, "/installed/slot-alias.service" => :link,
      "/installed/boot.target.wants" => :directory, "/installed/boot.target.wants/ace-slot.service" => :link}
    targets = {"/installed/slot-alias.service" => "ace-slot.service",
      "/installed/boot.target.wants/ace-slot.service" => "../ace-slot.service"}
    Ace::Runtime::Molecules::ProtectedSocket.stub(:root_path!, ->(*) { true }) do
      Dir.stub(:children, ->(path) { children.fetch(path) }) do
        File.stub(:lstat, ->(path) { stat.new(0, kinds.fetch(path)) }) do
          File.stub(:readlink, ->(path) { targets.fetch(path) }) do
            assert_equal targets.keys.sort, Installation::Files.new.activation_routes(["/installed"], "ace-slot.service").sort
          end
        end
      end
    end
  end

  def test_effective_overlay_cannot_shadow_hashed_native_or_config_even_if_manifest_declares_it
    %w[/usr/bin/herdr /usr /etc/ace/herdr.json].each do |target|
      overlay = [["/outside/unverified", target, false, 0]]
      @profiles["ace-slot.service"]["BindReadOnlyPaths"] = overlay
      @manifest["properties"]["service"]["BindReadOnlyPaths"] = overlay
      save_manifest
      assert_raises(Unavailable) { @installation.verify!(manager: @manager) }
    end
    @profiles["ace-slot.service"]["BindReadOnlyPaths"] = []
    @manifest["properties"]["service"]["BindReadOnlyPaths"] = []
    @profiles["ace-slot.service"]["BindPaths"] = [[@scope.fetch("root_directory") + "/usr", "/usr", false, 0]]
    @manifest["properties"]["service"]["BindPaths"] = @profiles["ace-slot.service"]["BindPaths"]
    save_manifest
    assert_raises(Unavailable) { @installation.verify!(manager: @manager) }
  end

  def test_implicit_mount_ordering_requires_active_exact_backing_and_no_job
    assert @installation.verify!(manager: @manager)
    @profiles["-.mount"]["Job"] = [42, "/org/freedesktop/systemd1/job/42"]
    assert_raises(Unavailable) { @installation.verify!(manager: @manager) }
    @profiles["-.mount"]["Job"] = [0, "/"]
    @profiles["run.mount"]["Where"] = "/foreign"
    assert_raises(Unavailable) { @installation.verify!(manager: @manager) }
  end

  def test_readonly_overlay_is_accepted_only_when_actual_source_bytes_are_verified
    artifact = @artifacts.find { |entry| entry["role"] == "native_executable" }
    original_host = artifact.fetch("host_path")
    replacement = "/installed/verified-herdr"
    @files.bytes[replacement] = @files.bytes.fetch(original_host)
    artifact["host_path"] = replacement
    overlay = [[replacement, "/usr/bin/herdr", false, 0], ["/run/authority/socket", "/run/authority/socket", false, 0], ["/run/ace/execution-slots/slot/devpts/ptmx", "/dev/pts/ptmx", false, 0]]
    @profiles["ace-slot.service"]["BindReadOnlyPaths"] = overlay
    @manifest["properties"]["service"]["BindReadOnlyPaths"] = overlay
    save_manifest
    assert @installation.verify!(manager: @manager)
    assert_includes @files.digested, replacement
    @files.bytes[replacement] = "changed actual bind source"
    assert_raises(Unavailable) { @installation.verify!(manager: @manager) }
  end

  def test_selected_devpts_pair_cannot_use_host_other_slot_alias_or_writable_node
    service = @profiles.fetch("ace-slot.service")
    original_rw = Marshal.load(Marshal.dump(service.fetch("BindPaths")))
    original_ro = Marshal.load(Marshal.dump(service.fetch("BindReadOnlyPaths")))
    [
      -> { service["BindPaths"] = [["/dev/pts", "/dev/pts", false, 0]] },
      -> { service["BindPaths"] = [["/run/ace/execution-slots/other/devpts", "/dev/pts", false, 0]] },
      -> { service["BindReadOnlyPaths"][1][1] = "/dev/ptmx" },
      -> { service["BindReadOnlyPaths"][1][0] = "/dev/pts/ptmx" },
      -> { service["BindPaths"] << service["BindReadOnlyPaths"].pop },
      -> { service["BindPaths"][0][2] = true }
    ].each do |mutate|
      service["BindPaths"] = Marshal.load(Marshal.dump(original_rw))
      service["BindReadOnlyPaths"] = Marshal.load(Marshal.dump(original_ro))
      mutate.call
      %w[BindPaths BindReadOnlyPaths].each { |key| @manifest["properties"]["service"][key] = service.fetch(key) }
      save_manifest
      assert_raises(Unavailable) { @installation.verify!(manager: @manager) }
    end
    service["BindPaths"], service["BindReadOnlyPaths"] = original_rw, original_ro
    %w[BindPaths BindReadOnlyPaths].each { |key| @manifest["properties"]["service"][key] = service.fetch(key) }
    save_manifest
    assert @installation.verify!(manager: @manager)
  end
  def test_host_tty_input_or_path_cannot_bypass_selected_devpts
    service = @profiles.fetch("ace-slot.service")
    %w[tty tty-force tty-fail].each do |input|
      service["StandardInput"] = input
      @manifest["properties"]["service"]["StandardInput"] = input
      save_manifest
      assert_raises(Unavailable) { @installation.verify!(manager: @manager) }
    end
    service["StandardInput"] = @manifest["properties"]["service"]["StandardInput"] = "null"
    service["TTYPath"] = @manifest["properties"]["service"]["TTYPath"] = "/dev/pts/12"
    save_manifest
    assert_raises(Unavailable) { @installation.verify!(manager: @manager) }
    service["TTYPath"] = @manifest["properties"]["service"]["TTYPath"] = ""
    save_manifest
    assert @installation.verify!(manager: @manager)
  end

  def test_other_kernel_mount_shadow_options_cannot_be_approved_by_manifest
    {"TemporaryFileSystem" => [["/usr", "ro"]], "RootImage" => "/foreign/image.raw", "RootEphemeral" => true,
     "InaccessiblePaths" => ["/usr/bin/herdr"], "ExtensionDirectories" => ["/foreign/extension"]}.each do |key, value|
      previous = @profiles["ace-slot.service"][key]
      @profiles["ace-slot.service"][key] = value
      @manifest["properties"]["service"][key] = value
      save_manifest
      assert_raises(Unavailable, key) { @installation.verify!(manager: @manager) }
      @profiles["ace-slot.service"][key] = previous
      @manifest["properties"]["service"][key] = previous
    end
  end

  def test_implicit_private_and_kernel_mounts_cannot_hide_hashed_root_image_executable
    %w[/dev/herdr /proc/herdr /sys/herdr /run/ace-slot/herdr /tmp/herdr /var/tmp/herdr].each do |view|
      artifact = @artifacts.find { |entry| entry["role"] == "native_executable" }
      bytes = @files.bytes.fetch(artifact.fetch("host_path"))
      artifact["host_path"] = @scope.fetch("root_directory") + view
      artifact["view_path"] = view
      @files.bytes[artifact.fetch("host_path")] = bytes
      @native["executable"] = view
      @profiles["ace-slot.service"]["ExecStartEx"] = [command(view, args: ["server"])]
      @manifest["properties"]["service"]["ExecStartEx"] = @profiles["ace-slot.service"]["ExecStartEx"].map { |item| item.first(3) }
      save_manifest
      assert_raises(Unavailable, view) { @installation.verify!(manager: @manager) }
    end
  end

end
