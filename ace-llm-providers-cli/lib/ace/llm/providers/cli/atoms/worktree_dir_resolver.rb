# frozen_string_literal: true

module Ace
  module LLM
    module Providers
      module CLI
        module Atoms
          # Detects if the current directory is a git worktree and returns
          # the common git dir path that needs to be writable for sandbox tools.
          #
          # In a worktree, `.git` is a file containing `gitdir: <path>` pointing
          # to the worktree metadata under the parent repo's `.git/worktrees/`.
          # The parent `.git/` directory must be writable for index.lock etc.
          class WorktreeDirResolver
            # @param working_dir [String] directory to check (default: Dir.pwd)
            # @return [String, nil] path to common .git dir, or nil if not a worktree
            def self.call(working_dir: Dir.pwd)
              new.call(working_dir: working_dir)
            end

            def call(working_dir: Dir.pwd)
              dot_git = File.join(working_dir, ".git")

              # If .git is a directory (normal repo) or doesn't exist, not a worktree
              return nil unless File.file?(dot_git)

              content = File.read(dot_git).strip
              return nil unless content.start_with?("gitdir:")

              gitdir = content.sub(/\Agitdir:\s*/, "")

              # Resolve relative paths against working_dir
              gitdir = File.expand_path(gitdir, working_dir) unless gitdir.start_with?("/")

              # Walk up from gitdir to find the common .git/ directory
              # Typical path: /repo/.git/worktrees/<name> → we want /repo/.git
              path = gitdir
              while path != "/" && path != "."
                basename = File.basename(path)
                parent = File.dirname(path)

                if basename == "worktrees" && File.directory?(File.join(parent, "refs"))
                  return parent
                end

                path = parent
              end

              nil
            end
          end
        end
      end
    end
  end
end
