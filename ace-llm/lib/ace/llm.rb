# frozen_string_literal: true

# Try to load ace-core if available
begin
  require "ace/core"
rescue LoadError
  # ace-core is optional for basic functionality
end

require_relative "llm/version"

# Configuration
require_relative "llm/configuration"

# Require all necessary components explicitly (no autoloading for now)
require_relative "llm/atoms/env_reader"
require_relative "llm/atoms/http_client"
require_relative "llm/atoms/xdg_directory_resolver"
require_relative "llm/atoms/error_classifier"

require_relative "llm/models/fallback_config"

require_relative "llm/molecules/file_io_handler"
require_relative "llm/molecules/llm_alias_resolver"
require_relative "llm/molecules/provider_model_parser"
require_relative "llm/molecules/format_handlers"
require_relative "llm/molecules/client_registry"
require_relative "llm/molecules/fallback_orchestrator"

require_relative "llm/query_interface"

require_relative "llm/organisms/base_client"
require_relative "llm/organisms/google_client"
require_relative "llm/organisms/groq_client"
require_relative "llm/organisms/openai_client"
require_relative "llm/organisms/anthropic_client"
require_relative "llm/organisms/mistral_client"
require_relative "llm/organisms/togetherai_client"
require_relative "llm/organisms/lmstudio_client"
require_relative "llm/organisms/xai_client"
require_relative "llm/organisms/zai_client"
require_relative "llm/organisms/openrouter_client"

# CLI and commands
require_relative "llm/cli"

module Ace
  module LLM
    class Error < StandardError; end
    class ProviderError < Error; end
    class ConfigurationError < Error; end
    class AuthenticationError < Error; end

    # Define module namespaces
    module Atoms; end
    module Molecules; end
    module Organisms; end
    module Models; end
    module Commands; end
  end
end
