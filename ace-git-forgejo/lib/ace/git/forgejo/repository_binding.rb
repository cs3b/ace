# frozen_string_literal: true

require "json"
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
          attr_reader :host, :authority, :host_url, :repo, :url

          SUPPORTED_SCHEMES = ["http", "https"].freeze

          # @param server_url [String] resolved server URL (https://host/owner/repo)
          # @raise [Ace::Git::ConfigError] when host, scheme, or owner/repository is missing
          def self.resolve(server_url)
            uri = URI.parse(server_url.to_s)
            raise_config_error!(server_url, "missing host") if uri.host.nil? || uri.host.empty?
            unless SUPPORTED_SCHEMES.include?(uri.scheme.to_s.downcase)
              raise_config_error!(server_url, "scheme must be http or https")
            end

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
            # `fj -H` accepts a full URL and otherwise assumes HTTPS (observed
            # v0.6.0); passing scheme + authority preserves the configured
            # endpoint exactly.
            host_url = "#{uri.scheme.downcase}://#{authority}"
            new(
              host: uri.host, authority: authority, host_url: host_url,
              repo: repo, url: "#{host_url}/#{repo}"
            )
          rescue URI::Error
            raise_config_error!(server_url, "unparseable URL")
          end

          def self.raise_config_error!(server_url, reason)
            raise Ace::Git::ConfigError,
              "Selected Forgejo server URL #{server_url.inspect} is unusable (#{reason}); " \
              "configure the server as scheme://host/owner/repository"
          end

          def initialize(host:, authority:, host_url:, repo:, url:)
            @host = host
            @authority = authority
            @host_url = host_url
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

          # Refuse to launch repository commands when the readable fj keys
          # file contains an alias that redirects the selected host. fj
          # v0.6.0 applies its `aliases` map to `-H` values (observed: an
          # alias silently rewrites the endpoint), and no CLI command prints
          # aliases, so ACE verifies the one configuration file it must
          # agree with — read-only, never modified. An absent or unreadable
          # keys file (other fj versions, moved storage) cannot be verified
          # and is allowed; misdirected runtime requests still classify
          # through the shared taxonomy.
          #
          # @param host_url [String] selected scheme://authority
          # @param config_path [String, nil] explicit keys-file path (tests)
          # @raise [Ace::Git::ConfigError] on a conflicting redirect
          def reject_selected_host_redirect!(host_url, config_path: nil)
            path = config_path || default_keys_path
            return unless path && File.exist?(path)

            data = JSON.parse(File.read(path))
            aliases = data.is_a?(Hash) ? data["aliases"] : nil
            return unless aliases.is_a?(Hash)

            selected = strip_scheme(host_url)
            redirect = aliases[selected] || aliases[host_url.to_s]
            return if redirect.nil? || redirect.to_s.empty?

            redirect_authority = strip_scheme(redirect)
            return if redirect_authority.casecmp(selected).zero?

            raise Ace::Git::ConfigError,
              "fj configuration redirects selected host #{selected} to #{redirect} " \
              "(#{path}); remove or fix the conflicting fj alias — ACE will not " \
              "operate on a redirected endpoint"
          rescue JSON::ParserError, IOError, SystemCallError
            nil
          end

          # Observed forgejo-cli keys-file locations (data_dir of the
          # `directories` crate, plus the legacy Cyborus org path). On macOS
          # the real CLI uses bundle-dir names: forgejo-cli.forgejo-cli
          # (current) and Cyborus.forgejo-cli (legacy).
          def default_keys_path
            candidates = []
            xdg = ENV["XDG_DATA_HOME"]
            candidates << File.join(xdg, "forgejo-cli", "keys.json") if xdg && !xdg.empty?
            home = Dir.home rescue nil
            if home
              candidates << File.join(home, ".local", "share", "forgejo-cli", "keys.json")
              candidates << File.join(home, "Library", "Application Support", "forgejo-cli", "keys.json")
              # macOS app-support uses reverse-DNS bundle directories.
              candidates << File.join(home, "Library", "Application Support", "forgejo-cli.forgejo-cli", "keys.json")
              candidates << File.join(home, ".local", "share", "Cyborus", "forgejo-cli", "keys.json")
              candidates << File.join(home, "Library", "Application Support", "Cyborus.forgejo-cli", "keys.json")
              candidates << File.join(home, "Library", "Application Support", "Cyborus", "forgejo-cli", "keys.json")
            end
            candidates.find { |path| File.exist?(path) }
          end

          private

          def strip_scheme(url)
            url.to_s.sub(%r{\A[a-z][a-z0-9+.\-]*://}i, "").chomp("/")
          end
        end
      end
    end
  end
end
