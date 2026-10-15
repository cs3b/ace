# frozen_string_literal: true

require "yaml"
require_relative "../errors"
require_relative "grant_resolver"

module Ace
  module Lab
    module Molecules
      # The host-installed forge merge configuration for the ordinary merge
      # receiver (spec 8x3.t.xz9.5 integration handoff). The scoped service
      # identity that may merge pull requests is provisioned by the HOST in
      # one root-owned file at a fixed path; this loader reads it through the
      # same trusted-storage verification as the authorization grants and
      # fails closed on anything else. An absent file is an immediate
      # actionable refusal naming the path and its owner — never a silent
      # local fallback and never an invented credential: a receiver without
      # the host-installed identity cannot merge and must say so.
      #
      # Contract (host installs, root-owned 0640, service-readable):
      #
      #   base_url: https://forgejo.example.net
      #   owner: cs3b
      #   repo: ace
      #   token: <scoped: PR read + PR merge + PR comment on that repo only>
      #   merge_timeout_seconds: 900
      #   escalation_owner: host-integrator
      #   review_attachment:
      #     enabled: true
      class ForgeMergeConfig
        DEFAULT_PATH = "/etc/lab/ace-lab/forge-merge.yml"
        DEFAULT_ESCALATION_OWNER = "host-integrator"
        KEYS = %w[base_url owner repo token merge_timeout_seconds escalation_owner
          review_attachment].freeze

        # @raise [Ace::Lab::InvalidConfigurationError] absent file ⇒ the
        #   actionable `config missing:` message naming the path and owner;
        #   every other trust/shape failure also fails closed.
        def self.load(path = DEFAULT_PATH)
          content = GrantResolver.read_verified(path)
          unless content
            raise Ace::Lab::InvalidConfigurationError,
              "config missing: #{path} (owner: #{DEFAULT_ESCALATION_OWNER} — install the " \
              "root-owned 0640 forge merge configuration for the scoped service identity)"
          end
          document = YAML.safe_load(content, permitted_classes: [Date], aliases: false)
          new(document, source: path)
        rescue Psych::Exception
          raise Ace::Lab::InvalidConfigurationError,
            "invalid lab configuration: forge merge configuration #{path} could not be parsed"
        end

        attr_reader :base_url, :owner, :repo, :token, :merge_timeout_seconds, :escalation_owner,
          :review_attachment_enabled, :source

        def initialize(document, source: nil)
          unless document.is_a?(Hash) && (document.keys - KEYS).empty? &&
              (KEYS - document.keys).empty?
            raise Ace::Lab::InvalidConfigurationError,
              "forge merge configuration must contain exactly: #{KEYS.join(", ")}"
          end
          @source = source
          @base_url = base_url!(document.fetch("base_url"))
          @owner = name!(document.fetch("owner"), "owner")
          @repo = name!(document.fetch("repo"), "repo")
          @token = token!(document.fetch("token"))
          @merge_timeout_seconds = timeout!(document.fetch("merge_timeout_seconds"))
          @escalation_owner = name!(document.fetch("escalation_owner"), "escalation_owner")
          attachment = document.fetch("review_attachment")
          unless attachment.is_a?(Hash) && attachment.keys == %w[enabled] &&
              [true, false].include?(attachment.fetch("enabled"))
            raise Ace::Lab::InvalidConfigurationError,
              "forge merge review_attachment must be exactly {enabled: true|false}"
          end
          @review_attachment_enabled = attachment.fetch("enabled")
          freeze
        end

        # The token is a live credential: never rendered, never logged.
        def inspect
          "#<#{self.class.name} base_url=#{@base_url} owner=#{@owner} repo=#{@repo} " \
            "token=[REDACTED] merge_timeout_seconds=#{@merge_timeout_seconds} " \
            "escalation_owner=#{@escalation_owner} " \
            "review_attachment_enabled=#{@review_attachment_enabled}>"
        end

        private

        def base_url!(value)
          uri = URI.parse(value.to_s)
          unless uri.is_a?(URI::HTTPS) && uri.host && uri.path.empty? && uri.to_s == value
            raise Ace::Lab::InvalidConfigurationError,
              "forge merge base_url must be an https origin without path, query or fragment"
          end
          value
        rescue URI::Error
          raise Ace::Lab::InvalidConfigurationError,
            "forge merge base_url must be an https origin without path, query or fragment"
        end

        def name!(value, name)
          unless value.is_a?(String) && !value.empty? && value.length <= 256 &&
              value.match?(%r{\A[A-Za-z0-9._-]+\z})
            raise Ace::Lab::InvalidConfigurationError, "forge merge #{name} is invalid"
          end
          value
        end

        def token!(value)
          unless value.is_a?(String) && value.length.between?(8, 512) &&
              value.match?(%r{\A[A-Za-z0-9._~+/=-]+\z})
            raise Ace::Lab::InvalidConfigurationError, "forge merge token is invalid"
          end
          value
        end

        def timeout!(value)
          unless value.is_a?(Integer) && value.positive? && value <= 86_400
            raise Ace::Lab::InvalidConfigurationError,
              "forge merge merge_timeout_seconds must be a positive integer"
          end
          value
        end
      end
    end
  end
end
