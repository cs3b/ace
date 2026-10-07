# frozen_string_literal: true
require_relative "../test_helper"
require "ace/assign/molecules/evidence_journal"

module Ace
  module Assign
    class EventCommitsTest < AceAssignTestCase
      def fixture
        with_temp_cache do |root|
          repo = File.join(root, "batch-history")
          FileUtils.mkdir_p(repo)
          git = lambda do |*args, input: nil|
            output, error, status = Open3.capture3("git", "-C", repo, *args, stdin_data: input.to_s)
            assert status.success?, error
            output.strip
          end
          git.call("init", "-b", "main")
          git.call("config", "user.name", "test")
          git.call("config", "user.email", "test@example.invalid")
          git.call("commit", "--allow-empty", "-m", "base")
          base = git.call("rev-parse", "HEAD")
          journal = Molecules::EvidenceJournal.new(repo_root: repo, checkout_root: File.join(root, "batch-checkout"))
          first = Models::EvidenceEvent.build(type: "intent", attempt_id: "attempt", payload: {"scope" => "one", "text" => "zażółć gęślą jaźń"})
          first_commit = journal.append(assignment_id: "assignment", attempt_id: "attempt", events: [first])
          second = Models::EvidenceEvent.build(type: "process_start", attempt_id: "attempt", payload: {"pid" => 1},
            previous_digest: first.fetch("digest"))
          tip = journal.append(assignment_id: "assignment", attempt_id: "attempt", events: [second])
          yield journal, git, base, first, second, first_commit, tip
        end
      end

      def test_batch_and_singletons_authenticate_same_introductions_with_one_complete_walk
        fixture do |journal, _git, _base, first, second, first_commit, tip|
          reads = 0
          scans = 0
          commands = 0
          read = journal.method(:read_events)
          execute = journal.method(:git)
          journal.define_singleton_method(:read_events) { |*args, **kwargs| reads += 1; read.call(*args, **kwargs) }
          journal.define_singleton_method(:git) { |*args| commands += 1; scans += 1 if args.first == "rev-list"; execute.call(*args) }
          digests = [first, second].map { |event| event.fetch("digest") }
          singleton = digests.to_h { |digest| [digest, journal.event_commit!(assignment_id: "assignment", event_digest: digest, commit: tip)] }
          singleton_reads = reads
          singleton_commands = commands
          assert_equal 2, scans
          reads = scans = commands = 0
          batch = journal.event_commits!(assignment_id: "assignment", event_digests: digests, commit: tip)
          assert_equal singleton, batch
          assert_equal [first_commit, tip], digests.map { |digest| batch.fetch(digest) }
          assert_equal 1, scans
          assert_equal singleton_reads / 2, reads
          assert_operator commands, :<, singleton_commands
          warn "HISTORY_BATCH_METRIC singleton_git=#{singleton_commands} batch_git=#{commands} singleton_reads=#{singleton_reads} batch_reads=#{reads}"
          assert_raises(FrozenError) { batch.fetch(digests.first).replace("changed") }
          assert_raises(FrozenError) { batch["changed"] = "value" }
        end
      end

      def test_history_batch_preserves_introductions_across_more_than_one_commit_chunk
        fixture do |journal, git, _base, first, second, first_commit, tip|
          tree = git.call("rev-parse", "#{tip}^{tree}")
          selected = tip
          70.times { |index| selected = git.call("commit-tree", tree, "-p", selected, "-m", "unchanged #{index}") }
          commands = []
          original = Herdr::Molecules::BoundedProcess.method(:call)
          runner = lambda do |argv, **options|
            commands << argv.dup
            original.call(argv, **options)
          end
          batch = Herdr::Molecules::BoundedProcess.stub(:call, runner) do
            journal.event_commits!(assignment_id: "assignment", event_digests: [first, second].map { |event| event.fetch("digest") }, commit: selected)
          end
          assert_equal first_commit, batch.fetch(first.fetch("digest"))
          assert_equal tip, batch.fetch(second.fetch("digest"))
          assert_equal 2, commands.count { |argv| argv[1] == "diff-tree" }, "73 prefixes require two fixed batches, including empty commits"
          assert_equal [first, second], journal.read_events("assignment", commit: selected)
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            journal.send(:decode_history_diff!, [first_commit, tip], ["execution/assignment/events/"], "#{tip}\0#{first_commit}\0")
          end
        end
      end

      def test_history_raw_frames_refuse_missing_duplicate_extra_and_invalid_object_metadata
        journal = Molecules::EvidenceJournal.new(repo_root: "/unused")
        commits = ["a" * 40, "b" * 40]
        paths = ["execution/assignment/events/"]
        path = paths.first + "event.json"
        oid = "c" * 40
        valid = "#{commits.first}\0:000000 100644 #{'0' * 40} #{oid} A\0#{path}\0#{commits.last}\0"
        assert_equal [[path, "A", "0" * 40, oid]], journal.send(:decode_history_diff!, commits, paths, valid).fetch(commits.first)
        [valid.chop, "", "#{commits.first}\0", valid + "extra\0", valid.sub(commits.last, commits.first),
          valid.sub("100644", "160000"), valid.sub("100644", "000000"), valid.sub(path, "execution/foreign/events/event.json"),
          valid.sub(" A\0", " R100\0"), valid.sub("#{commits.last}\0", ":000000 100644 #{'0' * 40} #{oid} A\0#{path}\0#{commits.last}\0")].each do |raw|
          assert_raises(AttemptErrors::EvidenceUnavailable) { journal.send(:decode_history_diff!, commits, paths, raw) }
        end
        assert_raises(AttemptErrors::EvidenceUnavailable) do
          journal.stub(:bounded_history_read!, "#{oid} tree 12\n") { journal.send(:history_blob_sizes!, [oid]) }
        end
      end

      def test_batch_refuses_changed_original_event_bytes_even_when_parsed_chain_is_unchanged
        fixture do |journal, git, _base, first, second, _first_commit, _tip|
          checkout = journal.send(:checkout_dir)
          path = File.join(checkout, "execution", "assignment", "events", journal.send(:event_filename, first))
          File.binwrite(path, File.binread(path) + " ")
          git.call("-C", checkout, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "-am", "raw event bytes changed")
          changed = git.call("-C", checkout, "rev-parse", "HEAD")
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            journal.event_commits!(assignment_id: "assignment", event_digests: [first, second].map { |event| event.fetch("digest") }, commit: changed)
          end
        end
      end

      def test_missing_duplicate_malformed_removed_reappeared_and_merge_history_refuse
        fixture do |journal, git, base, first, second, _first_commit, tip|
          digests = [first, second].map { |event| event.fetch("digest") }
          [[], [digests.first, digests.first], ["bad"], "scalar", [nil], Array.new(Molecules::EvidenceJournal::HISTORY_LIMIT + 1)].each do |selectors|
            assert_raises(AttemptErrors::EvidenceUnavailable) do
              journal.event_commits!(assignment_id: "assignment", event_digests: selectors, commit: tip)
            end
          end
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            journal.event_commits!(assignment_id: "assignment", event_digests: [digests.first, "a" * 64], commit: tip)
          end
          original_tree = git.call("rev-parse", "#{tip}^{tree}")
          empty_tree = git.call("rev-parse", "#{base}^{tree}")
          removed = git.call("commit-tree", empty_tree, "-p", tip, "-m", "removed")
          reappeared = git.call("commit-tree", original_tree, "-p", removed, "-m", "reappeared")
          merged = git.call("commit-tree", original_tree, "-p", tip, "-p", base, "-m", "merge")
          [removed, reappeared, merged].each do |commit|
            assert_raises(AttemptErrors::EvidenceUnavailable) do
              journal.event_commits!(assignment_id: "assignment", event_digests: digests, commit: commit)
            end
          end
        end
      end

      def test_batched_blob_reader_matches_actual_git_and_refuses_malformed_frames
        fixture do |journal, git, _base, first, second, _first_commit, tip|
          expected = [first, second]
          assert_equal expected, journal.read_events("assignment", commit: tip)
          first_path = "execution/assignment/events/#{journal.send(:event_filename, first)}"
          bytes, error, status = Open3.capture3("git", "-C", journal.repo_root, "show", "#{tip}:#{first_path}")
          assert status.success?, error
          oid = Digest::SHA1.hexdigest("blob #{bytes.bytesize}\0" + bytes)
          entries = [[oid, bytes.bytesize]]
          valid = "#{oid} blob #{bytes.bytesize}\n#{bytes}\n"
          assert_equal [bytes.b], journal.send(:decode_event_blobs!, entries, valid)
          assert_equal [bytes.b, bytes.b], journal.send(:decode_event_blobs!, entries * 2,
            (valid + valid).force_encoding(Encoding::UTF_8))
          ["", valid.chop, valid + "unexpected", valid.sub(" blob ", " commit "),
            valid.sub(oid, "a" * 40), valid.sub(bytes, bytes.sub("intent", "invent")),
            "#{oid} blob #{bytes.bytesize + 1}\n#{bytes}\n", "x" * 128 + "\n"].each do |output|
            assert_raises(AttemptErrors::EvidenceUnavailable) { journal.send(:decode_event_blobs!, entries, output) }
          end
          # Actual held blob bytes, not JSON reserialization, are hashed.
          selection = [[git.call("rev-parse", "#{tip}:#{first_path}"), bytes.bytesize]]
          assert_equal [bytes.b], journal.send(:decode_event_blobs!, selection, journal.send(:read_event_blobs!, selection))
          assert_raises(AttemptErrors::EvidenceUnavailable) { journal.send(:read_event_blobs!, [[selection.first.first, 0]]) }
        end
      end

      def test_bounded_process_empty_failure_timeout_and_oversized_refuse
        fixture do |journal, _git, _base, _first, _second, _first_commit, _tip|
          entries = [["a" * 40, 10]]
          status = Struct.new(:success?).new(true)
          process = Herdr::Molecules::BoundedProcess
          [process::Result.new("", "", status, false), process::Result.new("", "", status, true),
            process::Result.new("", "failure", Struct.new(:success?).new(false), false)].each do |result|
            process.stub(:call, result) do
              assert_raises(AttemptErrors::EvidenceUnavailable) do
                journal.send(:decode_event_blobs!, entries, journal.send(:read_event_blobs!, entries))
              end
            end
          end
          [Timeout::Error, process::PostLaunchError].each do |failure|
            process.stub(:call, ->(*) { raise failure, "controlled refusal" }) do
              assert_raises(AttemptErrors::EvidenceUnavailable) { journal.send(:read_event_blobs!, entries) }
            end
          end
        end
      end
    end
  end
end
