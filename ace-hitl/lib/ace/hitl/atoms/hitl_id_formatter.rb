# frozen_string_literal: true

require "ace/b36ts"

module Ace
  module Hitl
    module Atoms
      class HitlIdFormatter
        def self.generate(time = Time.now.utc)
          Ace::B36ts.encode(time, format: :"2sec")
        end
      end
    end
  end
end
