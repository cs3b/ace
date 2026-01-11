# frozen_string_literal: true

# Proxy file for backward compatibility
# ConfigFinder is now provided by ace-config gem
require 'ace/support/config'

# Ensure Ace::Core::Molecules::ConfigFinder is available
require_relative "../../core"
