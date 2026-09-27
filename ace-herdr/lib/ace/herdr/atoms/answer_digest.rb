# frozen_string_literal: true

require "digest"

module Ace
  module Herdr
    module Atoms
      # SHA-256 hex digest of delivery content; pure function
      module AnswerDigest
        module_function

        def call(content)
          Digest::SHA256.hexdigest(content.to_s)
        end
      end
    end
  end
end
