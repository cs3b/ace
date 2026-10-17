# frozen_string_literal: true

require_relative "../test_helper"
require "ace/assign/authority/candidate_transfer"
require "open3"

module Ace
  module Assign
    class CandidateTransferTest < AceAssignTestCase
      include Ace::TestSupport::ConfigHelpers
      def with_fixture
        # Public /tmp ancestry is intentionally inadmissible in production.
        Dir.mktmpdir("ace-candidate-test-", Etc.getpwuid(Process.uid).dir) do |root|
          File.chmod(0700, root)
          source = File.join(root, "source")
          authority = File.join(root, "authority")
          FileUtils.mkdir_p([source, authority], mode: 0700)
          git(source, "init", "-b", "main")
          File.binwrite(File.join(source, "README"), "candidate\x00\n".b)
          git(source, "add", "README")
          git(source, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "-m", "candidate")
          head = git(source, "rev-parse", "HEAD").strip
          path = File.join(root, "source.bundle")
          git(source, "bundle", "create", path, "--all")
          yield Authority::CandidateTransfer.new(root: authority), root, source, head, File.binread(path)
        end
      end

      def git(root, *args)
        output, error, status = Open3.capture3("/usr/bin/git", "-C", root, *args)
        assert status.success?, error
        output
      end

      def admit(transfer, head, bytes, **changes)
        transfer.admit(**{head: head, bytes: bytes, size: bytes.bytesize,
          sha256: Digest::SHA256.hexdigest(bytes)}.merge(changes))
      end

      def test_admits_self_contained_exact_candidate_and_exports_verified_bundle
        with_fixture do |transfer, root, source, head, bytes|
          result = admit(transfer, head, bytes)
          assert_equal head, result["head"]
          assert_equal git(source, "rev-parse", "HEAD^{tree}").strip, result["tree"]
          assert_equal Digest::SHA256.hexdigest(result["bundle"]), result["sha256"]
          assert_equal result["bundle"].bytesize, result["bytes"]
          receiver = File.join(root, "receiver")
          FileUtils.mkdir_p(receiver)
          git(receiver, "init", "--bare")
          received = File.join(root, "received.bundle")
          File.binwrite(received, result["bundle"])
          git(receiver, "fetch", received, "refs/heads/candidate:refs/heads/accepted")
          assert_equal "candidate\x00\n".b, git(receiver, "show", "refs/heads/accepted:README").b
          assert_empty Dir.children(File.join(root, "authority"))
        end
      end

      def test_campaign_materialization_has_exact_private_git_head_and_no_uploader_configuration
        with_fixture do |transfer, root, source, head, bytes|
          tree = git(source, "rev-parse", "HEAD^{tree}").strip
          result = transfer.materialize_repository(bytes: bytes, sha256: Digest::SHA256.hexdigest(bytes),
            size: bytes.bytesize, head: head, tree: tree, root: File.join(root, "authority"))
          private_repo = result.fetch("directory")
          refute_equal source, private_repo
          assert_equal head, git(private_repo, "rev-parse", "HEAD").strip
          assert_equal tree, git(private_repo, "rev-parse", "HEAD^{tree}").strip
          assert_equal "candidate\x00\n".b, File.binread(File.join(private_repo, "README"))
          assert_empty git(private_repo, "status", "--porcelain")
          assert_equal head, git(source, "rev-parse", "HEAD").strip
        end
      end

      def test_selected_entry_bound_counts_ancestor_directories_before_writing_source_files
        with_fixture do |transfer, root, source, _head, _bytes|
          FileUtils.mkdir_p(File.join(source, "nested"))
          File.write(File.join(source, "nested", "file"), "bounded")
          git(source, "add", ".")
          git(source, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "-m", "nested")
          head, tree = git(source, "rev-parse", "HEAD", "HEAD^{tree}").lines.map(&:strip)
          bundle = File.join(root, "bounded.bundle")
          git(source, "bundle", "create", bundle, "--all")
          bytes = File.binread(bundle)
          options = {bytes: bytes, sha256: Digest::SHA256.hexdigest(bytes), size: bytes.bytesize,
            head: head, tree: tree, root: File.join(root, "authority")}
          assert_raises(AttemptErrors::ReceiptRejected) { transfer.materialize_repository(**options, max_entries: 3) }
          assert_empty Dir.children(File.join(root, "authority"))
          materialized = transfer.materialize_repository(**options, max_entries: 4)
          assert_equal "bounded", File.read(File.join(materialized.fetch("directory"), "nested", "file"))
          assert_equal head, git(materialized.fetch("directory"), "rev-parse", "HEAD").strip
        end
      end

      def test_campaign_read_view_uses_exact_bundle_and_expires_without_changing_source
        with_fixture do |transfer, root, source, base, _bytes|
          File.binwrite(File.join(source, "README"), "second candidate\n")
          git(source, "add", "README")
          git(source, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "-m", "second")
          head = git(source, "rev-parse", "HEAD").strip
          tree = git(source, "rev-parse", "HEAD^{tree}").strip
          path = File.join(root, "full.bundle")
          git(source, "bundle", "create", path, "--all")
          bytes = File.binread(path)
          retained = nil
          transfer.with_campaign_repository(bytes: bytes, sha256: Digest::SHA256.hexdigest(bytes), size: bytes.bytesize,
            head: head, tree: tree, base: base) do |view|
            retained = view
            assert_equal head, view.head
            assert_equal base, view.base
            assert view.clean?
            assert view.full_diff?(base, head)
            assert_raises(AttemptErrors::ReceiptRejected) { view.commit!("f" * 40) }
            assert_raises(AttemptErrors::EvidenceUnavailable) { Thread.new { view.head }.value }
          end
          assert_raises(AttemptErrors::EvidenceUnavailable) { retained.head }
          assert_empty Dir.children(File.join(root, "authority"))
          assert_equal head, git(source, "rev-parse", "HEAD").strip
        end
      end

      def test_batched_materialization_preserves_path_order_and_duplicate_blob_bytes
        with_fixture do |transfer, root, source, _head, _bytes|
          File.write(File.join(source, "a"), "duplicate")
          File.write(File.join(source, "b"), "other")
          File.write(File.join(source, "c"), "duplicate")
          git(source, "add", ".")
          git(source, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "-m", "duplicates")
          input = comparison_input(root, source, "duplicate-input")
          selected = []
          result = transfer.materialize(**input, root: File.join(root, "authority")) do |path, _mode, _oid, content|
            selected << [path, content]
          end
          assert_equal %w[README a b c], selected.map(&:first)
          assert_equal "duplicate", File.binread(File.join(result.fetch("directory"), "a"))
          assert_equal "duplicate", File.binread(File.join(result.fetch("directory"), "c"))
          assert_equal "other", File.binread(File.join(result.fetch("directory"), "b"))
        end
      end

      def test_batched_materialization_accepts_an_empty_tree
        with_fixture do |transfer, root, source, _head, _bytes|
          git(source, "rm", "README")
          git(source, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "-m", "empty")
          input = comparison_input(root, source, "empty-input")
          result = transfer.materialize(**input, root: File.join(root, "authority"))
          assert_empty Dir.children(result.fetch("directory"))
        end
      end

      def test_batched_materialization_carries_an_oversized_single_blob_alone
        with_fixture do |transfer, root, source, _head, _bytes|
          payload = "b" * (Authority::CandidateBlobBatch::BATCH_BYTES + 1)
          File.binwrite(File.join(source, "large.bin"), payload)
          git(source, "add", "large.bin")
          git(source, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "-m", "oversized blob")
          input = comparison_input(root, source, "large-input")
          selected = []
          result = transfer.materialize(**input, root: File.join(root, "authority")) do |path, _mode, _oid, content|
            selected << [path, content.bytesize]
          end
          assert_equal [["README", 11], ["large.bin", payload.bytesize]], selected
          assert_equal payload, File.binread(File.join(result.fetch("directory"), "large.bin"))
        end
      end

      def test_blob_size_selector_rejects_oversized_or_malformed_oid_sets_before_git
        with_fixture do |transfer, _root, _source, _head, _bytes|
          oversized = Array.new(Authority::CandidateBlobBatch::MAX_OBJECTS + 1) { |index| format("%040x", index) }
          error = assert_raises(AttemptErrors::ReceiptRejected) do
            transfer.send(:candidate_blob_sizes, "/nonexistent", Process.clock_gettime(Process::CLOCK_MONOTONIC), oversized)
          end
          assert_match(/invalid or oversized/, error.message)
          error = assert_raises(AttemptErrors::ReceiptRejected) do
            transfer.send(:candidate_blob_sizes, "/nonexistent", Process.clock_gettime(Process::CLOCK_MONOTONIC), ["z" * 40])
          end
          assert_match(/invalid or oversized/, error.message)
        end
      end

      def test_refuses_size_digest_and_unadvertised_head_without_retained_objects
        with_fixture do |transfer, root, _source, head, bytes|
          assert_raises(AttemptErrors::ReceiptRejected) { admit(transfer, head, bytes, size: bytes.bytesize + 1) }
          assert_raises(AttemptErrors::ReceiptRejected) { admit(transfer, head, bytes, sha256: "0" * 64) }
          assert_raises(AttemptErrors::ReceiptRejected) { admit(transfer, "f" * 40, bytes) }
          assert_raises(AttemptErrors::ReceiptRejected) { admit(transfer, head, "not a bundle") }
          assert_empty Dir.children(File.join(root, "authority"))
        end
      end

      def test_head_comparison_reads_both_complete_nonancestor_bundles_and_expires
        with_fixture do |transfer, root, source, before_base, _bytes|
          File.write(File.join(source, "code.rb"), "puts :before\n")
          git(source, "add", ".")
          git(source, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "-m", "before")
          before = comparison_input(root, source, "before")
          git(source, "checkout", "--orphan", "new-base")
          File.write(File.join(source, "code.rb"), "puts :base\n")
          git(source, "add", ".")
          git(source, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "-m", "new base")
          after_base = git(source, "rev-parse", "HEAD").strip
          File.write(File.join(source, "code.rb"), "puts :after\n")
          git(source, "add", ".")
          git(source, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "-m", "after")
          after = comparison_input(root, source, "after")
          contexts = []
          escaped = nil
          2.times do
            transfer.with_head_comparison(before: before, after: after, before_base: before_base, after_base: after_base) do |view|
              escaped = view
              context = view.context
              contexts << context
              assert_equal before.fetch(:head), context.dig("reviewed", "head")
              assert_equal after.fetch(:head), context.dig("candidate", "head")
              assert_equal after_base, context.dig("candidate", "base")
              assert_equal %w[base_delta candidate_delta current_scope original_scope], context.fetch("changes").keys.sort
              delta = context.fetch("changes").fetch("candidate_delta")
              assert_includes delta.fetch("patch").fetch("bytes"), "+puts :after"
              assert_equal Digest::SHA256.hexdigest(delta.fetch("patch").fetch("bytes")), delta.fetch("patch_sha256")
              assert_equal ["code.rb"], delta.fetch("paths").map { |value| value.fetch("bytes") }
              assert_empty delta.fetch("binary_paths")
              assert_raises(AttemptErrors::EvidenceUnavailable) { Thread.new { view.context }.value }
            end
          end
          assert_equal contexts.first, contexts.last
          assert_raises(AttemptErrors::EvidenceUnavailable) { escaped.context }
          assert_empty Dir.children(File.join(root, "authority"))
          assert_equal after.fetch(:head), git(source, "rev-parse", "HEAD").strip
          error = assert_raises(AttemptErrors::ReceiptRejected) do
            transfer.with_head_comparison(before: before, after: after, before_base: "f" * 40, after_base: after_base) { |view| view.context }
          end
          assert_match(/Head comparison read failed/, error.message)
          assert_empty Dir.children(File.join(root, "authority"))
        end
      end

      def test_head_comparison_deadline_expires_without_partial_context
        with_fixture do |transfer, root, source, base, _bytes|
          input = comparison_input(root, source, "candidate")
          transfer.with_head_comparison(before: input, after: input, before_base: base, after_base: base) do |view|
            expired = Process.clock_gettime(Process::CLOCK_MONOTONIC) + Authority::CandidateTransfer::DEADLINE + 1
            transfer.stub(:monotonic, expired) do
              error = assert_raises(AttemptErrors::EvidenceUnavailable) { view.context }
              assert_equal "head comparison deadline expired", error.message
            end
          end
          assert_empty Dir.children(File.join(root, "authority"))
        end
      end

      def comparison_input(root, source, name)
        head = git(source, "rev-parse", "HEAD").strip
        tree = git(source, "rev-parse", "HEAD^{tree}").strip
        path = File.join(root, "#{name}.bundle")
        # HEAD alone is deliberate: the later nonancestor bundle cannot lend
        # the old reviewed objects to a comparison implementation by accident.
        git(source, "bundle", "create", path, "HEAD")
        bytes = File.binread(path)
        {bytes: bytes, size: bytes.bytesize, sha256: Digest::SHA256.hexdigest(bytes), head: head, tree: tree}
      end

      def test_head_comparison_keeps_binary_and_external_symlink_objects_without_following_or_executing
        with_fixture do |transfer, root, source, base, _bytes|
          marker = File.join(root, "unexpected-execution")
          File.symlink("../../nonexistent-archive", File.join(source, "historic-link"))
          File.write(File.join(source, ".gitattributes"), "* diff=evil filter=evil\n")
          File.write(File.join(source, "Gemfile"), "File.write(#{marker.inspect}, 'executed')\n")
          git(source, "add", ".")
          git(source, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "-m", "historical link")
          before = comparison_input(root, source, "before")
          File.binwrite(File.join(source, "README"), "new\x00binary\xff".b)
          File.delete(File.join(source, "historic-link"))
          File.symlink("/still/nonexistent", File.join(source, "historic-link"))
          git(source, "add", ".")
          git(source, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "-m", "new link and binary")
          after = comparison_input(root, source, "after")
          with_env("GIT_EXTERNAL_DIFF" => "touch #{marker}", "GIT_CONFIG_COUNT" => "1",
            "GIT_CONFIG_KEY_0" => "diff.evil.command", "GIT_CONFIG_VALUE_0" => "touch #{marker}") do
            transfer.with_head_comparison(before: before, after: after, before_base: base, after_base: base) do |view|
              context = view.context
              assert_equal ["README"], context.dig("changes", "candidate_delta", "binary_paths").map { |entry| entry["bytes"] }
              assert_includes context.dig("changes", "candidate_delta", "patch", "bytes"), "GIT binary patch"
              entries = context.dig("inventories", "reviewed_head", "entries")
              link = entries.find { |entry| entry.dig("path", "bytes") == "historic-link" }
              assert_equal "120000", link.fetch("mode")
              assert_equal "../../nonexistent-archive", context.dig("objects", link.fetch("oid"), "content", "bytes")
              current = context.dig("inventories", "candidate_head", "entries").find { |entry| entry.dig("path", "bytes") == "README" }
              assert_equal "base64", context.dig("objects", current.fetch("oid"), "content", "encoding")
            end
          end
          refute File.exist?(marker)
          assert_equal "/still/nonexistent", File.readlink(File.join(source, "historic-link"))
          assert_empty Dir.children(File.join(root, "authority"))
        end
      end

      def test_head_comparison_refuses_expanded_content_limit_and_declared_tree_mismatch
        with_fixture do |transfer, root, source, base, _bytes|
          before = comparison_input(root, source, "before")
          File.binwrite(File.join(source, "compressible"), "a" * 4096)
          git(source, "add", ".")
          git(source, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "-m", "large context")
          after = comparison_input(root, source, "after")
          bounded = Class.new(Authority::CandidateTransfer)
          bounded.const_set(:MAX_REVIEW_BYTES, 2048)
          limited = bounded.new(root: File.join(root, "authority"))
          error = assert_raises(AttemptErrors::ReceiptRejected) do
            limited.with_head_comparison(before: before, after: after, before_base: base, after_base: base) { |view| view.context }
          end
          assert_match(/oversized/, error.message)
          assert_raises(AttemptErrors::ReceiptRejected) do
            transfer.with_head_comparison(before: before.merge(tree: "f" * 40), after: after, before_base: base, after_base: base) { |view| view.context }
          end
          assert_empty Dir.children(File.join(root, "authority"))
        end
      end

      # Trees are built with hash-object/mktree/commit-tree because the host
      # filesystem refuses the oversized names these proofs must contain.
      # mktree is single-level: deep paths need bottom-up nested trees.
      def blob_oid(source, content = "content\n")
        output, _, status = Open3.capture3("/usr/bin/git", "-C", source, "hash-object", "-w", "--stdin", stdin_data: content)
        assert status.success?, status.inspect
        output.strip
      end

      def nested_tree(source, entries)
        output, error, status = Open3.capture3("/usr/bin/git", "-C", source, "mktree",
          stdin_data: entries.map { |mode, type, sha, name| "#{mode} #{type} #{sha}\t#{name}\n" }.join)
        assert status.success?, error
        output.strip
      end

      def deep_blob_tree(source, segments)
        sha, type = blob_oid(source), "blob"
        segments.reverse.each do |component|
          sha = nested_tree(source, [[type == "blob" ? "100644" : "040000", type, sha, component]])
          type = "tree"
        end
        sha
      end

      def commit_bounded_tree(source, tree)
        head, _, status = Open3.capture3("/usr/bin/git", "-C", source,
          "-c", "user.name=test", "-c", "user.email=test@example.invalid",
          "commit-tree", tree, "-m", "oversized path shape")
        assert status.success?
        git(source, "update-ref", "refs/heads/oversized", head.strip)
        head.strip
      end

      def bound_input(root, source, name, tree)
        head = commit_bounded_tree(source, tree)
        path = File.join(root, "#{name}.bundle")
        git(source, "bundle", "create", path, "refs/heads/oversized")
        bytes = File.binread(path)
        {bytes: bytes, size: bytes.bytesize, sha256: Digest::SHA256.hexdigest(bytes), head: head, tree: tree}
      end

      def test_materialization_refuses_unbounded_component_and_total_path_lengths
        with_fixture do |transfer, root, source, base, _bytes|
          component = bound_input(root, source, "component",
            deep_blob_tree(source, ["d" * (Atoms::CandidateLimits::PATH_COMPONENT_BYTES + 1)]))
          error = assert_raises(AttemptErrors::ReceiptRejected) do
            transfer.materialize(**component, root: File.join(root, "authority"))
          end
          assert_match(/unsafe filesystem entry/, error.message)
          segments = Array.new((Atoms::CandidateLimits::PATH_BYTES / Atoms::CandidateLimits::PATH_COMPONENT_BYTES) + 2,
            "c" * Atoms::CandidateLimits::PATH_COMPONENT_BYTES)
          total = bound_input(root, source, "total", deep_blob_tree(source, segments))
          error = assert_raises(AttemptErrors::ReceiptRejected) do
            transfer.materialize(**total, root: File.join(root, "authority"))
          end
          assert_match(/Candidate path exceeds bounded length/, error.message)
          assert_empty Dir.children(File.join(root, "authority"))
          assert_equal base, git(source, "rev-parse", "HEAD").strip
        end
      end

      def test_head_comparison_refuses_unbounded_inventory_paths
        with_fixture do |transfer, root, source, base, _bytes|
          before = comparison_input(root, source, "before")
          segments = Array.new((Atoms::CandidateLimits::PATH_BYTES / Atoms::CandidateLimits::PATH_COMPONENT_BYTES) + 2,
            "c" * Atoms::CandidateLimits::PATH_COMPONENT_BYTES)
          after = bound_input(root, source, "total", deep_blob_tree(source, segments))
          error = assert_raises(AttemptErrors::ReceiptRejected) do
            transfer.with_head_comparison(before: before, after: after, before_base: base, after_base: base) { |view| view.context }
          end
          assert_match(/Complete head comparison path exceeds bounded length/, error.message)
          assert_empty Dir.children(File.join(root, "authority"))
        end
      end

      def test_prepared_files_refuse_unbounded_paths_before_any_prefix_work
        with_fixture do |transfer, root, source, _base, _bytes|
          blob = blob_oid(source)
          long = "d" * (Atoms::CandidateLimits::PATH_COMPONENT_BYTES + 1)
          tree = nested_tree(source, [["100644", "blob", blob, "manifest.json"],
            ["100644", "blob", blob, "one"], ["100644", "blob", blob, "two"],
            ["100644", "blob", blob, long]])
          head = commit_bounded_tree(source, tree)
          path = File.join(root, "prepared.bundle")
          git(source, "bundle", "create", path, "refs/heads/oversized")
          bytes = File.binread(path)
          transfer.admit(bytes: bytes, size: bytes.bytesize, sha256: Digest::SHA256.hexdigest(bytes),
            head: head) do |repository, deadline, result|
            assert_equal tree, result.fetch("tree")
            error = assert_raises(AttemptErrors::ReceiptRejected) do
              transfer.prepared_files(repository: repository, deadline: deadline, head: head)
            end
            assert_match(/Prepared tree contains unsafe entry/, error.message)
          end
          assert_empty Dir.children(File.join(root, "authority"))
        end
      end

      def test_incremental_bundle_cannot_borrow_objects_from_uploader_or_ambient_repository
        with_fixture do |transfer, root, source, first, _bytes|
          File.write(File.join(source, "README"), "second")
          git(source, "add", "README")
          git(source, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "-m", "second")
          head = git(source, "rev-parse", "HEAD").strip
          incremental = File.join(root, "incremental.bundle")
          git(source, "bundle", "create", incremental, "#{first}..HEAD")
          bytes = File.binread(incremental)
          with_env("GIT_OBJECT_DIRECTORY" => File.join(source, ".git/objects"),
            "GIT_DIR" => File.join(source, ".git")) do
            assert_raises(AttemptErrors::ReceiptRejected) { admit(transfer, head, bytes) }
          end
          assert_empty Dir.children(File.join(root, "authority"))
        end
      end

      def test_ambient_git_config_and_hooks_do_not_execute_or_redefine_candidate
        with_fixture do |transfer, root, source, head, bytes|
          marker = File.join(root, "hook-ran")
          hook = File.join(source, ".git/hooks/post-checkout")
          File.write(hook, "#!/bin/sh\ntouch '#{marker}'\n")
          File.chmod(0700, hook)
          with_env("GIT_CONFIG_COUNT" => "1", "GIT_CONFIG_KEY_0" => "core.hooksPath",
            "GIT_CONFIG_VALUE_0" => File.dirname(hook), "GIT_DIR" => File.join(source, ".git")) do
            assert_equal head, admit(transfer, head, bytes)["head"]
          end
          refute File.exist?(marker)
          assert_equal head, git(source, "rev-parse", "HEAD").strip
        end
      end

      def test_root_symlink_or_shared_write_permissions_are_refused
        with_fixture do |_transfer, root, _source, _head, _bytes|
          link = File.join(root, "linked-root")
          File.symlink(File.join(root, "authority"), link)
          assert_raises(AttemptErrors::ReceiptRejected) { Authority::CandidateTransfer.new(root: link) }
          File.chmod(0770, File.join(root, "authority"))
          assert_raises(AttemptErrors::ReceiptRejected) { Authority::CandidateTransfer.new(root: File.join(root, "authority")) }
        end
      end

      def test_materializes_exact_bytes_in_peer_private_checkout_without_git_metadata
        with_fixture do |transfer, root, source, head, bytes|
          scratch = File.join(root, "peer-scratch")
          FileUtils.mkdir_p(scratch, mode: 0700)
          tree = git(source, "rev-parse", "HEAD^{tree}").strip
          result = transfer.materialize(bytes: bytes, size: bytes.bytesize,
            sha256: Digest::SHA256.hexdigest(bytes), head: head, tree: tree, root: scratch)
          assert_equal "candidate\x00\n".b, File.binread(File.join(result["directory"], "README"))
          assert_equal 0700, File.stat(result["directory"]).mode & 0777
          assert_equal 0600, File.stat(File.join(result["directory"], "README")).mode & 0777
          refute File.exist?(File.join(result["directory"], ".git"))
          assert_empty Dir.children(File.join(root, "authority"))
        end
      end

      def test_materialization_refuses_external_symlink_and_wrong_tree_and_cleans_only_own_directory
        with_fixture do |transfer, root, source, _head, _bytes|
          scratch = File.join(root, "peer-scratch")
          FileUtils.mkdir_p(scratch, mode: 0700)
          File.write(File.join(scratch, "preserved"), "peer-owned")
          File.symlink("../../outside", File.join(source, "escape"))
          git(source, "add", "escape")
          git(source, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "-m", "symlink")
          head = git(source, "rev-parse", "HEAD").strip
          tree = git(source, "rev-parse", "HEAD^{tree}").strip
          path = File.join(root, "symlink.bundle")
          git(source, "bundle", "create", path, "--all")
          bytes = File.binread(path)
          binding = {bytes: bytes, size: bytes.bytesize, sha256: Digest::SHA256.hexdigest(bytes), head: head, root: scratch}
          assert_raises(AttemptErrors::ReceiptRejected) { transfer.materialize(**binding, tree: "0" * 40) }
          assert_raises(AttemptErrors::ReceiptRejected) { transfer.materialize(**binding, tree: tree) }
          assert_equal ["preserved"], Dir.children(scratch)
          assert_equal "peer-owned", File.read(File.join(scratch, "preserved"))
          assert_empty Dir.children(File.join(root, "authority"))
        end
      end

      def test_review_snapshot_preserves_full_original_objects_and_independent_encodings
        with_fixture do |transfer, root, source, _head, _bytes|
          File.write(File.join(source, "text.rb"), "puts 'original'\n")
          File.symlink("README", File.join(source, "link"))
          binary_path = "zażółć".b
          File.binwrite(File.join(source.b, binary_path), "invalid-\xff".b)
          git(source, "add", ".")
          git(source, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "-m", "snapshot")
          head = git(source, "rev-parse", "HEAD").strip
          tree = git(source, "rev-parse", "HEAD^{tree}").strip
          bundle = File.join(root, "snapshot.bundle")
          git(source, "bundle", "create", bundle, "--all")
          bytes = File.binread(bundle)
          File.write(File.join(source, "text.rb"), "changed live uploader")
          scratch = File.join(root, "review-scratch")
          FileUtils.mkdir_p(scratch, mode: 0700)
          binding = {bytes: bytes, size: bytes.bytesize, sha256: Digest::SHA256.hexdigest(bytes), head: head, root: scratch}
          assert_raises(AttemptErrors::ReceiptRejected) { transfer.review_snapshot(**binding, tree: "0" * 40) }
          assert_empty Dir.children(scratch)
          result = transfer.review_snapshot(**binding, tree: tree)
          assert result.fetch("subject").frozen?
          snapshot = JSON.parse(result.fetch("subject"))
          assert_equal [head, tree], snapshot.values_at("head", "tree")
          entries = snapshot.fetch("files")
          assert_equal 4, entries.size
          decode = ->(value) { value.fetch("encoding") == "base64" ? value.fetch("bytes").unpack1("m0") : value.fetch("bytes").b }
          indexed = entries.to_h { |entry| [decode.call(entry.fetch("path")), entry] }
          assert_equal "candidate\x00\n".b, decode.call(indexed.fetch("README").fetch("content"))
          assert_equal "puts 'original'\n", decode.call(indexed.fetch("text.rb").fetch("content"))
          assert_equal "utf-8", indexed.fetch("text.rb").dig("content", "encoding")
          assert_equal "120000", indexed.fetch("link").fetch("mode")
          assert_equal "README", decode.call(indexed.fetch("link").fetch("content"))
          assert_equal "utf-8", indexed.fetch(binary_path).dig("path", "encoding")
          assert_equal "base64", indexed.fetch(binary_path).dig("content", "encoding")
          assert_equal "invalid-\xff".b, decode.call(indexed.fetch(binary_path).fetch("content"))
          entries.each { |entry| assert_match(/\A[0-9a-f]{40}\z/, entry.fetch("oid")) }
          File.write(File.join(result.fetch("directory"), "text.rb"), "changed scratch")
          assert_equal "puts 'original'\n", decode.call(JSON.parse(result.fetch("subject")).fetch("files").find { |e| e.dig("path", "bytes") == "text.rb" }.fetch("content"))
        end
      end

      def test_review_snapshot_bounds_complete_json_expansion_and_preserves_peer_scratch
        with_fixture do |transfer, root, source, _head, _bytes|
          File.binwrite(File.join(source, "escaped"), "\x01" * (11 * 1024 * 1024))
          git(source, "add", "escaped")
          git(source, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "-m", "escaped")
          head = git(source, "rev-parse", "HEAD").strip
          tree = git(source, "rev-parse", "HEAD^{tree}").strip
          bundle = File.join(root, "escaped.bundle")
          git(source, "bundle", "create", bundle, "--all")
          bytes = File.binread(bundle)
          scratch = File.join(root, "review-scratch")
          FileUtils.mkdir_p(scratch, mode: 0700)
          File.write(File.join(scratch, "preserved"), "owned elsewhere")
          error = assert_raises(AttemptErrors::ReceiptRejected) do
            transfer.review_snapshot(bytes: bytes, size: bytes.bytesize, sha256: Digest::SHA256.hexdigest(bytes), head: head, tree: tree, root: scratch)
          end
          assert_includes error.message, "snapshot is oversized"
          assert_equal ["preserved"], Dir.children(scratch)
          assert_empty Dir.children(File.join(root, "authority"))
        end
      end

      def test_materialization_accepts_internal_symlink_and_refuses_cycle
        with_fixture do |transfer, root, source, _head, _bytes|
          scratch = File.join(root, "peer-scratch")
          FileUtils.mkdir_p(scratch, mode: 0700)
          File.symlink("README", File.join(source, "link"))
          git(source, "add", "link")
          git(source, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "-m", "internal")
          head = git(source, "rev-parse", "HEAD").strip
          tree = git(source, "rev-parse", "HEAD^{tree}").strip
          path = File.join(root, "internal.bundle")
          git(source, "bundle", "create", path, "--all")
          bytes = File.binread(path)
          result = transfer.materialize(bytes: bytes, size: bytes.bytesize,
            sha256: Digest::SHA256.hexdigest(bytes), head: head, tree: tree, root: scratch)
          assert_equal "candidate\x00\n".b, File.binread(File.join(result["directory"], "link"))
          FileUtils.rm_rf(result["directory"])
          File.unlink(File.join(source, "link"))
          File.symlink("link", File.join(source, "link"))
          git(source, "add", "link")
          git(source, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "-m", "cycle")
          head = git(source, "rev-parse", "HEAD").strip
          tree = git(source, "rev-parse", "HEAD^{tree}").strip
          git(source, "bundle", "create", path, "--all")
          bytes = File.binread(path)
          assert_raises(AttemptErrors::ReceiptRejected) do
            transfer.materialize(bytes: bytes, size: bytes.bytesize,
              sha256: Digest::SHA256.hexdigest(bytes), head: head, tree: tree, root: scratch)
          end
          assert_empty Dir.children(scratch)
        end
      end
    end
  end
end
