# frozen_string_literal: true

require_relative "../test_helper"
require "ace/runtime/molecules/execution_unit_installation"
require "ace/runtime/molecules/readiness_configuration"

class ExecutionUnitInstallationTest < AceRuntimeTestCase
  Installation = Ace::Runtime::Molecules::ExecutionUnitInstallation
  Manager = Ace::Runtime::Molecules::SystemdScopeManager
  Unavailable = Ace::Runtime::RuntimeUnavailableError

  class Files
    attr_reader :bytes, :digested
    attr_accessor :routes
    def initialize
      @bytes, @digested = {}, []
    end
    def read(path, limit:)
      value = bytes.fetch(path) { raise Errno::ENOENT }
      raise Unavailable, "oversized" if value.bytesize > limit
      value
    end
    def activation_routes(paths, _unit)
      raise Unavailable, "missing lookup paths" if paths.empty?
      routes || []
    end
    def sha256(path)
      digested << path
      Digest::SHA256.hexdigest(bytes.fetch(path) { raise Errno::ENOENT })
    end
    def authority_socket!(authority)
      raise Unavailable, "wrong socket" unless authority.fetch("socket_path") == "/run/authority/socket" && authority.fetch("uid") == 13000
      [1, 2, 13000]
    end
  end

  class Command
    attr_reader :profiles, :calls
    attr_accessor :manager_environment
    def initialize(profiles)
      @profiles, @calls = profiles, []
      @manager_environment = ["PATH=/usr/bin:/bin", "LANG=C", "LC_CTYPE=C", "LANGUAGE=en"]
    end
    def call(argv, timeout:)
      calls << [argv, timeout]
      if argv.include?("get-property")
        if argv.last == "UnitPath"
          return JSON.generate("type" => "as", "data" => ["/etc/systemd/system", "/run/systemd/generator"]) + "\n"
        end
        if argv[-2..] == ["org.freedesktop.systemd1.Manager", "Environment"]
          return JSON.generate("type" => "as", "data" => manager_environment) + "\n"
        end
        index = argv.index("get-property")
        unit = argv[index + 2].delete_prefix("/org/freedesktop/systemd1/unit/").gsub(/_([0-9a-f]{2})/) { [$1.to_i(16)].pack("C") }
        interface = argv[index + 3].split(".").last
        signatures = case interface
        when "Unit" then Manager::UNIT_GRAPH_SIGNATURES.merge(Manager::UNIT_STATE_SIGNATURES)
        when "Service" then Manager::SERVICE_EXEC_SIGNATURES
        when "Mount" then Manager::MOUNT_SIGNATURES
        end
        profile = profiles.fetch(unit)
        return argv[(index + 4)..].map { |key| JSON.generate("type" => signatures.fetch(key), "data" => profile.fetch(key)) + "\n" }.join
      end
      unit = argv.last
      requested = argv.find { |arg| arg.start_with?("--property=") }.delete_prefix("--property=").split(",")
      scalar = {"Id" => unit, "LoadState" => "loaded", "ActiveState" => "inactive", "SubState" => "dead",
        "InvocationID" => "", "ControlGroup" => "", "Job" => "", "FragmentPath" => profiles.fetch(unit).fetch("FragmentPath"),
        "DropInPaths" => "", "MainPID" => "0", "Slice" => "ace-slot.slice"}
      requested.map { |key| "#{key}=#{scalar.fetch(key)}\n" }.join
    end
  end

  def command(path, args:, flags: [])
    [path, [path, *args], flags, 0, 0, 0, 0, 0, 0, 0]
  end

  def graph(unit, parent = nil)
    Manager::UNIT_GRAPH_SIGNATURES.transform_values { |signature| signature == "as" ? [] : signature == "b" ? false : "" }.merge(
      "Id" => unit, "Names" => [unit], "LoadState" => "loaded", "UnitFileState" => "static",
      "FragmentPath" => "/etc/systemd/system/#{unit}", "Requires" => parent ? [parent] : [], "After" => parent ? [parent] : [])
  end

  def setup
    @files = Files.new
    @scope = {"slot_id" => "slot", "slice_unit" => "ace-slot.slice", "service_unit" => "ace-slot.service",
      "root_directory" => "/var/lib/ace-slot/root", "runtime_directory" => "/run/ace-slot", "network_namespace_path" => "/run/netns/ace-slot"}
    paths = {"slice_fragment" => "/etc/systemd/system/ace-slot.slice",
      "service_fragment" => "/etc/systemd/system/ace-slot.service", "native_executable" => "/usr/bin/herdr",
      "native_configuration" => "/etc/ace/herdr.json", "readiness_executable" => "/usr/libexec/ace-scope-ready",
      "bootstrap" => "/usr/libexec/ace-worker-gate", "worker_executable" => "/usr/bin/codex",
      "readiness_configuration" => "/etc/ace/execution-slots/slot/readiness.json",
      "boundary_manifest" => "/etc/ace/execution-slots/slot/boundary-manifest.json",
      "runtime_dependency" => "/usr/bin/ruby"}
    @artifacts = paths.map do |role, path|
      host = %w[slice_fragment service_fragment].include?(role) ? path : @scope.fetch("root_directory") + path
      bytes = "immutable #{role} bytes"
      @files.bytes[host] = bytes
      {"role" => role, "host_path" => host, "view_path" => path, "sha256" => Digest::SHA256.hexdigest(bytes)}
    end
    boundary = {"schema" => "ace.execution-boundary-manifest/v1", "slot_id" => "slot", "network_installation" => {},
      "resources" => [{"host_path" => "/var/lib/ace-slot", "view_path" => "/host-private", "stage" => "parent",
        "worker_visible" => false, "read_only" => true},
        {"host_path" => "/run/ace-slot", "view_path" => "/run/ace-slot", "stage" => "native", "worker_visible" => true, "read_only" => false}]}
    boundary_artifact = @artifacts.find { |artifact| artifact["role"] == "boundary_manifest" }
    @files.bytes[boundary_artifact.fetch("host_path")] = JSON.generate(boundary)
    boundary_artifact["sha256"] = Digest::SHA256.hexdigest(@files.bytes.fetch(boundary_artifact.fetch("host_path")))
    @scope["boundary_manifest_sha256"] = boundary_artifact.fetch("sha256")
    readiness = {"schema" => Ace::Runtime::Molecules::ReadinessConfiguration::SCHEMA,
      "slot_id" => "slot", "mapping_id" => "map", "project_id" => "project",
      "authority" => {"uid" => 13000, "gid" => 13000, "groups" => [], "socket_path" => "/run/authority/socket"},
      "worker" => {"uid" => 13001, "gid" => 13001, "groups" => []},
      "native" => {"executable" => "/usr/bin/herdr", "socket_path" => "/run/ace-slot/socket", "version" => "0.9.3",
        "protocol" => 22, "workspace_id" => "w1", "executable_sha256" => "a" * 64},
      "boundary_manifest" => {"path" => paths.fetch("boundary_manifest"), "sha256" => @scope.fetch("boundary_manifest_sha256")},
      "runtime" => {"interpreter_path" => "/usr/bin/ruby", "load_paths" => ["/usr/lib/ruby"],
        "dependencies" => [{"path" => "/usr/bin/ruby", "sha256" => "a" * 64, "bytes" => 1}]}}
    config_artifact = @artifacts.find { |a| a["role"] == "readiness_configuration" }
    @files.bytes[config_artifact.fetch("host_path")] = JSON.generate(readiness)
    config_artifact["sha256"] = Digest::SHA256.hexdigest(@files.bytes.fetch(config_artifact.fetch("host_path")))
    @native = {"executable" => paths.fetch("native_executable"),
      "executable_sha256" => @artifacts.find { |a| a["role"] == "native_executable" }.fetch("sha256")}
    @profiles = {"ace-slot.slice" => graph("ace-slot.slice", "ace.slice"), "ace.slice" => graph("ace.slice", "-.slice"),
      "-.slice" => graph("-.slice"), "ace-slot.service" => graph("ace-slot.service", "ace-slot.slice")}
    service_defaults = Manager::SERVICE_EXEC_SIGNATURES.transform_values do |signature|
      case signature
      when "s" then ""
      when "b" then false
      when "t", "u" then 0
      when "(aiai)" then [[], []]
      when "(bas)" then [true, []]
      else []
      end
    end
    @profiles.fetch("ace-slot.service").merge!(service_defaults).merge!(Installation::SERVICE_REQUIRED).merge!(
      "User" => "13001", "Group" => "13001", "Slice" => @scope.fetch("slice_unit"),
      "RootDirectory" => @scope.fetch("root_directory"), "NetworkNamespacePath" => @scope.fetch("network_namespace_path"),
      "WantsMountsFor" => [@scope.fetch("root_directory")], "RequiresMountsFor" => ["/run/ace-slot"],
      "ReadOnlyPaths" => ["/dev", "/dev/shm"], "RuntimeDirectory" => ["ace-slot"], "After" => ["ace-slot.slice", "-.mount", "run.mount", "systemd-journald.socket"],
      "BindReadOnlyPaths" => [["/run/authority/socket", "/run/authority/socket", false, 0]],
      "Environment" => ["HERDR_CONFIG_PATH=#{paths.fetch('native_configuration')}"],
      "RestrictAddressFamilies" => [true, %w[AF_INET AF_INET6 AF_UNIX]],
      "ExecStartEx" => [command(paths.fetch("native_executable"), args: ["server"])],
      "ExecStartPostEx" => [command("/usr/bin/ruby", args: ["--disable=gems,rubyopt", paths.fetch("readiness_executable"), "slot"])])
    @profiles["-.mount"] = {"Id" => "-.mount", "LoadState" => "loaded", "ActiveState" => "active", "SubState" => "mounted", "Job" => [0, "/"], "Where" => "/"}
    @profiles["run.mount"] = {"Id" => "run.mount", "LoadState" => "loaded", "ActiveState" => "active", "SubState" => "mounted", "Job" => [0, "/"], "Where" => "/run"}
    @profiles["systemd-journald.socket"] = {"Id" => "systemd-journald.socket", "LoadState" => "loaded", "ActiveState" => "active", "SubState" => "listening", "Job" => [0, "/"]}
    @manifest = {"schema" => Installation::SCHEMA, "slot_id" => "slot", "artifacts" => @artifacts,
      "properties" => {"slice" => JSON.parse(JSON.generate(@profiles.fetch("ace-slot.slice"))),
        "service" => JSON.parse(JSON.generate(@profiles.fetch("ace-slot.service")))}}
    %w[ExecStartEx ExecStartPostEx].each { |key| @manifest["properties"]["service"][key] = @manifest["properties"]["service"][key].map { |item| item.first(3) } }
    save_manifest
    @command = Command.new(@profiles)
    @manager = Manager.new(slice_unit: @scope.fetch("slice_unit"), service_unit: @scope.fetch("service_unit"), command: @command)
    @installation = Installation.new(scope: @scope, native: @native, bootstrap: paths.fetch("bootstrap"),
      worker_executable: paths.fetch("worker_executable"), worker_uid: 13001, worker_gid: 13001, files: @files)
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

  def save_manifest
    bytes = JSON.generate(@manifest)
    @files.bytes["/etc/ace/execution-slots/slot/unit-manifest.json"] = bytes
    @scope["unit_manifest_sha256"] = Digest::SHA256.hexdigest(bytes)
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
    overlay = [[replacement, "/usr/bin/herdr", false, 0], ["/run/authority/socket", "/run/authority/socket", false, 0]]
    @profiles["ace-slot.service"]["BindReadOnlyPaths"] = overlay
    @manifest["properties"]["service"]["BindReadOnlyPaths"] = overlay
    save_manifest
    assert @installation.verify!(manager: @manager)
    assert_includes @files.digested, replacement
    @files.bytes[replacement] = "changed actual bind source"
    assert_raises(Unavailable) { @installation.verify!(manager: @manager) }
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
