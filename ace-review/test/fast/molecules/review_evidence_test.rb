# frozen_string_literal: true

require "test_helper"
require "ace/review/molecules/review_evidence"

class ReviewEvidenceTest < AceReviewTest
  def make_session(name, pr: "https://github.com/example/repo/pull/42")
    dir = File.join(@test_dir, name)
    FileUtils.mkdir_p(dir)
    File.write(File.join(dir, "metadata.yml"), YAML.dump({"preset" => "code-valid", "pr_url" => pr,
      "diff_manifest" => {head_sha: "old"}}))
    File.write(File.join(dir, "review-report-model.md"), "Review of #{name}")
    dir
  end

  def evidence(*dirs)
    Ace::Review::Molecules::ReviewEvidence.build(session_dirs: dirs,
      pr_metadata: {"url" => "https://github.com/example/repo/pull/42", "headRefOid" => "new"})
  end

  def test_prior_commit_is_context_without_receipts_or_history_scan
    selected = make_session("selected")
    make_session("unrelated-history")
    result = evidence(selected)
    assert result[:success], result[:error]
    assert_includes result[:content], "Review of selected"
    refute_includes result[:content], "unrelated-history"
  end

  def test_closed_findings_keep_their_claim_and_resolution
    dir = make_session("fixed")
    archive = File.join(dir, "feedback", "_archived")
    FileUtils.mkdir_p(archive)
    File.write(File.join(archive, "finding.s.md"), <<~MD)
      ---
      id: finding01
      title: Missing check
      priority: high
      status: done
      files: [lib/app.rb]
      finding: Missing request validation
      resolution: Added validation and regression test
      ---
      ## Finding
      Missing request validation
    MD
    result = evidence(dir)
    assert result[:success], result[:error]
    assert_includes result[:content], "finding01 [high/done]"
    assert_includes result[:content], "Missing request validation"
    assert_includes result[:content], "Added validation and regression test"
  end

  def test_other_pr_is_not_silently_used_as_previous_review
    result = evidence(make_session("other", pr: "https://github.com/example/repo/pull/99"))
    refute result[:success]
    assert_includes result[:error], "different PR"
  end

  def test_empty_or_scalar_metadata_has_actionable_error
    dir = make_session("invalid")
    ["", "42"].each do |content|
      File.write(File.join(dir, "metadata.yml"), content)
      result = evidence(dir)
      refute result[:success]
      assert_includes result[:error], "Invalid session metadata"
    end
  end

  def test_missing_report_has_actionable_error
    dir = make_session("unfinished")
    File.delete(File.join(dir, "review-report-model.md"))
    result = evidence(dir)
    refute result[:success]
    assert_includes result[:error], "No review report"
  end
end
