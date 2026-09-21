# frozen_string_literal: true

require_relative "atoms/command_executor"
require_relative "atoms/server_url"
require_relative "errors"
require_relative "resolved_server"

module Ace
  module Git
    # An exactly-resolved forge server identity.
    #
    # Produced by ServerRegistry (by explicit name, by default resolution, or by
    # remote URL matching). Carries the configured server name, the provider
    # type that owns its behavior, and the configured base URL.
    #
    # @example
    #   ResolvedServer.new(name: "forgejo-lab", provider: :forgejo, url: "https://forgejo.example.com")
    ResolvedServer = Data.define(:name, :provider, :url) do
      # @return [Hash] Plain hash representation
      def to_h
        {name: name, provider: provider, url: url}
      end
    end

    # Resolves forge server identity from configuration, deterministically.
    #
    # Configuration lives under the `git.servers` key (see
    # `.ace-defaults/git/config.yml`). Each entry is a uniquely named server:
    #
    # ```yaml
    # servers:
    #   - name: forgejo-lab
    #     provider: forgejo
    #     url: https://forgejo.example.com/owner/repo
    #     default: true
    #   - name: github-public
    #     provider: github
    #     url: https://github.com/owner/repo
    # ```
    #
    # At most one server may be marked `default: true`. Resolution never falls
    # back silently: every failure raises a classified error from the failure
    # taxonomy.
    class ServerRegistry
      # Internal configured entry: resolved identity plus its default flag.
      Entry = Data.define(:server, :default)

      class << self
        # All configured servers, in configuration order.
        #
        # @return [Array<ResolvedServer>]
        # @raise [DuplicateServerNameError] when two servers share a name
        # @raise [ConfigError] when an entry is malformed
        def servers
          entries.map(&:server)
        end

        # Resolve a server by its explicit, configured name.
        #
        # @param name [String, Symbol] configured server name
        # @return [ResolvedServer]
        # @raise [UnknownServerNameError] when no server has that name
        def resolve(name)
          wanted = name.to_s
          entries.map(&:server).find { |server| server.name == wanted } ||
            raise(UnknownServerNameError, "No server named '#{wanted}' is configured " \
              "(configured: #{servers.map(&:name).join(", ")}); add it to git.servers")
        end

        # Resolve the explicitly configured default server.
        #
        # @return [ResolvedServer]
        # @raise [NoDefaultServerConfiguredError] when zero servers are default
        # @raise [MultipleDefaultServersError] when more than one is default
        def resolve_default
          defaults = entries.select(&:default)
          if defaults.empty?
            raise NoDefaultServerConfiguredError,
              "No default server configured; mark exactly one entry in git.servers with default: true"
          end
          if defaults.size > 1
            raise MultipleDefaultServersError,
              "Multiple servers marked as default: #{defaults.map { |e| e.server.name }.join(", ")}; " \
              "keep exactly one"
          end

          defaults.first.server
        end

        # Resolve server identity from a git remote URL, matching configured
        # servers deterministically (no hostname assumptions).
        #
        # @param remote_name [String, nil] git remote name (default: configured
        #   `remote`, then "origin")
        # @return [ResolvedServer] the single matching configured server
        # @raise [AmbiguousRemoteError] when the remote matches no configured
        #   server, or more than one
        def resolve_remote(remote_name = nil)
          remote_name ||= Ace::Git.config["remote"] || "origin"
          remote_url = read_remote_url(remote_name)
          matches = entries.map(&:server).select { |server| Atoms::ServerUrl.match?(server.url, remote_url) }

          if matches.empty?
            raise AmbiguousRemoteError,
              "Remote '#{remote_name}' (#{remote_url || "missing"}) matches no configured server " \
              "(configured: #{servers.map(&:name).join(", ")})"
          end
          if matches.size > 1
            raise AmbiguousRemoteError,
              "Remote '#{remote_name}' (#{remote_url}) matches multiple configured servers: " \
              "#{matches.map(&:name).join(", ")}; make server URLs distinct"
          end

          matches.first
        end

        private

        # Validated configured entries, in configuration order.
        def entries
          raw = Ace::Git.config["servers"]
          return [] if raw.nil?

          raise ConfigError, "servers config must be a list" unless raw.is_a?(Array)

          list = raw.map { |entry| build_entry(entry) }
          assert_unique_names!(list)
          list
        end

        # Read a remote URL with local git only (no network, no forge CLI).
        def read_remote_url(remote_name)
          result = Atoms::CommandExecutor.execute("git", "remote", "get-url", remote_name.to_s)
          result[:success] ? result[:output].to_s.strip : nil
        end

        # Build one internal entry from a config entry, validating structure.
        def build_entry(entry)
          unless entry.is_a?(Hash)
            raise ConfigError, "Each git.servers entry must be a mapping with name, provider, url"
          end

          normalized = entry.transform_keys(&:to_s)
          %w[name provider url].each do |key|
            next unless normalized[key].nil? || normalized[key].to_s.empty?

            raise ConfigError, "git.servers entry is missing '#{key}': #{entry.inspect}"
          end

          Entry.new(
            server: ResolvedServer.new(
              name: normalized["name"].to_s,
              provider: normalized["provider"].to_s.to_sym,
              url: normalized["url"].to_s
            ),
            default: normalized["default"] == true || normalized["default"].to_s == "true"
          )
        end

        def assert_unique_names!(list)
          names = list.map { |entry| entry.server.name }
          duplicates = names.tally.select { |_name, count| count > 1 }.keys
          return if duplicates.empty?

          raise DuplicateServerNameError,
            "Duplicate server names in git.servers: #{duplicates.join(", ")}; server names must be unique"
        end
      end
    end
  end
end
