# frozen_string_literal: true

require "ace/git"

module Ace
  module Git
    module Worktree
      module Molecules
        # Creates draft pull requests for task worktrees through the
        # forge-neutral provider contract.
        #
        # The caller must supply the exact pushed head SHA (`expected_head`);
        # creation or reuse is proven against that SHA by the provider, never
        # inferred from branch names. Server selection resolves lazily inside
        # the lifecycle organism, so local-only task runs never touch a forge.
        class PullRequestCreator
          # @param server_name [String, nil] explicit server selection
          # @param use_default [Boolean] resolve the configured default server
          # @param remote_name [String, nil] remote used for fallback resolution
          # @param timeout [Integer, nil] provider timeout
          # @param runner [Proc, nil] injectable provider runner (tests)
          def initialize(server_name: nil, use_default: false, remote_name: nil, timeout: nil, runner: nil)
            @selection = {
              server_name: server_name, use_default: use_default, remote_name: remote_name
            }
            @timeout = timeout
            @runner = runner
          end

          # Create (or reconcile to) a draft PR for a pushed branch.
          #
          # @param branch [String] pushed head branch
          # @param base [String] base branch/ref
          # @param title [String] PR title
          # @param expected_head [String] exact SHA the pushed branch resolves to
          # @param head_repository_url [String, nil] source repository URL
          #   (defaults to the selected server's repository)
          # @param body [String, nil] PR body text
          # @return [Hash] {success:, pr_number:, pr_url:, existing:, head_sha:, error:}
          def create_draft(branch:, base:, title:, expected_head:, head_repository_url: nil, body: nil)
            lifecycle = Ace::Git::Organisms::PullRequestLifecycle.new(**@selection.merge(timeout: @timeout, runner: @runner))
            receipt = lifecycle.create(
              head_ref: branch,
              head_repository_url: head_repository_url,
              base_ref: base,
              expected_head: expected_head,
              title: title,
              body: body,
              draft: true
            )
            pr = receipt.pull_request
            {
              success: true,
              pr_number: pr.number,
              pr_url: pr.url,
              existing: receipt.idempotency == :existing,
              head_sha: pr.head_sha,
              error: nil
            }
          rescue Ace::Git::Error => e
            {success: false, pr_number: nil, pr_url: nil, existing: false, head_sha: nil, error: e.message}
          end
        end
      end
    end
  end
end
