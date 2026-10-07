# frozen_string_literal: true
require "test_helper"
require_relative "../../../ace-lab/test/support/protected_service_boundary_fixture"
require "ace/git/cli"
require "ace/git/forgejo"
require "stringio"

# Actual wire/claim/candidate/import owners; only kernel identity, process
# execution and remote provider transport are controlled excluded boundaries.
class ServiceMergeBoundaryTest < AceGitTestCase
  include ProtectedServiceBoundaryFixture
  URL = "https://forge.example.com/owner/repo"

  def configure_result_owner_fixture
    super
    uid = Process.uid
    @executor.merge!("uid" => uid, "gid" => Process.gid, "groups" => Process.groups.sort)
    @project["service_executor_uids"] = [uid]
    @project["peer_credentials"][uid.to_s] = @executor.slice("gid", "groups").merge("scratch_root" => @root)
    @project["service_receivers"]["executor"]["executor_uid"] = uid
    @document["principals"][uid.to_s] = {"projects" => ["project"]}
    @document["operations"] = {"merge" => {"project" => "project", "service_id" => "executor", "executor_uid" => uid,
      "argv" => [File.expand_path("../../../bin/ace-git", __dir__), "service", "merge"],
      "lease_expires_at" => (Time.now.utc + 3600).iso8601}}
  end

  def test_real_receiver_fixed_cli_neutral_merge_and_canonical_receipt_import
    fixture do
      submission, = prepared_submission
      input = {"target" => {"resource" => "#{URL}/pulls/25", "artifact_digest" => nil}, "method" => "squash",
        "delivery" => {"forge_server" => "selected", "forge_default" => false,
          "pr_provenance" => {"mode" => "canonical", "head_repository_url" => URL, "head_ref" => "feature/x",
            "base_repository_url" => URL, "base_ref" => "main"}}}
      bytes = JSON.generate(input)
      digest = Ace::Lab::Atoms::ServiceInput.digest(input)
      target = Ace::Lab::Atoms::ServiceInput.target(input)
      submission.merge!("operation" => "merge", "input_digest" => digest, "target" => target)
      @document["authorizations"]["decision"].merge!("operation" => "merge", "input_digest" => digest, "target" => target)
      Ace::Git.instance_variable_set(:@config, Ace::Git.config.merge("servers" => [
        {"name" => "selected", "provider" => "forgejo", "url" => URL}]))
      calls, merged = [], false
      runner = lambda do |args:, **|
        calls << args
        payload = if args[1] == "POST"
          assert_equal @head, args[3].fetch("head_commit_id")
          assert_equal "squash", args[3].fetch("Do")
          merged = true
          nil
        elsif args[2].end_with?("/version")
          {"version" => "8.0.5"}
        else
          assert_equal "GET", args[1]
          assert_equal "https://forge.example.com/api/v1/repos/owner/repo/pulls/25", args[2]
          branch = ->(ref, head) { {"ref" => ref, "sha" => head, "repo" => {"full_name" => "owner/repo"}} }
          {"number" => 25, "title" => "Ship", "body" => "", "state" => merged ? "closed" : "open", "draft" => false,
            "merged" => merged, "merged_at" => merged ? "2026-10-07T12:00:00Z" : nil,
            "merge_commit_sha" => merged ? "d" * 40 : nil, "user" => {"login" => "worker"},
            "head" => branch.call("feature/x", @head), "base" => branch.call("main", "e" * 40)}
        end
        {success: true, status: 200, stdout: payload ? JSON.generate(payload) : "", stderr: "", exit_code: 0}
      end
      producer = Ace::Git::Organisms::ServiceMerge.new(lifecycle_factory: ->(**selection) {
        Ace::Git::Organisms::PullRequestLifecycle.new(**selection, runner: runner) })
      effects = 0
      original_process = Ace::Herdr::Molecules::BoundedProcess.method(:call)
      process = lambda do |argv, **options|
        unless argv == @document.fetch("operations").fetch("merge").fetch("argv")
          next original_process.call(argv, **options)
        end
        assert_equal @document.fetch("operations").fetch("merge").fetch("argv"), argv
        effects += 1
        out, err = capture_io do
          Ace::Git::CLI::Commands::ServiceMerge.new(input: StringIO.new(options.fetch(:stdin_data)),
            producer: producer, root: options.fetch(:chdir)).call
        end
        status = Object.new
        status.define_singleton_method(:success?) { true }
        Struct.new(:stdout, :stderr, :status, :oversized).new(out, err, status, false)
      end
      client = start_service_server
      phases = []
      traced = Object.new
      traced.define_singleton_method(:call) do |name, params, **options|
        phases << name
        client.call(name, params, **options)
      rescue StandardError, SecurityError => error
        phases << [name, error.class.name, error.message]
        raise
      end
      result = nil
      Ace::Lab::Molecules::GrantResolver.stub(:trusted_document, @document) do
        Ace::Herdr::Molecules::BoundedProcess.stub(:call, process) do
          result = receiver(traced, Ace::Lab::Molecules::ProtectedServiceHandler.new).execute(
            submission: submission, peer: @worker, input_bytes: bytes, mutation_id: "merge-original")
        end
      end
      assert_equal "succeeded", result.fetch("state"), [result, phases].inspect
      assert_equal 1, effects
      assert_equal 1, calls.count { |args| args[1] == "POST" }
      record = @journal.service_request(submission.fetch("request_id"))
      assert_equal "succeeded", record.fetch("state")
      assert_equal @head, record.fetch("candidate_head")
      assert_equal digest, record.fetch("input_digest")
      assert_equal target, record.fetch("target")
      assert_equal "merge", record.fetch("operation")
      assert @journal.read_events("assignment").any? { |event| event["type"] == "service_transition" && event.dig("payload", "state") == "succeeded" }
    end
  end
end
