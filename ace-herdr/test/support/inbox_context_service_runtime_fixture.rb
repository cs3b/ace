# frozen_string_literal: true

require "ace/herdr/molecules/inbox_context_lifetime"
require_relative "../../../ace-runtime/test/support/execution_unit_installation_fixture"
require_relative "inbox_context_owner_fixture"
require_relative "inbox_context_service_selection_fixture"

module InboxContextServiceRuntimeFixture
  include InboxContextServiceSelectionFixture
  include ExecutionUnitInstallationFixture
  alias_method :setup_installation, :setup
  Lifetime = Ace::Herdr::Molecules::InboxContextLifetime
  BOOT = "00000000-0000-0000-0000-000000000001"

  class Kernel
    attr_accessor :foreign, :dead
    def capture(pid)
      {"pid" => pid, "uid" => foreign ? 14001 : 13001, "gid" => 13001, "groups" => [13002],
        "parent_pid" => 1, "host" => "controlled", "started_at" => "linux:#{BOOT}:42"}
    end
    def live!(_peer)
      raise Ace::Runtime::RuntimeUnavailableError, "controlled dead owner" if dead
      true
    end
    def same?(left, right) = left == right
  end

  class Cgroups
    attr_accessor :populated, :replaced, :foreign
    attr_reader :handle
    def initialize = (@populated = 1)
    def pin(path)
      @handle = File.open(File::NULL)
      {handle: @handle, identity: {"path" => path, "mount_id" => 1, "filesystem_type" => "cgroup2", "device" => 2, "inode" => 3}}
    end
    def member!(peer, pinned:, kernel:)
      kernel.live!(peer)
      raise Ace::Runtime::RuntimeUnavailableError, "controlled foreign member" if foreign
      observe(pinned)
      true
    end
    def observe(pinned)
      raise Ace::Runtime::RuntimeUnavailableError, "controlled replacement" if replaced
      {"cgroup_identity" => pinned.fetch(:identity), "populated" => populated}
    end
  end

  def setup
    setup_installation
    @installation = context_installation
    @root = File.realpath(Dir.mktmpdir("ic", "/tmp"))
    path = File.join(@root, "config.json")
    data = {"schema" => "ace.herdr.inbox-context-service/v1", "project_id" => "project", "inbox_context_id" => "ctx", "native_mapping_id" => "map",
      "native_clients" => native_client_selection,
      "control_socket_path" => "/run/context/control.sock", "state_root" => "/var/lib/context/state", "deliveries_dir" => "/var/lib/context/events",
      "owner_credentials" => {"uid" => 13001, "gid" => 13001, "groups" => [13002]}, "socket_gid" => 13002,
      "key" => {"public_key_path" => "/etc/context/public.pem", "configuration_path" => "/etc/context/key.json"},
      "authority" => {"socket_path" => "/run/authority/socket", "uid" => 13000, "gid" => 13000, "groups" => []},
      "grants" => [{"uid" => 13000, "gid" => 13000, "groups" => [13002], "role" => "authority", "purposes" => %w[deliver enqueue reconcile]}]}
    bytes = JSON.generate(data)
    File.write(path, bytes)
    File.chmod(0o600, path)
    @configuration = Ace::Herdr::Molecules::InboxContextServiceConfiguration.load(stage: {
      "schema" => "ace.herdr.inbox-context-stage/v1", "codex_runtime" => {"path" => "/opt/context/runtime.json", "bytes" => 1, "sha256" => "a" * 64}, "project_id" => "project", "inbox_context_id" => "ctx",
      "configuration" => {"path" => path, "bytes" => bytes.bytesize, "sha256" => Digest::SHA256.hexdigest(bytes)}},
      artifacts: Ace::Runtime::Molecules::ProtectedArtifactSet.new(protection: InboxContextOwnerFixture::FixtureArtifacts.new(@root)))
    artifact = @artifacts.find { |entry| entry["role"] == "context_configuration" }
    old_host = artifact.fetch("host_path")
    artifact["host_path"], artifact["view_path"], artifact["sha256"] = path, path, Digest::SHA256.hexdigest(bytes)
    @profiles.fetch("ace-slot.service")["BindReadOnlyPaths"].reject! { |mount| mount[0] == old_host }
    @files.bytes[path] = bytes
    @profiles.fetch("ace-slot.service")["BindReadOnlyPaths"] << [path, artifact.fetch("view_path"), false, 0]
    @manifest["properties"]["service"]["BindReadOnlyPaths"] = @profiles.fetch("ace-slot.service")["BindReadOnlyPaths"]
    save_manifest
    manifest_path = @context_selection.fetch("unit_manifest").fetch("path")
    @context_selection["unit_manifest"] = {"path" => manifest_path, "bytes" => @files.bytes.fetch(manifest_path).bytesize,
      "sha256" => @scope.fetch("unit_manifest_sha256")}
    @installation = Installation.for_inbox_context(service: @context_selection, configuration: @configuration.reference, load_paths: ["/usr/lib/ruby"],
      authority: data.fetch("authority"), owner_credentials: data.fetch("owner_credentials"), files: @files)
    @profiles.fetch("ace-slot.service").merge!("MainPID" => Process.pid, "ControlPID" => 0,
      "ActiveState" => "active", "SubState" => "running", "Job" => [0, "/"], "InvocationID" => [1] * 16, "ControlGroup" => "/ace-slot.slice/context.service")
    @profiles.fetch("ace-slot.slice").merge!("ActiveState" => "active", "SubState" => "active", "Job" => [0, "/"], "InvocationID" => [2] * 16, "ControlGroup" => "/ace-slot.slice")
    @kernel, @cgroups = Kernel.new, Cgroups.new
    @boot_files = Object.new
    @boot_files.define_singleton_method(:boot_id) { BOOT }
    @lifetime = Lifetime.new(installation: @installation, manager: @manager, configuration: @configuration,
      kernel: @kernel, cgroups: @cgroups, files: @boot_files)
  end

  def teardown = FileUtils.remove_entry(@root)

end
