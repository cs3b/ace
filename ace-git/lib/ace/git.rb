# frozen_string_literal: true

require_relative 'git/version'

module Ace
  module Git
    # Workflow-only gem providing git operation workflows
    # Access workflows via ace-nav protocol:
    # - wfi://rebase - Changelog-preserving rebase
    # - wfi://create-pr - Pull request creation
    # - wfi://squash-pr - Version-based commit squashing
  end
end
