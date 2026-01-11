# frozen_string_literal: true

# Proxy file for backward compatibility
# ConfigResolver is now provided by ace-config gem
require 'ace/support/config'

# Ensure Ace::Core::Organisms::ConfigResolver is available
require_relative "../../core"
