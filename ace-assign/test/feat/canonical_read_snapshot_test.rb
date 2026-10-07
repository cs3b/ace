# frozen_string_literal: true
require_relative "../test_helper"
require "ace/assign/molecules/canonical_read_snapshot"
require "open3"

module Ace
  module Assign
    class CanonicalReadSnapshotTest < AceAssignTestCase
      Snapshot = Molecules::CanonicalReadSnapshot
      REF = "refs/ace/execution"

      def git(root, *arguments)
        out, error, status = Open3.capture3("git", *arguments, chdir: root, stdin_data: "")
        assert status.success?, "controlled Git #{arguments.inspect} failed (#{status.inspect}): #{error}"
        out.strip
      end

      def fixture
        with_temp_cache do |cache|
          Dir.mktmpdir("snapshot-", cache) do |temporary|
          root = File.realpath(temporary)
          repo, checkout, private_root = %w[repo checkout private].map { |name| File.join(root, name) }
          [repo, private_root].each { |path| FileUtils.mkdir_p(path, mode: 0o700) }
          git(repo, "init", "-b", "main")
          git(repo, "config", "user.name", "test")
          git(repo, "config", "user.email", "test@example.invalid")
          File.binwrite(File.join(repo, "README"), "candidate")
          git(repo, "add", "README")
          git(repo, "commit", "-m", "candidate")
          writer = Molecules::EvidenceJournal.new(repo_root: repo, checkout_root: checkout, ref: REF)
          event = Models::EvidenceEvent.build(type: "intent", attempt_id: "attempt", payload: {"operation" => "implement"})
          commit = writer.append(assignment_id: "assignment", attempt_id: "attempt", events: [event])
          snapshot = Snapshot.new(repo_root: repo, checkout_root: checkout, ref: REF, private_root: private_root)
          yield snapshot, writer, repo, private_root, event, commit
          end
        end
      end

      def deadline
        Process.clock_gettime(Process::CLOCK_MONOTONIC) + 30
      end

      def reader(snapshot)
        Molecules::EvidenceJournal.new(repo_root: "/unused/source", checkout_root: "/unused/checkout",
          ref: REF, read_boundary: snapshot)
      end

      def test_complete_inventory_diff_admits_only_fixed_root_or_selected_event_paths
        snapshot = Snapshot.new(repo_root: "/unused/repo", checkout_root: "/unused/checkout",
          ref: REF, private_root: "/unused/private")
        snapshot.instance_variable_set(:@view, "/unused/view")
        snapshot.instance_variable_set(:@commit, "a" * 40)
        calls = []
        snapshot.define_singleton_method(:run!) do |argv, **options|
          calls << [argv, options]
          Struct.new(:stdout).new("controlled raw diff")
        end
        assert_equal "controlled raw diff", snapshot.history_diff(["a" * 40], ["execution/"], output_limit: 1024)
        assert_equal "execution/", calls.last.first.last
        assert_equal "a" * 40 + "\n", calls.last.last.fetch(:stdin_data)
        %w[execution execution/assignment/ ../source/].each do |path|
          assert_raises(Snapshot::Unavailable) { snapshot.history_diff(["a" * 40], [path], output_limit: 1024) }
        end
        assert_raises(Snapshot::Unavailable) do
          snapshot.history_diff(["a" * 40], ["execution/", "execution/assignment/events/"], output_limit: 1024)
        end
        assert_equal 1, calls.size
      end

      def test_lock_fifo_and_symlink_checkout_refuse_without_waiting_for_writer
        fixture do |snapshot, writer, _repo, private_root, _event, _commit|
          checkout = writer.instance_variable_get(:@checkout_root)
          lock = File.join(checkout, ".evidence.lock")
          File.unlink(lock)
          File.mkfifo(lock, 0o600)
          assert_raises(Snapshot::Unavailable) { snapshot.with(deadline: deadline) { flunk "FIFO admitted" } }
          assert_empty Dir.children(private_root)
        end
        fixture do |snapshot, writer, _repo, private_root, _event, _commit|
          checkout = writer.instance_variable_get(:@checkout_root)
          moved = "#{checkout}-moved"
          File.rename(checkout, moved)
          File.symlink(moved, checkout)
          assert_raises(Snapshot::Unavailable) { snapshot.with(deadline: deadline) { flunk "symlink ancestry admitted" } }
          assert_empty Dir.children(private_root)
        end
      end

      def test_private_symlink_and_writable_ancestors_refuse_before_writes
        fixture do |snapshot, _writer, _repo, private_root, _event, _commit|
          parent = File.dirname(private_root)
          File.chmod(0o777, parent)
          begin
            assert_raises(Snapshot::Unavailable) { snapshot.with(deadline: deadline) { flunk "writable ancestry admitted" } }
            assert_empty Dir.children(private_root)
          ensure
            File.chmod(0o700, parent)
          end
        end
        fixture do |snapshot, _writer, _repo, private_root, _event, _commit|
          parent = File.dirname(private_root)
          moved = "#{parent}-moved"
          File.rename(parent, moved)
          File.symlink(moved, parent)
          begin
            assert_raises(Snapshot::Unavailable) { snapshot.with(deadline: deadline) { flunk "symlink ancestry admitted" } }
            assert_empty Dir.children(File.join(moved, "private"))
          ensure
            File.unlink(parent)
            File.rename(moved, parent)
          end
        end
      end

      def test_actual_immutable_owner_reads_use_private_view_and_source_config_is_not_executed
        fixture do |snapshot, writer, repo, private_root, event, commit|
          File.binwrite(File.join(repo, ".git", "config"), "[include]\npath=/unavailable/foreign-config\n[core]\nfsmonitor=never-run-this\n")
          snapshot.with(deadline: deadline) do |selected|
            journal = reader(selected)
            assert_equal commit, selected.commit
            assert_equal commit, journal.ref_value
            assert_equal [event], journal.read_events("assignment")
            assert_equal commit, journal.event_commit!(assignment_id: "assignment", event_digest: event.fetch("digest"), commit: commit)
            assert journal.verify_canonical_prefix!(commit: commit)
            assert_raises(Snapshot::Unavailable) { selected.history_diff([commit, commit], ["execution/assignment/events/"], output_limit: 1024) }
            assert_raises(Snapshot::Unavailable) { selected.history_diff([commit], ["../source/"], output_limit: 1024) }
            assert_raises(Snapshot::Unavailable) { selected.blob_sizes(["not-an-oid"]) }
            assert_raises(Snapshot::Unavailable) { selected.call(["update-ref", REF, "0" * 40]) }
            assert_raises(AttemptErrors::EvidenceUnavailable) do
              journal.append(assignment_id: "assignment", attempt_id: "attempt", events: [event])
            end
          end
          assert_empty Dir.children(private_root)
          assert_nil snapshot.commit
        end
      end

      def test_copied_prefix_remains_valid_after_source_advances_and_new_operation_selects_new_tip
        fixture do |snapshot, writer, _repo, private_root, event, commit|
          later = Models::EvidenceEvent.build(type: "process_start", attempt_id: "attempt",
            payload: {"pid" => 123}, previous_digest: event.fetch("digest"))
          tip = nil
          snapshot.with(deadline: deadline) do |selected|
            tip = writer.append(assignment_id: "assignment", attempt_id: "attempt", events: [later])
            assert_equal commit, reader(selected).ref_value
            assert_equal [event], reader(selected).read_events("assignment")
          end
          snapshot.with(deadline: deadline) do |selected|
            assert_equal tip, selected.commit
            assert_equal [event, later], reader(selected).read_events("assignment")
          end
          assert_empty Dir.children(private_root)
        end
      end

      def test_packed_reference_and_corrupt_or_redirected_sources
        fixture do |snapshot, _writer, repo, private_root, _event, commit|
          git(repo, "repack", "-a", "-d")
          git(repo, "pack-refs", "--all", "--prune")
          snapshot.with(deadline: deadline) { |selected| assert_equal commit, reader(selected).ref_value }
          FileUtils.mkdir_p(File.join(repo, ".git", "refs", "ace"))
          File.binwrite(File.join(repo, ".git", REF), "ref: refs/heads/main\n")
          assert_raises(Snapshot::Unavailable) { snapshot.with(deadline: deadline) { flunk "symbolic ref admitted" } }
          assert_empty Dir.children(private_root)
        end
        fixture do |snapshot, _writer, repo, private_root, _event, _commit|
          File.binwrite(File.join(repo, ".git", "objects", "info", "alternates"), "/foreign/objects\n")
          assert_raises(Snapshot::Unavailable) { snapshot.with(deadline: deadline) { flunk "alternates admitted" } }
          assert_empty Dir.children(private_root)
        end
        fixture do |snapshot, _writer, repo, _private_root, _event, _commit|
          object = Dir.glob(File.join(repo, ".git", "objects", "[0-9a-f][0-9a-f]", "*")).first
          File.chmod(0o644, object)
          File.binwrite(object, "corrupted object")
          assert_raises(Snapshot::Unavailable) { snapshot.with(deadline: deadline) { flunk "corrupt graph admitted" } }
        end
      end

      def test_expired_and_copy_resource_limits_are_typed_and_do_not_mutate_source
        fixture do |snapshot, writer, repo, private_root, _event, commit|
          error = assert_raises(Snapshot::Unavailable) { snapshot.with(deadline: 0) { flunk "expired snapshot admitted" } }
          assert_includes error.message, "resource_limit"
          directory = File.join(repo, ".git", "objects", "ff")
          FileUtils.mkdir_p(directory)
          File.open(File.join(directory, "f" * 38), "wb") do |file|
            file.truncate(Snapshot::BYTE_LIMIT + 1)
          end
          error = assert_raises(Snapshot::Unavailable) { snapshot.with(deadline: deadline) { flunk "oversized snapshot admitted" } }
          assert_includes error.message, "resource_limit"
          assert_equal commit, writer.ref_value
          assert_empty Dir.children(private_root)
        end
      end

      def test_source_ref_and_lock_replacement_during_copy_refuse_before_private_git
        [:ref, :lock].each do |replace|
          fixture do |snapshot, _writer, repo, private_root, _event, _commit|
            copied = snapshot.method(:copy!)
            changed = false
            snapshot.define_singleton_method(:copy!) do |relative, source|
              copied.call(relative, source)
              unless changed
                changed = true
                if replace == :ref
                  File.binwrite(File.join(repo, ".git", REF), "#{'f' * 40}\n")
                else
                  path = File.join(File.dirname(private_root), "checkout", ".evidence.lock")
                  File.rename(path, path + ".retained")
                  File.binwrite(path, "replacement")
                end
              end
            end
            error = assert_raises(Snapshot::Unavailable) { snapshot.with(deadline: deadline) { flunk "changed source admitted" } }
            assert_includes error.message, "source_changed"
            assert_empty Dir.children(private_root)
          end
        end
      end

      def test_shared_lock_excludes_existing_writers_and_busy_snapshot_refuses_without_io
        fixture do |snapshot, _writer, _repo, private_root, _event, commit|
          entered, release = Queue.new, Queue.new
          copied = snapshot.method(:copy!)
          first = true
          snapshot.define_singleton_method(:copy!) do |relative, source|
            if first
              first = false
              entered << true
              release.pop
            end
            copied.call(relative, source)
          end
          operation = Thread.new { snapshot.with(deadline: deadline) { |selected| reader(selected).ref_value } }
          Timeout.timeout(2) { entered.pop }
          lock_path = File.join(File.dirname(private_root), "checkout", ".evidence.lock")
          File.open(lock_path, File::RDONLY) { |lock| refute lock.flock(File::LOCK_EX | File::LOCK_NB) }
          error = assert_raises(Snapshot::Unavailable) { snapshot.with(deadline: deadline) { flunk "busy snapshot admitted" } }
          assert_includes error.message, "snapshot_busy"
          release << true
          assert operation.join(10), "snapshot did not release shared source lock"
          assert_equal commit, operation.value
          File.open(lock_path, File::RDONLY) { |lock| assert lock.flock(File::LOCK_EX | File::LOCK_NB) }
          assert_empty Dir.children(private_root)
        ensure
          release << true if release && operation&.alive?
          operation&.join(10)
        end
      end

      def test_private_view_parent_and_symbolic_object_paths_refuse
        fixture do |snapshot, _writer, _repo, private_root, _event, _commit|
          File.chmod(0o755, private_root)
          error = assert_raises(Snapshot::Unavailable) { snapshot.with(deadline: deadline) { flunk "public view admitted" } }
          assert_includes error.message, "private_storage_unprotected"
        end
        fixture do |snapshot, _writer, repo, private_root, _event, _commit|
          path = File.join(repo, ".git", "objects", "ff")
          File.symlink(private_root, path)
          assert_raises(Snapshot::Unavailable) { snapshot.with(deadline: deadline) { flunk "symbolic object directory admitted" } }
          assert_empty Dir.children(private_root)
        end
      end

      def test_canonical_raw_and_bounded_blobs_share_private_reader_and_preserve_binary_bytes
        fixture do |snapshot, writer, repo, _private_root, _event, _commit|
          bytes = "original\0binary\n\n".b
          reply = writer.mutate(assignment_id: "assignment", attempt_id: "attempt", mutation_id: "import",
            operation: "fixture", parameters_digest: "a" * 64, expected_generation: 0) do
            {data: {}, blobs: {"evidence/imports/original" => bytes}}
          end
          File.binwrite(File.join(repo, ".git", "config"), "[include]\npath=/foreign/config\n")
          snapshot.with(deadline: deadline) do |selected|
            journal = reader(selected)
            commit = reply.fetch("journal_commit")
            assert_equal bytes, journal.blob("evidence/imports/original", commit: commit)
            assert_equal bytes, journal.bounded_blob("evidence/imports/original", commit: commit, max_bytes: bytes.bytesize)
            assert_raises(Snapshot::Unavailable) do
              journal.bounded_blob("evidence/imports/original", commit: commit, max_bytes: bytes.bytesize - 1)
            end
          end
        end
      end

      def test_standalone_config_parser_normalizes_keys_and_never_follows_source_include
        fixture do |snapshot, _writer, repo, _private_root, _event, commit|
          foreign = File.join(repo, "foreign-config")
          File.binwrite(foreign, "[extensions]\nrefStorage=reftable\n")
          File.binwrite(File.join(repo, ".git", "config"), "[include]\npath=#{foreign}\n[core]\nrepositoryformatversion=0\n")
          snapshot.with(deadline: deadline) { |selected| assert_equal commit, reader(selected).ref_value }
        end
        ["[EXTENSIONS]\nReFStOrAgE=reftable\n", "[CoRe]\nRePoSiToRyFoRmAtVeRsIoN=1\n",
          "[core]\nrepositoryformatversion=0\nrepositoryformatversion=0\n", "[CORE]\nWoRkTrEe=/foreign\n"].each do |config|
          fixture do |snapshot, _writer, repo, private_root, _event, _commit|
            File.binwrite(File.join(repo, ".git", "config"), config)
            error = assert_raises(Snapshot::Unavailable) { snapshot.with(deadline: deadline) { flunk "unsupported backend admitted" } }
            assert_includes error.message, "unsupported_source"
            assert_empty Dir.children(private_root)
          end
        end
      end

      def test_complete_inventory_count_limit_does_not_truncate_or_accept_partial_view
        fixture do |snapshot, writer, repo, private_root, _event, commit|
          pack = File.join(repo, ".git", "objects", "pack")
          (Snapshot::ENTRY_LIMIT + 1).times do |index|
            File.binwrite(File.join(pack, "pack-#{format('%040x', index)}.keep"), "")
          end
          error = assert_raises(Snapshot::Unavailable) { snapshot.with(deadline: deadline) { flunk "truncated inventory admitted" } }
          assert_includes error.message, "resource_limit"
          assert_equal commit, writer.ref_value
          assert_empty Dir.children(private_root)
        end
      end
    end
  end
end
