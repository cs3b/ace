# frozen_string_literal: true
require_relative "execution_unit_installation_fixture"

module CodexRuntimeInstallationFixture
  include ExecutionUnitInstallationFixture
  attr_reader :selection, :manager, :files
  def selected_installation(change = nil, intent_override: nil, authority: {"socket_path" => "/run/authority/socket", "uid" => 13000}, metadata_root: nil)
    @scope["backend"] = "linux_systemd_cgroup_v2"
    @original = {"project_id" => "project", "worker_cwd" => "/workspace", "worker_uid" => 13001,
      "worker_gid" => 13001, "worker_groups" => [], "execution_scope" => @scope.dup}
    @artifacts.select! { |artifact| Installation::CODEX_ROLES.include?(artifact["role"]) }
    @artifacts.reject! { |artifact| artifact["role"] == "runtime_dependency" }
    native = @artifacts.find { |artifact| artifact["role"] == "native_executable" }
    boundary = @artifacts.find { |artifact| artifact["role"] == "boundary_manifest" }
    ref = ->(artifact) { {"path" => artifact.fetch("host_path"), "bytes" => @files.bytes.fetch(artifact.fetch("host_path")).bytesize, "sha256" => artifact.fetch("sha256")} }
    @intent = {"schema" => "lab.codex-runtime-intent/v1", "project_id" => "project", "inbox_context_id" => "context",
      "native_mapping_id" => "map", "unit_name" => "codex.service", "codex" => ref.call(native), "dependencies" => [],
      "cwd" => "/workspace", "home" => "/home/native", "socket_path" => "/run/ace-slot/codex.sock", "socket_gid" => 13001,
      "credentials" => {"uid" => 13001, "gid" => 13001, "groups" => []}, "environment" => {},
      "thread_configuration" => {"model" => "gpt-6.1-sol", "approval_policy" => "never", "sandbox" => "danger-full-access"}}
    if intent_override
      @intent = Marshal.load(Marshal.dump(intent_override))
      @original.merge!("worker_cwd" => @intent.fetch("cwd"), "worker_uid" => @intent.fetch("credentials").fetch("uid"),
        "worker_gid" => @intent.fetch("credentials").fetch("gid"), "worker_groups" => @intent.fetch("credentials").fetch("groups"))
      @files.bytes[@intent.fetch("codex").fetch("path")] = File.binread(@intent.fetch("codex").fetch("path"))
      native.merge!("host_path" => @intent.fetch("codex").fetch("path"), "view_path" => @intent.fetch("codex").fetch("path"), "sha256" => @intent.fetch("codex").fetch("sha256"))
    end
    change&.call(@intent)
    config = @artifacts.find { |artifact| artifact["role"] == "native_configuration" }
    if metadata_root
      config["host_path"] = config["view_path"] = File.join(metadata_root, "intent.json")
    end
    @files.bytes[config.fetch("host_path")] = JSON.generate(@intent)
    config["sha256"] = Digest::SHA256.hexdigest(@files.bytes.fetch(config.fetch("host_path")))
    @intent_ref = ref.call(config)
    @artifacts.each { |artifact| artifact["view_path"] = artifact.fetch("host_path") unless %w[slice_fragment service_fragment].include?(artifact["role"]) }
    fragment = @artifacts.find { |artifact| artifact["role"] == "service_fragment" }
    @files.bytes["/etc/systemd/system/codex.service"] = @files.bytes.fetch(fragment.fetch("host_path"))
    fragment["host_path"] = fragment["view_path"] = "/etc/systemd/system/codex.service"
    service = @profiles.delete("ace-slot.service")
    @profiles["codex.service"] = service
    service["Id"], service["Names"], service["FragmentPath"] = "codex.service", ["codex.service"], fragment.fetch("host_path")
    service["WorkingDirectory"] = @intent.fetch("cwd")
    service["User"], service["Group"] = @intent.fetch("credentials").values_at("uid", "gid").map(&:to_s)
    service["SupplementaryGroups"] = @intent.fetch("credentials").fetch("groups").map(&:to_s)
    service["Environment"] = ["HOME=" + @intent.fetch("home")]
    service["ExecStartEx"] = [command(native.fetch("host_path"), args: ["app-server", "--listen", "unix://" + @intent.fetch("socket_path")])]
    service["ExecStartPostEx"] = []
    @artifacts.each do |artifact|
      next if %w[slice_fragment service_fragment].include?(artifact["role"])
      service["BindReadOnlyPaths"] << [artifact.fetch("host_path"), artifact.fetch("view_path"), false, 0]
    end
    @manifest["properties"]["service"] = JSON.parse(JSON.generate(service))
    %w[ExecStartEx ExecStartPostEx].each { |key| @manifest["properties"]["service"][key] = service[key].map { |item| item.first(3) } }
    @scope["service_unit"] = "codex.service"
    save_manifest
    if metadata_root
      original_path = boundary.fetch("host_path")
      boundary_path = File.join(metadata_root, "codex-boundary.json")
      @files.bytes[boundary_path] = @files.bytes.fetch(original_path)
      boundary.merge!("host_path" => boundary_path, "view_path" => boundary_path)
      service["BindReadOnlyPaths"].reject! { |row| row[0] == original_path }
      service["BindReadOnlyPaths"] << [boundary_path, boundary_path, false, 0]
      @manifest["properties"]["service"]["BindReadOnlyPaths"] = service.fetch("BindReadOnlyPaths")
      save_manifest
    end
    @selection = {"unit_manifest" => {"path" => "/etc/ace/execution-slots/slot/unit-manifest.json", "sha256" => @scope.fetch("unit_manifest_sha256"), "bytes" => @files.bytes.fetch("/etc/ace/execution-slots/slot/unit-manifest.json").bytesize},
      "boundary_manifest" => ref.call(boundary), "execution_scope" => @scope}
    if metadata_root
      manifest_path = File.join(metadata_root, "codex-unit.json")
      @files.bytes[manifest_path] = @files.bytes.fetch(@selection.fetch("unit_manifest").fetch("path"))
      @selection.fetch("unit_manifest")["path"] = manifest_path
      [@selection.fetch("unit_manifest"), @selection.fetch("boundary_manifest")].each do |selected|
        File.binwrite(selected.fetch("path"), @files.bytes.fetch(selected.fetch("path")))
        File.chmod(0o600, selected.fetch("path"))
      end
    end
    @manager = Manager.new(slice_unit: @scope.fetch("slice_unit"), service_unit: "codex.service", command: @command)
    Installation.for_codex_runtime(service: @selection, intent_reference: @intent_ref, original_mapping: @original,
      mapping_id: "map", authority: authority, files: @files)
  end

end
