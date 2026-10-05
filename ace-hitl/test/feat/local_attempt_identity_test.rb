# frozen_string_literal: true

require_relative "../test_helper"
require "ace/assign"
require "ace/assign/organisms/attempt_coordinator"
require "ace/hitl/providers/lab/assignment_binding"
require "open3"
require "socket"
require "etc"

# Actual kernel Unix peer, canonical Assign ownership and the existing HITL
# binding consumer. Native reverse-address/installed policy proof is separate.
class LocalAttemptIdentityTest < AceHitlTestCase
  def git(repo, *args)
    out, err, status = Open3.capture3("git", *args, chdir: repo)
    raise err unless status.success?
    out.strip
  end

  def test_unix_peer_owns_real_local_attempt_despite_foreign_terminal_login
    Dir.mktmpdir("local-attempt-identity", "/tmp") do |dir|
      repo = File.join(dir, "repo")
      FileUtils.mkdir_p(repo)
      git(repo, "init", "-b", "main")
      git(repo, "-c", "user.name=test", "-c", "user.email=test@test", "commit", "--allow-empty", "-m", "base")
      cache = File.join(dir, "cache")
      manager = Ace::Assign::Molecules::AssignmentManager.new(cache_base: cache)
      assignment = manager.create(name: "local-identity", source_config: "job.yaml", task_id: "8x4.t.5qv",
        project_id: "ace")
      coordinator = Ace::Assign::Organisms::AttemptCoordinator.new(cache_base: cache, repo_root: repo,
        journal: Ace::Assign::Molecules::EvidenceJournal.new(repo_root: repo, checkout_root: File.join(dir, "journal")),
        identity_resolver: Ace::Assign::Molecules::ExecutionIdentityResolver.new(adapter: "local"),
        lifecycle_exclusion: Ace::Assign::Molecules::LifecycleExclusion.new(root: File.join(dir, "exclusion")))
      attempt = Etc.stub(:getlogin, "foreign-terminal-login") do
        coordinator.start(assignment_id: assignment.id, step: "010", project_id: "ace")
      end
      binding = Ace::Hitl::Providers::Lab::AssignmentBinding.new(coordinator: coordinator)
      service = Ace::Hitl::Lifecycle::Service.new(root: File.join(dir, "hitl"), binding: binding,
        policy: nil, socket_path: File.join(dir, "hitl.sock"))
      UNIXSocket.pair do |client, accepted|
        client.write("actual-peer")
        assert_equal "actual-peer", accepted.read(11)
        peer = service.send(:authenticate!, accepted)
        assert_equal Process.euid, peer.uid
        assert_equal Etc.getpwuid(Process.euid).name, peer.username
        assert_equal peer.username, attempt.binding.actor
        allowed = false
        binding.with_active(assignment: assignment.id, attempt: attempt.attempt_id, project: "ace",
          requester: peer.username) { allowed = true }
        assert allowed, "authenticated same-account peer must own the local attempt"
        assert_raises(Ace::Hitl::Lifecycle::EndedAttemptError) do
          binding.with_active(assignment: assignment.id, attempt: attempt.attempt_id, project: "ace",
            requester: "foreign-terminal-login") { flunk "foreign account was admitted" }
        end
        assert_equal peer.username, coordinator.store.find(attempt.attempt_id).binding.actor
      end
    end
  end
end
