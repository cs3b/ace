# frozen_string_literal: true

require_relative "../test_helper"
require "open3"

# The local assignment flow owns only `.ace-local/assign/`. It must never
# create the removed authority/attempt/journal evidence: no `refs/ace/execution`
# ref, no journal commits, and no evidence checkout.
class LocalFlowJournalFreeTest < AceAssignTestCase
  def setup
    super
    @previous_root = ENV.key?("PROJECT_ROOT_PATH") ? ENV["PROJECT_ROOT_PATH"] : :absent
    @previous_cache_dir = Ace::Assign.config["cache_dir"]
    @previous_dir = Dir.pwd
  end

  def teardown
    Dir.chdir(@previous_dir) if @previous_dir && File.directory?(@previous_dir)
    if @previous_root == :absent
      ENV.delete("PROJECT_ROOT_PATH")
    else
      ENV["PROJECT_ROOT_PATH"] = @previous_root
    end
    Ace::Assign.config["cache_dir"] = @previous_cache_dir
    Ace::Assign.reset_config!
    super
  end

  def test_local_flow_writes_no_authority_journal_or_evidence_checkout
    with_temp_cache do |temp|
      repo = File.join(temp, "repo")
      cache = File.join(repo, ".ace-local/assign")
      FileUtils.mkdir_p(repo)
      git_in(repo, "init", "-b", "main")
      git_in(repo, "config", "user.email", "test@example.com")
      git_in(repo, "config", "user.name", "Test")
      File.write(File.join(repo, "work.txt"), "base\n")
      git_in(repo, "add", "work.txt")
      git_in(repo, "commit", "-m", "base")

      config_path = File.join(repo, "job.yaml")
      File.write(config_path, {
        "assignment" => {"name" => "journal-free", "description" => "local only"},
        "steps" => [{"name" => "implement", "instructions" => "Implement the step"}]
      }.to_yaml)

      ENV["PROJECT_ROOT_PATH"] = repo
      Ace::Assign.config["cache_dir"] = cache
      Dir.chdir(repo)
      baseline_commits = git_in(repo, "rev-list", "--count", "HEAD")

      capture_io { assert_equal 0, Ace::Assign::CLI.start(["create", "--yaml", config_path]) }
      capture_io { assert_equal 0, Ace::Assign::CLI.start(["start"]) }

      report = File.join(repo, "report.md")
      File.write(report, "implemented")
      capture_io { assert_equal 0, Ace::Assign::CLI.start(["finish", "--message", report]) }

      status = JSON.parse(capture_io { Ace::Assign::CLI.start(["status", "--format", "json"]) }.first)
      assert_equal "completed", status.dig("assignment", "state")
      assert_equal "1/1 done", status["progress"]
      refute status.key?("attempt"), "local status projected attempt authority"
      refute status.key?("journal_commit"), "local status projected a journal commit"

      # No authority journal ref and no journal commits were created.
      refute git_ref_exists?(repo, "refs/ace/execution"), "local flow created refs/ace/execution"
      assert_equal "", git_in(repo, "for-each-ref", "refs/ace")
      assert_equal baseline_commits, git_in(repo, "rev-list", "--count", "HEAD")

      # No disposable evidence checkout and no attempt/journal/evidence state.
      refute Dir.exist?(File.join(cache, "evidence-checkout")), "local flow created the evidence checkout"
      assignment_id = status.dig("assignment", "id")
      assignment_dir = File.join(cache, assignment_id)
      assert Dir.exist?(assignment_dir)
      assert_equal %w[assignment.yaml reports steps], Dir.children(assignment_dir).sort
      assert_empty Dir.glob(File.join(cache, "**", "*.{json,journal,log}"))
      assert_empty Dir.glob(File.join(cache, "*attempt*"))
      assert_empty Dir.glob(File.join(cache, "*evidence*"))
      assert_empty Dir.glob(File.join(cache, "*journal*"))
    end
  end

  private

  def git_ref_exists?(repo, ref)
    _out, _err, status = Open3.capture3("git", "-C", repo, "rev-parse", "--verify", "--quiet", ref)
    status.success?
  end
end
