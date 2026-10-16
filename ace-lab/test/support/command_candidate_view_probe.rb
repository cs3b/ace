# frozen_string_literal: true
# Source-only Linux root I/O fixture. Installed policy/runtime are controlled;
# tiny runner is NOT ace-test, no owner/journal/test proof is manufactured.
require "ace/lab/organisms/command_candidate_view"
require "rbconfig"
require "etc"
require "open3"

def git(directory, *arguments)
  output, error, status = Open3.capture3({"GIT_CONFIG_GLOBAL" => "/dev/null", "GIT_CONFIG_NOSYSTEM" => "1", "GIT_OPTIONAL_LOCKS" => "0"},
    "/usr/bin/git", "-C", directory, *arguments)
  raise "fixture Git failed: #{error}" unless status.success?
  output
end

Dir.mktmpdir("ace-candidate-view-source-only-", "/run") do |root|
  File.chmod(0o755, root)
  repository, views, runtime = %w[repository views runtime].map { |part| File.join(root, part) }
  FileUtils.mkdir_p([repository, views, runtime], mode: 0o755)
  package = File.join(repository, "fixture-source")
  FileUtils.mkdir_p(File.join(package, "lib"), mode: 0o755)
  File.write(File.join(package, "lib", "value.rb"), "FIXTURE_VALUE = 1\n")
  File.symlink("lib/value.rb", File.join(package, "alias"))
  File.write(File.join(package, "fixture-source.gemspec"), <<~RUBY)
    raise "candidate evaluated as root" if Process.uid.zero?
    File.write(File.join(ENV.fetch("TMPDIR"), "evaluated-uid"), Process.uid.to_s)
    Gem::Specification.new do |spec|
      spec.name = "fixture-source"
      spec.version = "1.0.0"
      spec.summary = "Source-only controlled fixture"
      spec.authors = ["fixture"]
      spec.files = ["lib/value.rb"]
    end
  RUBY
  git(repository, "init", "-b", "main")
  git(repository, "add", ".")
  git(repository, "-c", "user.name=fixture", "-c", "user.email=fixture@example.invalid", "commit", "-m", "fixture")
  head, tree = git(repository, "rev-parse", "HEAD", "HEAD^{tree}").lines.map(&:strip)
  bundle = File.join(root, "candidate.bundle")
  git(repository, "bundle", "create", bundle, "refs/heads/main")
  bytes = File.binread(bundle)
  gem_home = File.join(runtime, "gems")
  %w[cache specifications gems/fixture-runtime-1.0.0/lib].each { |path| FileUtils.mkdir_p(File.join(gem_home, path), mode: 0o755) }
  # This tests root trust/inventory/digest checks, not archive installation.
  archive = File.join(gem_home, "cache", "fixture-runtime-1.0.0.gem")
  File.write(archive, "source-only fixture archive bytes")
  File.write(File.join(gem_home, "specifications", "fixture-runtime-1.0.0.gemspec"), <<~RUBY)
    Gem::Specification.new do |spec|
      spec.name = "fixture-runtime"
      spec.version = "1.0.0"
      spec.summary = "Controlled installed-boundary fixture"
      spec.authors = ["fixture"]
    end
  RUBY
  runner = File.join(runtime, "source-only-probe.rb")
  File.write(runner, <<~'RUBY')
    require "bundler"
    Bundler.ui.silence { require "bundler/setup" }
    denied = false
    begin
      File.write("lib/value.rb", "modified")
    rescue Errno::EACCES
      denied = true
    end
    File.write(File.join(ENV.fetch("TMPDIR"), "writable"), "output")
    puts [Process.uid, denied, Gem.loaded_specs.fetch("fixture-source").full_gem_path,
      ENV.fetch("BUNDLE_GEMFILE")].join("\t")
  RUBY
  File.chmod(0o555, runner)
  profile = {"schema" => "ruby-test-runtime/v1", "gem_paths" => [gem_home],
    "gems" => {"fixture-runtime" => {"version" => "1.0.0", "sha256" => Digest::SHA256.file(archive).hexdigest}},
    "source_gems" => {"fixture-source" => "fixture-source"}, "package" => "fixture-source",
    "argv" => [RbConfig.ruby, runner, "--config-path", "@configuration", "--report-dir", "@output"],
    "executable_sha256" => Digest::SHA256.file(RbConfig.ruby).hexdigest, "entrypoint_sha256" => Digest::SHA256.file(runner).hexdigest}
  profile_path = File.join(root, "runtime.json")
  File.write(profile_path, JSON.generate(profile))
  account = Etc.getpwnam("nobody")
  recipe = {"kind" => "ordinary-candidate", "root" => views, "runtime_path" => profile_path, "runtime_sha256" => Digest::SHA256.file(profile_path).hexdigest}
  reference = {"assignment_id" => "fixture-only", "attempt_id" => "not-an-admission", "candidate_generation" => 1, "acceptance_event_digest" => "a" * 64}
  selection = {"argv" => ["source-only-fixture"], "executor" => nil, "services" => nil, "pane" => nil, "candidate" => reference}
  document = {"version" => 1, "projects" => {"fixture" => {
    "launcher" => {"socket_path" => "/run/unused-source-only.sock", "identity_path" => "/run/unused-source-only.json"},
    "default_executor" => "fixture", "default_services" => [], "services" => {},
    "executors" => {"fixture" => {"uid" => account.uid, "gid" => account.gid, "groups" => [], "home" => "/nonexistent",
      "cwd" => "/unused-source-only", "path" => ["/usr/bin", "/bin"], "environment" => {}}},
    "commands" => {"fixture" => {"purpose" => "test", "argv" => selection.fetch("argv"),
      "executable_sha256" => profile.fetch("executable_sha256"), "source" => recipe}},
    "grants" => [{"kind" => "operator", "uid" => account.uid, "command" => "fixture", "executor" => "fixture", "services" => []}]}}}
  policy = Ace::Lab::Molecules::CommandPolicy.new(document, project: "fixture")
  selected = policy.select(selection: selection, peer: {"uid" => account.uid})
  candidate = {"head" => head, "tree" => tree, "sha256" => Digest::SHA256.hexdigest(bytes), "bytes" => bytes.bytesize,
    "candidate_generation" => 1, "bundle_ref" => "fixture-only/no-canonical-reference", "reference" => reference}
  compiler = Ace::Lab::Molecules::CommandTestRuntime.load(recipe)
  definition = compiler.compile(definition: selected, execution_id: "source-only", candidate: candidate)
  view = Ace::Lab::Organisms::CommandCandidateView.new(project: "fixture", definition: definition, policy_loader: -> { policy })
  view.prepare! { |_scratch| bytes }
  result = {"scope" => "source-only-controlled-runtime-no-canonical-proof"}
  output_root = File.join(views, "source-only", "output")
  read, write = IO.pipe
  child = fork do
    read.close
    $stdout.reopen(write)
    $stderr.reopen(write)
    write.close
    Process.groups = []
    Process::GID.change_privilege(account.gid)
    Process::UID.change_privilege(account.uid)
    Dir.chdir(definition.dig("executor", "cwd"))
    exec(definition.dig("executor", "environment"), *definition.fetch("argv"), unsetenv_others: true)
  end
  write.close
  child_output = read.read
  read.close
  _, status = Process.waitpid2(child)
  raise "source-only dropped fixture failed: #{child_output}" unless status.success?
  child_uid, source_denied, source_spec, bundle_path = child_output.strip.split("\t", 4)
  result["child"] = {"uid" => Integer(child_uid, 10), "source_denied" => source_denied == "true", "source_spec" => source_spec, "bundle" => bundle_path}
  result["evaluated_uid"] = Integer(File.read(File.join(output_root, "tmp", "evaluated-uid")), 10)
  result["lock_bytes"] = File.size(File.join(output_root, "Gemfile.lock"))
  result["config_owner"] = File.lstat(File.join(views, "source-only", "config", "Gemfile.lock")).uid
  result["lock_owner"] = File.stat(File.join(output_root, "Gemfile.lock")).uid
  result["alias"] = File.readlink(File.join(views, "source-only", "source", "fixture-source", "alias"))
  result["clean"] = git(File.join(views, "source-only", "source"), "status", "--porcelain").empty?
  result["link_denied"] = []
  {"dangling" => "lib/missing.rb", "escaping" => "/etc/passwd"}.each do |kind, target|
    File.unlink(File.join(package, "alias"))
    File.symlink(target, File.join(package, "alias"))
    git(repository, "add", ".")
    git(repository, "-c", "user.name=fixture", "-c", "user.email=fixture@example.invalid", "commit", "-m", "unsafe #{kind}")
    changed_head, changed_tree = git(repository, "rev-parse", "HEAD", "HEAD^{tree}").lines.map(&:strip)
    File.unlink(bundle)
    git(repository, "bundle", "create", bundle, "refs/heads/main")
    changed_bytes = File.binread(bundle)
    changed_candidate = candidate.merge("head" => changed_head, "tree" => changed_tree,
      "sha256" => Digest::SHA256.hexdigest(changed_bytes), "bytes" => changed_bytes.bytesize)
    changed_definition = compiler.compile(definition: selected, execution_id: "source-only-#{kind}", candidate: changed_candidate)
    begin
      Ace::Lab::Organisms::CommandCandidateView.new(project: "fixture", definition: changed_definition,
        policy_loader: -> { policy }).prepare! { changed_bytes }
    rescue Ace::Assign::AttemptErrors::ReceiptRejected
      result["link_denied"] << kind
    end
  end
  result["runtime_denied"] = []
  File.chmod(0o666, archive)
  begin
    compiler.verify_installed!
  rescue Ace::Lab::InvalidConfigurationError
    result["runtime_denied"] << "writable"
  ensure
    File.chmod(0o644, archive)
  end
  File.write(File.join(gem_home, "specifications", "undeclared-1.0.0.gemspec"), "unloaded")
  begin
    compiler.verify_installed!
  rescue Ace::Lab::InvalidConfigurationError
    result["runtime_denied"] << "undeclared"
  end
  puts JSON.generate(result)
end
