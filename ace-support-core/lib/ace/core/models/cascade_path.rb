# frozen_string_literal: true

# Proxy file for backward compatibility
# CascadePath is now provided by ace-config gem
require 'ace/support/config'

# Ensure Ace::Core::Models::CascadePath is available
require_relative "../../core"
