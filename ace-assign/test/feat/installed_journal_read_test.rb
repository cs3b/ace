# frozen_string_literal: true

require_relative "../test_helper"
require "ace/assign/molecules/installed_journal_read"

module Ace
  module Assign
    class InstalledJournalReadTest < AceAssignTestCase
      def setup
        super
        @root = File.realpath(Dir.mktmpdir("ace-installed-read-", Dir.home))
        @repo = File.join(@root, "repo")
        FileUtils.mkdir_p(@repo)
        git("init", "-b", "main")
        @writer = Molecules::EvidenceJournal.new(repo_root: @repo,
          checkout_root: File.join(@root, "private-checkout"), ref: "refs/ace/execution")
        @event = Models::EvidenceEvent.build(type: "intent", attempt_id: "attempt",
          payload: {"operation" => "implement"})
        @commit = @writer.append(assignment_id: "assignment", attempt_id: "attempt", events: [@event])
        @boundary = Molecules::InstalledJournalRead.new(repo_root: @repo,
          ref: @writer.ref, owner_uid: Process.uid)
      end

      def teardown
        FileUtils.rm_rf(@root) if @root
        super
      end

      def test_reads_pinned_history_without_writer_lock_or_cache_and_refreshes_next_observation
        lock = File.open(File.join(@writer.checkout_root, ".evidence.lock"), File::RDONLY)
        lock.flock(File::LOCK_EX)
        @boundary.with(deadline: deadline) do |view|
          journal = reader(view)
          assert_equal @commit, journal.ref_value
          assert_equal [@event], journal.read_events("assignment")
          assert_nil journal.fixed_merge_request("absent")
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            journal.append(assignment_id: "assignment", attempt_id: "attempt", events: [@event])
          end
          assert_raises(AttemptErrors::EvidenceUnavailable) { view.call(["update-ref", @writer.ref, @commit]) }
        end
        lock.close
        second = Models::EvidenceEvent.build(type: "recovery_observation", attempt_id: "attempt",
          previous_digest: @event.fetch("digest"), payload: {"fact" => "next"})
        @boundary.with(deadline: deadline) do |view|
          updated = @writer.append(assignment_id: "assignment", attempt_id: "attempt", events: [second])
          refute_equal @commit, updated
          assert_equal @commit, reader(view).ref_value
          assert_equal [@event], reader(view).read_events("assignment")
        end
        @boundary.with(deadline: deadline) { |view| assert_equal [@event, second], reader(view).read_events("assignment") }
        refute File.exist?(File.join(@root, "unused-reader"))
      ensure
        lock&.close unless lock&.closed?
      end

      def test_poisoned_git_environment_and_cwd_cannot_select_another_journal
        previous = ENV.to_h.slice("GIT_DIR", "GIT_WORK_TREE", "GIT_CONFIG_COUNT", "GIT_CONFIG_KEY_0", "GIT_CONFIG_VALUE_0")
        ENV["GIT_DIR"] = "/missing/poisoned"
        ENV["GIT_WORK_TREE"] = "/missing/poisoned"
        ENV["GIT_CONFIG_COUNT"] = "1"
        ENV["GIT_CONFIG_KEY_0"] = "core.repositoryformatversion"
        ENV["GIT_CONFIG_VALUE_0"] = "999"
        Dir.chdir("/") do
          @boundary.with(deadline: deadline) { |view| assert_equal [@event], reader(view).read_events("assignment") }
        end
      ensure
        %w[GIT_DIR GIT_WORK_TREE GIT_CONFIG_COUNT GIT_CONFIG_KEY_0 GIT_CONFIG_VALUE_0].each { |key| ENV[key] = previous[key] }
      end

      def test_writable_ancestor_symlink_and_alternate_object_store_are_refused
        File.chmod(0o770, @root)
        assert_raises(AttemptErrors::EvidenceUnavailable) { @boundary.with(deadline: deadline) { flunk "writable parent" } }
        File.chmod(0o700, @root)
        File.rename(File.join(@repo, ".git"), File.join(@repo, "actual"))
        File.symlink("actual", File.join(@repo, ".git"))
        assert_raises(AttemptErrors::EvidenceUnavailable) { @boundary.with(deadline: deadline) { flunk "symlink" } }
        File.unlink(File.join(@repo, ".git"))
        File.rename(File.join(@repo, "actual"), File.join(@repo, ".git"))
        File.write(File.join(@repo, ".git/objects/info/alternates"), "/foreign/objects")
        assert_raises(AttemptErrors::EvidenceUnavailable) { @boundary.with(deadline: deadline) { flunk "alternate" } }
      end

      def test_writable_git_children_and_config_includes_cannot_supply_canonical_evidence
        %w[refs/ace/execution config objects].each do |name|
          path = File.join(@repo, ".git", name)
          mode = File.stat(path).mode & 0o777
          File.chmod(mode | 0o020, path)
          assert_raises(AttemptErrors::EvidenceUnavailable) { @boundary.with(deadline: deadline) { flunk name } }
          File.chmod(mode, path)
        end
        git("config", "include.path", "/foreign/config")
        assert_raises(AttemptErrors::EvidenceUnavailable) { @boundary.with(deadline: deadline) { flunk "include" } }
      end

      private

      def deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 10

      def reader(boundary)
        Molecules::EvidenceJournal.new(repo_root: @repo, ref: @writer.ref,
          checkout_root: File.join(@root, "unused-reader"), read_boundary: boundary)
      end

      def git(*args)
        _out, error, status = Open3.capture3("git", *args, chdir: @repo)
        assert status.success?, error
      end
    end
  end
end
