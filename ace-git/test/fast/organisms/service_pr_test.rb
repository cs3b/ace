# frozen_string_literal: true
require "test_helper"
require "tmpdir"
require "ace/git/github"
require "ace/git/forgejo"
require "ace/git/organisms/service_merge"
require "ace/git/atoms/service_pr_evidence"
require "ace/git/cli"
require "stringio"

# Real lifecycle, provider parsers and immutable artifact; only remote I/O is
# controlled. No workers, Lab users, sockets or replica installer are needed.
class ServicePrTest < AceGitTestCase
  HEAD = "a" * 40
  URL = "https://forge.example.com/owner/repo"

  def test_draft_create_update_and_ready_publish_verifiable_original_results
    %w[github forgejo].product(%w[create update ready], %i[named default url]).each do |provider, operation, selection|
      with_operation(provider, operation, selection: selection) do |producer, envelope, root, calls|
        result = producer.call(bytes: JSON.generate(envelope), root: root)
        ref = result.fetch("evidence").first
        bytes = File.binread(File.join(root, ref.fetch("ref")))
        assert_equal "succeeded", result.fetch("outcome")
        assert_equal Digest::SHA256.hexdigest(bytes), ref.fetch("sha256")
        proof = Ace::Git::Atoms::ServicePrEvidence.validate(bytes, operation: operation,
          request_id: "request", input_digest: envelope.dig("request", "input_digest"),
          target: envelope.dig("input", "target"), head: HEAD)
        assert_equal envelope.fetch("input"), proof.fetch(:input)
        assert_equal operation != "ready", proof.fetch(:pr).fetch("draft")
        assert_equal 1, calls.count { |args| mutation?(provider, args) }
      end
    end
  end

  def test_ready_existing_pr_cannot_be_updated_as_a_draft
    %w[github forgejo].each do |provider|
      with_operation(provider, "update", draft: false) do |producer, envelope, root, calls|
        assert_raises(Ace::Git::ProviderExpectedHeadConflictError) do
          producer.call(bytes: JSON.generate(envelope), root: root)
        end
        assert_equal 0, calls.count { |args| mutation?(provider, args) }
        assert_empty Dir.children(root)
      end
    end
  end

  def test_lost_reply_or_wrong_post_mutation_head_has_no_success_and_no_retry
    %w[github forgejo].product(%w[create update ready], %i[lost_reply changed_head]).each do |provider, operation, fault|
      with_operation(provider, operation, fault: fault) do |producer, envelope, root, calls|
        assert_raises(Ace::Git::Error) do
          producer.call(bytes: JSON.generate(envelope), root: root)
        end
        assert_equal 1, calls.count { |args| mutation?(provider, args) }
        assert_empty Dir.children(root)
      end
    end
  end

  def test_fixed_public_entry_selects_create_not_merge_and_has_no_operation_override
    with_operation("forgejo", "create") do |producer, envelope, root, calls|
      previous = $stdin
      $stdin = StringIO.new(JSON.generate(envelope))
      output = capture_io do
        Dir.chdir(root) do
          Ace::Git::Organisms::ServiceMerge.stub(:new, ->(operation:) { assert_equal "create", operation; producer }) do
            Ace::Git::CLI.start(%w[service create])
          end
        end
      end
      assert_equal "succeeded", JSON.parse(output.first).fetch("outcome")
      assert_empty output.last
      assert_equal 1, calls.count { |args| mutation?("forgejo", args) }
    ensure
      $stdin = previous
    end
  end

  private

  def mutation?(provider, args)
    provider == "github" ? %w[create edit ready].include?(args[2]) : %w[POST PATCH].include?(args[1])
  end

  def with_operation(provider, operation, draft: true, fault: nil, selection: :named)
    Ace::Git.instance_variable_set(:@config, Ace::Git.config.merge("servers" => [
      {"name" => "selected", "provider" => provider, "url" => URL, "default" => true}]))
    calls, changed = [], false
    title, body = provider == "forgejo" && draft ? "WIP: Before" : "Before", "Before"
    resource = "#{URL}/#{provider == 'github' ? 'pull' : 'pulls'}/25"
    repository = {"id" => 1, "full_name" => "owner/repo", "owner" => {"id" => 10, "login" => "owner"}}
    runner = lambda do |args:, **|
      calls << args
      if mutation?(provider, args)
        changed = true
        if provider == "github"
          if operation == "ready"
            draft = false
          else
            title, body = args.fetch(args.index("--title") + 1), args.fetch(args.index("--body") + 1)
            draft = true
            assert_includes args, "--draft" if operation == "create"
          end
        else
          form = args.fetch(3)
          title = form.fetch("title")
          body = form.fetch("body", body)
          draft = title.start_with?("WIP:")
        end
        next {success: false, exit_code: 1, status: 0, stdout: "", stderr: "connection reset"} if fault == :lost_reply
      end
      head = changed && fault == :changed_head ? "b" * 40 : HEAD
      payload = if provider == "github"
        if args[2] == "list"
          []
        elsif args[2] == "create"
          resource
        else
          {"number" => 25, "title" => title, "body" => body, "state" => "OPEN", "isDraft" => draft,
            "author" => {"login" => "worker"}, "headRefName" => "feature", "baseRefName" => "main",
            "url" => resource, "headRefOid" => head, "headRepositoryOwner" => {"login" => "owner"},
            "headRepository" => {"name" => "repo"}, "mergeCommit" => nil, "mergedAt" => nil}
        end
      elsif args[2].end_with?("/api/v1/version")
        {"version" => "8.0.5"}
      elsif args[2].include?("?state=open")
        []
      elsif args[2].end_with?("/repos/owner/repo/") || args[2].end_with?("/repos/owner/repo")
        repository
      else
        branch = ->(ref, sha) { {"ref" => ref, "sha" => sha, "label" => "owner/repo:#{ref}", "repo" => repository} }
        {"number" => 25, "title" => title, "body" => body, "state" => "open", "draft" => draft,
          "merged" => false, "user" => {"login" => "worker"}, "head" => branch.call("feature", head),
          "base" => branch.call("main", "e" * 40), "merged_at" => nil, "merge_commit_sha" => nil}
      end
      # Github create is plain URL output; every other response is JSON.
      stdout = payload.is_a?(String) ? payload : JSON.generate(payload)
      {success: true, exit_code: 0, status: provider == "forgejo" && args[1] == "POST" ? 201 : 200,
        stdout: stdout, stderr: ""}
    end
    input = {"target" => {"resource" => operation == "create" ? URL : resource, "artifact_digest" => nil},
      "delivery" => {"forge_server" => selection == :named ? "selected" : nil, "forge_default" => selection == :default,
        "pr_provenance" => {"mode" => "canonical", "head_repository_url" => URL,
          "head_ref" => "feature", "base_repository_url" => URL, "base_ref" => "main"}}}
    input.merge!("title" => "Ship", "body" => "Description") unless operation == "ready"
    request = {"request_id" => "request", "assignment_id" => "assignment", "attempt_id" => "attempt",
      "project_id" => "project", "operation" => operation, "input_digest" => Digest::SHA256.hexdigest(JSON.generate(canonical(input))),
      "target" => input.fetch("target"), "candidate_head" => HEAD, "executor_uid" => Process.uid,
      "transport" => "unix", "authorization" => "decision", "service_id" => "service", "caller_uid" => Process.uid + 1}
    envelope = {"version" => 1, "request" => request, "input" => input,
      "execution" => {"executor_uid" => Process.uid, "authority_id" => "authority", "claim_binding" => "b" * 64,
        "candidate_generation" => 1, "head" => HEAD, "staging_id" => "stage"}}
    factory = ->(**selection) { Ace::Git::Organisms::PullRequestLifecycle.new(**selection, runner: runner) }
    producer = Ace::Git::Organisms::ServiceMerge.new(operation: operation, lifecycle_factory: factory)
    Dir.mktmpdir("service-pr-") do |root|
      File.chmod(0o700, root)
      yield producer, envelope, root, calls
    end
  end

  def canonical(value)
    value.is_a?(Hash) ? value.keys.sort.to_h { |key| [key, canonical(value.fetch(key))] } : value
  end
end
