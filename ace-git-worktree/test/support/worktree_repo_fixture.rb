# frozen_string_literal: true

require "fileutils"
require "tmpdir"

# Builds disposable git repositories with linked worktrees for probe, runner,
# and list-report tests. All commits use fixed identities and explicit
# author/committer dates so activity windows are deterministic.
module WorktreeRepoFixture
  def build_repo(prefix: "ace-worktree-fixture")
    root = Dir.mktmpdir(prefix)
    git!("init", "--quiet", "-b", "main", root)
    git!("-C", root, "config", "user.name", "Fixture")
    git!("-C", root, "config", "user.email", "fixture@example.com")
    git!("-C", root, "config", "commit.gpgsign", "false")
    root
  end

  def remove_repo(root)
    FileUtils.rm_rf(root) if root && Dir.exist?(root)
  end

  # Write a file and commit it.
  #
  # @return [String] commit sha
  def commit_file(worktree_path, relative_path, content, message: "fixture commit", date: Time.now)
    write_file(worktree_path, relative_path, content)
    git!("-C", worktree_path, "add", "--", relative_path)
    git!("-C", worktree_path, "commit", "--quiet", "-m", message, env: commit_env(date))
    git_output("-C", worktree_path, "rev-parse", "HEAD").strip
  end

  # Create a linked worktree from a branch tip (defaults to main).
  #
  # @return [String] worktree path
  def create_worktree(repo_root, name, branch:, from: "main")
    path = File.join(repo_root, ".ace-wt", name)
    FileUtils.mkdir_p(File.dirname(path))
    git!("-C", repo_root, "worktree", "add", "--quiet", "-b", branch, path, from)
    path
  end

  def write_file(worktree_path, relative_path, content)
    absolute = File.join(worktree_path, relative_path)
    FileUtils.mkdir_p(File.dirname(absolute))
    File.write(absolute, content)
    absolute
  end

  def write_task(project_root, dir_name, id:, worktree_path: nil, worktree_branch: nil, status: "pending")
    frontmatter = ["---", "id: #{id}", "status: #{status}"]
    if worktree_path || worktree_branch
      frontmatter << "worktree:"
      frontmatter << "  path: #{worktree_path}" if worktree_path
      frontmatter << "  branch: #{worktree_branch}" if worktree_branch
    end
    frontmatter << "---"
    relative = File.join(".ace-tasks", dir_name, "#{dir_name}.s.md")
    write_file(project_root, relative, "#{frontmatter.join("\n")}\n\n# Task\n")
  end

  def git_output(*args)
    out = IO.popen([{"GIT_CONFIG_NOSYSTEM" => "1"}, "git", *args], err: [:child, :out], &:read)
    raise "git #{args.join(" ")} failed: #{out}" unless $?.success?

    out
  end

  def git!(*args, env: {})
    full_env = {"GIT_CONFIG_NOSYSTEM" => "1"}.merge(env)
    success = system(full_env, "git", *args, out: File::NULL, err: File::NULL)
    raise "git #{args.join(" ")} failed" unless success

    true
  end

  private

  def commit_env(date)
    stamp = date.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
    {"GIT_AUTHOR_DATE" => stamp, "GIT_COMMITTER_DATE" => stamp}
  end
end
