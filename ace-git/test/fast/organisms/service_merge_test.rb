# frozen_string_literal: true
require "test_helper"
require "tmpdir"
require "ace/git/github"
require "ace/git/forgejo"
require "ace/git/organisms/service_merge"
require "ace/git/cli"
require "stringio"

class ServiceMergeTest < AceGitTestCase
  HEAD = "a" * 40
  URL = "https://forge.example.com/owner/repo"

  def test_actual_neutral_adapters_merge_once_and_publish_exact_bounded_evidence
    %w[github forgejo].product([false, true], [false, true]).each do |provider, default, fork|
      with_producer(provider, default: default, fork: fork) do |producer, envelope, root, calls|
        response = producer.call(bytes: JSON.generate(envelope), root: root)
        assert_equal "succeeded", response.fetch("outcome")
        artifact = File.binread(File.join(root, "merge-result.txt"))
        assert_equal Digest::SHA256.hexdigest(artifact), response.fetch("evidence").first.fetch("sha256")
        assert_includes artifact, "request:request-1 input:#{envelope.fetch('request').fetch('input_digest')} outcome:succeeded"
        assert_equal 1, calls.count { |args| mutation?(provider, args) }
        assert_equal 0o400, File.stat(File.join(root, "merge-result.txt")).mode & 0o777
      end
    end
  end

  def test_malformed_original_binding_refuses_before_any_provider_call
    with_producer("forgejo") do |producer, envelope, root, calls|
      envelope.fetch("execution")["head"] = "b" * 40
      assert_raises(ArgumentError) { producer.call(bytes: JSON.generate(envelope), root: root) }
      assert_empty calls
      refute File.exist?(File.join(root, "merge-result.txt"))
    end
  end

  def test_unverified_post_merge_never_publishes_success_or_retries
    with_producer("forgejo", verify_merge: false) do |producer, envelope, root, calls|
      assert_raises(Ace::Git::ProviderUnknownOutcomeError) do
        producer.call(bytes: JSON.generate(envelope), root: root)
      end
      assert_equal 1, calls.count { |args| mutation?("forgejo", args) }
      refute File.exist?(File.join(root, "merge-result.txt"))
    end
  end

  def test_decoded_duplicate_and_non_json_envelopes_refuse_before_provider_io
    with_producer("forgejo") do |producer, envelope, root, calls|
      valid = JSON.generate(envelope)
      [valid.sub('"version":1', '"version":1,"\\u0076ersion":1'),
        valid.sub('"version":1', '"version":NaN'), "/* comment */#{valid}"].each do |bytes|
        assert_raises(ArgumentError) { producer.call(bytes: bytes, root: root) }
      end
      assert_empty calls
      refute File.exist?(File.join(root, "merge-result.txt"))
    end
  end

  def test_fixed_public_cli_uses_real_producer_and_emits_only_existing_response
    with_producer("forgejo") do |producer, envelope, root, calls|
      previous = $stdin
      $stdin = StringIO.new(JSON.generate(envelope))
      stdout, stderr = capture_io do
        Dir.chdir(root) do
          Ace::Git::Organisms::ServiceMerge.stub(:new, -> { producer }) { Ace::Git::CLI.start(%w[service merge]) }
        end
      end
      response = JSON.parse(stdout)
      assert_equal %w[evidence input_digest outcome request_id], response.keys.sort
      assert_equal "succeeded", response.fetch("outcome")
      assert_empty stderr
      assert_equal 1, calls.count { |args| mutation?("forgejo", args) }
    ensure
      $stdin = previous
    end
  end

  def test_changed_staging_mode_after_merge_retains_uncertainty_without_evidence
    with_producer("forgejo", change_mode: true) do |producer, envelope, root, calls|
      assert_raises(Ace::Git::ProviderUnknownOutcomeError) { producer.call(bytes: JSON.generate(envelope), root: root) }
      assert_equal 1, calls.count { |args| mutation?("forgejo", args) }
      refute File.exist?(File.join(root, "merge-result.txt"))
    end
  end

  def test_float_executor_join_is_not_an_integer_original_identity
    with_producer("forgejo") do |producer, envelope, root, calls|
      envelope.fetch("execution")["executor_uid"] = envelope.fetch("request").fetch("executor_uid").to_f
      assert_raises(ArgumentError) { producer.call(bytes: JSON.generate(envelope), root: root) }
      assert_empty calls
    end
  end

  private

  def mutation?(provider, args)
    provider == "github" ? args[0, 3] == %w[gh pr merge] : args[1] == "POST"
  end

  def with_producer(provider, default: false, fork: false, verify_merge: true, change_mode: false)
    Ace::Git.instance_variable_set(:@config, Ace::Git.config.merge("servers" => [
      {"name" => "selected", "provider" => provider, "url" => URL, "default" => true}
    ]))
    calls, merged, staging = [], false, nil
    head_owner = fork ? "fork-owner" : "owner"
    runner = lambda do |args:, **|
      calls << args
      if mutation?(provider, args)
        if provider == "github"
          assert_includes args, HEAD
          assert_includes args, "--squash"
        else
          assert_equal HEAD, args[3].fetch("head_commit_id")
          assert_equal "squash", args[3].fetch("Do")
        end
        merged = verify_merge
        File.chmod(0o755, staging) if change_mode
        next {success: true, status: 200, stdout: "", stderr: "", exit_code: 0}
      end
      payload = if provider == "github"
        assert_equal %w[gh pr view 25], args[0, 4]
        {"number" => 25, "title" => "Ship", "body" => "", "state" => merged ? "MERGED" : "OPEN",
         "isDraft" => false, "author" => {"login" => "worker"}, "headRefName" => "feature/x", "baseRefName" => "main",
         "url" => "#{URL}/pull/25", "headRefOid" => HEAD, "headRepositoryOwner" => {"login" => head_owner},
         "headRepository" => {"name" => "repo"}, "mergeCommit" => merged ? {"oid" => "d" * 40} : nil,
         "mergedAt" => merged ? "2026-10-07T12:00:00Z" : nil}
      elsif args[2] == "https://forge.example.com/api/v1/version"
        {"version" => "8.0.5"}
      else
        assert_equal "GET", args[1]
        assert_equal "https://forge.example.com/api/v1/repos/owner/repo/pulls/25", args[2]
        {"number" => 25, "title" => "Ship", "body" => "", "state" => merged ? "closed" : "open",
         "draft" => false, "merged" => merged, "user" => {"login" => "worker"},
         "merged_at" => merged ? "2026-10-07T12:00:00Z" : nil, "merge_commit_sha" => merged ? "d" * 40 : nil,
         "head" => branch("feature/x", HEAD, head_owner), "base" => branch("main", "e" * 40, "owner")}
      end
      {success: true, status: 200, stdout: JSON.generate(payload), stderr: "", exit_code: 0}
    end
    factory = ->(**selection) { Ace::Git::Organisms::PullRequestLifecycle.new(**selection, runner: runner) }
    Dir.mktmpdir("service-merge-") do |root|
      staging = root
      File.chmod(0o700, root)
      resource = "#{URL}/#{provider == 'github' ? 'pull' : 'pulls'}/25"
      input = {"target" => {"resource" => resource, "artifact_digest" => nil}, "method" => "squash",
        "delivery" => {"forge_server" => default ? nil : "selected", "forge_default" => default,
          "pr_provenance" => {"mode" => fork ? "fork" : "canonical", "head_repository_url" => "https://forge.example.com/#{head_owner}/repo",
            "head_ref" => "feature/x", "base_repository_url" => URL, "base_ref" => "main"}}}
      digest = Digest::SHA256.hexdigest(JSON.generate(canonical(input)))
      request = {"request_id" => "request-1", "assignment_id" => "assignment-1", "attempt_id" => "attempt-1",
        "project_id" => "project-1", "operation" => "merge", "input_digest" => digest, "target" => input.fetch("target"),
        "candidate_head" => HEAD, "executor_uid" => 501, "transport" => "unix", "authorization" => "authorization-1",
        "service_id" => "service-1", "caller_uid" => 502}
      envelope = {"version" => 1, "request" => request, "input" => input,
        "execution" => {"executor_uid" => 501, "authority_id" => "authority-1", "claim_binding" => "b" * 64,
          "candidate_generation" => 1, "head" => HEAD, "staging_id" => "stage-1"}}
      producer = Ace::Git::Organisms::ServiceMerge.new(lifecycle_factory: factory, uid: -> { Process.uid }, euid: -> { Process.euid })
      # Kernel identity is an excluded boundary: inject the claimed UID while
      # keeping real temporary-file ownership validation on the current UID.
      request["executor_uid"] = envelope["execution"]["executor_uid"] = Process.uid
      request["caller_uid"] = Process.uid + 1
      yield producer, envelope, root, calls
    end
  end

  def branch(ref, sha, owner)
    {"ref" => ref, "sha" => sha, "label" => "#{owner}/repo:#{ref}",
      "repo" => {"id" => 1, "full_name" => "#{owner}/repo", "owner" => {"id" => 10, "login" => owner}}}
  end

  def canonical(value)
    value.is_a?(Hash) ? value.keys.sort.to_h { |key| [key, canonical(value.fetch(key))] } : value
  end
end
