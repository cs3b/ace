# frozen_string_literal: true

module Ace
  module Demo
    module Models
      class RecordingResult
        attr_reader :backend, :visual_path, :cast_path, :verification, :tape_path, :sandbox_path

        def initialize(backend:, visual_path:, cast_path: nil, verification: nil, tape_path: nil, sandbox_path: nil)
          @backend = backend
          @visual_path = visual_path
          @cast_path = cast_path
          @verification = verification
          @tape_path = tape_path
          @sandbox_path = sandbox_path
        end
      end
    end
  end
end
