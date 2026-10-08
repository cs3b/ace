# frozen_string_literal: true
require "digest"
require "json"

module CampaignFixtures
  def campaign_policy(scopes: ["full"])
    {"revision" => "delivery-v1", "minimum_rounds" => 3, "clean_rounds" => 2,
      "required_scopes" => scopes, "required_checks" => ["tests"]}
  end

  def campaign_subject
    {"repository" => "local:#{File.realpath(@test_dir)}", "local_candidate_id" => "candidate"}
  end

  def campaign_manager
    Ace::Review::Organisms::CampaignManager.new(repo_root: @test_dir,
      revisions: ->(ref, *_args) { ref == "HEAD" ? @head : @base }, check_evidence: fixture_check_evidence, review_evidence: fixture_review_evidence, approval_evidence: fixture_approval_evidence)
  end

  def start_campaign(scopes: ["full"])
    campaign_manager.start(subject: campaign_subject, contract: "Frozen requirements", policy: campaign_policy(scopes: scopes))
  end

  def round_input(round, scopes: ["full"], attempt: nil)
    {"attempt_id" => attempt || "attempt-#{round}", "round_id" => "round-#{round}", "head" => @head,
      "base" => @base, "required_scopes" => scopes, "scope_identity" => scopes.to_h { |s| [s, {"preset" => "code-valid", "subjects" => ["diff:#{@base}..#{@head}"]}] },
      "sessions" => [], "dispositions" => []}
  end

  def full_pr_manifest(delta: nil)
    manifest = {"selected_files" => %w[one.rb two.rb], "excluded_files" => [],
      "raw_sha256" => "d" * 64, "selected_sha256" => "d" * 64,
      "received_diff_accounted_for" => true, "head_sha" => @head,
      "base_branch_sha" => @base, "pr_file_inventory_verified" => true}
    manifest.merge!("delta_reference_head" => delta, "delta_base_head" => @head) if delta
    manifest
  end

  def artifact_ref(path)
    {"path" => path, "sha256" => Digest::SHA256.file(File.expand_path(path, @test_dir)).hexdigest}
  end

  def make_campaign_session(campaign, input, scope: "full", finding: nil, noop: false, failed: false)
    existing = campaign_manager.store.read(campaign["campaign_id"])["attempts"]
    unless existing.any? { |a| a["round_id"] == input["round_id"] }
      pin = input.merge("attempt_id" => "pin-#{input['round_id']}", "sessions" => [], "dispositions" => [])
      campaign_manager.record_round(campaign["campaign_id"], pin)
    end
    dir = ".ace-local/review/sessions/#{input['round_id']}-#{scope}"
    full = File.join(@test_dir, dir)
    FileUtils.mkdir_p(full)
    File.write(File.join(full, "system.prompt.md"), "review system")
    File.write(File.join(full, "user.prompt.md"), "review candidate source")
    report = File.join(full, "review-report-reviewer.md")
    File.write(report, "Substantive fixture review: checked candidate, contract and scope; no remaining defects.")
    binding = {"campaign_id" => campaign["campaign_id"], "contract_identity" => campaign["contract_identity"],
      "subject" => campaign["subject"], "round_id" => input["round_id"], "scope" => scope,
      "head" => input["head"], "base" => input["base"], "scope_identity" => input["scope_identity"][scope]}
    metadata = {"preset" => "code-valid", "head" => @head, "campaign_binding" => binding, "noop_round" => noop,
      "models" => noop ? [] : [{"status" => failed ? "failed" : "success", "completed_at" => Time.now.utc.iso8601,
        "execution" => {"status" => failed ? "failed" : "succeeded", "provider" => "fixture", "model" => "reviewer"},
        "output_file" => File.basename(report), "report_sha256" => Digest::SHA256.file(report).hexdigest,
        "prompt_sha256" => {"system" => Digest::SHA256.hexdigest("review system"),
          "user" => Digest::SHA256.hexdigest("review candidate source")}}]}
    if finding
      feedback = File.join(full, "feedback")
      FileUtils.mkdir_p(feedback)
      item = {"id" => "finding", "title" => "Missing invariant", "files" => ["candidate.rb"],
        "status" => "pending", "priority" => "high", "finding" => "An invariant is violated.",
        "research" => "Verified against the executable negative control."}.merge(finding)
      File.write(File.join(feedback, "finding.s.md"), "---\n#{YAML.dump(item).delete_prefix("---\n")}---\n")
      input["dispositions"] << {"source_id" => "#{dir}#finding", "reason" => "Verified fixture disposition"}
    end
    metadata["diff_manifest"] = full_pr_manifest if campaign["subject"]["pr"]
    metadata["feedback_extraction"] = {"status" => "succeeded", "finding_ids" => finding ? ["finding"] : [],
      "report_sha256" => noop || failed ? [] : [Digest::SHA256.file(report).hexdigest]}
    metadata_file = File.join(dir, "metadata.yml")
    File.write(File.join(@test_dir, metadata_file), YAML.dump(metadata))
    input["sessions"] << {"scope" => scope, "metadata" => artifact_ref(metadata_file)}
    accept_review_session(input, dir) unless noop || failed
    dir
  end

  def review_artifacts(dir)
    paths = %w[metadata.yml system.prompt.md user.prompt.md].map { |name| File.join(dir, name) }
    llm = File.join(dir, "llm_metadata.yml")
    paths << llm if File.file?(File.join(@test_dir, llm))
    paths.concat(Dir.glob(File.join(@test_dir, dir, "review-report-*.md")).map { |path| path.delete_prefix(@test_dir + "/") })
    paths.map { |path| artifact_ref(path) }
  end

  def accepted_review_reference(dir)
    proof = {"head" => @head, "artifacts" => review_artifacts(dir), "operation" => "review-collect"}
    digest = Ace::Review::Atoms::CampaignContract.digest(proof)
    (@accepted_reviews ||= {})[digest] = proof
    {"attempt_id" => "accepted-review", "digest" => digest}
  end

  def accept_review_session(input, dir)
    input["sessions"].find { |session| session["metadata"]["path"] == File.join(dir, "metadata.yml") }["receipt"] =
      accepted_review_reference(dir)
  end

  def fixture_review_evidence
    lambda do |ref, head:, artifacts:, historical: false|
      proof = (@accepted_reviews || {})[ref["digest"]]
      unless proof && proof["head"] == head && (artifacts - proof["artifacts"]).empty?
        raise Ace::Review::Atoms::CampaignContract::Invalid, "fixture coordinator did not accept review execution"
      end
      # Historical authority is journal-backed: working files legitimately age
      # (feedback resolve archives and annotates finding files), so only
      # current-head reads re-hash artifacts.
      proof["artifacts"].each do |artifact|
        unless artifact_ref(artifact["path"]) == artifact
          raise Ace::Review::Atoms::CampaignContract::Invalid, "accepted review artifact changed"
        end
      end unless historical
      proof
    end
  end

  def accepted_approval_reference(reports:, producer:, reviewer:)
    proof = {"head" => @head, "artifacts" => reports, "producer" => producer, "reviewer" => reviewer}
    digest = Ace::Review::Atoms::CampaignContract.digest(proof)
    (@accepted_approvals ||= {})[digest] = proof
    {"attempt_id" => "accepted-approval", "digest" => digest}
  end

  def fixture_approval_evidence
    lambda do |ref, head:, artifacts:, producer:, reviewer:, historical: false|
      Ace::Review::Atoms::CampaignContract.object!(ref, "accepted approval receipt")
      proof = (@accepted_approvals || {})[ref["digest"]]
      unless proof && proof["head"] == head && proof["producer"] == producer && proof["reviewer"] == reviewer &&
          (artifacts - proof["artifacts"]).empty?
        raise Ace::Review::Atoms::CampaignContract::Invalid, "fixture coordinator did not accept independent approval"
      end
      proof["artifacts"].each do |artifact|
        raise Ace::Review::Atoms::CampaignContract::Invalid, "accepted approval artifact changed" unless artifact_ref(artifact["path"]) == artifact
      end unless historical
      proof
    end
  end

  def fixture_check_evidence
    lambda do |ref, head:, name:|
      proof = (@accepted_checks || {})[ref["digest"]]
      unless proof && proof["head"] == head && proof["checks"].any? { |c| c["name"] == name && c["verdict"] == "passed" }
        raise Ace::Review::Atoms::CampaignContract::Invalid, "fixture coordinator did not accept check evidence"
      end
      proof["artifacts"].each do |artifact|
        unless artifact_ref(artifact["path"]) == artifact
          raise Ace::Review::Atoms::CampaignContract::Invalid, "accepted check artifact changed"
        end
      end
      proof
    end
  end

  def accepted_check_reference(check_path)
    proof = {"head" => @head, "checks" => [{"name" => "tests", "verdict" => "passed"}],
      "artifacts" => [artifact_ref(check_path)]}
    digest = Ace::Review::Atoms::CampaignContract.digest(proof)
    (@accepted_checks ||= {})[digest] = proof
    {"attempt_id" => "accepted-test", "digest" => digest}
  end

  def add_campaign_approval(campaign, input, producer: "worker", reviewer: "reviewer")
    check_path = ".ace-local/check-#{input['round_id']}.json"
    File.write(File.join(@test_dir, check_path), JSON.generate("name" => "tests", "head" => input["head"],
      "status" => "succeeded", "exit_code" => 0, "completed_at" => Time.now.utc.iso8601))
    reports = input["sessions"].map do |session|
      artifact_ref(File.join(File.dirname(session["metadata"]["path"]), "review-report-reviewer.md"))
    end
    approval_path = ".ace-local/approval-#{input['round_id']}.json"
    approval = {"head" => input["head"], "base" => input["base"], "contract_identity" => campaign["contract_identity"],
      "required_scopes" => input["required_scopes"], "verdict" => "approved", "producer" => producer,
      "reviewer" => reviewer, "reports" => reports,
      "report_models" => reports.map { |ref| {"report" => ref, "report_model" => "reviewer"} },
      "receipt" => accepted_approval_reference(reports: reports, producer: producer, reviewer: reviewer),
      "checks" => [{"name" => "tests", "verdict" => "passed", "receipt" => accepted_check_reference(check_path)}]}
    File.write(File.join(@test_dir, approval_path), JSON.generate(approval))
    input["approval"] = artifact_ref(approval_path)
  end
end
