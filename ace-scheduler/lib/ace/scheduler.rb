# frozen_string_literal: true

require "ace/core"
require_relative "scheduler/version"
require_relative "scheduler/cli"

module Ace
  module Scheduler
    class Error < StandardError; end

    module Atoms; end
    module Molecules; end
    module Organisms; end
    module Models; end
    module Commands; end
  end
end
