# frozen_string_literal: true

require "open3"
require "yaml"
require "ace/git/atoms/server_url"

module Ace
  module Review
    module Molecules
      # Resolves and validates the reference head for a delta review round.
      #
      # A delta round reviews only the diff between a reference head (an earlier
      # reviewed commit) and the PR's current head. The reference is either given
      # explicitly or auto-resolved from the most recent prior review session of
      # the same PR. Every failure mode fails closed: no prior session, a
      # non-ancestor reference (e.g. rewritten history) or missing local objects
      # refuse the round instead of falling back to a full review.
      module DeltaResolver
        SHA_PATTERN = /\A[0-9a-f]{40}\z/

        # Resolve the reference head and compute the delta diff.
        #
        # @param reference [String, Symbol, nil] explicit head, or :auto to resolve
        #   from the most recent prior session of this PR
        # @param pr_metadata [Hash] PR metadata (requires headRefOid and url)
        # @param project_root [String, nil] repository root for git commands
        # @return [Hash] {success:, reference_head:, source:, session_dir:, diff:, error:}
        def self.resolve(reference, pr_metadata, project_root: nil)
          head = pr_metadata["headRefOid"].to_s
          return {success: false, error: "Delta review requires the PR head SHA"} unless head.match?(SHA_PATTERN)

          if reference == :auto || reference.nil?
            session = latest_session_head(pr_metadata["url"].to_s, project_root: project_root)
            return session unless session[:success]

            reference = session[:reference_head]
            session_dir = session[:session_dir]
            source = :session
          else
            source = :explicit
          end

          resolved = rev_parse(reference, project_root: project_root)
          return resolved unless resolved[:success]

          reference_head = resolved[:stdout]
          return {success: false, error: "Delta reference '#{reference}' is not a commit SHA"} unless reference_head.match?(SHA_PATTERN)
          return {success: false, error: "Delta reference head #{reference_head} is not an ancestor of the current PR head #{head}; history was likely rewritten — re-run a full review round"} unless ancestor?(reference_head, head, project_root: project_root)

          if reference_head == head && newer_local_head?(head, pr_metadata, project_root: project_root)
            return {success: false, error: "PR metadata still reports the reviewed head #{head}, but the local PR branch is newer; reconcile the push and refresh PR metadata before recording an empty delta"}
          end

          diff = run_git(["diff", "#{reference_head}..#{head}"], project_root: project_root)
          return diff unless diff[:success]

          {success: true, reference_head: reference_head, source: source,
           session_dir: session_dir, diff: diff[:stdout]}
        end

        # Repeated provider reads can return the same stale snapshot after a
        # push. A local descendant is evidence against certifying that no code
        # changed. Select the PR branch explicitly; an unrelated checkout does
        # not define that PR's head.
        def self.newer_local_head?(head, metadata, project_root:)
          branch = metadata["headRefName"].to_s
          repository = metadata["head_repository_url"].to_s
          return false if branch.empty? || repository.empty?
          remote = run_git(["for-each-ref", "--format=%(push:remotename)%00%(push:remoteref)", "refs/heads/#{branch}"], project_root: project_root)
          return false unless remote[:success]
          remote_name, remote_ref = remote[:stdout].strip.split("\0", -1)
          return false if remote_name.to_s.empty?
          remote_ref = default_push_ref(branch, remote_name, project_root: project_root) if remote_ref.to_s.empty?
          return false unless remote_ref == "refs/heads/#{branch}"
          urls = run_git(["remote", "get-url", "--push", "--all", remote_name], project_root: project_root)
          return false unless urls[:success] && urls[:stdout].lines.any? do |url|
            Ace::Git::Atoms::ServerUrl.match?(repository, url.strip)
          end
          local = rev_parse("refs/heads/#{branch}", project_root: project_root)
          local[:success] && local[:stdout] != head && ancestor?(head, local[:stdout], project_root: project_root)
        end
        private_class_method :newer_local_head?

        # Git exposes push:remoteref for explicit push refspecs only. Its
        # default policies use branch names/upstream, not that empty atom.
        def self.default_push_ref(branch, remote, project_root:)
          explicit = run_git(["config", "--get-all", "remote.#{remote}.push"], project_root: project_root)
          return nil if explicit[:success] && !explicit[:stdout].empty?
          policy = run_git(["config", "--get", "push.default"], project_root: project_root)
          upstream = run_git(["config", "--get", "branch.#{branch}.merge"], project_root: project_root)
          case policy[:stdout].to_s.strip
          when "", "simple"
            target = upstream[:stdout].to_s.strip
            fetch = run_git(["config", "--get", "branch.#{branch}.remote"], project_root: project_root)
            triangular = fetch[:success] && fetch[:stdout].strip != remote
            "refs/heads/#{branch}" if triangular || target.empty? || target == "refs/heads/#{branch}"
          when "current", "matching" then "refs/heads/#{branch}"
          when "upstream" then upstream[:stdout].to_s.strip
          end
        end
        private_class_method :default_push_ref

        # Find the head SHA recorded by the most recent prior session of this PR.
        #
        # @param pr_url [String] canonical PR URL stored in session metadata
        # @param project_root [String, nil]
        # @return [Hash] {success:, reference_head:, session_dir:, error:}
        def self.latest_session_head(pr_url, project_root: nil)
          root = project_root || Dir.pwd
          sessions_dir = File.join(root, ".ace-local", "review", "sessions")
          return {success: false, error: no_prior_session_message(pr_url)} unless Dir.exist?(sessions_dir)

          candidates = Dir.glob(File.join(sessions_dir, "review-*"))
            .select { |path| File.directory?(path) }
            # Order by the session's own last write (metadata.yml), not the
            # directory entry — directory mtimes tie when sessions are created
            # within the same second.
            .sort_by { |path| -session_mtime(path).to_f }

          candidates.each do |dir|
            metadata_path = File.join(dir, "metadata.yml")
            next unless File.file?(metadata_path)

            metadata = YAML.safe_load_file(metadata_path, permitted_classes: [Time, Date, Symbol])
            next unless metadata.is_a?(Hash)
            next unless metadata["pr_url"].to_s == pr_url

            head = metadata.dig("diff_manifest", "head_sha") ||
                   metadata.dig("diff_manifest", :head_sha)
            next unless head.to_s.match?(SHA_PATTERN)

            return {success: true, reference_head: head, session_dir: dir}
          end

          {success: false, error: no_prior_session_message(pr_url)}
        rescue Psych::Exception, Errno::ENOENT => e
          {success: false, error: "Cannot read prior review sessions for delta resolution: #{e.message}"}
        end

        def self.session_mtime(session_dir)
          metadata_path = File.join(session_dir, "metadata.yml")
          File.file?(metadata_path) ? File.mtime(metadata_path) : File.mtime(session_dir)
        end
        private_class_method :session_mtime

        def self.no_prior_session_message(pr_url)
          "No prior review session records a head for #{pr_url}; " \
            "run a full review round first or pass an explicit reference: --delta <head>"
        end
        private_class_method :no_prior_session_message

        def self.rev_parse(reference, project_root:)
          result = run_git(["rev-parse", "#{reference}^{commit}"], project_root: project_root)
          return result unless result[:success]

          result[:stdout] = result[:stdout].strip
          result
        end

        def self.ancestor?(reference_head, head, project_root:)
          root = project_root || Dir.pwd
          system("git", "merge-base", "--is-ancestor", reference_head, head, chdir: root,
            out: File::NULL, err: File::NULL)
        end
        private_class_method :ancestor?

        def self.run_git(args, project_root:)
          root = project_root || Dir.pwd
          stdout, stderr, status = Open3.capture3("git", *args, chdir: root)
          unless status.success?
            detail = stderr.strip
            detail = "exit #{status.exitstatus}" if detail.empty?
            return {success: false, error: "git #{args.first} failed for delta review: #{detail}"}
          end

          {success: true, stdout: stdout}
        end
        private_class_method :run_git
      end
    end
  end
end
