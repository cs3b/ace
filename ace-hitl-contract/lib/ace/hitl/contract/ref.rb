# frozen_string_literal: true

require_relative "errors"

module Ace
  module Hitl
    module Providers
      # Typed reverse address of the asking agent: Herdr tokens or the exact
      # paired native tmux IDs. Syntax never supplies native ownership authority.
      # Versioned schema ace.hitl.ref/v1; ace-herdr exports the environment
      # variables when it bootstraps an agent pane.
      #
      # The ref identifies WHERE the answer goes; it never carries answer
      # content.
      class Ref
        SCHEMA = "ace.hitl.ref/v1"
        SESSION_ENV = "HERDR_SESSION"
        PANE_ENV = "HERDR_PANE"
        MAX_LENGTH = 128
        TOKEN_PATTERN = /\A[A-Za-z0-9._:-]+\z/.freeze
        SESSION_ID_PATTERN = /\A\$(?:0|[1-9][0-9]*)\z/.freeze
        PANE_ID_PATTERN = /\A%(?:0|[1-9][0-9]*)\z/.freeze

        attr_reader :session, :pane

        def initialize(session:, pane:, canonical: false, session_source: "session", pane_source: "pane")
          @session = validated_component(session, session_source, SESSION_ID_PATTERN, canonical)
          @pane = validated_component(pane, pane_source, PANE_ID_PATTERN, canonical)
          unless SESSION_ID_PATTERN.match?(@session) == PANE_ID_PATTERN.match?(@pane)
            raise InvalidRefError, "#{session_source}/#{pane_source} require a paired native tmux session and pane"
          end
        end

        # Fail closed: raises InvalidRefError naming the offending variable
        # and rule when the reverse address is absent or invalid.
        def self.from_env(env = ENV)
          new(session: env[SESSION_ENV], pane: env[PANE_ENV],
            session_source: SESSION_ENV, pane_source: PANE_ENV)
        end

        def to_h
          {schema: SCHEMA, session: session, pane: pane}
        end

        private

        def validated_component(value, source, native_pattern, canonical)
          raise InvalidRefError, "#{source} is required (reverse address, #{SCHEMA})" if value.nil?
          unless value.is_a?(String) && value.valid_encoding? && value.encoding.ascii_compatible?
            raise InvalidRefError, "#{source} must be an ASCII-compatible encoded String"
          end
          token = value.strip
          if token.empty?
            raise InvalidRefError,
              "#{source} is required (reverse address, #{SCHEMA})"
          end
          if token.length > MAX_LENGTH
            raise InvalidRefError,
              "#{source} exceeds #{MAX_LENGTH} characters"
          end
          if canonical && token != value
            raise InvalidRefError, "#{source} must be a canonical reverse address component"
          end
          unless token.match?(TOKEN_PATTERN) || token.match?(native_pattern)
            raise InvalidRefError,
              "#{source} contains invalid characters " \
              "(expected a Herdr token or a canonical native ID for this field)"
          end

          token.freeze
        end
      end
    end
  end
end
