# frozen_string_literal: true

require "ace/core"
require_relative "scheduler/version"

# Models
require_relative "scheduler/models/scheduled_task"
require_relative "scheduler/models/event_trigger"
require_relative "scheduler/models/execution_result"

# Atoms
require_relative "scheduler/atoms/cron_parser"
require_relative "scheduler/atoms/next_run_calculator"
require_relative "scheduler/atoms/crontab_builder"

# Molecules
require_relative "scheduler/molecules/config_loader"
require_relative "scheduler/molecules/task_executor"
require_relative "scheduler/molecules/state_manager"
require_relative "scheduler/molecules/cron_installer"

# CLI and commands
require_relative "scheduler/cli"

module Ace
  module Scheduler
    class Error < StandardError; end

    module Atoms; end
    module Molecules; end
    module Organisms; end
    module Models; end
    module Commands; end
  end
end
