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
      revisions: ->(ref, *_args) { ref == "HEAD" ? @head : @base })
  end

  def start_campaign(scopes: ["full"])
    campaign_manager.start(subject: campaign_subject, contract: "Frozen requirements", policy: campaign_policy(scopes: scopes))
  end

  def round_input(round, scopes: ["full"], attempt: nil)
    {"attempt_id" => attempt || "attempt-#{round}", "round_id" => "round-#{round}", "head" => @head,
      "base" => @base, "required_scopes" => scopes, "scope_identity" => scopes.to_h { |s| [s, "code-valid"] },
      "sessions" => [], "dispositions" => []}
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
      "subject" => campaign_subject, "round_id" => input["round_id"], "scope" => scope,
      "head" => input["head"], "base" => input["base"], "scope_identity" => "code-valid"}
    metadata = {"preset" => "code-valid", "campaign_binding" => binding, "noop_round" => noop,
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
    metadata_file = File.join(dir, "metadata.yml")
    File.write(File.join(@test_dir, metadata_file), YAML.dump(metadata))
    input["sessions"] << {"scope" => scope, "metadata" => artifact_ref(metadata_file)}
    dir
  end

  def add_campaign_approval(campaign, input, producer: "worker")
    check_path = ".ace-local/check-#{input['round_id']}.json"
    File.write(File.join(@test_dir, check_path), JSON.generate("name" => "tests", "head" => input["head"],
      "status" => "succeeded", "exit_code" => 0, "completed_at" => Time.now.utc.iso8601))
    reports = input["sessions"].map do |session|
      artifact_ref(File.join(File.dirname(session["metadata"]["path"]), "review-report-reviewer.md"))
    end
    approval_path = ".ace-local/approval-#{input['round_id']}.json"
    approval = {"head" => input["head"], "base" => input["base"], "contract_identity" => campaign["contract_identity"],
      "required_scopes" => input["required_scopes"], "verdict" => "approved", "producer" => producer,
      "reviewer" => "reviewer", "reports" => reports,
      "checks" => [{"name" => "tests", "verdict" => "passed", "artifact" => artifact_ref(check_path)}]}
    File.write(File.join(@test_dir, approval_path), JSON.generate(approval))
    input["approval"] = artifact_ref(approval_path)
  end
end
