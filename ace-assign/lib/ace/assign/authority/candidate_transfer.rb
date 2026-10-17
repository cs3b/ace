# frozen_string_literal: true

require "digest"
require "json"
require "fileutils"
require "tmpdir"
require "tempfile"
require "set"
require "ace/herdr/molecules/bounded_process"
require "ace/review/atoms/campaign_contract"
require_relative "private_directory"
require_relative "../atoms/candidate_limits"
require_relative "candidate_head_comparison"
require_relative "candidate_blob_batch"

module Ace
  module Assign
    module Authority
      # Untrusted bundles enter a clean bare quarantine. Only complete verified
      # objects are retained; no uploader configuration or worktree is read.
      class CandidateTransfer
        include CandidateHeadComparison
        include CandidateBlobBatch
        MAX_BYTES = Atoms::CandidateLimits::BYTES
        MAX_REVIEW_BYTES = Ace::Review::Atoms::CampaignContract::MAX_HEAD_CONTEXT_BYTES
        # Measured on the real 82,809,675-byte candidate (9,203 entries,
        # 71,583,200 expanded bytes): two full admits alone need ~14s of
        # bounded Git work and the complete comparison ~23s on a loaded host
        # (evidence in .ace-tasks/8xf.t.ei9-wave-3 evidence). 30s failed
        # closed under legitimate load; 60s keeps a finite secondary guard
        # with measured headroom. Inputs stay byte/count-bounded separately.
        DEADLINE = 60
        SHA = /\A[0-9a-f]{40}\z/

        class CampaignReadView
          def initialize(owner:, repository:, base:, deadline:)
            @owner, @repository, @base, @deadline = owner, repository, base, deadline
            @thread, @active = Thread.current, true
          end

          def close = @active = false
          def head = command("rev-parse", "HEAD").strip
          def base
            commit!(@base)
            @base
          end
          def commit!(revision)
            raise ArgumentError, "campaign revision is invalid" unless revision.is_a?(String) && revision.match?(SHA)
            command("cat-file", "-e", "#{revision}^{commit}")
            true
          end
          def full_diff?(base, head)
            commit!(base)
            commit!(head)
            !command("diff", "--raw", "--no-ext-diff", "--no-textconv", base, head, "--").empty?
          end
          def clean?
            command("status", "--porcelain", "-z", "--untracked-files=all").split("\0")
              .all? { |entry| entry.start_with?("?? .ace-local/") }
          end

          private

          def command(*arguments)
            unless @active && Thread.current.equal?(@thread)
              raise AttemptErrors::EvidenceUnavailable, "campaign Git read view escaped its source lifetime"
            end
            @owner.send(:git, @repository, @deadline, *arguments)
          rescue Timeout::Error
            raise AttemptErrors::EvidenceUnavailable, "campaign Git read deadline expired"
          end
        end

        def with_campaign_repository(bytes:, sha256:, size:, head:, tree:, base:)
          raise ArgumentError, "campaign repository requires a block" unless block_given?
          deadline = monotonic + DEADLINE
          materialized = materialize_repository(bytes: bytes, sha256: sha256, size: size, head: head, tree: tree, root: @root)
          directory = materialized.fetch("directory")
          reader = CampaignReadView.new(owner: self, repository: directory, base: base, deadline: deadline)
          unless reader.head == head
            raise AttemptErrors::EvidenceUnavailable, "campaign Git head differs from original candidate"
          end
          reader.base
          yield reader
        ensure
          reader&.close
          FileUtils.remove_entry(directory) if directory && File.directory?(directory)
        end

        def initialize(root:)
          @root = File.expand_path(root)
          verify_root!
        end

        # Export the already validated prepared tree using the same isolated Git
        # boundary as admission. The returned bytes are retained by the producer;
        # registration must not rebuild them after a lost response.
        def export_prepared(work:)
          require_relative "prepared_work"
          reject!("Prepared export requires validated work") unless work.is_a?(PreparedWork)
          verify_root!
          deadline = monotonic + DEADLINE
          Dir.mktmpdir("prepared-export-", @root) do |directory|
            File.chmod(0700, directory)
            repository = File.join(directory, "repository")
            git(directory, deadline, "init", "--template=", "--initial-branch=prepared", repository)
            work.files.each do |path, bytes|
              target = File.join(repository, path)
              FileUtils.mkdir_p(File.dirname(target), mode: 0700)
              File.open(target, File::WRONLY | File::CREAT | File::EXCL | File::NOFOLLOW, 0600) do |file|
                file.write(bytes)
              end
            end
            git(repository, deadline, "add", "--", ".")
            git(repository, deadline, "-c", "user.name=ACE prepared input", "-c", "user.email=prepared@ace.invalid",
              "-c", "commit.gpgSign=false", "commit", "--no-verify", "-m", "Prepared assignment input")
            head = git(repository, deadline, "rev-parse", "HEAD").strip
            tree = git(repository, deadline, "rev-parse", "HEAD^{tree}").strip
            bundle = File.join(directory, "prepared.bundle")
            git(repository, deadline, "bundle", "create", bundle, "refs/heads/prepared")
            bytes = read_bundle(bundle).freeze
            {"head" => head.freeze, "tree" => tree.freeze, "bundle" => bytes,
              "bytes" => bytes.bytesize, "sha256" => Digest::SHA256.hexdigest(bytes).freeze,
              "definition_bytes" => work.definition_bytes(head: head, tree: tree)}.freeze
          end
        rescue Timeout::Error
          reject!("Prepared export deadline exceeded")
        rescue SystemCallError
          reject!("Prepared export filesystem is unavailable")
        end

        def admit(bytes:, sha256:, size:, head:, deadline: nil, &consumer)
          unless bytes.is_a?(String) && size.is_a?(Integer) && size.positive? && size <= MAX_BYTES &&
              size == bytes.bytesize && sha256.is_a?(String) &&
              Digest::SHA256.hexdigest(bytes.b) == sha256 && head.is_a?(String) && head.match?(SHA)
            reject!("Candidate bundle binding or size is invalid")
          end
          verify_root!
          deadline = deadline ? [deadline, monotonic + DEADLINE].min : monotonic + DEADLINE
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
        def materialize(bytes:, sha256:, size:, head:, tree:, root:, max_entries: nil)
          unless max_entries.nil? || (max_entries.is_a?(Integer) && max_entries.positive?)
            raise ArgumentError, "invalid materialized source entry bound"
          end
          self.class.new(root: root)
          admit(bytes: bytes, sha256: sha256, size: size, head: head) do |repository, deadline, result|
            reject!("Candidate tree differs from accepted tree") unless result["tree"] == tree
            destination = Dir.mktmpdir("candidate-", root)
            File.chmod(0700, destination)
            begin
              entries = git(repository, deadline, "ls-tree", "-r", "-z", head, limit: MAX_BYTES).b.split("\0")
              if max_entries
                inventory = Set.new([""])
                entries.each do |entry|
                  path = entry.split("\t", 2).last
                  path.to_s.split("/").each_with_object(+"") do |part, parent|
                    parent << "/" unless parent.empty?
                    parent << part
                    inventory.add(parent.dup)
                    reject!("Candidate source entry count exceeds selected bound") if inventory.size > max_entries
                  end
                end
              end
              reject!("Candidate file inventory is oversized") if entries.size > MAX_OBJECTS
              parsed = entries.map do |entry|
                metadata, path = entry.split("\t", 2)
                mode, kind, oid = metadata.to_s.split(" ")
                # Total path bytes are bounded before any component or
                # filesystem prefix work consumes them.
                reject!("Candidate path exceeds bounded length") unless path && !path.start_with?("/") &&
                  path.bytesize <= Atoms::CandidateLimits::PATH_BYTES
                parts = path.split("/", -1)
                unless parts.none? { |part| part.empty? || part.bytesize > Atoms::CandidateLimits::PATH_COMPONENT_BYTES ||
                    %w[. .. .git].include?(part.downcase) } &&
                    kind == "blob" && %w[100644 100755 120000].include?(mode) && oid&.match?(SHA)
                  reject!("Candidate contains unsafe filesystem entry")
                end
                [path, mode, oid]
              end
              by_oid = parsed.group_by(&:last)
              sizes = by_oid.keys.zip(candidate_blob_sizes(repository, deadline, by_oid.keys)).to_h
              reject!("Candidate expanded content is oversized") if parsed.sum { |_path, _mode, oid| sizes.fetch(oid) } > MAX_BYTES
              links = []
              ordered = parsed.each
              each_candidate_blob(repository, deadline, parsed.map { |_path, _mode, oid| [oid, sizes.fetch(oid)] }) do |oid, content|
                path, mode, _oid = ordered.next
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
                yield(path.freeze, mode.freeze, oid.freeze, content.freeze) if block_given?
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

        # Executing campaign children need local Git history as well as files.
        # Create only our own empty administration; no uploader configuration,
        # checkout filters or hooks enter this private repository.
        def materialize_repository(bytes:, sha256:, size:, head:, tree:, root:, max_entries: nil)
          deadline = monotonic + DEADLINE
          result = materialize(bytes: bytes, sha256: sha256, size: size, head: head, tree: tree, root: root, max_entries: max_entries)
          directory = result.fetch("directory")
          Tempfile.create(["campaign-candidate-", ".bundle"], root) do |file|
            file.binmode
            file.write(bytes); file.flush
            git(directory, deadline, "init", "--template=", "--initial-branch=work")
            git(directory, deadline, "fetch", "--no-tags", file.path, "#{head}:refs/heads/candidate")
            git(directory, deadline, "symbolic-ref", "HEAD", "refs/heads/candidate")
            git(directory, deadline, "read-tree", head)
            reject!("Campaign private repository differs") unless git(directory, deadline, "rev-parse", "HEAD^{tree}").strip == tree
          end
          result
        rescue Exception
          FileUtils.remove_entry(directory) if directory && File.directory?(directory) && !File.symlink?(directory)
          raise
        end

        # Full immutable review input comes from the same admitted Git objects
        # used for materialization, never a second read of the scratch checkout.
        def review_snapshot(bytes:, sha256:, size:, head:, tree:, root:)
          subject = JSON.generate("schema" => "ace.candidate-review-snapshot/v1", "head" => head, "tree" => tree)
            .delete_suffix("}") + ',"files":['
          first = true
          result = materialize(bytes: bytes, sha256: sha256, size: size, head: head, tree: tree, root: root) do |path, mode, oid, content|
            entry = JSON.generate("path" => review_bytes(path), "mode" => mode, "oid" => oid, "content" => review_bytes(content))
            separator = first ? "" : ","
            reject!("Complete candidate review snapshot is oversized") if subject.bytesize + separator.bytesize + entry.bytesize + 2 > Atoms::CandidateLimits::REVIEW_SNAPSHOT_BYTES
            subject << separator << entry
            first = false
          end
          subject << "]}"
          result.merge("subject" => subject.freeze)
        end

        # Prepared instructions have a narrower tree contract than candidates:
        # no executable entries or symlinks, and bounded UTF-8 files. Read only
        # verified Git objects; never run checkout filters or reopen uploader paths.
        def prepared_files(repository:, deadline:, head:)
          entries = git(repository, deadline, "ls-tree", "-r", "-z", head, limit: MAX_BYTES).b.split("\0")
          reject!("Prepared file inventory is oversized") unless entries.size.between?(4, 4096)
          parsed = entries.map do |entry|
            metadata, path = entry.split("\t", 2)
            mode, kind, oid = metadata.to_s.split(" ")
            reject!("Prepared tree path exceeds bounded length") unless path && !path.start_with?("/") &&
              path.bytesize <= Atoms::CandidateLimits::PATH_BYTES
            unless mode == "100644" && kind == "blob" && oid&.match?(SHA) &&
                path.split("/", -1).none? { |part| part.empty? || part.bytesize > Atoms::CandidateLimits::PATH_COMPONENT_BYTES ||
                  %w[. .. .git].include?(part.downcase) }
              reject!("Prepared tree contains unsafe entry")
            end
            [path, oid]
          end
          by_oid = parsed.group_by(&:last)
          sizes = by_oid.keys.zip(candidate_blob_sizes(repository, deadline, by_oid.keys)).to_h
          reject!("Prepared text is oversized") unless sizes.values.all? { |size| size.between?(1, 1024 * 1024) }
          reject!("Prepared expanded content is oversized") if parsed.sum { |_path, oid| sizes.fetch(oid) } > Atoms::CandidateLimits::PREPARED_BYTES
          files = {}
          ordered = parsed.each
          each_candidate_blob(repository, deadline, parsed.map { |_path, oid| [oid, sizes.fetch(oid)] }) do |_oid, content|
            files[ordered.next.first] = content
          end
          reject!("Prepared inventory has duplicate paths") unless files.size == entries.size
          files
        end

        private

        def review_bytes(bytes)
          text = bytes.dup.force_encoding(Encoding::UTF_8)
          if text.valid_encoding? && !text.include?("\0")
            {"encoding" => "utf-8", "bytes" => text}
          else
            {"encoding" => "base64", "bytes" => [bytes].pack("m0")}
          end
        end

        def verify_root!
          PrivateDirectory.verify!(@root)
        end

        def git(repository, deadline, *arguments, limit: 65_536, stdin_data: "")
          remaining = deadline - monotonic
          raise Timeout::Error if remaining <= 0
          # Git variables may redirect object/config storage even in a clean
          # repository. Strip every inherited Git setting and global config.
          environment = ENV.keys.to_h { |key| [key, nil] }
          environment.merge!("GIT_CONFIG_NOSYSTEM" => "1", "GIT_CONFIG_GLOBAL" => "/dev/null",
            "GIT_ATTR_NOSYSTEM" => "1",
            "GIT_TERMINAL_PROMPT" => "0", "GIT_ALLOW_PROTOCOL" => "file",
            "GIT_NO_REPLACE_OBJECTS" => "1", "PATH" => "/usr/bin:/bin", "LC_ALL" => "C")
          result = Herdr::Molecules::BoundedProcess.call([environment, "/usr/bin/git", "-C", repository,
            "-c", "core.hooksPath=/dev/null", "-c", "core.attributesFile=/dev/null", "-c", "protocol.file.allow=always", *arguments],
            stdin_data: stdin_data, timeout_s: remaining, output_limit: limit)
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
