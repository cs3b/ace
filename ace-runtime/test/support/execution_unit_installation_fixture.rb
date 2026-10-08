# frozen_string_literal: true

require "ace/runtime/molecules/execution_unit_installation"
require "ace/runtime/molecules/readiness_configuration"

module ExecutionUnitInstallationFixture
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
        when "Unit" then Manager::UNIT_GRAPH_SIGNATURES.merge(Manager::UNIT_STATE_SIGNATURES).merge(Manager::ACTIVATION_UNIT_SIGNATURES)
        when "Service" then Manager::SERVICE_EXEC_SIGNATURES.merge(Manager::ACTIVATION_SERVICE_SIGNATURES).merge("TimeoutStopUSec" => "t")
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

  def context_installation
    @scope["backend"] = "linux_systemd_cgroup_v2"
    @artifacts.reject! { |artifact| %w[native_executable native_configuration readiness_executable].include?(artifact["role"]) }
    renames = {"worker_executable" => "context_executable", "readiness_configuration" => "context_configuration", "runtime_dependency" => "interpreter"}
    @artifacts.each { |artifact| artifact["role"] = renames.fetch(artifact["role"], artifact["role"]) }
    dependency = {"role" => "runtime_dependency", "host_path" => @scope.fetch("root_directory") + "/usr/lib/ruby/context.rb",
      "view_path" => "/usr/lib/ruby/context.rb", "sha256" => Digest::SHA256.hexdigest("dependency")}
    @files.bytes[dependency.fetch("host_path")] = "dependency"
    @artifacts << dependency
    service = @profiles.fetch("ace-slot.service")
    service["BindPaths"] = []
    service["BindReadOnlyPaths"] = [["/run/authority/socket", "/run/authority/socket", false, 0]]
    @artifacts.each do |artifact|
      next unless %w[bootstrap boundary_manifest context_configuration].include?(artifact["role"])
      artifact["view_path"] = artifact.fetch("host_path")
      service["BindReadOnlyPaths"] << [artifact.fetch("host_path"), artifact.fetch("view_path"), false, 0]
    end
    service["Environment"] = []
    service["SupplementaryGroups"] = ["13002"]
    service["ExecStartEx"] = [command("/usr/bin/ruby", args: ["--disable=gems,rubyopt", "-I", "/usr/lib/ruby", "/usr/bin/codex"])]
    service["ExecStartPostEx"] = []
    service["TimeoutStopUSec"] = 35_000_000
    @manifest["properties"]["service"] = JSON.parse(JSON.generate(service))
    %w[ExecStartEx ExecStartPostEx].each { |key| @manifest["properties"]["service"][key] = service[key].map { |item| item.first(3) } }
    save_manifest
    ref = lambda do |role|
      artifact = @artifacts.find { |item| item["role"] == role }
      {"path" => artifact.fetch("host_path"), "sha256" => artifact.fetch("sha256"), "bytes" => @files.bytes.fetch(artifact.fetch("host_path")).bytesize}
    end
    manifest_path = "/etc/ace/execution-slots/slot/unit-manifest.json"
    @context_selection = {"execution_scope" => @scope, "entry" => ref.call("context_executable"), "interpreter" => ref.call("interpreter"),
      "configuration" => ref.call("context_configuration"), "bootstrap_manifest" => ref.call("bootstrap"), "boundary_manifest" => ref.call("boundary_manifest"),
      "unit_manifest" => {"path" => manifest_path, "bytes" => @files.bytes.fetch(manifest_path).bytesize, "sha256" => @scope.fetch("unit_manifest_sha256")}}
    configuration = @context_selection.delete("configuration")
    Installation.for_inbox_context(service: @context_selection, configuration: configuration, load_paths: ["/usr/lib/ruby"],
      authority: {"socket_path" => "/run/authority/socket", "uid" => 13000},
      owner_credentials: {"uid" => 13001, "gid" => 13001, "groups" => [13002]}, files: @files)
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
    reference = {"path" => "/etc/ace/network/profile", "sha256" => "a" * 64, "bytes" => 1}
    boundary = {"schema" => "ace.execution-boundary-manifest/v1", "slot_id" => "slot", "network_installation" => {
      "profile" => reference, "installer_artifact" => reference, "current_selection_path" => "/etc/ace/execution-slots/slot/network-installation-selection.json"},
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
      "BindPaths" => [["/run/ace/execution-slots/slot/devpts", "/dev/pts", false, 0]],
      "BindReadOnlyPaths" => [["/run/authority/socket", "/run/authority/socket", false, 0], ["/run/ace/execution-slots/slot/devpts/ptmx", "/dev/pts/ptmx", false, 0]],
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
    @worker_entry = {"wrapper" => "worker_executable", "interpreter" => "runtime_dependency"}.to_h do |key, role|
      artifact = @artifacts.find { |item| item["role"] == role }
      [key, {"path" => artifact.fetch("view_path"), "bytes" => @files.bytes.fetch(artifact.fetch("host_path")).bytesize,
        "sha256" => artifact.fetch("sha256")}]
    end
    @installation = Installation.new(scope: @scope, native: @native, bootstrap: paths.fetch("bootstrap"),
      worker_entry: @worker_entry, worker_uid: 13001, worker_gid: 13001, files: @files)
  end


  def save_manifest
    bytes = JSON.generate(@manifest)
    @files.bytes["/etc/ace/execution-slots/slot/unit-manifest.json"] = bytes
    @scope["unit_manifest_sha256"] = Digest::SHA256.hexdigest(bytes)
  end

end
