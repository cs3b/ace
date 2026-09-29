# frozen_string_literal: true

require "fileutils"
require "open3"

# Temporary Git repository fixture for prune safety tests.
module PruneGitFixtures
  class Repo
    attr_reader :path

    def initialize(path)
      @path = File.expand_path(path)
      FileUtils.mkdir_p(@path)
    end

    def init
      git!("init", "-q", "-b", "main")
      git!("config", "user.email", "prune-test@example.com")
      git!("config", "user.name", "Prune Tests")
      git!("config", "commit.gpgsign", "false")
      self
    end

    def git!(*args)
      stdout, stderr, status = Open3.capture3("git", "-C", @path, *args.map(&:to_s))
      raise "git #{args.join(' ')} failed in #{@path}: #{stderr}" unless status.success?

      stdout.strip
    end

    def write(relative_path, content)
      file = File.join(@path, relative_path)
      FileUtils.mkdir_p(File.dirname(file))
      File.write(file, content)
      file
    end

    def symlink(relative_path, target)
      file = File.join(@path, relative_path)
      FileUtils.mkdir_p(File.dirname(file))
      File.symlink(target, file)
    end

    def remove(relative_path)
      File.delete(File.join(@path, relative_path))
    end

    def chmod(relative_path, mode)
      File.chmod(mode, File.join(@path, relative_path))
    end

    def commit(message)
      git!("add", "-A")
      git!("commit", "-q", "--allow-empty", "-m", message)
      rev("HEAD")
    end

    def rev(revision)
      git!("rev-parse", revision)
    end

    def branch(name, start_point = "HEAD")
      git!("branch", name, start_point.to_s)
    end

    def checkout(branch_name, create: false)
      if create
        git!("checkout", "-q", "-b", branch_name)
      else
        git!("checkout", "-q", branch_name)
      end
    end

    def add_worktree(worktree_path, branch_name = nil, start_point = "HEAD")
      if branch_name
        git!("worktree", "add", "-q", "-b", branch_name, worktree_path, start_point.to_s)
      else
        git!("worktree", "add", "-q", worktree_path, start_point.to_s)
      end
      Repo.new(worktree_path)
    end

    def clone_to(destination_path)
      git!("clone", "-q", @path, destination_path)
      Repo.new(destination_path)
    end
  end
end
