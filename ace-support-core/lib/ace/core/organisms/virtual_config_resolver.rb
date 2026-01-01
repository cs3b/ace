# frozen_string_literal: true

# Proxy file for backward compatibility
# VirtualConfigResolver is now provided by ace-config gem
require "ace/config"

# Ensure Ace::Core::Organisms::VirtualConfigResolver is available
require_relative "../../core"
