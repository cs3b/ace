# frozen_string_literal: true

require "ace/support/items"
require_relative "hitl/version"
require_relative "hitl/atoms/hitl_file_pattern"
require_relative "hitl/atoms/hitl_id_formatter"
require_relative "hitl/models/hitl_event"
require_relative "hitl/molecules/hitl_config_loader"
require_relative "hitl/molecules/hitl_scanner"
require_relative "hitl/molecules/hitl_resolver"
require_relative "hitl/molecules/hitl_loader"
require_relative "hitl/molecules/hitl_display_formatter"
require_relative "hitl/molecules/hitl_answer_editor"
require_relative "hitl/molecules/hitl_creator"
require_relative "hitl/molecules/resume_dispatcher"
require_relative "hitl/molecules/worktree_scope_resolver"
require_relative "hitl/organisms/hitl_manager"
require_relative "hitl/cli"

module Ace
  module Hitl
    class Error < StandardError; end
  end
end
