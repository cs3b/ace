# frozen_string_literal: true

require_relative "mac_clipboard/version"
require_relative "mac_clipboard/content_type"
require_relative "mac_clipboard/reader"
require_relative "mac_clipboard/content_parser"

module Ace
  module Support
    module MacClipboard
      class Error < StandardError; end
    end
  end
end
