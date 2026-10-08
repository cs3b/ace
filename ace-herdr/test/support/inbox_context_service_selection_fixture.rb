# frozen_string_literal: true

# Literal source-selection shape only. These references do not pretend to be
# native executables; executable construction tests supply actual held bytes.
module InboxContextServiceSelectionFixture
  def native_client_selection
    %w[codex pi herdr].to_h { |role| [role, {"path" => "/opt/context/#{role}", "bytes" => 100, "sha256" => "a" * 64}] }.merge(
      "dependencies" => [], "environment" => {}, "cwd" => "/var/lib/context/native",
      "resources" => [{"path" => "/var/lib/context/native", "kind" => "directory", "access" => "read", "uid" => 200, "gid" => 300, "mode" => 0o750}])
  end
end
