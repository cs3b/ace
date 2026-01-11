# frozen_string_literal: true

# Proxy file for backward compatibility
# YamlLoader is now provided by ace-config gem
require 'ace/support/config'

# Ensure Ace::Core::Molecules::YamlLoader is available
require_relative "../../core"
