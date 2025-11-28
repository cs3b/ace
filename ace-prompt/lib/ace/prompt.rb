# frozen_string_literal: true

require_relative "prompt/version"
require_relative "prompt/atoms/timestamp_generator"
require_relative "prompt/atoms/content_hasher"
require_relative "prompt/molecules/prompt_reader"
require_relative "prompt/molecules/prompt_archiver"
require_relative "prompt/organisms/prompt_processor"
require_relative "prompt/cli"

module Ace
  module Prompt
    class Error < StandardError; end
  end
end
