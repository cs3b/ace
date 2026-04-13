# frozen_string_literal: true

require_relative "../../test_helper"

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
      "diff for files: #{files&.join(", ")}"
    end

    def changed_files(staged_only: false)
      staged_only ? ["a.md"] : []
    end
  end

  class FakeStager
    attr_reader :last_error, :paths, :last_skipped_files

    def initialize
      @last_error = nil
      @paths = []
      @last_skipped_files = []
    end

    def stage_paths(paths, quiet: false)
      @paths = paths
      true
    end

    def all_files_skipped?
      false
    end
  end

  class FakeGenerator
    def generate(*)
      "feat: test"
    end

    def generate_batch(groups_context, intention: nil, config: nil)
      messages = groups_context.map { |ctx| "feat(#{ctx[:scope_name]}): test changes" }
      {messages: messages, order: groups_context.map { |ctx| ctx[:scope_name] }}
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
      config: {"model" => "glite"},
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
        config: {"model" => "glite"},
        files: ["README.md"]
      ),
      Ace::GitCommit::Models::CommitGroup.new(
        scope_name: "taskflow",
        source: ".ace/git/commit.yml",
        config: {"model" => "glite"},
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
      define_method(:stage_paths) { |_, quiet: false| true }
      define_method(:all_files_skipped?) { false }
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
        config: {"model" => "glite"},
        files: ["README.md"]
      ),
      Ace::GitCommit::Models::CommitGroup.new(
        scope_name: "taskflow",
        source: ".ace/git/commit.yml",
        config: {"model" => "glite"},
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
      define_method(:stage_paths) do |_, quiet: false|
        stage_count += 1
        stage_count <= 1 # First succeeds, second fails
      end
      define_method(:all_files_skipped?) { false }
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

  def test_skips_commit_when_all_files_gitignored
    git = FakeGit.new
    diff = FakeDiff.new
    generator = FakeGenerator.new

    # Create a stager that returns all_files_skipped? as true
    stager = Class.new do
      attr_reader :last_error, :last_skipped_files

      def initialize
        @last_error = nil
        @last_skipped_files = [{path: "ignored.log", pattern: "*.log"}]
      end

      def stage_paths(paths, quiet: false)
        true
      end

      def all_files_skipped?
        true
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

    assert result.success?, "Should succeed when all files are gitignored"
    assert result.skipped?, "Should indicate some groups were skipped"
    refute git.executed.any? { |args| args.first == "commit" }, "Should not commit gitignored groups"
  end

  def test_handles_mixed_valid_and_gitignored_groups
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
          return "ok"
        end
        "ok"
      end
    end.new

    diff = FakeDiff.new
    generator = FakeGenerator.new

    # First group has valid files, second has all gitignored
    stager = Class.new do
      attr_reader :last_error, :last_skipped_files

      def initialize
        @last_error = nil
        @last_skipped_files = []
        @stage_count = 0
      end

      def stage_paths(paths, quiet: false)
        @stage_count += 1
        if @stage_count == 1
          @last_skipped_files = []
          true
        else
          @last_skipped_files = [{path: "ignored.log", pattern: "*.log"}]
          true
        end
      end

      def all_files_skipped?
        @stage_count > 1
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
        files: ["ignored.log"]
      )
    ]

    options = Ace::GitCommit::Models::CommitOptions.new(quiet: true)

    result = executor.execute(groups, options)

    assert result.success?, "Should succeed with mixed valid and skipped groups"
    assert result.skipped?, "Should indicate some groups were skipped"
    assert_equal 1, commit_count, "Should only commit the valid group"
    assert_equal 1, result.records.count { |r| r.status == :success }
    assert_equal 1, result.records.count { |r| r.status == :skipped }
  end

  def test_falls_back_to_per_scope_generation_when_batch_fails
    git = FakeGit.new
    diff = FakeDiff.new
    stager = FakeStager.new

    generator = Class.new do
      def generate_batch(*)
        raise Ace::GitCommit::Error, "batch parse failed"
      end

      def generate(_diff, intention: nil, files: [], config: nil)
        scope = files.first.split("/").first
        return "feat(ace-assign): improve split fallback reliability" if scope == "ace-assign"
        "fix(ace-docs): correct changelog grouping examples"
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
        scope_name: "ace-assign",
        source: ".ace/git/commit.yml",
        config: {},
        files: ["ace-assign/lib/a.rb"]
      ),
      Ace::GitCommit::Models::CommitGroup.new(
        scope_name: "ace-docs",
        source: ".ace/git/commit.yml",
        config: {},
        files: ["ace-docs/lib/b.rb"]
      )
    ]

    options = Ace::GitCommit::Models::CommitOptions.new(quiet: true)
    result = executor.execute(groups, options)

    assert result.success?
    commit_messages = git.executed.filter_map do |args|
      args[2] if args[0] == "commit" && args[1] == "-m"
    end
    assert_includes commit_messages, "feat(ace-assign): improve split fallback reliability"
    assert_includes commit_messages, "fix(ace-docs): correct changelog grouping examples"
    refute commit_messages.any? { |msg| msg.start_with?("chore: update") }
  end
end
