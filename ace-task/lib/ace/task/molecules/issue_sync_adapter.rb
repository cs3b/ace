# frozen_string_literal: true

require_relative "issue_link"
require "pathname"

module Ace
  module Task
    module Molecules
      class IssueSyncAdapter
        def initialize(provider_factory: Ace::Git::Providers)
          @provider_factory = provider_factory
        end

        def validate_link!(identity:, task_id: nil, previous_task_id: nil)
          server = IssueLink.validate!(identity)
          tracking(server).validate_link!(number: identity.fetch("number"), task_id: task_id,
            previous_task_id: previous_task_id)
        end

        def sync_task(task:, previous_task_id: nil, before_create: nil)
          identity = task.metadata.fetch("remote_issue")
          server = IssueLink.validate!(identity)
          tracking(server).sync(
            number: identity.fetch("number"), task_id: task.id,
            previous_task_id: previous_task_id,
            task_link: task_link(identity, task), task_status: task.status,
            create_pending: task.metadata["issue_sync_operation"] == "reconcile-create",
            before_create: before_create
          )
        end

        def clear_task(task:, previous_task_id: nil)
          identity = task.metadata.fetch("remote_issue")
          server = IssueLink.validate!(identity)
          tracking(server).clear(number: identity.fetch("number"), task_id: task.id,
            previous_task_id: previous_task_id)
        end

        private

        def tracking(server)
          Ace::Git::Organisms::IssueTracking.new(provider: @provider_factory.for(server))
        end

        # Repository-relative so the forge blob link is stable no matter which
        # working directory ace-task was invoked from.
        def safe_task_path(task)
          path = Pathname.new(task.file_path || task.path).expand_path
          root = Pathname.new(git_repo_root(path))
          relative = path.relative_path_from(root).to_s
          relative.start_with?("../") ? path.basename.to_s : relative
        rescue ArgumentError, SystemCallError
          path.basename.to_s
        end

        def git_repo_root(path)
          candidate = path.dirname
          loop do
            return candidate.to_s if File.exist?(File.join(candidate, ".git"))

            parent = candidate.parent
            raise SystemCallError, "no git repository" if parent == candidate

            candidate = parent
          end
        end

        # A repository-relative path is not a resolvable link target inside a
        # forge comment; build a web URL from the linked repository using the
        # provider's file-browse route (GitHub: /blob/, Forgejo: /src/branch/).
        def task_link(identity, task)
          base = Ace::Git::Atoms::ServerUrl.web_base(identity.fetch("repository_url"))
          path = safe_task_path(task)
          if identity.fetch("provider") == "github"
            "#{base}/blob/HEAD/#{path}"
          else
            "#{base}/src/branch/HEAD/#{path}"
          end
        end
      end
    end
  end
end
