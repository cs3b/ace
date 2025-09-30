# frozen_string_literal: true

require_relative "nav/version"

module Ace
  module Nav
    class Error < StandardError; end

    # Define module namespaces
    module Atoms; end
    module Molecules; end
    module Organisms; end
    module Models; end
  end
end