# frozen_string_literal: true

require "test_helper"
require "ace/task/molecules/issue_sync_adapter"
require "tmpdir"
require "fileutils"

class IssueSyncAdapterTest < AceTaskTestCase
  def test_sync_uses_stored_identity_and_exact_task_path
    in_temp_git_repo do |root|
      identity = {"server_name" => "lab", "provider" => "forgejo",
                  "repository_url" => "https://forge.example/owner/repo", "number" => 42,
                  "url" => "https://forge.example/owner/repo/issues/42"}
      server = Ace::Git::ResolvedServer.new(name: "lab", provider: :forgejo,
        url: identity.fetch("repository_url"))
      captured = nil
      tracking = Object.new
      tracking.define_singleton_method(:sync) { |**args| captured = args }
      factory = Object.new
      factory.define_singleton_method(:for) { |_server| :provider }
      adapter = Ace::Task::Molecules::IssueSyncAdapter.new(provider_factory: factory)
      task = Ace::Task::Models::Task.new(id: "8pp.t.q7w", status: "pending",
        path: File.join(root, "tasks", "8pp.t.q7w"),
        file_path: File.join(root, "tasks", "8pp.t.q7w", "task.s.md"),
        metadata: {"remote_issue" => identity})

      Ace::Task::Molecules::IssueLink.stub(:validate!, server) do
        Ace::Git::Organisms::IssueTracking.stub(:new, tracking) { adapter.sync_task(task: task) }
      end

      assert_equal({number: 42, task_id: task.id,
                    task_link: "https://forge.example/owner/repo/blob/HEAD/tasks/8pp.t.q7w/task.s.md",
                    task_status: "pending"}, captured)
    end
  end

  def test_task_link_strips_clone_suffix_from_repository_url
    in_temp_git_repo do |root|
      identity = {"server_name" => "lab", "provider" => "forgejo",
                  "repository_url" => "https://forge.example/owner/repo.git", "number" => 7,
                  "url" => "https://forge.example/owner/repo/issues/7"}
      server = Ace::Git::ResolvedServer.new(name: "lab", provider: :forgejo,
        url: identity.fetch("repository_url"))
      captured = nil
      tracking = Object.new
      tracking.define_singleton_method(:sync) { |**args| captured = args }
      factory = Object.new
      factory.define_singleton_method(:for) { |_server| :provider }
      adapter = Ace::Task::Molecules::IssueSyncAdapter.new(provider_factory: factory)
      task = Ace::Task::Models::Task.new(id: "8pp.t.q7w", status: "pending",
        path: File.join(root, "tasks", "8pp.t.q7w"),
        file_path: File.join(root, "tasks", "8pp.t.q7w", "task.s.md"),
        metadata: {"remote_issue" => identity})

      Ace::Task::Molecules::IssueLink.stub(:validate!, server) do
        Ace::Git::Organisms::IssueTracking.stub(:new, tracking) { adapter.sync_task(task: task) }
      end

      assert_equal "https://forge.example/owner/repo/blob/HEAD/tasks/8pp.t.q7w/task.s.md", captured[:task_link]
    end
  end

  def test_task_link_is_stable_regardless_of_working_directory
    in_temp_git_repo do |root|
      identity = {"server_name" => "lab", "provider" => "forgejo",
                  "repository_url" => "https://forge.example/owner/repo", "number" => 42,
                  "url" => "https://forge.example/owner/repo/issues/42"}
      server = Ace::Git::ResolvedServer.new(name: "lab", provider: :forgejo,
        url: identity.fetch("repository_url"))
      captured = nil
      tracking = Object.new
      tracking.define_singleton_method(:sync) { |**args| captured = args }
      factory = Object.new
      factory.define_singleton_method(:for) { |_server| :provider }
      adapter = Ace::Task::Molecules::IssueSyncAdapter.new(provider_factory: factory)
      task = Ace::Task::Models::Task.new(id: "8pp.t.q7w", status: "pending",
        path: File.join(root, "tasks", "8pp.t.q7w"),
        file_path: File.join(root, "tasks", "8pp.t.q7w", "task.s.md"),
        metadata: {"remote_issue" => identity})

      Dir.chdir(File.join(root, "tasks")) do
        Ace::Task::Molecules::IssueLink.stub(:validate!, server) do
          Ace::Git::Organisms::IssueTracking.stub(:new, tracking) { adapter.sync_task(task: task) }
        end
      end

      assert_equal "https://forge.example/owner/repo/blob/HEAD/tasks/8pp.t.q7w/task.s.md", captured[:task_link]
    end
  end

  private

  def in_temp_git_repo
    Dir.mktmpdir("issue-sync-adapter") do |dir|
      root = File.realpath(dir)
      FileUtils.mkdir_p(File.join(root, "tasks", "8pp.t.q7w"))
      FileUtils.mkdir_p(File.join(root, ".git"))
      yield root
    end
  end
end
