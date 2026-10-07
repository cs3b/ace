# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/overseer/organisms/protected_review"
require "ace/review"
require "ace/overseer/cli/commands/review"
require "open3"

class ProtectedReviewTest < AceOverseerTestCase
  class Provider
    attr_accessor :verdict
    def execute(system_prompt:, user_prompt:, model:, session_dir:, output_file: nil, **)
      if model == "role:review-default"
        packet = JSON.parse(user_prompt)
        response = JSON.generate("schema" => "ace.review.candidate-verdict/v1", "head" => packet.dig("candidate", "head"),
          "tree" => packet.dig("candidate", "tree"), "subject_sha256" => packet.fetch("subject_sha256"),
          "verdict" => verdict || "approved", "summary" => "Controlled completed review", "findings" => [])
        output_file ||= File.join(session_dir, "review-report-controlled.md")
      else
        response = '{"findings":[]}'
      end
      FileUtils.mkdir_p(session_dir)
      File.write(output_file, response)
      {success: true, response: response, output_file: output_file, requested_selector: model,
        execution: {"status" => "succeeded", "provider" => "controlled", "model" => "fixture"}}
    end
  end

  def fixture
    Dir.mktmpdir("ace-review-consumer-", Etc.getpwuid(Process.uid).dir) do |root|
      @root = root
      @peer = {"pid" => 42, "uid" => 12001, "gid" => 12001, "groups" => [12001], "started_at" => "birth", "host" => "host", "parent_pid" => 1}
      @map = {"project_id" => "project", "worker_uid" => 12002, "worker_actor" => "worker"}
      @installed = {"reviewer_uids" => [12001], "peer_credentials" => {"12001" => {"gid" => 12001, "groups" => [12001], "scratch_root" => root}}}
      deployment = Object.new
      map, installed = @map, @installed
      deployment.define_singleton_method(:mapping) { |_| map }
      deployment.define_singleton_method(:project) { |_| installed }
      kernel = Object.new
      peer = @peer
      kernel.define_singleton_method(:capture) { |_| peer }
      kernel.define_singleton_method(:live!) { |_| true }
      kernel.define_singleton_method(:same?) { |left, right| left == right }
      @calls = []
      @replayed, @assigned, @fail_accept = false, true, false
      @owner = Ace::Overseer::Organisms::ProtectedReview.new(deployment_loader: -> { deployment }, kernel: kernel,
        client_factory: ->(*_) { self })
      source = File.join(root, "source")
      FileUtils.mkdir_p(source, mode: 0o700)
      git(source, "init", "-b", "main")
      File.write(File.join(source, "source.rb"), "puts 'complete candidate'\n")
      git(source, "add", ".")
      git(source, "-c", "user.name=fixture", "-c", "user.email=fixture@example.invalid", "commit", "-m", "fixture")
      @head, @tree = git(source, "rev-parse", "HEAD").strip, git(source, "rev-parse", "HEAD^{tree}").strip
      bundle = File.join(root, "candidate.bundle")
      git(source, "bundle", "create", bundle, "--all")
      @bundle = File.binread(bundle)
      @args = {project: "project", agent: "mapping", assignment: "assignment", attempt: "attempt", mutation: "request",
        head: @head, candidate_generation: 1, expected_generation: 7, accept_mutation: "accept"}
      @provider = Provider.new
      limits = Struct.new(:context_limit, :output_limit).new(200_000, 8192)
      Ace::Review::Molecules::LlmExecutor.stub(:new, @provider) do
        Ace::Review::Atoms::ContextLimitResolver.stub(:resolve_details, limits) { yield }
      end
    end
  end

  # Authority transport boundary is injected here. Actual canonical integration
  # belongs to the separate real Server/Journal feature fixture.
  def call(operation, params, **options)
    @calls << [operation, params, options]
    data, parts = case operation
    when "request_review"
      [{"state" => @assigned ? "assigned" : "uncertain", "generation" => 10,
        "assignment" => {"head" => @head, "candidate_generation" => 1, "generation" => 9,
          "reviewer_uid" => @peer.fetch("uid"), "reviewer_actor" => "uid-12001", "reviewer_process_binding" => @peer, "review_id" => "review"}}, nil]
    when "attempt_status"
      assert_equal 1, params.fetch("result_candidate_generation")
      [{"assignment_id" => "assignment", "attempt_id" => "attempt", "scope" => "1.2", "generation" => 88}, nil]
    when "export_candidate"
      [{"head" => @head, "tree" => @tree, "candidate_generation" => 1, "bytes" => @bundle.bytesize, "sha256" => Digest::SHA256.hexdigest(@bundle)}, [@bundle]]
    when "accept_review"
      raise Ace::Assign::AttemptErrors::EvidenceUnavailable, "controlled lost acceptance" if @fail_accept
      [{"head" => @head, "candidate_generation" => 1, "review_id" => "review", "reviewer_uid" => 12001, "uploaded_receipt_sha256" => params.fetch("receipt_sha256")}, nil]
    when "review_status", "cancel_review"
      [{"state" => operation == "review_status" ? "observed" : "cancelled"}, nil]
    else raise "unexpected #{operation}"
    end
    Ace::Assign::Authority::Client::Reply.new(data: data, parts: parts, replayed: @replayed)
  end

  def git(directory, *args)
    output, error, status = Open3.capture3("/usr/bin/git", "-C", directory, *args)
    assert status.success?, error
    output
  end

  def test_actual_snapshot_review_and_receipt_use_original_reply_generation
    fixture do
      result = @owner.call(**@args)
      assert_equal "accepted", result["state"], result.inspect
      assert_equal %w[request_review attempt_status export_candidate accept_review], @calls.map(&:first)
      _, params, options = @calls.last
      assert_equal 10, params.fetch("expected_generation"), "neither assignment generation nor current status refresh is permitted"
      receipt = JSON.parse(options.fetch(:upload_parts).first)
      assert_equal "1.2", receipt.fetch("scope")
      assert_equal "worker", receipt.dig("producer", "actor")
      assert_equal "uid-12001", receipt.dig("review", "reviewer", "actor")
      assert_equal 4, options.fetch(:upload_parts).size
      receipt.fetch("artifacts").zip(options.fetch(:upload_parts).drop(1)).each do |ref, bytes|
        assert_equal ref.fetch("sha256"), Digest::SHA256.hexdigest(bytes)
      end
      assert File.file?(File.join(result.fetch("session_dir"), "acceptance.json"))
      assert File.file?(File.join(result.fetch("session_dir"), "accepted.json"))
    end
  end

  def test_replay_uncertainty_and_nonapproval_do_not_reexecute_or_accept
    fixture do
      @replayed = true
      assert_equal "inspect_review_status", @owner.call(**@args).fetch("required_action")
      assert_equal ["request_review"], @calls.map(&:first)
      @replayed, @assigned = false, false
      @calls.clear
      assert_equal "uncertain", @owner.call(**@args).fetch("state")
      assert_equal ["request_review"], @calls.map(&:first)
      @assigned = true
      @provider.verdict = "changes_requested"
      @calls.clear
      assert_equal "not_approved", @owner.call(**@args).fetch("state")
      refute @calls.any? { |call| call.first == "accept_review" }
    end
  end

  def test_lost_acceptance_retains_exact_receipt_and_token_without_retry
    fixture do
      @fail_accept = true
      result = @owner.call(**@args)
      assert_equal "uncertain", result.fetch("state")
      assert_equal 1, @calls.count { |call| call.first == "accept_review" }
      retained = JSON.parse(File.read(File.join(result.fetch("session_dir"), "acceptance.json")))
      assert_equal "accept", retained.fetch("mutation")
      assert_equal 10, retained.dig("params", "expected_generation")
      assert File.file?(File.join(result.fetch("session_dir"), "receipt.json"))
    end
  end

  def test_actual_cli_replaces_legacy_forwarding_and_exposes_read_only_status
    fixture do
      command = Ace::Overseer::CLI::Commands::Review.new(review: @owner)
      status = @args.slice(:project, :agent, :assignment, :attempt, :mutation).merge(status: true)
      output, = capture_io { command.call(**status) }
      assert_equal "observed", JSON.parse(output).fetch("state")
      @calls.clear
      assert_raises(Ace::Support::Cli::Error) { command.call(**status.merge(work: "old-work", pr: 1)) }
      assert_raises(Ace::Support::Cli::Error) { command.call(**@args.merge(status: true)) }
      assert_empty @calls
    end
  end

  def test_mode_errors_refuse_before_rpc_and_status_and_cancel_have_no_review_effect
    fixture do
      assert_raises(Ace::Overseer::Error) { @owner.call(**@args.merge(status: true)) }
      assert_raises(Ace::Overseer::Error) { @owner.call(**@args.merge(accept_mutation: "request")) }
      assert_raises(Ace::Overseer::Error) { @owner.call(**@args.merge(candidate_generation: 1.0)) }
      assert_empty @calls
      status = @args.slice(:project, :agent, :assignment, :attempt, :mutation).merge(status: true)
      assert_equal "observed", @owner.call(**status).fetch("state")
      assert_equal "cancelled", @owner.call(**@args.except(:accept_mutation).merge(cancel: true, review_event: "a" * 64)).fetch("state")
      assert_equal %w[review_status cancel_review], @calls.map(&:first)
    end
  end
end
