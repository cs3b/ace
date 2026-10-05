# frozen_string_literal: true

require_relative "../test_helper"
require "ace/runtime/molecules/execution_unit_installation"

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
  end

  class Command
    attr_reader :profiles, :calls
    def initialize(profiles)
      @profiles, @calls = profiles, []
    end
    def call(argv, timeout:)
      calls << [argv, timeout]
      if argv.include?("get-property")
        if argv.last == "UnitPath"
          return JSON.generate("type" => "as", "data" => ["/etc/systemd/system", "/run/systemd/generator"]) + "\n"
        end
        index = argv.index("get-property")
        unit = argv[index + 2].delete_prefix("/org/freedesktop/systemd1/unit/").gsub(/_([0-9a-f]{2})/) { [$1.to_i(16)].pack("C") }
        interface = argv[index + 3].split(".").last
        signatures = interface == "Unit" ? Manager::UNIT_GRAPH_SIGNATURES : Manager::SERVICE_EXEC_SIGNATURES
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
      "root_directory" => "/var/lib/ace-slot/root", "network_namespace_path" => "/run/netns/ace-slot"}
    paths = {"slice_fragment" => "/etc/systemd/system/ace-slot.slice",
      "service_fragment" => "/etc/systemd/system/ace-slot.service", "native_executable" => "/usr/bin/herdr",
      "native_configuration" => "/etc/ace/herdr.json", "readiness_executable" => "/usr/libexec/ace-scope-ready",
      "bootstrap" => "/usr/libexec/ace-worker-gate", "worker_executable" => "/usr/bin/codex"}
    @artifacts = paths.map do |role, path|
      host = %w[slice_fragment service_fragment].include?(role) ? path : @scope.fetch("root_directory") + path
      bytes = "immutable #{role} bytes"
      @files.bytes[host] = bytes
      {"role" => role, "host_path" => host, "view_path" => path, "sha256" => Digest::SHA256.hexdigest(bytes)}
    end
    @native = {"executable" => paths.fetch("native_executable"),
      "executable_sha256" => @artifacts.find { |a| a["role"] == "native_executable" }.fetch("sha256")}
    @profiles = {"ace-slot.slice" => graph("ace-slot.slice", "ace.slice"), "ace.slice" => graph("ace.slice", "-.slice"),
      "-.slice" => graph("-.slice"), "ace-slot.service" => graph("ace-slot.service", "ace-slot.slice")}
    service_defaults = Manager::SERVICE_EXEC_SIGNATURES.transform_values do |signature|
      case signature
      when "s" then ""
      when "b" then false
      when "t" then 0
      when "(aiai)" then [[], []]
      when "(bas)" then [true, []]
      else []
      end
    end
    @profiles.fetch("ace-slot.service").merge!(service_defaults).merge!(Installation::SERVICE_REQUIRED).merge!(
      "User" => "13001", "Group" => "13001", "Slice" => @scope.fetch("slice_unit"),
      "RootDirectory" => @scope.fetch("root_directory"), "NetworkNamespacePath" => @scope.fetch("network_namespace_path"),
      "Environment" => ["HERDR_CONFIG_PATH=#{paths.fetch('native_configuration')}"],
      "RestrictAddressFamilies" => [true, %w[AF_INET AF_INET6 AF_UNIX]],
      "ExecStartEx" => [command(paths.fetch("native_executable"), args: ["server"])],
      "ExecStartPostEx" => [command(paths.fetch("readiness_executable"), args: ["slot"])])
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

  def save_manifest
    bytes = JSON.generate(@manifest)
    @files.bytes["/etc/ace/execution-slots/slot/unit-manifest.json"] = bytes
    @scope["unit_manifest_sha256"] = Digest::SHA256.hexdigest(bytes)
  end

  def test_verifies_actual_artifact_bytes_and_effective_manager_profile_without_claiming_runtime_proof
    value = @installation.verify!(manager: @manager)
    assert_equal @manifest, value
    assert_equal @artifacts.map { |a| a["host_path"] }, @files.digested
    assert_equal 10, @command.calls.size
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

end
