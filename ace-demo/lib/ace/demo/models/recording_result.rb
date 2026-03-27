# frozen_string_literal: true

module Ace
  module Demo
    module Models
      class RecordingResult
        attr_reader :backend, :visual_path, :cast_path, :verification

        def initialize(backend:, visual_path:, cast_path: nil, verification: nil)
          @backend = backend
          @visual_path = visual_path
          @cast_path = cast_path
          @verification = verification
        end
      end
    end
  end
end
