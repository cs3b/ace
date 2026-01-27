# frozen_string_literal: true

require_relative "../test_helper"

class SplitCommitExecutorTest < TestCase
  class FakeGit
    attr_reader :executed

    def initialize
      @executed = []
    end

    def execute(*args)
      @executed << args
      return "abc123" if args == ["rev-parse", "HEAD"]
      "ok"
    end
  end

  class FakeDiff
    def get_staged_diff
      "diff"
    end

    def get_all_diff(files = nil)
      "diff for files: #{files&.join(', ')}"
    end

    def changed_files(staged_only: false)
      staged_only ? ["a.md"] : []
    end
  end

  class FakeStager
    attr_reader :last_error, :paths

    def initialize
      @last_error = nil
      @paths = []
    end

    def stage_paths(paths)
      @paths = paths
      true
    end
  end

  class FakeGenerator
    def generate(*)
      "feat: test"
    end

    def generate_batch(groups_context, intention: nil, config: nil)
      messages = groups_context.map { |ctx| "feat(#{ctx[:scope_name]}): test changes" }
      { messages: messages, order: groups_context.map { |ctx| ctx[:scope_name] } }
    end
  end

  def test_dry_run_does_not_commit
    git = FakeGit.new
    diff = FakeDiff.new
    stager = FakeStager.new
    generator = FakeGenerator.new

    executor = Ace::GitCommit::Molecules::SplitCommitExecutor.new(
      git_executor: git,
      diff_analyzer: diff,
      file_stager: stager,
      message_generator: generator
    )

    group = Ace::GitCommit::Models::CommitGroup.new(
      scope_name: "docs",
      source: ".ace/git/commit.yml",
      config: { "model" => "glite" },
      files: ["a.md"]
    )

    options = Ace::GitCommit::Models::CommitOptions.new(dry_run: true, quiet: true)

    result = executor.execute([group], options)

    assert result.success?
    refute git.executed.any? { |args| args.first == "commit" }
  end

  def test_dry_run_tracks_groups_for_visibility
    git = FakeGit.new
    diff = FakeDiff.new
    stager = FakeStager.new
    generator = FakeGenerator.new

    executor = Ace::GitCommit::Molecules::SplitCommitExecutor.new(
      git_executor: git,
      diff_analyzer: diff,
      file_stager: stager,
      message_generator: generator
    )

    groups = [
      Ace::GitCommit::Models::CommitGroup.new(
        scope_name: "docs",
        source: ".ace/git/commit.yml",
        config: { "model" => "glite" },
        files: ["README.md"]
      ),
      Ace::GitCommit::Models::CommitGroup.new(
        scope_name: "taskflow",
        source: ".ace/git/commit.yml",
        config: { "model" => "glite" },
        files: ["task.md"]
      )
    ]

    options = Ace::GitCommit::Models::CommitOptions.new(dry_run: true, quiet: true)

    result = executor.execute(groups, options)

    assert result.success?
    assert result.dry_run?, "Result should indicate dry-run mode"
    assert_equal 2, result.records.length, "Dry-run should track all groups for visibility"
    assert result.records.all? { |r| r.sha.nil? }, "Dry-run records should have nil SHA"
    assert result.records.all? { |r| r.status == :dry_run }, "Dry-run records should have :dry_run status"
  end

  def test_rollback_on_second_group_failure
    commit_count = 0
    git = Class.new do
      define_method(:initialize) { @executed = [] }
      attr_reader :executed

      define_method(:execute) do |*args|
        @executed << args
        if args == ["rev-parse", "HEAD"]
          return "original123"
        elsif args.first == "commit"
          commit_count += 1
          raise Ace::GitCommit::GitError, "Commit failed" if commit_count > 1
          return "ok"
        end
        "ok"
      end
    end.new

    stager = Class.new do
      define_method(:last_error) { nil }
      define_method(:stage_paths) { |_| true }
    end.new

    diff = FakeDiff.new
    generator = FakeGenerator.new

    executor = Ace::GitCommit::Molecules::SplitCommitExecutor.new(
      git_executor: git,
      diff_analyzer: diff,
      file_stager: stager,
      message_generator: generator
    )

    groups = [
      Ace::GitCommit::Models::CommitGroup.new(
        scope_name: "docs",
        source: ".ace/git/commit.yml",
        config: { "model" => "glite" },
        files: ["README.md"]
      ),
      Ace::GitCommit::Models::CommitGroup.new(
        scope_name: "taskflow",
        source: ".ace/git/commit.yml",
        config: { "model" => "glite" },
        files: ["task.md"]
      )
    ]

    options = Ace::GitCommit::Models::CommitOptions.new(quiet: true)

    result = executor.execute(groups, options)

    assert result.failed?, "Should fail when second group commit fails"
    assert git.executed.any? { |args| args == ["reset", "--soft", "original123"] },
           "Should rollback to original HEAD"
    assert_equal 2, result.records.length
    assert_equal :success, result.records[0].status
    assert_equal :failure, result.records[1].status
  end

  def test_rollback_on_staging_failure
    git = FakeGit.new
    diff = FakeDiff.new
    generator = FakeGenerator.new

    stage_count = 0
    stager = Class.new do
      define_method(:last_error) { "Failed to stage files" }
      define_method(:stage_paths) do |_|
        stage_count += 1
        stage_count <= 1 # First succeeds, second fails
      end
    end.new

    executor = Ace::GitCommit::Molecules::SplitCommitExecutor.new(
      git_executor: git,
      diff_analyzer: diff,
      file_stager: stager,
      message_generator: generator
    )

    groups = [
      Ace::GitCommit::Models::CommitGroup.new(
        scope_name: "docs",
        source: ".ace/git/commit.yml",
        config: {},
        files: ["README.md"]
      ),
      Ace::GitCommit::Models::CommitGroup.new(
        scope_name: "taskflow",
        source: ".ace/git/commit.yml",
        config: {},
        files: ["task.md"]
      )
    ]

    options = Ace::GitCommit::Models::CommitOptions.new(quiet: true)

    result = executor.execute(groups, options)

    assert result.failed?, "Should fail when staging fails"
    assert git.executed.any? { |args| args == ["reset", "--soft", "abc123"] },
           "Should rollback to original HEAD on staging failure"
  end
end
