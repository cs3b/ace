# frozen_string_literal: true

# Proxy file for backward compatibility
# YamlParser is now provided by ace-config gem
require 'ace/support/config'

# Ensure Ace::Core::Atoms::YamlParser is available
require_relative "../../core"
