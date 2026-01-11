# frozen_string_literal: true

# Proxy file for backward compatibility
# DeepMerger is now provided by ace-config gem
require 'ace/support/config'

# Ensure Ace::Core::Atoms::DeepMerger is available
require_relative "../../core"
