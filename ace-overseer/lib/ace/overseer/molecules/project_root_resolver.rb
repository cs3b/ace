# frozen_string_literal: true

module Ace
  module Overseer
    module Molecules
      # Canonical project-root resolution for `ace-overseer start`
      # (task 8xs.t.pu0.1): a subdirectory, a symlinked checkout and a
      # linked WORKTREE of the same repository all resolve to the same
      # owning root, so one repository never runs two whole-project
      # overseers. Worktrees map to the main working tree's root through
      # Git's own `--git-common-dir`; the resolved root is realpathed.
      # All Git access runs through an injectable argv runner seam.
      class ProjectRootResolver
        def initialize(runner: nil)
          @runner = runner || method(:run_argv)
        end

        # @param cwd [String] directory the command was invoked in
        # @return [String] canonical project root (realpath)
        # @raise [Ace::Overseer::Error] not a repository, or a bare repo
        def resolve(cwd:)
          toplevel = git_output(cwd, ["git", "-C", cwd, "rev-parse", "--show-toplevel"])
          root = File.realpath(toplevel)

          common = git_output(cwd, ["git", "-C", root, "rev-parse", "--git-common-dir"])
          common_path = File.expand_path(common, root)
          if File.realpath(common_path) != File.realpath(File.join(root, ".git"))
            # a linked worktree: the main working tree owns the project
            main_root = File.dirname(File.realpath(common_path))
            root = File.realpath(main_root) if File.directory?(main_root)
          end

          root
        rescue Errno::ENOENT, Errno::ENOTDIR
          raise Ace::Overseer::Error, "cannot resolve the project root: '#{cwd}' does not exist"
        end

        private

        def git_output(cwd, argv)
          result = @runner.call(argv)
          unless result["status"] == "ok"
            raise Ace::Overseer::Error,
              "cannot resolve the project root under '#{cwd}': run " \
                "ace-overseer start inside the configured project repository"
          end

          line = result["out"].to_s.lines.first.to_s.strip
          raise Ace::Overseer::Error, "git returned no root for '#{cwd}'" if line.empty?

          line
        end

        def run_argv(argv)
          out, err, status = Open3.capture3(*argv)
          {"status" => status.success? ? "ok" : (status.exitstatus || "signal"),
           "out" => out, "err" => err}
        rescue Errno::ENOENT
          {"status" => "enoent", "out" => "", "err" => ""}
        rescue SystemCallError => e
          {"status" => "exec_failed", "out" => "", "err" => e.class.name}
        end
      end
    end
  end
end
