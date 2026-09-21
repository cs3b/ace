# frozen_string_literal: true

module Ace
  module Git
    # Normalized evidence types produced by every provider implementation.
    #
    # Provider packages translate their CLI responses into exactly these
    # shapes, so consumers can stay forge-neutral. All fields except the
    # identifying ones may be nil when a provider cannot supply them.
    #
    # Pull request state values: :open, :merged, :closed. Issue state values:
    # :open, :closed.
    ProviderPullRequest = Data.define(
      :server_name, :number, :title, :state, :head_ref, :base_ref,
      :head_sha, :author, :url, :draft, :merged_at
    )

    ProviderIssue = Data.define(:server_name, :number, :title, :state, :author, :url, :labels)

    # Normalized check/CI evidence for one check run.
    ProviderCheck = Data.define(:server_name, :name, :state, :conclusion, :url)

    # Normalized repository evidence.
    ProviderRepository = Data.define(:server_name, :full_name, :default_branch, :url)
  end
end
