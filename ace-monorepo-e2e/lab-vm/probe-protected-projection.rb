# frozen_string_literal: true

require "etc"
require "fileutils"
require "json"
require "tmpdir"

version = ARGV.fetch(0)
abort "invalid version" unless version.match?(/\A[0-9A-Za-z.]+\z/)
abort "requires a provisioned disposable Linux VM" unless RUBY_PLATFORM.include?("linux") &&
  Process.euid.zero? && File.file?("/var/lib/ace-e2e/runtime-ready.sha256") && ENV["ACE_TOOLCHAIN"] == "installed"
gem "ace-lab", "= #{version}"
require "ace/lab"
require "ace/lab/molecules/extension_provisioner"
require "ace/lab/organisms/verify"

manifest = JSON.parse(File.read("/var/lib/ace-e2e/input/release-manifest.json"))
wake = manifest.fetch("gems").find { |entry| entry["name"] == "ace-wake" }
raise "missing pinned ace-wake" unless wake && wake.fetch("version").match?(/\A[0-9A-Za-z.]+\z/)
root = Dir.mktmpdir("protected-projection-probe-", "/opt/ace")
File.chmod(0o755, root)
passed = false
begin
  output = File.join(root, "extensions")
  input = {extensions: [{"gem" => "ace-wake", "path" => output, "account" => "mo"}],
           gems: [{"name" => "ace-wake", "version" => wake.fetch("version")}]}
  provisioner = Ace::Lab::Molecules::ExtensionProvisioner.new(gem_home: "/opt/ace/runtime/gems")
  report = provisioner.call(**input).fetch(0)
  raise "projection failed: #{report['message']}" unless report["status"] == "projected"
  files = report.fetch("files") + [Ace::Lab::Molecules::ExtensionProjection::RECEIPT_NAME]
  Ace::Lab::Molecules::ExtensionProjection.validate_protected_files!(output, files)
  verifier = Ace::Lab::Organisms::Verify.new
  verify = -> { verifier.send(:extension_reason, input.fetch(:extensions).fetch(0), input.fetch(:gems).fetch(0),
    "/opt/ace/runtime/gems", Etc.getpwnam("mo")) }
  raise "protected projection failed verification" unless verify.call.nil?
  executable = File.join(output, "ace-wake", "index.js")
  raise "managed extension is writable by mo" if system("/usr/sbin/runuser", "-u", "mo", "--", "/usr/bin/test", "-w", executable)

  user_path = "/home/mo/.pi/agent/extensions"
  refused = provisioner.call(**input.merge(extensions: [{"gem" => "ace-wake", "path" => user_path, "account" => "mo"}])).fetch(0)
  raise "user-controlled ancestor was accepted" unless refused["status"] == "failed" && refused.fetch("message").include?("not root-controlled")
  File.chown(Etc.getpwnam("mo").uid, Etc.getpwnam("mo").gid, executable)
  raise "agent-owned extension passed verification" unless verify.call.to_s.include?("not root-controlled")
  refused = provisioner.call(**input).fetch(0)
  raise "agent-owned extension was accepted" unless refused["status"] == "failed" && refused.fetch("message").include?("not root-controlled")
  puts "protected projection is root-owned; user-controlled ancestor and agent-owned file refused"
  passed = true
ensure
  if passed
    FileUtils.remove_entry_secure(root)
  else
    warn "probe failed; preserved #{root}"
  end
end
