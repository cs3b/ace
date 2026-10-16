# frozen_string_literal: true

require "ace/assign/molecules/installed_journal_read"

module Ace
  module Lab
    module Molecules
      # Observe a mutable ordinary worker checkout. The root-installed project
      # selection supplies both boundaries; caller input never selects a Git
      # repository. This is historical observation, not a checkout freeze.
      class OrdinaryWorktreeRead
        def initialize(root:, common_dir:, deadline:)
          @root, @common, @deadline = root, common_dir, deadline
          [root, common_dir].each { |path| absolute!(path) }
        end

        def observe(cwd)
          absolute!(cwd)
          remaining
          unless within?(cwd, @root)
            unavailable!("worker working directory is outside installed worktrees")
          end
          before = selection(cwd)
          head = git(before, "rev-parse", "--verify", "HEAD^{commit}").strip
          unavailable!("worker HEAD is unavailable") unless head.match?(/\A[0-9a-f]{40}\z/)
          after = selection(cwd)
          unless before == after && git(after, "rev-parse", "--verify", "HEAD^{commit}").strip == head
            unavailable!("worker checkout changed during observation")
          end
          {"cwd" => cwd, "worktree" => before.fetch("worktree"), "git_dir" => before.fetch("git_dir"),
            "common_dir" => @common, "head" => head}
        rescue SystemCallError, IOError, Timeout::Error, Ace::Herdr::Molecules::BoundedProcess::PostLaunchError
          unavailable!("worker checkout cannot be observed")
        end

        def ref_head(cwd, ref)
          unless ref.is_a?(String) && ref.match?(%r{\Arefs/[a-zA-Z0-9_./-]+\z}) && !ref.include?("..")
            unavailable!("selected Git ref is invalid")
          end
          with_selected_read(cwd) do |selected|
            head = git(selected, "rev-parse", "--verify", "#{ref}^{commit}").strip
            unavailable!("selected ref is not a commit") unless head.match?(/\A[0-9a-f]{40}\z/)
            head
          end
        end

        def commit?(cwd, head)
          exact_head!(head)
          with_selected_read(cwd) do |selected|
            git(selected, "rev-parse", "--verify", "--quiet", "#{head}^{commit}", allowed_status: [0, 1], result: true).status.success?
          end
        end

        def ancestor?(cwd, ancestor, descendant)
          exact_head!(ancestor); exact_head!(descendant)
          with_selected_read(cwd) do |selected|
            git(selected, "merge-base", "--is-ancestor", ancestor, descendant, allowed_status: [0, 1], result: true).status.success?
          end
        end

        private

        def exact_head!(head)
          unavailable!("selected Git head is invalid") unless head.is_a?(String) && head.match?(/\A[0-9a-f]{40}\z/)
        end

        def with_selected_read(cwd)
          absolute!(cwd)
          unavailable!("selected repository leaves installed worktrees") unless within?(cwd, @root)
          before = selection(cwd)
          value = yield before
          unavailable!("selected repository changed during read") unless before == selection(cwd)
          value
        rescue SystemCallError, IOError, Timeout::Error, Ace::Herdr::Molecules::BoundedProcess::PostLaunchError => error
          unavailable!("selected repository cannot be observed (#{error.class})")
        end

        def selection(cwd)
          directory!(cwd)
          directory!(@common)
          worktree = cwd
          loop do
            break if File.exist?(File.join(worktree, ".git")) || File.symlink?(File.join(worktree, ".git"))
            unavailable!("worker checkout is unavailable") if worktree == @root
            worktree = File.dirname(worktree)
          end
          marker = File.join(worktree, ".git")
          metadata = {}
          git_dir = if File.lstat(marker).directory?
            directory!(marker)
            unavailable!("worker belongs to another project") unless marker == @common
            marker
          else
            bytes = regular!(marker, metadata, 4096)
            match = bytes.match(/\Agitdir: ([^\n\0]+)\n?\z/)
            unavailable!("worker Git pointer is invalid") unless match
            selected = File.expand_path(match[1], worktree)
            unless File.dirname(selected) == File.join(@common, "worktrees")
              unavailable!("worker Git pointer leaves installed project")
            end
            directory!(selected)
            common = regular!(File.join(selected, "commondir"), metadata, 4096).strip
            unavailable!("worker common directory differs") unless File.expand_path(common, selected) == @common
            back = regular!(File.join(selected, "gitdir"), metadata, 4096).strip
            unavailable!("worker Git backpointer differs") unless back == marker
            selected
          end
          @entries = 0
          %w[objects refs].each { |name| storage!(File.join(@common, name)) }
          %w[commondir shallow reftable info/grafts objects/info/alternates objects/info/http-alternates].each do |name|
            path = File.join(@common, name)
            unavailable!("worker object storage is redirected") if File.exist?(path) || File.symlink?(path)
          end
          regular!(File.join(git_dir, "HEAD"), metadata, 4096)
          packed = File.join(@common, "packed-refs")
          storage!(packed) if File.exist?(packed) || File.symlink?(packed)
          local_refs = File.join(git_dir, "refs")
          storage!(local_refs) if git_dir != @common && (File.exist?(local_refs) || File.symlink?(local_refs))
          config!(File.join(@common, "config"), metadata)
          local = File.join(git_dir, "config.worktree")
          config!(local, metadata) if File.exist?(local) || File.symlink?(local)
          {"worktree" => worktree, "git_dir" => git_dir, "metadata" => metadata,
            "directories" => [cwd, worktree, git_dir, @common].to_h { |path| [path, identity(File.lstat(path))] }}
        end

        def config!(path, metadata)
          bytes = regular!(path, metadata, 65_536)
          output = run(["config", "--no-includes", "--null", "--list", "--file", "/dev/stdin"], stdin: bytes)
          output.split("\0").each do |entry|
            key, value = entry.split("\n", 2)
            if key.start_with?("include.", "includeif.", "extensions.") || key == "core.worktree" ||
                key == "core.repositoryformatversion" && value != "0"
              unavailable!("worker Git configuration redirects project storage")
            end
          end
        end

        def git(selected, *argv, allowed_status: [0], result: false)
          captured = run_result(["--git-dir=#{selected.fetch('git_dir')}", "--work-tree=#{selected.fetch('worktree')}",
            "-c", "safe.directory=#{selected.fetch('worktree')}", "-c", "core.hooksPath=/dev/null",
            "-c", "core.fsmonitor=false", "-c", "protocol.allow=never", *argv],
            environment: {"GIT_COMMON_DIR" => @common, "GIT_OBJECT_DIRECTORY" => File.join(@common, "objects")}, allowed_status: allowed_status)
          result ? captured : captured.stdout
        end

        def run(argv, stdin: "", environment: {})
          run_result(argv, stdin: stdin, environment: environment).stdout
        end

        def run_result(argv, stdin: "", environment: {}, allowed_status: [0])
          result = Ace::Herdr::Molecules::BoundedProcess.call(["/usr/bin/git", "--no-pager", *argv],
            environment: Ace::Assign::Molecules::InstalledJournalRead::ENVIRONMENT.merge(environment), chdir: "/",
            stdin_data: stdin, timeout_s: remaining, output_limit: 65_536, cleanup_group: true)
          unavailable!("worker Git read failed or exceeded its bound") unless allowed_status.include?(result.status.exitstatus) && !result.oversized
          result
        end

        def regular!(path, metadata, limit)
          directory!(File.dirname(path))
          File.open(path, File::RDONLY | File::NOFOLLOW | File::NONBLOCK) do |file|
            before = file.stat
            unavailable!("worker metadata must be a bounded regular file") unless before.file? && before.size <= limit
            bytes = file.read(limit + 1)
            unless bytes.bytesize <= limit && stamp(before) == stamp(file.stat) && stamp(before) == stamp(File.lstat(path))
              unavailable!("worker metadata changed during read")
            end
            metadata[path] = [stamp(before), bytes]
            bytes
          end
        end

        def directory!(path)
          current = path
          loop do
            remaining
            stat = File.lstat(current)
            unavailable!("worker directory is redirected") unless stat.directory? && !stat.symlink?
            break if current == "/"
            current = File.dirname(current)
          end
        end

        def storage!(path)
          remaining
          @entries += 1
          unavailable!("worker storage inventory exceeds its bound") if @entries > Ace::Assign::Molecules::InstalledJournalRead::ENTRY_LIMIT
          stat = File.lstat(path)
          unavailable!("worker storage is redirected") unless !stat.symlink? && (stat.file? || stat.directory?)
          Dir.each_child(path) { |name| storage!(File.join(path, name)) } if stat.directory?
        end

        def absolute!(path)
          unless path.is_a?(String) && path.bytesize.between?(1, 4096) && !path.include?("\0") &&
              path.start_with?("/") && File.expand_path(path) == path
            unavailable!("worker path is invalid")
          end
        end

        def within?(path, parent) = path == parent || path.start_with?(parent + "/")
        def identity(stat) = [stat.dev, stat.ino]
        def stamp(stat) = [stat.dev, stat.ino, stat.size, stat.mtime, stat.ctime]

        def remaining
          unless @deadline.is_a?(Numeric) && @deadline.finite? && (left = @deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)).positive?
            unavailable!("worker observation deadline elapsed")
          end
          left
        end

        def unavailable!(reason)
          raise Ace::Assign::AttemptErrors::EvidenceUnavailable, reason
        end
      end
    end
  end
end
