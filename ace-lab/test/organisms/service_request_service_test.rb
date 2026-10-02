# frozen_string_literal: true

require_relative "../test_helper"
require "open3"

module Ace
  module Lab
    class ServiceRequestServiceTest < Minitest::Test
      def git(dir, *args)
        out, err, status = Open3.capture3("git", *args, chdir: dir)
        raise "git failed: #{err}" unless status.success?
        out.strip
      end

      def setup_fixture(dir)
        repo = File.join(dir, "repo")
        FileUtils.mkdir_p(repo)
        git(repo, "init", "-b", "main")
        git(repo, "config", "user.name", "test")
        git(repo, "config", "user.email", "test@example.com")
        File.write(File.join(repo, "README.md"), "candidate")
        git(repo, "add", "README.md")
        git(repo, "commit", "-m", "candidate")
        head = git(repo, "rev-parse", "HEAD")

        config = authorized_for_local(topology_config, ["atlas"])
        service = config["topology"]["services"].find { |entry| entry["id"] == "atlas-search" }
        service["capabilities"] = ["forge-sync"]
        service["default_for"] = ["forge-sync"]
        topology = Organisms::TopologyService.from_config(config)

        cache = File.join(dir, "cache")
        manager = Ace::Assign::Molecules::AssignmentManager.new(cache_base: cache)
        assignment = manager.create(name: "service-test", source_config: "job.yaml", task_id: "8wr.t.qjx",
          project_id: "atlas")
        journal = Ace::Assign::Molecules::EvidenceJournal.new(repo_root: repo,
          checkout_root: File.join(dir, "journal"))
        coordinator = Ace::Assign::Organisms::AttemptCoordinator.new(cache_base: cache, repo_root: repo,
          journal: journal, lifecycle_exclusion: Ace::Assign::Molecules::LifecycleExclusion.new(
            root: File.join(dir, "exclusion")))
        attempt = coordinator.start(assignment_id: assignment.id, step: "010", project_id: "atlas")

        input = {"target" => {"resource" => "forge/repository"}, "args" => {"mode" => "sync"}}
        input_path = File.join(dir, "input.json")
        File.write(input_path, JSON.generate(input))
        binding = {"operation" => "forge-sync", "project_id" => "atlas",
          "assignment_id" => assignment.id, "attempt_id" => attempt.attempt_id,
          "input_digest" => Atoms::ServiceInput.digest(input),
          "target" => Atoms::ServiceInput.target(input), "candidate_head" => head,
          "caller_uid" => Process.uid}
        operation = {"project" => "atlas", "service_id" => "atlas-search", "transport" => "unix",
          "socket_path" => File.join(dir, "service.sock"), "executor_uid" => Process.uid,
          "lease_expires_at" => (Time.now.utc + 3600).iso8601}
        policy = Molecules::ServicePolicy.new("operations" => {"forge-sync" => operation},
          "authorizations" => {
            "decision-1" => binding.merge("expires_at" => (Time.now.utc + 3600).iso8601),
            "decision-stale" => binding.merge("candidate_head" => "c" * 40,
              "expires_at" => (Time.now.utc + 3600).iso8601)
          })
        [repo, topology, coordinator, policy, input_path, assignment, attempt]
      end

      def test_request_is_journaled_once_and_dry_run_has_no_effect
        Dir.mktmpdir do |dir|
          repo, topology, coordinator, policy, input_path, assignment, attempt = setup_fixture(dir)
          executor = Object.new
          calls = []
          executor.define_singleton_method(:execute) do |operation:, request:, input:, **_|
            calls << [operation, request, input]
            {"outcome" => "succeeded", "evidence" => [{"ref" => "forge/receipt", "sha256" => "a" * 64}],
             "executor_uid" => Process.uid}
          end
          service = Organisms::ServiceRequestService.new(topology: topology, policy: policy,
            coordinator: coordinator, executor: executor, repo_root: repo)
          args = {project: "atlas", assignment: assignment.id, attempt: attempt.attempt_id,
            operation: "forge-sync", input_path: input_path, authorization: "decision-1", request_id: "request-1"}

          preview = service.request(**args, dry_run: true)
          assert_equal true, preview.dig("data", "dry_run")
          assert_nil coordinator.service_request_status("request-1")
          first = service.request(**args)
          assert_equal "succeeded", first.dig("data", "outcome")
          assert_equal 1, calls.size
          repeated = service.request(**args)
          assert_equal "succeeded", repeated.dig("data", "outcome")
          assert_equal 1, calls.size
          assert_equal "succeeded", service.status(request_id: "request-1").dig("data", "outcome")
          assert_equal "succeeded", coordinator.service_request_status("request-1")["state"]
        end
      end

      def test_missing_executor_receipt_stays_uncertain_and_is_not_replayed
        Dir.mktmpdir do |dir|
          repo, topology, coordinator, policy, input_path, assignment, attempt = setup_fixture(dir)
          executor = Object.new
          calls = 0
          executor.define_singleton_method(:execute) do |**_|
            calls += 1
            nil
          end
          service = Organisms::ServiceRequestService.new(topology: topology, policy: policy,
            coordinator: coordinator, executor: executor, repo_root: repo)
          args = {project: "atlas", assignment: assignment.id, attempt: attempt.attempt_id,
            operation: "forge-sync", input_path: input_path, authorization: "decision-1", request_id: "request-1"}
          assert_equal "uncertain", service.request(**args).dig("data", "outcome")
          assert_equal "uncertain", service.request(**args).dig("data", "outcome")
          assert_equal 1, calls
        end
      end

      def test_stale_authorization_is_rejected_and_audited_without_dispatch
        Dir.mktmpdir do |dir|
          repo, topology, coordinator, policy, input_path, assignment, attempt = setup_fixture(dir)
          executor = Object.new
          executor.define_singleton_method(:execute) { |**_| raise "must not execute" }
          service = Organisms::ServiceRequestService.new(topology: topology, policy: policy,
            coordinator: coordinator, executor: executor, repo_root: repo)
          result = service.request(project: "atlas", assignment: assignment.id, attempt: attempt.attempt_id,
            operation: "forge-sync", input_path: input_path, authorization: "decision-stale",
            request_id: "request-stale")
          assert_equal "unauthorized", result.dig("error", "code")
          assert_equal "rejected", coordinator.service_request_status("request-stale")["state"]
        end
      end

      def test_claimed_role_in_input_does_not_expand_authorization
        Dir.mktmpdir do |dir|
          repo, topology, coordinator, policy, input_path, assignment, attempt = setup_fixture(dir)
          forged = JSON.parse(File.read(input_path)).merge("role" => "admin")
          File.write(input_path, JSON.generate(forged))
          executor = Object.new
          executor.define_singleton_method(:execute) { |**_| raise "must not execute" }
          service = Organisms::ServiceRequestService.new(topology: topology, policy: policy,
            coordinator: coordinator, executor: executor, repo_root: repo)

          result = service.request(project: "atlas", assignment: assignment.id, attempt: attempt.attempt_id,
            operation: "forge-sync", input_path: input_path, authorization: "decision-1", request_id: "role-1")
          assert_equal "unauthorized", result.dig("error", "code")
          assert_equal "rejected", coordinator.service_request_status("role-1")["state"]
        end
      end

      def test_local_executor_uses_os_identity_and_fixed_argv_once
        Dir.mktmpdir do |dir|
          repo, topology, coordinator, _policy, input_path, assignment, attempt = setup_fixture(dir)
          executable = File.join(dir, "executor")
          count_path = File.join(dir, "invocations")
          File.write(executable, <<~'RUBY')
            #!/usr/bin/env ruby
            require "json"
            request = JSON.parse(STDIN.read).fetch("request")
            File.open(ARGV.fetch(0), "a") { |file| file.puts(request.fetch("request_id")) }
            puts JSON.generate("request_id" => request.fetch("request_id"),
              "input_digest" => request.fetch("input_digest"), "outcome" => "succeeded",
              "evidence" => [{"ref" => "fixture/result", "sha256" => "a" * 64}])
          RUBY
          File.chmod(0o700, executable)
          input = JSON.parse(File.read(input_path))
          binding = {"operation" => "forge-sync", "project_id" => "atlas",
            "assignment_id" => assignment.id, "attempt_id" => attempt.attempt_id,
            "input_digest" => Atoms::ServiceInput.digest(input), "target" => Atoms::ServiceInput.target(input),
            "candidate_head" => git(repo, "rev-parse", "HEAD"), "caller_uid" => Process.uid}
          operation = {"project" => "atlas", "service_id" => "atlas-search", "transport" => "local",
            "argv" => [executable, count_path], "executor_uid" => Process.uid,
            "lease_expires_at" => (Time.now.utc + 3600).iso8601}
          policy = Molecules::ServicePolicy.new("operations" => {"forge-sync" => operation},
            "authorizations" => {"decision-1" => binding.merge("expires_at" => (Time.now.utc + 3600).iso8601)})
          service = Organisms::ServiceRequestService.new(topology: topology, policy: policy,
            coordinator: coordinator, repo_root: repo)
          args = {project: "atlas", assignment: assignment.id, attempt: attempt.attempt_id,
            operation: "forge-sync", input_path: input_path, authorization: "decision-1", request_id: "local-1"}

          assert_equal "succeeded", service.request(**args).dig("data", "outcome")
          assert_equal "succeeded", service.request(**args).dig("data", "outcome")
          assert_equal ["local-1"], File.readlines(count_path, chomp: true)
          assert_equal Process.uid, coordinator.service_request_status("local-1").dig("receipt", "executor_uid")
        end
      end
    end
  end
end
