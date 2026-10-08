# frozen_string_literal: true

# Copied outside the checkout and loaded only from an isolated GEM_HOME.
# This is a controlled one-host local-mode fixture, not a deployment policy.
require "ace/hitl"
require "ace/hitl/hermes/runtime"
require "ace/lab"
require "ace/assign"
require "ace/assign/organisms/attempt_coordinator"
require "ace/hitl/providers/lab/assignment_binding"
require "json"
require "fileutils"
require "open3"
require "rbconfig"
require "etc"
require "timeout"
require "digest"
require "securerandom"

class InstalledProposalScenario
  def initialize(root)
    @root = root
    @repo = File.join(root, "repo")
    @socket = File.join(root, "hitl.sock")
    @checks = 0
  end

  def path(name) = File.join(@root, name)
  def read(name) = JSON.parse(File.read(path(name)))
  def write(name, value) = File.write(path(name), JSON.pretty_generate(value))
  def clock = -> { Time.iso8601(read("clock.json")) }
  def check(value, message)
    raise message unless value
    @checks += 1
  end

  def git(*args)
    out, err, status = Open3.capture3("git", *args, chdir: @repo)
    raise err unless status.success?
    out.strip
  end

  def coordinator
    journal = Ace::Assign::Molecules::EvidenceJournal.new(repo_root: @repo, checkout_root: path("journal"))
    resolver = Ace::Assign::Molecules::ExecutionIdentityResolver.new(adapter: "local", caller_pid: Process.pid)
    Ace::Assign::Organisms::AttemptCoordinator.new(cache_base: path("cache"), repo_root: @repo,
      journal: journal, identity_resolver: resolver,
      lifecycle_exclusion: Ace::Assign::Molecules::LifecycleExclusion.new(root: path("exclusion")))
  end

  def client
    Ace::Hitl::Lifecycle::Client.new(socket_path: @socket, service_uid: Process.uid)
  end

  def service
    boundary = Ace::Hitl::Lifecycle::Service.new(root: path("hitl"), socket_path: @socket,
      binding: Ace::Hitl::Providers::Lab::AssignmentBinding.new(coordinator: coordinator),
      policy: Ace::Hitl::Lifecycle::GrantsPolicy.new(document: read("policy.json")),
      group: Etc.getgrgid(Process.gid).name, proposal_clock: clock)
    Signal.trap("TERM") { Thread.new { boundary.stop } }
    boundary.run
  end

  def actor
    root = @root
    adapter = Object.new
    adapter.define_singleton_method(:updates) do |**|
      raise IOError, "fixture ingress unavailable" if File.exist?(File.join(root, "poll-failed"))
      File.open(File.join(root, "polls"), "a") { |file| file.puts(JSON.parse(File.read(File.join(root, "clock.json")))) }
      []
    end
    adapter.define_singleton_method(:call) do |channel, _|
      raise Ace::Hitl::Hermes::Transport::SubmitFailed if File.exist?(File.join(root, "submit-failed"))
      File.open(File.join(root, "submissions"), "a") { |file| file.puts("acknowledged") }
      {"success" => true, "chat_id" => channel.fetch("chat_id"), "message_id" => "100"}
    end
    runtime = Ace::Hitl::Hermes::Runtime.new(path("runtime.json"), clock: clock)
    runtime.define_singleton_method(:telegram) { adapter }
    runtime.serve(once: true)
  end

  def invoke_actor(success: true)
    out, status = Open3.capture2e(RbConfig.ruby, __FILE__, "actor", @root, chdir: @root)
    check(status.success? == success, "actor terminal mismatch: #{out}")
    check(out.include?("Telegram poll unavailable; ingress coverage is unknown"), "actor failed for an unrelated reason: #{out}") unless success
  end

  def start_service
    @service_pid = Process.spawn(RbConfig.ruby, __FILE__, "service", @root,
      chdir: @root, out: path("service.log"), err: [:child, :out])
    Timeout.timeout(10) do
      loop do
        begin
          return if client.ping
        rescue Ace::Hitl::Lifecycle::Error
          raise "service exited: #{File.read(path('service.log'))}" if Process.waitpid(@service_pid, Process::WNOHANG)
          sleep 0.02
        end
      end
    end
  end

  def stop_service
    return unless @service_pid
    Process.kill("TERM", @service_pid)
    _, status = Timeout.timeout(10) { Process.wait2(@service_pid) }
    @service_pid = nil
    check(status.success?, "HITL service exited unsuccessfully: #{File.read(path('service.log'))}")
  end

  def executor
    input = JSON.parse(STDIN.read)
    request = input.fetch("request")
    File.open(path("effects"), "a", 0600) { |file| file.puts(request.fetch("request_id")) }
    content = "ace-service-attestation request:#{request.fetch('request_id')} input:#{request.fetch('input_digest')} outcome:succeeded\n"
    FileUtils.mkdir_p(File.join(@repo, "fixture"))
    File.write(File.join(@repo, "fixture/receipt"), content, mode: "w", perm: 0600)
    puts JSON.generate("request_id" => request.fetch("request_id"), "input_digest" => request.fetch("input_digest"),
      "outcome" => "succeeded", "evidence" => [{"ref" => "fixture/receipt", "sha256" => Digest::SHA256.hexdigest(content)}])
  end

  def service_request(owner)
    policy = Ace::Lab::Molecules::ServicePolicy.new(read("policy.json"),
      ->(reference, exact) { owner.proposal_authorization(reference, exact) })
    Ace::Lab::Organisms::ServiceRequestService.new(repo_root: @repo, coordinator: owner, policy: policy,
      topology: Ace::Lab::Organisms::TopologyService.from_config(read("topology.json")))
  end

  def run
    FileUtils.mkdir_p(@repo)
    git("init", "-b", "main")
    git("-c", "user.name=fixture", "-c", "user.email=fixture@example.invalid", "commit", "--allow-empty", "-m", "candidate")
    owner = coordinator
    manager = Ace::Assign::Molecules::AssignmentManager.new(cache_base: path("cache"))
    assignment = manager.create(name: "installed-sc3", source_config: "fixture", task_id: "8wr.t.qjz", project_id: "ace")
    attempt = owner.start(assignment_id: assignment.id, step: "010", project_id: "ace")
    check(owner.runtime_binding(attempt_id: attempt.attempt_id, caller_pid: Process.pid)["runtime"] == "tmux", "real local runtime binding missing")
    input = {"target" => {"resource" => "controlled-fixture"}, "args" => {"mode" => "sync"}}
    write("input.json", input)
    write("clock.json", "2026-10-05T01:00:00Z")
    write("policy.json", {"hitl" => {"proposal_uids" => [Process.uid], "transport_uids" => [Process.uid], "service_uid" => Process.uid},
      "authorization" => {"principals" => {Process.uid.to_s => {"projects" => ["ace"]}}},
      "operations" => {"forge-sync" => {"project" => "ace", "service_id" => "fixture-service", "transport" => "local",
        "argv" => [RbConfig.ruby, __FILE__, "executor", @root], "executor_uid" => Process.uid,
        "lease_expires_at" => (Time.now.utc + 3600).iso8601}}})
    principal = Ace::Lab::Molecules::CallerAuthorizer.local_identity.first
    write("topology.json", {"schema_version" => 1, "authorization" => {"principals" => {principal => {"projects" => ["ace"]}}},
      "topology" => {"projects" => [{"id" => "ace"}], "agents" => [], "services" => [{"id" => "fixture-service", "project" => "ace",
        "capabilities" => ["forge-sync"], "default_for" => ["forge-sync"], "endpoint" => {"kind" => "http", "url" => "http://127.0.0.1:1/fixture"},
        "binding" => {"kind" => "service", "state" => "active", "instance_id" => "fixture", "attested_instance_id" => "fixture"}}]}})
    FileUtils.mkdir_p(path("inbox"), mode: 0750)
    write("registry.json", {"schema" => "ace.hitl.hermes.channels/v1", "channels" => [{"name" => "fixture", "machine" => "local",
      "folder" => path("inbox"), "target" => "overseer", "projects" => ["ace"], "chat_id" => "-424242", "captain_user_ids" => ["42"]}]})
    File.write(path("gateway.yml"), "platforms:\n  telegram:\n    enabled: false\n")
    write("runtime.json", {"schema" => "ace.hitl.hermes.runtime/v1", "registry" => path("registry.json"), "state" => path("hermes"),
      "hitl_socket" => @socket, "hitl_service_uid" => Process.uid, "hermes_gateway_config" => path("gateway.yml"), "polling_owner" => "ace-hitl-hermes"})
    start_service
    document = {"operation" => "forge-sync", "target" => Ace::Lab::Atoms::ServiceInput.target(input), "candidate_head" => git("rev-parse", "HEAD"),
      "input_digest" => Ace::Lab::Atoms::ServiceInput.digest(input), "context" => "Installed controlled SC3", "options" => ["yes", "no"],
      "recommendation" => "yes", "prerequisites" => ["fixed fixture executor and exact candidate"]}
    id = "proposal-#{SecureRandom.hex(12)}"
    args = {id: id, assignment: assignment.id, attempt: attempt.attempt_id, project: "ace", document: document}
    initial = client.proposal_create(**args)
    check(initial["state"] == "awaiting-delivery" && !initial.key?("deadline"), "creation armed unconfirmed deadline")
    check(Dir.empty?(path("inbox")), "proposal creation manually populated transport")
    File.write(path("submit-failed"), "fixture")
    invoke_actor
    check(!client.proposal_show(id, project: "ace").key?("deadline"), "failed submission armed deadline")
    File.unlink(path("submit-failed"))
    invoke_actor
    armed = client.proposal_show(id, project: "ace")
    check(armed["state"] == "awaiting-decision", "acknowledgement did not arm proposal")
    check(armed["deadline"] == "2026-10-05T17:00:00Z", "deadline differs from confirmed +16h")
    check(File.readlines(path("submissions")).size == 1, "unexpected submissions")
    stop_service
    start_service
    check(client.proposal_create(**args)["deadline"] == armed["deadline"], "creation retry reset deadline")
    write("clock.json", "2026-10-05T16:59:59Z")
    check(Ace::Hitl::Proposals::Evaluator.new(boundary: client, project: "ace").call.empty?, "premature due wake")
    invoke_actor
    check(client.proposal_show(id, project: "ace")["decision_state"] == "awaiting-decision", "approved before deadline")
    write("clock.json", armed["deadline"])
    wake = Ace::Hitl::Proposals::Evaluator.new(boundary: client, project: "ace").call
    check(wake.first["status"] == "queued-for-transport", "due wake bypassed transport")
    invoke_actor
    decision = client.proposal_show(id, project: "ace")
    check(decision["decision_state"] == "approved-by-silence", "post-poll deadline did not resolve")
    check(decision["deadline"] == armed["deadline"], "restart changed deadline")
    request = {project: "ace", assignment: assignment.id, attempt: attempt.attempt_id, operation: "forge-sync",
      input_path: path("input.json"), authorization: decision["authorization"], request_id: "sc3-effect"}
    write("changed-input.json", input.merge("target" => {"resource" => "different-scope"}))
    invalid = service_request(owner).request(**request.merge(input_path: path("changed-input.json"),
      request_id: "sc3-invalid", dry_run: true))
    check(invalid.dig("error", "code") == "unauthorized", "silence bypassed exact technical scope: #{invalid}")
    check(!File.exist?(path("effects")), "technical refusal executed effect")
    check(owner.service_request_status("sc3-invalid").nil?, "preview consumed effect authorization")
    result = service_request(owner).request(**request)
    check(result.dig("data", "outcome") == "succeeded", "real service effect failed: #{result}")
    stop_service
    start_service
    invoke_actor
    check(Ace::Hitl::Proposals::Evaluator.new(boundary: client, project: "ace").call.empty?, "resolved proposal repeated wake")
    check(service_request(coordinator).request(**request).dig("data", "outcome") == "succeeded", "receipt replay failed")
    check(File.readlines(path("effects"), chomp: true) == ["sc3-effect"], "effect replayed")
    check(File.readlines(path("submissions")).size == 1, "restart resent acknowledged proposal")
    check(client.proposal_show(id, project: "ace")["state"] == "succeeded", "actual outcome projection missing")
    claims = owner.send(:journal_for).proposal_claims(decision["revision_id"])
    check(claims.length == 1 && claims.first["state"] == "succeeded", "canonical claim/receipt duplicated")
    check(claims.first.dig("receipt", "executor_uid") == Process.uid, "receipt identity differs")
    # A separate decision demonstrates the conservative coverage-loss gate:
    # healthy polling afterward cannot fabricate coverage before the failure.
    blocked_id = "proposal-#{SecureRandom.hex(12)}"
    client.proposal_create(**args.merge(id: blocked_id))
    invoke_actor
    blocked = client.proposal_show(blocked_id, project: "ace")
    write("clock.json", blocked.fetch("deadline"))
    Ace::Hitl::Proposals::Evaluator.new(boundary: client, project: "ace").call
    File.write(path("poll-failed"), "fixture")
    invoke_actor(success: false)
    check(client.proposal_show(blocked_id, project: "ace")["decision_state"] == "awaiting-decision", "failed poll authorized silence")
    File.unlink(path("poll-failed"))
    invoke_actor
    check(client.proposal_show(blocked_id, project: "ace")["decision_state"] == "awaiting-decision", "fresh poll invented lost coverage")
    check(owner.send(:journal_for).proposal_claims(blocked["revision_id"]).empty?, "unhealthy proposal consumed authority")
    write("canonical-evidence.json", {"proposal" => client.proposal_show(id, project: "ace"), "claims" => claims,
      "blocked_proposal" => client.proposal_show(blocked_id, project: "ace"), "ref" => owner.send(:journal_for).ref_value,
      "native_binding" => owner.runtime_binding(attempt_id: attempt.attempt_id, caller_pid: Process.pid)})
    {"success" => true, "checks" => @checks, "effect_count" => 1, "window_seconds" => 16 * 3600,
      "outcome" => "succeeded", "decision" => decision["decision_state"],
      "loaded_specs" => Gem.loaded_specs.values.map { |s| {"name" => s.name, "version" => s.version.to_s, "path" => s.full_gem_path, "default" => s.default_gem?} },
      "features" => $LOADED_FEATURES}
  ensure
    stop_service
  end
end

mode, root = ARGV
record_process = lambda do |phase|
  File.open(File.join(root, "processes.jsonl"), "a", 0600) do |file|
    file.flock(File::LOCK_EX)
    file.puts(JSON.generate("mode" => mode, "phase" => phase, "pid" => Process.pid, "uid" => Process.uid,
      "identity" => Ace::Runtime::Molecules::ProcessIdentity.new.capture(Process.pid),
      "gem_paths" => Gem.loaded_specs.values.reject(&:default_gem?).map(&:full_gem_path),
      "loaded_specs" => Gem.loaded_specs.values.map { |spec| {"name" => spec.name, "version" => spec.version.to_s,
        "path" => spec.full_gem_path, "default" => spec.default_gem?} }, "features" => $LOADED_FEATURES))
  end
end
record_process.call("start")
at_exit do
  record_process.call("exit")
  File.write(File.join(root, "completed"), "consumer exited\n") if mode == "main"
end
scenario = InstalledProposalScenario.new(root)
if mode == "main"
  begin
    result = scenario.run
  rescue Exception => error
    result = {"success" => false, "error" => "#{error.class}: #{error.message}", "backtrace" => error.backtrace}
  ensure
    File.write(File.join(root, "result.json"), JSON.pretty_generate(result))
  end
  exit(result["success"] ? 0 : 1)
else
  scenario.public_send(mode)
end
