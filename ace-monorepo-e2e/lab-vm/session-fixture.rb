# frozen_string_literal: true
# Trusted fixture configuration only. Product installation remains ace-lab install.
require "yaml"
require "json"
require "fileutils"
require "etc"
require "ace/lab/auth"
raise "fixture configuration requires root" unless Process.uid.zero?
run_id, vm_uuid = ARGV
raise "fixture identity is required" unless ARGV.length == 2 && run_id.match?(/\A[a-f0-9]{16}\z/) &&
  vm_uuid.match?(/\A[0-9a-fA-F-]{36}\z/)
manifest_path = "/etc/lab/ace-lab/install.yml"
authorization_path = "/etc/lab/ace-lab/authorization.yml"
raise "authorization already exists" if File.exist?(authorization_path) || File.symlink?(authorization_path)
stat = File.lstat(manifest_path)
raise "unsafe deployment manifest" unless stat.file? && stat.uid.zero? && (stat.mode & 0o7777) == 0o644
manifest = YAML.safe_load_file(manifest_path, permitted_classes: [], aliases: false)
raise "fixture is already configured" if %w[projects grants coordinator session_runtime].any? { |key| manifest.key?(key) }
baseline = "/var/lib/ace-e2e/install-base.yml"
raise "fixture baseline already exists" if File.exist?(baseline) || File.symlink?(baseline)
File.open(baseline, File::WRONLY | File::CREAT | File::EXCL | File::NOFOLLOW, 0o600) { |file| file.write(File.read(manifest_path)) }
release = JSON.parse(File.read("/var/lib/ace-e2e/input/release-manifest.json"))
manifest["projects"] = [{"id" => "ace", "path" => "/lab/ace",
  "remote" => "http://127.0.0.1:3000/e2e-integrator/ace.git", "label" => "ACE E2E fixture"}]
manifest["coordinator"] = {"id" => "lab", "path" => "/lab"}
manifest["grants"] = {"mo" => %w[lab ace]}
manifest["roles"] = {"worker" => "coworker/worker", "verifier" => "coworker/reviewer",
  "integrator" => "coworker/integrator", "project-overseer" => "overseer/start", "lab-overseer" => "overseer/lab-start"}
  .map { |role, guide| {"id" => role, "account" => "mo", "instructions" => "wfi://#{guide}"} }
manifest["session_runtime"] = {
  "node" => "/opt/ace/toolchains/node-v#{release.fetch('node').fetch('version')}-linux-arm64/bin/node",
  "pi" => "/opt/ace/runtime/pi/node_modules/@earendil-works/pi-coding-agent/dist/cli.js",
  "path" => ["/opt/ace/runtime/bin", "/opt/ace/runtime/pi/node_modules/.bin",
    "/opt/ace/toolchains/ruby-#{release.fetch('ruby').fetch('version')}/bin",
    "/opt/ace/toolchains/node-v#{release.fetch('node').fetch('version')}-linux-arm64/bin", "/usr/bin"],
  "provider" => "zai", "model" => "glm-5.3-flash", "credentials" => "/etc/lab/ace-lab/pi-auth.json",
  "herdr" => {"account" => "mo", "socket" => "/run/lab/herdr/herdr.sock"}}
# Provision ready, repository-restricted role credentials once. The source
# password belongs to fixture setup; no auth service or root agent is needed.
password = File.read("/run/ace-e2e-forgejo/e2e-admin.password")[/password\s+is\s+'([^']+)'/i, 1]
raise "Forgejo generated password is unavailable" unless password
secret_path = "/run/ace-e2e-forgejo/issuer-password"
File.open(secret_path, File::WRONLY | File::CREAT | File::EXCL | File::NOFOLLOW, 0o600) { |file| file.write(password) }
profiles = {
  "e2e-worker" => ["worker", "e2e-worker", %w[write:repository write:issue]],
  "e2e-reviewer" => ["verifier", "e2e-reviewer", %w[write:repository read:issue]],
  "e2e-integrator" => ["integrator", "e2e-integrator", %w[write:repository write:issue]],
  "e2e-overseer" => ["project-overseer", "e2e-integrator", %w[read:repository write:issue]],
  "e2e-lab-overseer" => ["lab-overseer", "e2e-integrator", %w[read:repository read:issue]]
}.to_h do |name, (role, account, scopes)|
  [name, {"provider" => "forgejo", "roles" => [role], "principals" => ["mo"],
    "repos" => ["e2e-integrator/ace"], "scopes" => scopes, "ttl_minutes" => 5,
    "issuer" => {"url" => "http://127.0.0.1:3000", "account" => account,
      "admin_username" => "e2e-admin", "password_file" => secret_path}}]
end
account = Etc.getpwnam("mo")
provider = Ace::Lab::Auth::Plugins::ForgejoProvider.new
%w[/home/mo /home/mo/.config /home/mo/.config/ace-e2e /home/mo/.config/ace-e2e/roles].each do |path|
  raise "symlink in fixture credential directory" if File.symlink?(path)
end
environment_files = profiles.to_h do |name, profile|
  role = profile.fetch("roles").first
  directory = "/home/mo/.config/ace-e2e/roles/#{role}"
  raise "role environment already exists" if File.exist?(directory) || File.symlink?(directory)
  FileUtils.mkdir_p(directory, mode: 0o700)
  credential = provider.issue(profile: profile, lease: {"id" => "fixture-#{run_id}-#{role}",
    "repos" => ["e2e-integrator/ace"]}).fetch("token")
  token_path = File.join(directory, "token")
  File.open(token_path, File::WRONLY | File::CREAT | File::EXCL | File::NOFOLLOW, 0o600) { |file| file.write(credential) }
  login = File.join(directory, "forgejo-cli")
  Dir.mkdir(login, 0o700)
  File.open(File.join(login, "keys.json"), File::WRONLY | File::CREAT | File::EXCL | File::NOFOLLOW, 0o600) do |file|
    file.write(JSON.generate({"hosts" => {"127.0.0.1:3000" => {"type" => "Application", "token" => credential}},
      "aliases" => {}, "default_ssh" => []}))
  end
  environment = {"XDG_DATA_HOME" => directory, "ACE_LAB_CREDENTIAL_FILE" => token_path, "LC_ALL" => "C.UTF-8", "GIT_ASKPASS" => Ace::Lab::Auth::Plugins::ForgejoProvider::ASKPASS,
    "GIT_TERMINAL_PROMPT" => "0", "GIT_CONFIG_COUNT" => "2",
    "GIT_CONFIG_KEY_0" => "credential.helper", "GIT_CONFIG_VALUE_0" => "",
    "GIT_CONFIG_KEY_1" => "credential.useHttpPath", "GIT_CONFIG_VALUE_1" => "false",
    "ACE_LAB_FORGEJO_ORIGIN" => "http://127.0.0.1:3000", "ACE_LAB_FORGEJO_SCHEME" => "http",
    "ACE_LAB_FORGEJO_AUTHORITY" => "127.0.0.1:3000", "ACE_LAB_FORGEJO_ACCOUNT" => profile.fetch("issuer").fetch("account")}
  path = File.join(directory, "environment.json")
  File.open(path, File::WRONLY | File::CREAT | File::EXCL | File::NOFOLLOW, 0o600) { |file| file.write(JSON.generate(environment)) }
  [role, path]
end
FileUtils.chown_R(account.uid, account.gid, "/home/mo/.config/ace-e2e")
manifest["projects"].first["environment_files"] = environment_files.reject { |role, _| role == "lab-overseer" }
manifest["coordinator"]["environment_files"] = environment_files.slice("lab-overseer")
# Public temporary-lease checks run as the operator, with a private source.
# Agent roles only receive the ready scoped tokens above.
operator = Etc.getpwnam("lab-operator")
probe_root = "/home/lab-operator/.ace-e2e-auth"
raise "operator probe already exists" if File.exist?(probe_root) || File.symlink?(probe_root)
Dir.mkdir(probe_root, 0o700)
probe_secret = File.join(probe_root, "issuer-password")
File.open(probe_secret, File::WRONLY | File::CREAT | File::EXCL | File::NOFOLLOW, 0o600) { |file| file.write(password) }
FileUtils.chown_R(operator.uid, operator.gid, probe_root)
probe_profile = profiles.fetch("e2e-integrator").merge("roles" => ["worker"], "principals" => ["lab-operator"],
  "issuer" => profiles.fetch("e2e-integrator").fetch("issuer").merge("password_file" => probe_secret))
authorization = {"auth" => {"leases_dir" => File.join(probe_root, "leases"),
  "credentials_dir" => File.join(probe_root, "credentials"), "profiles" => {"e2e-probe" => probe_profile}}}
File.open(authorization_path, File::WRONLY | File::CREAT | File::EXCL | File::NOFOLLOW, 0o644) do |file|
  file.write(YAML.dump(authorization)); file.flush; file.fsync
end
File.open(manifest_path + ".fixture", File::WRONLY | File::CREAT | File::EXCL | File::NOFOLLOW, 0o644) do |file|
  file.write(YAML.dump(manifest)); file.flush; file.fsync
end
File.rename(manifest_path + ".fixture", manifest_path)
File.open("/var/lib/ace-e2e/fixture-run.json", File::WRONLY | File::CREAT | File::EXCL | File::NOFOLLOW, 0o600) do |file|
  file.write(JSON.generate({"run_id" => run_id, "vm_uuid" => vm_uuid}))
end
puts "Fixture roles, installed runtime and repository-scoped environment files configured."
