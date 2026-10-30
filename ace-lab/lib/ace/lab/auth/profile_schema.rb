# frozen_string_literal: true

module Ace
  module Lab
    module Auth
      # Pure validation/normalization of the trusted auth configuration
      # (task 8xs.t.pu0.7): the host-owned `auth:` section of the same
      # root-owned authorization document install converges
      # (`/etc/lab/ace-lab/authorization.yml`). The existing `principals`
      # map stays a VISIBILITY map — it never grants token issuance; only
      # an explicit auth profile does, and a project/coworker config can
      # only NAME a profile, never widen one.
      #
      # A profile declares: provider (forgejo|github|env), the roles and
      # principals allowed to request it, repos/scopes, ttl (default 30m,
      # max 60m unless the host sets an explicit profile limit), the
      # expiry mode (provider | host-revoke | process), the handoff
      # style, and REFERENCES to issuer credentials (paths — values stay
      # in the host's protected store).
      class ProfileSchema
        # The bundled providers; an explicitly registered plugin (tests,
        # host extensions) resolves through the registry at request
        # time — the schema only demands a concrete provider name.
        BUNDLED_PROVIDERS = %w[forgejo github env].freeze
        EXPIRY_MODES = %w[provider host-revoke process].freeze
        DEFAULT_TTL_MINUTES = 30
        DEFAULT_MAX_TTL_MINUTES = 60
        PROFILE_KEYS = %w[provider roles principals repos scopes ttl_minutes max_ttl_minutes
          expiry_mode handoff issuer env_names].freeze

        class << self
          # @param document [Hash] parsed authorization document
          # @return [Hash] {"leases_dir"=>, "credentials_dir"=>,
          #   "profiles" => {name => normalized profile}}
          # @raise [Ace::Lab::InvalidConfigurationError]
          def normalize(document)
            auth = document["auth"]
            if auth.nil?
              return {"leases_dir" => nil, "credentials_dir" => nil, "profiles" => {}}
            end
            unless auth.is_a?(Hash)
              raise Ace::Lab::InvalidConfigurationError, "auth section must be a mapping"
            end

            profiles = auth["profiles"] || {}
            unless profiles.is_a?(Hash) && profiles.values.all? { |profile| profile.is_a?(Hash) }
              raise Ace::Lab::InvalidConfigurationError, "auth profiles must be a mapping of profile names to settings"
            end

            normalized = profiles.to_h { |name, raw| [name, profile(name, raw)] }
            {"leases_dir" => optional_path(auth["leases_dir"]),
             "credentials_dir" => optional_path(auth["credentials_dir"]),
             "profiles" => normalized}
          end

          private

          def profile(name, raw)
            unknown = raw.keys - PROFILE_KEYS
            unless unknown.empty?
              raise Ace::Lab::InvalidConfigurationError,
                "auth profile '#{name}' has unknown key '#{unknown.sort.first}'"
            end

            provider = required_string(raw, name, "provider")

            roles = string_list(raw["roles"], name, "roles")
            principals = string_list(raw["principals"], name, "principals")
            repos = string_list(raw["repos"], name, "repos")
            ttl = positive_minutes(raw["ttl_minutes"], name, DEFAULT_TTL_MINUTES)
            max_ttl = positive_minutes(raw["max_ttl_minutes"], name, DEFAULT_MAX_TTL_MINUTES)
            raise_conflict(name, "ttl_minutes exceeds max_ttl_minutes") if ttl > max_ttl

            expiry_mode = raw["expiry_mode"] || default_expiry_mode(provider)
            unless EXPIRY_MODES.include?(expiry_mode)
              raise Ace::Lab::InvalidConfigurationError,
                "auth profile '#{name}' expiry_mode must be one of: #{EXPIRY_MODES.join(', ')}"
            end
            if provider == "env" && expiry_mode != "process" && raw["env_names"] &&
              raw["issuer"].nil?
              # A standalone env profile only exposes process-scoped
              # values; it cannot guarantee remote expiry or revoke.
              raise Ace::Lab::InvalidConfigurationError,
                "auth profile '#{name}': a standalone env profile cannot declare " \
                  "remote expiry/revoke (expiry_mode process only)"
            end

            {"provider" => provider, "roles" => roles, "principals" => principals,
             "repos" => repos, "scopes" => string_list(raw["scopes"], name, "scopes"),
             "ttl_minutes" => ttl, "max_ttl_minutes" => max_ttl,
             "expiry_mode" => expiry_mode,
             "handoff" => raw["handoff"] || "file",
             "issuer" => raw["issuer"].is_a?(Hash) ? raw["issuer"] : {},
             "env_names" => string_list(raw["env_names"], name, "env_names")}
          end

          def default_expiry_mode(provider)
            case provider
            when "github" then "provider" # installation tokens carry a native expires_at
            when "forgejo" then "host-revoke" # no native TTL proven across server versions
            else "process"
            end
          end

          def required_string(raw, name, key)
            value = raw[key]
            unless value.is_a?(String) && !value.strip.empty?
              raise Ace::Lab::InvalidConfigurationError,
                "auth profile '#{name}' key '#{key}' is required"
            end

            value.strip
          end

          def string_list(raw, name, key)
            list = raw.nil? ? [] : raw
            unless list.is_a?(Array) && list.all? { |entry| entry.is_a?(String) && !entry.strip.empty? }
              raise Ace::Lab::InvalidConfigurationError,
                "auth profile '#{name}' key '#{key}' must be a list of non-empty strings"
            end

            list.map(&:strip).uniq
          end

          def positive_minutes(raw, name, default)
            value = raw.nil? ? default : raw
            unless value.is_a?(Integer) && value.positive?
              raise Ace::Lab::InvalidConfigurationError,
                "auth profile '#{name}' ttl must be a positive number of minutes"
            end

            value
          end

          def optional_path(raw)
            return nil if raw.nil?
            unless raw.is_a?(String) && !raw.strip.empty? && raw.start_with?("/")
              raise Ace::Lab::InvalidConfigurationError, "auth paths must be absolute"
            end

            raw.strip
          end

          def raise_conflict(name, reason)
            raise Ace::Lab::InvalidConfigurationError, "auth profile '#{name}': #{reason}"
          end
        end
      end
    end
  end
end
