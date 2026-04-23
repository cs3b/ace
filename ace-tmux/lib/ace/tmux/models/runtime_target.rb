# frozen_string_literal: true

module Ace
  module Tmux
    module Models
      class RuntimeTarget
        attr_reader :session, :window, :pane, :source

        def initialize(session: nil, window: nil, pane: nil, source:, raw_window_target: nil)
          @session = presence(session)
          @window = presence(window)
          @pane = presence(pane)
          @source = source.to_s
          @raw_window_target = presence(raw_window_target)
        end

        def session_target
          session
        end

        def window_target
          return @raw_window_target if @raw_window_target
          return nil unless session && window

          "#{session}:#{window}"
        end

        def pane_target
          return pane if pane&.start_with?("%")
          return pane if pane&.start_with?("@")
          return pane if pane&.include?(":")
          return nil unless pane && window_target

          "#{window_target}.#{pane}"
        end

        private

        def presence(value)
          normalized = value.to_s.strip
          normalized.empty? ? nil : normalized
        end
      end
    end
  end
end
