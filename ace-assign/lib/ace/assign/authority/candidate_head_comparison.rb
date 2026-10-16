# frozen_string_literal: true

module Ace
  module Assign
    module Authority
      # Compare retained Git objects in a private bare repository. Historical
      # links are object bytes, never paths to materialize or follow. This view
      # supplies evidence; it does not classify a change or grant acceptance.
      # Host: CandidateTransfer supplies bounded Git/admission, byte encoding,
      # private-root storage, monotonic deadlines and rejection helpers.
      module CandidateHeadComparison
        class ReadView
          def initialize(owner:, repository:, reviewed:, candidate:, deadline:)
            @owner, @repository, @reviewed, @candidate, @deadline = owner, repository, reviewed, candidate, deadline
            @thread, @active = Thread.current, true
          end

          def close = @active = false

          def context
            unless @active && Thread.current.equal?(@thread)
              raise AttemptErrors::EvidenceUnavailable, "head comparison escaped its source lifetime"
            end
            @owner.send(:head_comparison_context, @repository, @deadline, @reviewed, @candidate)
          rescue Timeout::Error
            raise AttemptErrors::EvidenceUnavailable, "head comparison deadline expired"
          end
        end

        def with_head_comparison(before:, after:, before_base:, after_base:)
          raise ArgumentError, "head comparison requires a block" unless block_given?
          [before, after].each do |input|
            unless input.is_a?(Hash) && input.keys.sort == %i[bytes head sha256 size tree] &&
                input[:tree].is_a?(String) && input[:tree].match?(self.class::SHA)
              reject!("Head comparison candidate binding is invalid")
            end
          end
          [before_base, after_base].each do |base|
            reject!("Head comparison base is invalid") unless base.is_a?(String) && base.match?(self.class::SHA)
          end
          deadline = monotonic + self.class::DEADLINE
          # Each complete bundle is independently verified against an empty
          # repository before either can contribute objects to the comparison.
          admit(**before.reject { |key, _| key == :tree }, deadline: deadline) do |_old_repo, _old_deadline, reviewed|
            reject!("Reviewed tree differs from accepted tree") unless reviewed.fetch("tree") == before[:tree]
            admit(**after.reject { |key, _| key == :tree }, deadline: deadline) do |repository, _new_deadline, candidate|
              reject!("Candidate tree differs from accepted tree") unless candidate.fetch("tree") == after[:tree]
              Tempfile.create(["reviewed-", ".bundle"], @root) do |file|
                file.binmode
                file.write(reviewed.fetch("bundle")); file.flush
                git(repository, deadline, "fetch", "--no-tags", file.path, "#{before[:head]}:refs/heads/reviewed")
                reader = ReadView.new(owner: self, repository: repository,
                  reviewed: {"head" => before[:head], "base" => before_base, "tree" => before[:tree]},
                  candidate: {"head" => after[:head], "base" => after_base, "tree" => after[:tree]}, deadline: deadline)
                yield reader
              ensure
                reader&.close
              end
            end
          end
        end

        private

        def head_comparison_context(repository, deadline, reviewed, candidate)
          context = {"schema" => "ace.candidate-head-comparison/v1", "reviewed" => reviewed,
            "candidate" => candidate, "inventories" => {}, "objects" => {}, "changes" => {}}
          remaining = self.class::MAX_REVIEW_BYTES
          {"reviewed_head" => reviewed["head"], "reviewed_base" => reviewed["base"],
            "candidate_head" => candidate["head"], "candidate_base" => candidate["base"]}.each do |label, commit|
            git(repository, deadline, "cat-file", "-e", "#{commit}^{commit}")
            tree = git(repository, deadline, "rev-parse", "#{commit}^{tree}").strip
            inventory = head_comparison_inventory(repository, deadline, tree)
            remaining -= JSON.generate(inventory).bytesize
            reject!("Complete head comparison context is oversized") if remaining.negative?
            context.fetch("inventories")[label] = {"tree" => tree, "entries" => inventory}
          end
          oids = context.fetch("inventories").values.flat_map { |inventory| inventory.fetch("entries").map { |entry| entry.fetch("oid") } }.uniq
          sizes = oids.zip(candidate_blob_sizes(repository, deadline, oids)).to_h
          reject!("Complete head comparison object content is oversized") if sizes.values.sum > remaining
          each_candidate_blob(repository, deadline, sizes.to_a) do |oid, content|
            object = {"size" => content.bytesize, "sha256" => Digest::SHA256.hexdigest(content), "content" => review_bytes(content)}
            remaining -= JSON.generate(object).bytesize
            reject!("Complete head comparison context is oversized") if remaining.negative?
            context.fetch("objects")[oid] = object
          end
          {"candidate_delta" => [reviewed["head"], candidate["head"]],
            "base_delta" => [reviewed["base"], candidate["base"]],
            "original_scope" => [reviewed["base"], reviewed["head"]],
            "current_scope" => [candidate["base"], candidate["head"]]}.each do |label, revisions|
            delta = head_comparison_delta(repository, deadline, revisions, remaining)
            remaining -= JSON.generate(delta).bytesize
            reject!("Complete head comparison context is oversized") if remaining.negative?
            context.fetch("changes")[label] = delta
          end
          # Include structural JSON overhead in the final bound as well as all
          # original bytes. No partial inventory or truncated patch is returned.
          reject!("Complete head comparison context is oversized") if JSON.generate(context).bytesize > self.class::MAX_REVIEW_BYTES
          context
        rescue AttemptErrors::ReceiptRejected => error
          reject!("Head comparison read failed: #{error.message}")
        end

        def head_comparison_inventory(repository, deadline, tree)
          entries = git(repository, deadline, "ls-tree", "-r", "-z", tree, limit: self.class::MAX_BYTES).b.split("\0")
          reject!("Complete head comparison inventory is oversized") if entries.size > self.class::MAX_OBJECTS
          entries.map do |entry|
            metadata, path = entry.split("\t", 2)
            mode, kind, oid = metadata.to_s.split(" ")
            # Inventory entries carry whole paths only; bound their bytes
            # before JSON encoding or delta cross-checks consume them.
            reject!("Complete head comparison path exceeds bounded length") unless path && !path.empty? &&
              path.bytesize <= Atoms::CandidateLimits::PATH_BYTES
            unless kind == "blob" && %w[100644 100755 120000].include?(mode) && oid&.match?(self.class::SHA)
              reject!("Complete head comparison contains an unsupported Git entry")
            end
            {"path" => review_bytes(path), "mode" => mode, "oid" => oid}
          end
        end

        def head_comparison_delta(repository, deadline, revisions, remaining)
          options = ["--no-ext-diff", "--no-textconv", "--no-renames", "--ignore-submodules=none"]
          patch = git(repository, deadline, "diff", *options, "--binary", "--full-index", "--src-prefix=a/", "--dst-prefix=b/",
            *revisions, "--", limit: [remaining, 1].max).b
          paths = git(repository, deadline, "diff", *options, "--name-only", "-z", *revisions, "--", limit: [remaining, 1].max).b.split("\0")
          stats = git(repository, deadline, "diff", *options, "--numstat", "-z", *revisions, "--", limit: [remaining, 1].max).b.split("\0")
          binary = stats.filter_map do |entry|
            added, removed, path = entry.split("\t", 3)
            reject!("Complete head comparison diff inventory is invalid") unless path && paths.include?(path)
            path if added == "-" || removed == "-"
          end
          {"from" => revisions.first, "to" => revisions.last, "patch" => review_bytes(patch),
            "patch_sha256" => Digest::SHA256.hexdigest(patch), "paths" => paths.map { |path| review_bytes(path) },
            "binary_paths" => binary.map { |path| review_bytes(path) }}
        end
      end
    end
  end
end
