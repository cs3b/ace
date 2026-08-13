# frozen_string_literal: true

require "digest"
require "json"
require "open3"
require "time"

module Ace
  module Git
    module Worktree
      module Molecules
        # Builds a complete, deterministic, report-only worktree cleanup inventory.
        #
        # Inventories worktrees, local refs, and remote refs independently.
        # Proves ancestry where possible. Produces an ordered no-mutation plan
        # with a canonical SHA-256 digest.
        class CleanupReporter
          SCHEMA_VERSION = "1.0"

          # @param target [String] Target ref (e.g. "main", "origin/main")
          # @param remote [String] Remote name (e.g. "origin")
          # @param offline [Boolean] Skip remote refresh
          def initialize(target:, remote: "origin", offline: false)
            @target = target
            @remote = remote
            @offline = offline
          end

          # Build complete cleanup report.
          # @return [Hash] Report with inventories, actions, and plan_digest
          def report
            common_dir = resolve_common_dir
            return error_result("Cannot resolve common git directory") unless common_dir

            target_sha = resolve_ref(@target)
            return error_result("Cannot resolve target ref '#{@target}'") unless target_sha

            remote_sha = resolve_ref("#{@remote}/#{@target}")

            # Refresh remote evidence (fetch objects only, no ref update)
            refresh_result = refresh_remote_evidence unless @offline

            # Collect inventories
            worktrees = inventory_worktrees(common_dir)
            local_refs = inventory_local_refs
            remote_refs = inventory_remote_refs

            # Classify each item
            classify_worktrees(worktrees, target_sha)
            classify_refs(local_refs, target_sha, "local")
            classify_refs(remote_refs, target_sha, "remote")

            # Build ordered action plan
            actions = build_action_plan(worktrees, local_refs, remote_refs)

            # Compute canonical digest
            plan_digest = compute_plan_digest(worktrees, local_refs, remote_refs, actions, target_sha)

            {
              success: true,
              schema_version: SCHEMA_VERSION,
              repository: common_dir,
              target: {ref: @target, sha: target_sha},
              remote: {name: @remote, sha: remote_sha},
              refresh: @offline ? {status: "offline"} : (refresh_result || {status: "skipped"}),
              worktrees: worktrees,
              local_refs: local_refs,
              remote_refs: remote_refs,
              actions: actions,
              plan_digest: plan_digest
            }
          end

          private

          def error_result(message)
            {success: false, error: message, schema_version: SCHEMA_VERSION}
          end

          # --- Repository resolution ---

          def resolve_common_dir
            out, status = Open3.capture2("git", "rev-parse", "--git-common-dir")
            return nil unless status.success?

            path = out.strip
            # Normalize to absolute
            File.expand_path(path)
          end

          def resolve_ref(ref)
            out, status = Open3.capture2("git", "rev-parse", "--verify", "#{ref}^{commit}")
            return nil unless status.success?

            out.strip
          end

          # --- Remote evidence ---

          def refresh_remote_evidence
            # Fetch objects without updating refs
            _out, _err, status = Open3.capture3(
              "git", "fetch", @remote, "--no-tags", "--no-write-fetch-head"
            )
            {status: status.success? ? "refreshed" : "failed"}
          rescue Errno::ENOENT
            {status: "unavailable"}
          end

          # --- Worktree inventory ---

          def inventory_worktrees(common_dir)
            out, status = Open3.capture2("git", "worktree", "list", "--porcelain")
            return [] unless status.success?

            parse_porcelain_worktrees(out, common_dir)
          end

          def parse_porcelain_worktrees(output, common_dir)
            blocks = output.split("\n\n").reject(&:empty?)
            blocks.map { |block| parse_worktree_block(block, common_dir) }.compact
          end

          def parse_worktree_block(block, common_dir)
            fields = {}
            block.each_line do |line|
              line = line.chomp
              if line.start_with?("worktree ")
                fields[:path] = line.sub("worktree ", "")
              elsif line.start_with?("HEAD ")
                fields[:sha] = line.sub("HEAD ", "")
              elsif line.start_with?("branch ")
                fields[:branch] = line.sub("branch ", "").sub("refs/heads/", "")
              elsif line == "bare"
                fields[:bare] = true
              elsif line == "detached"
                fields[:detached] = true
              elsif line.start_with?("locked")
                fields[:locked] = true
                reason = line.sub("locked", "").strip
                fields[:lock_reason] = reason unless reason.empty?
              elsif line.start_with?("prunable")
                fields[:prunable] = true
              end
            end

            return nil unless fields[:path]

            primary = primary_worktree?(fields[:path], common_dir)
            dirty = primary ? nil : dirty_state(fields[:path])

            {
              path: fields[:path],
              sha: fields[:sha],
              branch: fields[:branch],
              primary: primary,
              bare: fields[:bare] || false,
              detached: fields[:detached] || false,
              locked: fields[:locked] || false,
              lock_reason: fields[:lock_reason],
              prunable: fields[:prunable] || false,
              dirty: dirty,
              protected: primary || (fields[:locked] || false),
              ancestry: nil,
              action: nil,
              retention_reason: nil
            }
          end

          def primary_worktree?(path, common_dir)
            # Primary worktree contains the .git directory
            git_path = File.join(path, ".git")
            return true if File.directory?(git_path)

            # Also check if common_dir parent matches
            common_parent = File.dirname(common_dir)
            File.expand_path(path) == File.expand_path(common_parent)
          end

          def dirty_state(path)
            return nil unless File.directory?(path)

            out, status = Open3.capture2("git", "-C", path, "status", "--porcelain")
            return nil unless status.success?

            lines = out.lines.map(&:chomp).reject(&:empty?)
            return nil if lines.empty?

            staged = []
            unstaged = []
            untracked = []

            lines.each do |line|
              xy = line[0..1]
              file = line[3..]
              if xy[0] == "?"
                untracked << file
              elsif xy[0] != " "
                staged << file
              end
              if xy[1] != " " && xy[1] != "?"
                unstaged << file
              end
            end

            {staged: staged, unstaged: unstaged, untracked: untracked}
          end

          # --- Ref inventory ---

          def inventory_local_refs
            out, status = Open3.capture2(
              "git", "for-each-ref",
              "--format=%(refname:short) %(objectname) %(upstream:short)",
              "refs/heads/"
            )
            return [] unless status.success?

            out.lines.map do |line|
              parts = line.strip.split(" ", 3)
              {
                name: parts[0],
                sha: parts[1],
                upstream: parts[2]&.empty? ? nil : parts[2],
                protected: protected_ref?(parts[0]),
                ancestry: nil,
                action: nil,
                retention_reason: nil
              }
            end
          end

          def inventory_remote_refs
            out, status = Open3.capture2(
              "git", "for-each-ref",
              "--format=%(refname:short) %(objectname)",
              "refs/remotes/#{@remote}/"
            )
            return [] unless status.success?

            out.lines.map do |line|
              parts = line.strip.split(" ", 2)
              short_name = parts[0].sub("#{@remote}/", "")
              next if short_name == "HEAD"

              {
                name: parts[0],
                short_name: short_name,
                sha: parts[1],
                protected: short_name == @target,
                ancestry: nil,
                action: nil,
                retention_reason: nil
              }
            end.compact
          end

          def protected_ref?(name)
            return true if name == @target

            protected = begin
              Ace::Git::Worktree.protected_branches
            rescue
              %w[main master]
            end
            protected.include?(name)
          end

          # --- Classification ---

          def classify_worktrees(worktrees, target_sha)
            worktrees.each do |wt|
              if wt[:primary]
                wt[:action] = "retain"
                wt[:retention_reason] = "primary_checkout"
              elsif wt[:locked]
                wt[:action] = "retain"
                wt[:retention_reason] = "locked"
              elsif wt[:dirty] && !wt[:dirty].values.all?(&:empty?)
                wt[:action] = "retain"
                wt[:retention_reason] = "dirty"
              elsif wt[:sha] && ancestor?(wt[:sha], target_sha)
                wt[:ancestry] = "ancestor"
                wt[:action] = "remove"
              else
                wt[:ancestry] = "unproven"
                wt[:action] = "retain"
                wt[:retention_reason] = "ancestry_unproven"
              end
            end
          end

          def classify_refs(refs, target_sha, kind)
            refs.each do |ref|
              if ref[:protected]
                ref[:action] = "retain"
                ref[:retention_reason] = "protected"
              elsif ancestor?(ref[:sha], target_sha)
                ref[:ancestry] = "ancestor"
                ref[:action] = "remove"
              else
                ref[:ancestry] = "unproven"
                ref[:action] = "retain"
                ref[:retention_reason] = "ancestry_unproven"
              end
            end
          end

          def ancestor?(candidate_sha, target_sha)
            return false unless candidate_sha && target_sha

            _out, status = Open3.capture2(
              "git", "merge-base", "--is-ancestor", candidate_sha, target_sha
            )
            status.success?
          end

          # --- Action plan ---

          def build_action_plan(worktrees, local_refs, remote_refs)
            actions = []

            # Order: worktrees first, local refs second, remote refs last
            worktrees.select { |wt| wt[:action] == "remove" }.each do |wt|
              actions << {
                type: "remove_worktree",
                target: wt[:path],
                branch: wt[:branch],
                sha: wt[:sha],
                proof: wt[:ancestry]
              }
            end

            local_refs.select { |r| r[:action] == "remove" }.each do |ref|
              actions << {
                type: "delete_local_ref",
                target: ref[:name],
                sha: ref[:sha],
                proof: ref[:ancestry]
              }
            end

            remote_refs.select { |r| r[:action] == "remove" }.each do |ref|
              actions << {
                type: "delete_remote_ref",
                target: ref[:name],
                sha: ref[:sha],
                proof: ref[:ancestry]
              }
            end

            actions
          end

          # --- Canonical digest ---

          def compute_plan_digest(worktrees, local_refs, remote_refs, actions, target_sha)
            canonical = {
              target_sha: target_sha,
              worktrees: worktrees.sort_by { |wt| wt[:path] }.map { |wt| [wt[:path], wt[:sha], wt[:action]] },
              local_refs: local_refs.sort_by { |r| r[:name] }.map { |r| [r[:name], r[:sha], r[:action]] },
              remote_refs: remote_refs.sort_by { |r| r[:name] }.map { |r| [r[:name], r[:sha], r[:action]] },
              actions: actions.map { |a| [a[:type], a[:target], a[:sha]] }
            }

            Digest::SHA256.hexdigest(JSON.generate(canonical))
          end
        end
      end
    end
  end
end
