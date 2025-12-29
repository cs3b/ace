# frozen_string_literal: true

module Ace
  module Support
    module Fs
      # Base error class for all ace-support-fs errors
      class Error < StandardError; end

      # Raised when a path cannot be resolved
      class PathError < Error; end
    end
  end
end
