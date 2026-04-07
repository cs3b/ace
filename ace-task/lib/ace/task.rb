# frozen_string_literal: true

require_relative "task/version"

# Dependencies
require "ace/support/items"
require "ace/b36ts"
require "ace/git"

# Atoms
require_relative "task/atoms/task_id_formatter"
require_relative "task/atoms/task_file_pattern"
require_relative "task/atoms/task_frontmatter_defaults"

# Models
require_relative "task/models/task"

# Molecules
require_relative "task/molecules/task_config_loader"
require_relative "task/molecules/task_scanner"
require_relative "task/molecules/task_resolver"
require_relative "task/molecules/task_loader"
require_relative "task/molecules/task_creator"
require_relative "task/molecules/subtask_creator"
require_relative "task/molecules/task_display_formatter"
require_relative "task/molecules/path_utils"
require_relative "task/molecules/github_issue_sync_adapter"
require_relative "task/molecules/task_plan_cache"
require_relative "task/molecules/task_plan_generator"

# Organisms
require_relative "task/organisms/task_manager"

module Ace
  # Task provides B36TS-based task management with type-marked IDs.
  # Tasks use the format xxx.t.yyy where xxx and yyy are 3-char b36ts components.
  module Task
  end
end
