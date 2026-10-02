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

        def validate_link!(identity:, task_id: nil)
          server = IssueLink.validate!(identity)
          tracking(server).validate_link!(number: identity.fetch("number"), task_id: task_id)
        end

        def sync_task(task:)
          identity = task.metadata.fetch("remote_issue")
          server = IssueLink.validate!(identity)
          tracking(server).sync(
            number: identity.fetch("number"), task_id: task.id,
            task_path: safe_task_path(task), task_status: task.status
          )
        end

        def clear_task(task:)
          identity = task.metadata.fetch("remote_issue")
          server = IssueLink.validate!(identity)
          tracking(server).clear(number: identity.fetch("number"), task_id: task.id)
        end

        private

        def tracking(server)
          Ace::Git::Organisms::IssueTracking.new(provider: @provider_factory.for(server))
        end

        def safe_task_path(task)
          path = Pathname.new(task.file_path || task.path)
          relative = path.relative_path_from(Pathname.pwd).to_s
          relative.start_with?("../") ? path.basename.to_s : relative
        rescue ArgumentError
          path.basename.to_s
        end
      end
    end
  end
end
