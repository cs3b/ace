#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require_relative 'ace-test-runner/lib/ace/test_runner'
require_relative 'ace-test-runner/lib/ace/test_runner/suite/display_manager'
require_relative 'ace-test-runner/lib/ace/test_runner/suite/process_monitor'
require_relative 'ace-test-runner/lib/ace/test_runner/suite/result_aggregator'
require_relative 'ace-test-runner/lib/ace/test_runner/suite/orchestrator'

# Run tests for all packages
orchestrator = Ace::TestRunner::Suite::Orchestrator.new
result = orchestrator.run
# Result is true/false, not a hash
exit(result ? 0 : 1)