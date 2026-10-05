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

      def test_refuses_size_digest_and_unadvertised_head_without_retained_objects
        with_fixture do |transfer, root, _source, head, bytes|
          assert_raises(AttemptErrors::ReceiptRejected) { admit(transfer, head, bytes, size: bytes.bytesize + 1) }
          assert_raises(AttemptErrors::ReceiptRejected) { admit(transfer, head, bytes, sha256: "0" * 64) }
          assert_raises(AttemptErrors::ReceiptRejected) { admit(transfer, "f" * 40, bytes) }
          assert_raises(AttemptErrors::ReceiptRejected) { admit(transfer, head, "not a bundle") }
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
