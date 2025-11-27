# frozen_string_literal: true

require_relative "prompt/version"

# Define base module and error class first
module Ace
  module Prompt
    class Error < StandardError; end
  end
end

# Load all components
require_relative "prompt/atoms/content_hasher"
require_relative "prompt/atoms/frontmatter_extractor"
require_relative "prompt/atoms/model_alias_resolver"
require_relative "prompt/atoms/task_path_resolver"
require_relative "prompt/atoms/timestamp_generator"

require_relative "prompt/molecules/config_loader"
require_relative "prompt/molecules/context_loader"
require_relative "prompt/molecules/enhancement_tracker"
require_relative "prompt/molecules/prompt_archiver"
require_relative "prompt/molecules/prompt_reader"
require_relative "prompt/molecules/template_manager"
require_relative "prompt/molecules/template_resolver"

require_relative "prompt/organisms/enhancement_session_manager"
require_relative "prompt/organisms/prompt_enhancer"
require_relative "prompt/organisms/prompt_initializer"
require_relative "prompt/organisms/prompt_processor"

# ace/llm is not a dependency, remove this require

# Simple queue-based prompt workflow for AI development
