# frozen_string_literal: true

module Ace
  module Lab
    module Models
      # Immutable value object carrying the assembled status report.
      # ok? is false exactly when a configuration source is invalid or a
      # state location failed to read — an empty-but-valid lab is ok.
      class StatusReport
        attr_reader :config, :runtime_config, :state, :root

        def initialize(config:, runtime_config:, state:, root:)
          @config = config.freeze
          @runtime_config = runtime_config.freeze
          @state = state.map(&:freeze).freeze
          @root = root
          freeze
        end

        def ok?
          @config[:state] != :invalid &&
            @runtime_config[:state] != :invalid &&
            @state.none? { |location| location[:state] == :error }
        end

        def to_h
          {
            config: @config,
            runtime_config: @runtime_config,
            state: @state,
            root: @root,
            ok: ok?
          }
        end
      end
    end
  end
end
