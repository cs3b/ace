# frozen_string_literal: true

require "uri"

module Ace
  module Git
    module Forgejo
      # Selected-server identity binding for `fj` repository commands.
      #
      # Forgejo CLI v0.6.0 exposes two explicit-target mechanisms and no
      # others (see the task evidence file): `-H HOST` plus either
      # `-r OWNER/REPO` (search, create, issue/actions repo selection) or a
      # qualified `OWNER/REPO#N` object id (view/edit/status family). A
      # repository command may only launch through {RepositoryBinding.argv_for},
      # which exists for operations whose argv form was observed on a real
      # binary; everything else refuses before any subprocess.
      module RepositoryBinding
        # forgejo-cli versions whose help/output this table was observed on.
        # A different installed version must not inherit these capabilities;
        # the executor refuses it until the table is re-observed and extended.
        OBSERVED_VERSIONS = ["v0.6.0"].freeze

        # The validated selected repository. Built once from the resolved
        # server URL; malformed selections fail with ConfigError before any
        # subprocess launch.
        class Target
          attr_reader :host, :authority, :repo, :url

          # @param server_url [String] resolved server URL (https://host/owner/repo)
          # @raise [Ace::Git::ConfigError] when host or owner/repository is missing
          def self.resolve(server_url)
            uri = URI.parse(server_url.to_s)
            raise_config_error!(server_url, "missing host") if uri.host.nil? || uri.host.empty?

            authority = if uri.port && uri.port != uri.default_port
              "#{uri.host}:#{uri.port}"
            else
              uri.host
            end
            path = uri.path.to_s.sub(%r{/+\z}, "").sub(/\.git\z/i, "")
            segments = path.split("/").reject(&:empty?)
            unless segments.length == 2
              raise_config_error!(server_url, "path must be exactly owner/repository")
            end

            repo = "#{segments[0]}/#{segments[1]}"
            new(
              host: uri.host, authority: authority, repo: repo,
              url: "#{uri.scheme || "https"}://#{authority}/#{repo}"
            )
          rescue URI::Error
            raise_config_error!(server_url, "unparseable URL")
          end

          def self.raise_config_error!(server_url, reason)
            raise Ace::Git::ConfigError,
              "Selected Forgejo server URL #{server_url.inspect} is unusable (#{reason}); " \
              "configure the server as scheme://host/owner/repository"
          end

          def initialize(host:, authority:, repo:, url:)
            @host = host
            @authority = authority
            @repo = repo
            @url = url
          end
          private_class_method :new

          # Qualified object id form accepted by `fj pr/issue view|edit` (v0.6.0).
          def qualified_ref(number)
            "#{repo}##{number}"
          end
        end

        # Capability table: repository operations with an argv form observed
        # on real forgejo-cli v0.6.0 (task evidence file). Forms receive the
        # validated Target plus the provider's per-call arguments and return
        # the argv after the binary name; the executor stamps `-H host`.
        FORMS = {
          pr_view: ->(target, number) do
            ["--style", "minimal", "pr", "view", target.qualified_ref(number)]
          end,
          pr_commits: ->(target, number) do
            ["--style", "minimal", "pr", "view", target.qualified_ref(number), "commits"]
          end,
          pr_diff: ->(target, number) do
            ["pr", "view", target.qualified_ref(number), "diff"]
          end,
          pr_search: ->(target, state) do
            ["--style", "minimal", "pr", "search", "--state", state, "-r", target.repo]
          end,
          pr_create: ->(target, title, head_ref, base_ref, body) do
            argv = ["pr", "create", title, "--head", head_ref, "--base", base_ref]
            argv += ["--body", body] if body
            argv + ["-r", target.repo]
          end,
          pr_edit_title: ->(target, number, title) do
            ["pr", "edit", target.qualified_ref(number), "title", title]
          end,
          pr_edit_body: ->(target, number, body) do
            ["pr", "edit", target.qualified_ref(number), "body", body]
          end,
          issue_view: ->(target, number) do
            ["--style", "minimal", "issue", "view", target.qualified_ref(number)]
          end,
          actions_tasks: ->(target) do
            ["--style", "minimal", "actions", "tasks", "-r", target.repo]
          end,
          repo_view: ->(target) do
            ["--style", "minimal", "repo", "view", target.repo]
          end
        }.freeze

        class << self
          # Resolve one repository operation to its explicitly bound argv.
          #
          # @param operation [Symbol] key in {FORMS}
          # @param target [Target] validated selected repository
          # @param arguments [Array] per-operation arguments
          # @raise [Ace::Git::ProviderUnsupportedCapabilityError] when the
          #   operation has no observed form
          def argv_for(operation, target, arguments)
            form = FORMS.fetch(operation) do
              raise Ace::Git::ProviderUnsupportedCapabilityError,
                "forgejo-cli #{OBSERVED_VERSIONS.join("/")} exposes no repository-bound " \
                "argv form for #{operation.inspect}; refusing to run it against #{target.repo}"
            end
            form.call(target, *arguments)
          end
        end
      end
    end
  end
end
