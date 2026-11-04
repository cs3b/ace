# frozen_string_literal: true
# Trusted fixture configuration only. Product installation remains ace-lab install.
require "yaml"
require "json"
raise "fixture configuration requires root" unless Process.uid.zero?
manifest_path = "/etc/lab/ace-lab/install.yml"
authorization_path = "/etc/lab/ace-lab/authorization.yml"
raise "authorization already exists" if File.exist?(authorization_path) || File.symlink?(authorization_path)
stat = File.lstat(manifest_path)
raise "unsafe deployment manifest" unless stat.file? && stat.uid.zero? && (stat.mode & 0o7777) == 0o644
manifest = YAML.safe_load_file(manifest_path, permitted_classes: [], aliases: false)
raise "fixture is already configured" if %w[projects grants coordinator session_runtime].any? { |key| manifest.key?(key) }
release = JSON.parse(File.read("/var/lib/ace-e2e/input/release-manifest.json"))
manifest["projects"] = [{"id" => "ace", "path" => "/lab/ace",
  "remote" => "http://127.0.0.1:3000/e2e-integrator/ace.git", "label" => "ACE E2E fixture"}]
manifest["coordinator"] = {"id" => "lab", "path" => "/lab"}
manifest["grants"] = {"mo" => %w[lab ace], "session:lab-overseer" => ["ace"], "session:project-overseer" => ["ace"]}
manifest["roles"] = {"worker" => "coworker/worker", "verifier" => "coworker/reviewer",
  "integrator" => "coworker/integrator", "project-overseer" => "overseer/start", "lab-overseer" => "overseer/lab-start"}
  .map { |role, guide| {"id" => role, "account" => "mo", "instructions" => "wfi://#{guide}"} }
manifest["session_runtime"] = {
  "node" => "/opt/ace/toolchains/node-v#{release.fetch('node').fetch('version')}-linux-arm64/bin/node",
  "pi" => "/opt/ace/runtime/pi/node_modules/@earendil-works/pi-coding-agent/dist/cli.js",
  "path" => ["/opt/ace/runtime/bin", "/opt/ace/toolchains/node-v#{release.fetch('node').fetch('version')}-linux-arm64/bin", "/usr/bin"],
  "provider" => "zai", "model" => "glm-5.3-flash", "credentials" => "/etc/lab/ace-lab/pi-auth.json",
  "herdr" => {"account" => "mo", "socket" => "/run/lab/herdr/herdr.sock"}}
# This issuer password remains host-only; profiles contain references, not values.
password = File.read("/run/ace-e2e-forgejo/e2e-admin.password")[/password\s+is\s+'([^']+)'/i, 1]
raise "Forgejo generated password is unavailable" unless password
secret_path = "/run/ace-e2e-forgejo/issuer-password"
File.open(secret_path, File::WRONLY | File::CREAT | File::EXCL | File::NOFOLLOW, 0o600) { |file| file.write(password) }
profiles = {
  "e2e-worker" => ["worker", "e2e-worker", %w[write:repository write:issue]],
  "e2e-reviewer" => ["verifier", "e2e-reviewer", %w[write:repository read:issue]],
  "e2e-integrator" => ["integrator", "e2e-integrator", %w[write:repository write:issue]],
  "e2e-overseer" => ["project-overseer", "e2e-integrator", %w[read:repository write:issue]]
}.to_h do |name, (role, account, scopes)|
  [name, {"provider" => "forgejo", "roles" => [role], "principals" => ["session:#{role}"],
    "repos" => ["e2e-integrator/ace"], "scopes" => scopes, "ttl_minutes" => 5,
    "issuer" => {"url" => "http://127.0.0.1:3000", "account" => account,
      "admin_username" => "e2e-admin", "password_file" => secret_path}}]
end
File.open(authorization_path, File::WRONLY | File::CREAT | File::EXCL | File::NOFOLLOW, 0o644) do |file|
  file.write(YAML.dump({"auth" => {"profiles" => profiles}})); file.flush; file.fsync
end
File.open(manifest_path + ".fixture", File::WRONLY | File::CREAT | File::EXCL | File::NOFOLLOW, 0o644) do |file|
  file.write(YAML.dump(manifest)); file.flush; file.fsync
end
File.rename(manifest_path + ".fixture", manifest_path)
puts "Protected fixture roles, runtime and scoped lease profiles configured."
