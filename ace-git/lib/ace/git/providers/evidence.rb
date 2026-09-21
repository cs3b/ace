# frozen_string_literal: true

module Ace
  module Git
    module Providers
      # Normalized evidence types produced by every provider implementation.
      #
      # Provider packages translate their CLI responses into exactly these
      # shapes, so consumers can stay forge-neutral. All fields except the
      # identifying ones may be nil when a provider cannot supply them.
      module Evidence
        # Pull request state values: :open, :merged, :closed
      end

      # Normalized pull request evidence.
      #
      # @example
      #   #<Ace::Git::ProviderPullRequest number=25 title="..." head_sha="fc14c43d3..." base_ref="main" state=:merged>
      ProviderPullRequest = Data.define(
        :server_name, :number, :title, :state, :head_ref, :base_ref,
        :head_sha, :author, :url, :draft, :merged_at
      )

      # Normalized issue evidence. Issue state values: :open, :closed
      ProviderIssue = Data.define(:server_name, :number, :title, :state, :author, :url, :labels)

      # Normalized check/CI evidence for one check run.
      ProviderCheck = Data.define(:server_name, :name, :state, :conclusion, :url)

      # Normalized repository evidence.
      ProviderRepository = Data.define(:server_name, :full_name, :default_branch, :url)
    end
  end
end
