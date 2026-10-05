# frozen_string_literal: true

require "digest"
require "fileutils"
require "tmpdir"
require "ace/herdr"

module Ace
  module Assign
    module Authority
      # Untrusted bundles enter a clean bare quarantine. Only complete verified
      # objects are retained; no uploader configuration or worktree is read.
      class CandidateTransfer
        MAX_BYTES = 64 * 1024 * 1024
        DEADLINE = 30
        SHA = /\A[0-9a-f]{40}\z/

        def initialize(root:)
          @root = File.expand_path(root)
          verify_root!
        end

        def admit(bytes:, sha256:, size:, head:, &consumer)
          unless bytes.is_a?(String) && size.is_a?(Integer) && size.positive? && size <= MAX_BYTES &&
              size == bytes.bytesize && sha256.is_a?(String) &&
              Digest::SHA256.hexdigest(bytes.b) == sha256 && head.is_a?(String) && head.match?(SHA)
            reject!("Candidate bundle binding or size is invalid")
          end
          verify_root!
          deadline = monotonic + DEADLINE
          Dir.mktmpdir("quarantine-", @root) do |directory|
            File.chmod(0700, directory)
            bundle = File.join(directory, "candidate.bundle")
            File.open(bundle, File::WRONLY | File::CREAT | File::EXCL | File::NOFOLLOW, 0600) { |f| f.write(bytes.b) }
            repository = File.join(directory, "repository")
            git(directory, deadline, "init", "--bare", "--template=", repository)
            # Verification against an empty repository rejects incremental
            # bundles requiring any caller-supplied prerequisites.
            git(repository, deadline, "bundle", "verify", bundle)
            advertised = git(repository, deadline, "bundle", "list-heads", bundle).lines.map { |line| line.split.first }
            reject!("Candidate head is not advertised") unless advertised.include?(head)
            git(repository, deadline, "fetch", "--no-tags", bundle, "#{head}:refs/heads/candidate")
            actual = git(repository, deadline, "rev-parse", "refs/heads/candidate^{commit}").strip
            reject!("Candidate commit differs from declared head") unless actual == head
            git(repository, deadline, "fsck", "--full", "--strict", "--no-reflogs")
            tree = git(repository, deadline, "rev-parse", "#{head}^{tree}").strip
            exported = File.join(directory, "verified.bundle")
            git(repository, deadline, "bundle", "create", exported, "refs/heads/candidate")
            verified = read_bundle(exported)
            # The journal owns candidate identity/generation. This object is
            # only immutable transport bytes, not another authority ledger.
            result = {"head" => head, "tree" => tree, "bundle" => verified,
                      "sha256" => Digest::SHA256.hexdigest(verified), "bytes" => verified.bytesize}
            consumer ? consumer.call(repository, deadline, result) : result
          end
        rescue Timeout::Error
          reject!("Candidate transfer deadline exceeded")
        rescue SystemCallError
          reject!("Candidate transfer filesystem is unavailable")
        end

        # root is selected from installed peer credentials by the receiver,
        # never a request field. Materialization reads objects rather than Git
        # checkout, so .gitattributes, filters and uploader hooks cannot run.
        def materialize(bytes:, sha256:, size:, head:, tree:, root:)
          self.class.new(root: root)
          admit(bytes: bytes, sha256: sha256, size: size, head: head) do |repository, deadline, result|
            reject!("Candidate tree differs from accepted tree") unless result["tree"] == tree
            destination = Dir.mktmpdir("candidate-", root)
            File.chmod(0700, destination)
            begin
              entries = git(repository, deadline, "ls-tree", "-r", "-z", head, limit: MAX_BYTES).split("\0")
              total = 0
              links = []
              entries.each do |entry|
                metadata, path = entry.split("\t", 2)
                mode, kind, oid = metadata.to_s.split(" ")
                parts = path.to_s.split("/", -1)
                unless path && !path.start_with?("/") &&
                    parts.none? { |part| part.empty? || %w[. .. .git].include?(part.downcase) } &&
                    kind == "blob" && %w[100644 100755 120000].include?(mode) && oid.match?(SHA)
                  reject!("Candidate contains unsafe filesystem entry")
                end
                content = git(repository, deadline, "cat-file", "blob", oid, limit: MAX_BYTES).b
                total += content.bytesize
                reject!("Candidate expanded content is oversized") if total > MAX_BYTES
                target = File.join(destination, path)
                FileUtils.mkdir_p(File.dirname(target), mode: 0700)
                if mode == "120000"
                  resolved = File.expand_path(content, File.dirname(target))
                  unless !content.include?("\0") && !content.start_with?("/") &&
                      resolved.start_with?(destination + "/")
                    reject!("Candidate symlink escapes private checkout")
                  end
                  links << [target, content]
                else
                  File.open(target, File::WRONLY | File::CREAT | File::EXCL | File::NOFOLLOW,
                    mode == "100755" ? 0700 : 0600) { |file| file.write(content) }
                end
              end
              links.each { |target, content| File.symlink(content, target) }
              links.each do |target, _content|
                resolved = File.realpath(target)
                reject!("Candidate symlink escapes private checkout") unless resolved.start_with?(destination + "/")
              end
              result.reject { |key, _value| key == "bundle" }.merge("directory" => destination)
            rescue Exception
              # Only this freshly created private disposable directory is
              # removed. An existing peer scratch tree is never cleaned.
              FileUtils.rm_rf(destination)
              raise
            end
          end
        rescue SystemCallError, ArgumentError
          reject!("Candidate filesystem materialization is unverifiable")
        end

        private

        def verify_root!
          cursor = @root
          loop do
            stat = File.lstat(cursor)
            unless stat.directory? && !stat.symlink? && [0, Process.uid].include?(stat.uid) && (stat.mode & 0022).zero?
              reject!("Candidate root is not protected")
            end
            break if cursor == "/"
            cursor = File.dirname(cursor)
          end
          root_stat = File.stat(@root)
          unless root_stat.uid == Process.uid && (root_stat.mode & 0077).zero?
            reject!("Candidate root must be owned by this peer and private")
          end
        rescue SystemCallError
          reject!("Candidate root is unavailable")
        end

        def git(repository, deadline, *arguments, limit: 65_536)
          remaining = deadline - monotonic
          raise Timeout::Error if remaining <= 0
          # Git variables may redirect object/config storage even in a clean
          # repository. Strip every inherited Git setting and global config.
          environment = ENV.keys.to_h { |key| [key, nil] }
          environment.merge!("GIT_CONFIG_NOSYSTEM" => "1", "GIT_CONFIG_GLOBAL" => "/dev/null",
            "GIT_TERMINAL_PROMPT" => "0", "GIT_ALLOW_PROTOCOL" => "file",
            "GIT_NO_REPLACE_OBJECTS" => "1", "PATH" => "/usr/bin:/bin", "LC_ALL" => "C")
          result = Herdr::Molecules::BoundedProcess.call([environment, "/usr/bin/git", "-C", repository,
            "-c", "core.hooksPath=/dev/null", "-c", "protocol.file.allow=always", *arguments],
            stdin_data: "", timeout_s: remaining, output_limit: limit)
          reject!("Candidate Git verification failed") unless result.status.success? && !result.oversized
          result.stdout
        end

        def read_bundle(path)
          File.open(path, File::RDONLY | File::NOFOLLOW) do |file|
            reject!("Verified bundle is oversized") unless file.stat.file? && file.stat.size <= MAX_BYTES
            bytes = file.read(MAX_BYTES + 1).b
            reject!("Verified bundle is oversized") if bytes.bytesize > MAX_BYTES
            bytes
          end
        end

        def monotonic
          Process.clock_gettime(Process::CLOCK_MONOTONIC)
        end

        def reject!(message)
          raise AttemptErrors::ReceiptRejected, message
        end
      end
    end
  end
end
