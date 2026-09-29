# frozen_string_literal: true

require "json"
require "ace/support/cli"

module Ace
  module Git
    module CLI
      module Commands
        # Forge-neutral pull request lifecycle commands.
        #
        # Every subcommand accepts `--server NAME` / `--default-server`
        # (mutually exclusive; remote resolution when neither is given) and
        # `--format json`. Success output carries the resolved server,
        # provider, and exact PR identity; failures exit nonzero with the
        # classified provider error and never claim success.
        module Pr
          # Shared plumbing for all pr subcommands.
          class BaseCommand < Ace::Support::Cli::Command
            include Ace::Support::Cli::Base

            option :server, type: :string, desc: "Explicit configured forge server name"
            option :default_server, type: :boolean, desc: "Use the configured default forge server"
            option :remote, type: :string, desc: "Git remote used for server resolution when nothing is selected"
            option :format, type: :string, default: "text", desc: "Output format: text, json"

            private

            def lifecycle(options)
              Organisms::PullRequestLifecycle.new(
                server_name: options[:server],
                use_default: options[:default_server] == true,
                remote_name: options[:remote]
              )
            end

            def render_evidence(options, header: nil, **fields)
              if options[:format] == "json"
                puts JSON.pretty_generate(fields)
              else
                puts header if header
                fields.each do |label, value|
                  next if value.nil?

                  puts "#{label.to_s.tr("_", "-")}: #{format_value(value)}"
                end
              end
            end

            def format_value(value)
              case value
              when Hash
                value.compact.map { |key, nested| "#{key}=#{nested}" }.join(" ")
              else
                value.to_s
              end
            end

            def emit_receipt(options, operation, receipt)
              pr = receipt.pull_request
              render_evidence(
                options,
                header: "#{operation} PR ##{pr.number} on #{receipt.server_name}",
                server: receipt.server_name,
                operation: receipt.operation,
                idempotency: receipt.idempotency,
                number: pr.number,
                url: pr.url,
                title: pr.title,
                state: pr.state,
                draft: pr.draft,
                head: pr.head_sha,
                head_ref: pr.head_ref,
                head_repository: pr.head_repository_url,
                base_ref: pr.base_ref,
                base_repository: pr.base_repository_url
              )
            end
          end

          # `ace-git pr show ID`
          class Show < BaseCommand
            desc "Show normalized pull request evidence"

            argument :identifier, required: true, desc: "PR number, owner/repo#number, or URL"

            def call(identifier:, **options)
              pr = lifecycle(options).show(identifier)
              render_evidence(
                options,
                header: "PR ##{pr.number} on #{pr.server_name}",
                server: pr.server_name,
                number: pr.number,
                url: pr.url,
                title: pr.title,
                state: pr.state,
                draft: pr.draft,
                head: pr.head_sha,
                head_ref: pr.head_ref,
                head_repository: pr.head_repository_url,
                base_ref: pr.base_ref,
                base_repository: pr.base_repository_url,
                merge_commit: pr.merge_commit_sha
              )
            rescue Ace::Git::Error, ArgumentError => e
              raise Ace::Support::Cli::Error.new(e.message)
            end
          end

          # `ace-git pr create --head REF --head-repo URL --base REF --expected-head SHA --title TEXT [--body-file PATH] [--draft]`
          class Create < BaseCommand
            desc "Create (or reconcile to) a pull request; drafts are the default"

            option :head, type: :string, required: true, desc: "Source branch/ref"
            option :head_repo, type: :string, desc: "Source repository URL (fork); defaults to the base repository"
            option :base, type: :string, required: true, desc: "Base branch/ref"
            option :expected_head, type: :string, required: true, desc: "Exact SHA the pushed source ref must resolve to"
            option :title, type: :string, required: true, desc: "Pull request title"
            option :body_file, type: :string, desc: "Path to the pull request body text"
            option :draft, type: :boolean, default: true, desc: "Create as draft when the provider supports it"

            def call(head:, base:, expected_head:, title:, **options)
              receipt = lifecycle(options).create(
                head_ref: head,
                head_repository_url: options[:head_repo],
                base_ref: base,
                expected_head: expected_head,
                title: title,
                body_file: options[:body_file],
                draft: options[:draft] != false
              )
              emit_receipt(options, "created", receipt)
            rescue Ace::Git::Error, ArgumentError => e
              raise Ace::Support::Cli::Error.new(e.message)
            end
          end

          # `ace-git pr update ID --expected-head SHA [--title TEXT] [--body-file PATH]`
          class Update < BaseCommand
            desc "Update pull request title/body after head verification"

            argument :identifier, required: true, desc: "PR number, owner/repo#number, or URL"
            option :expected_head, type: :string, required: true, desc: "Exact SHA the PR head must still be"
            option :title, type: :string, desc: "New title"
            option :body_file, type: :string, desc: "Path to the new body text"

            def call(identifier:, expected_head:, **options)
              receipt = lifecycle(options).update(
                identifier,
                expected_head: expected_head,
                title: options[:title],
                body_file: options[:body_file]
              )
              emit_receipt(options, "updated", receipt)
            rescue Ace::Git::Error, ArgumentError => e
              raise Ace::Support::Cli::Error.new(e.message)
            end
          end

          # `ace-git pr ready ID --expected-head SHA`
          class Ready < BaseCommand
            desc "Mark a draft pull request ready for review"

            argument :identifier, required: true, desc: "PR number, owner/repo#number, or URL"
            option :expected_head, type: :string, required: true, desc: "Exact SHA the PR head must still be"

            def call(identifier:, expected_head:, **options)
              receipt = lifecycle(options).ready(identifier, expected_head: expected_head)
              emit_receipt(options, "readied", receipt)
            rescue Ace::Git::Error, ArgumentError => e
              raise Ace::Support::Cli::Error.new(e.message)
            end
          end

          # `ace-git pr merge ID --expected-head SHA --method squash|merge|rebase`
          class Merge < BaseCommand
            desc "Merge with provider-side expected-head enforcement; no default method"

            argument :identifier, required: true, desc: "PR number, owner/repo#number, or URL"
            option :expected_head, type: :string, required: true, desc: "Exact SHA enforced by the provider"
            option :method, type: :string, required: true, desc: "Merge method: squash, merge, rebase"

            def call(identifier:, expected_head:, method:, **options)
              receipt = lifecycle(options).merge(identifier, expected_head: expected_head, method: method)
              emit_receipt(options, "merged", receipt)
            rescue Ace::Git::Error, ArgumentError => e
              raise Ace::Support::Cli::Error.new(e.message)
            end
          end
        end
      end
    end
  end
end
