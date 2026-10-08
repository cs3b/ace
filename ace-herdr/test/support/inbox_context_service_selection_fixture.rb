# frozen_string_literal: true

# Literal source-selection shape only. These references do not pretend to be
# native executables; executable construction tests supply actual held bytes.
module InboxContextServiceSelectionFixture
  def native_client_selection
    %w[codex pi herdr codex_runtime_intent].to_h { |role| [role, {"path" => "/opt/context/#{role}", "bytes" => 100, "sha256" => "a" * 64}] }.merge(
      "codex_runtime_service" => {"unit_manifest" => {"path" => "/opt/context/codex-unit", "bytes" => 100, "sha256" => "b" * 64},
        "boundary_manifest" => {"path" => "/opt/context/codex-boundary", "bytes" => 100, "sha256" => "c" * 64},
        "execution_scope" => {"backend" => "linux_systemd_cgroup_v2", "slot_id" => "slot", "slice_unit" => "slot.slice", "service_unit" => "codex.service",
          "root_directory" => "/var/lib/context/root", "runtime_directory" => "/run/context", "network_namespace_path" => "/run/netns/context",
          "unit_manifest_sha256" => "b" * 64, "boundary_manifest_sha256" => "c" * 64}},
      "dependencies" => [], "environment" => {}, "cwd" => "/var/lib/context/native",
      "resources" => [{"path" => "/var/lib/context/native", "kind" => "directory", "access" => "read", "uid" => 200, "gid" => 300, "mode" => 0o750}])
  end
end
