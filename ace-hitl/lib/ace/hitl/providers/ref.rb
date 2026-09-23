# frozen_string_literal: true

require_relative "errors"

module Ace
  module Hitl
    module Providers
      # Typed reverse address of the asking agent: herdr session + pane
      # (spec 8wm.t.vrz §3). Versioned schema ace.hitl.ref/v1; captured
      # fail-closed from the herdr environment at ask time. ace-herdr
      # exports both variables when it bootstraps an agent pane.
      #
      # The ref identifies WHERE the answer goes; it never carries answer
      # content.
      class Ref
        SCHEMA = "ace.hitl.ref/v1"
        SESSION_ENV = "HERDR_SESSION"
        PANE_ENV = "HERDR_PANE"
        MAX_LENGTH = 128
        TOKEN_PATTERN = /\A[A-Za-z0-9._:-]+\z/.freeze

        attr_reader :session, :pane

        def initialize(session:, pane:)
          @session = session
          @pane = pane
        end

        # Fail closed: raises InvalidRefError naming the offending variable
        # and rule when the reverse address is absent or invalid.
        def self.from_env(env = ENV)
          session = validate!(env[SESSION_ENV], SESSION_ENV)
          pane = validate!(env[PANE_ENV], PANE_ENV)
          new(session: session, pane: pane)
        end

        def self.validate!(value, source)
          token = value.to_s.strip
          if token.empty?
            raise InvalidRefError,
              "#{source} is required (herdr reverse address, #{SCHEMA})"
          end
          if token.length > MAX_LENGTH
            raise InvalidRefError,
              "#{source} exceeds #{MAX_LENGTH} characters"
          end
          unless token.match?(TOKEN_PATTERN)
            raise InvalidRefError,
              "#{source} contains invalid characters " \
              "(allowed: letters, digits, '.', '_', ':', '-')"
          end

          token
        end

        def to_h
          {schema: SCHEMA, session: session, pane: pane}
        end
      end
    end
  end
end
