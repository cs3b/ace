# frozen_string_literal: true

# Compatibility shim for ace-config → ace-support-config rename
#
# This file provides backward compatibility for code that still uses:
#   require "ace/config"
#   Ace::Config
#
# These are aliased to the new namespace:
#   require "ace/support/config"
#   Ace::Support::Config

# Load the new namespace
require "ace/support/config"

module Ace
  # Backward compatibility alias for the Config namespace
  #
  # @deprecated Use Ace::Support::Config instead
  @config_deprecation_warned ||= false
  unless @config_deprecation_warned
    warn "[DEPRECATION] Ace::Config is deprecated. Use Ace::Support::Config instead." if $VERBOSE
    @config_deprecation_warned = true
  end
  Config = Support::Config
end
