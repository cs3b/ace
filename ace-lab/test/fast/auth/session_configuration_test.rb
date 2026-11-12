# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/lab/auth/session_configuration"

module Ace::Lab::Auth
  class SessionConfigurationTest < Minitest::Test
    def document
      {"coordinator" => {"id" => "lab", "path" => "/lab", "environment_files" => {"lab-overseer" => "/config/lab.json"}},
       "projects" => [{"id" => "ace", "path" => "/lab/ace", "environment_files" => {"worker" => "/config/ace-worker.json"}}],
       "roles" => %w[lab-overseer worker verifier].map { |role| {"id" => role, "account" => "mo", "instructions" => "wfi://coworker/#{role}"} },
       "gemset" => {"gem_home" => "/opt/ace"}, "session_runtime" => {"node" => "/usr/bin/node"}}
    end

    def test_selects_only_the_requested_project_and_role_environment
      config = SessionConfiguration.new(loader: -> { document })
      worker = config.resolve(project: "ace", role: "worker")
      assert_equal "/lab/ace", worker.path
      assert_equal "/config/ace-worker.json", worker.environment_file
      assert_equal "/opt/ace", worker.gem_home
      assert_nil config.resolve(project: "ace", role: "verifier").environment_file
      assert_equal "/config/lab.json", config.resolve(project: "lab", role: "lab-overseer").environment_file
    end

    def test_advisor_and_bootstrap_execution_can_use_coordinator_scope
      data = document
      data["roles"] << {"id" => "second-captain", "instructions" => "wfi://coworker/second-captain"}
      config = SessionConfiguration.new(loader: -> { data })
      assert_equal "/lab", config.resolve(project: "lab", role: "second-captain").path
      assert_equal "/lab/ace", config.resolve(project: "ace", role: "second-captain").path
      assert_nil config.resolve(project: "lab", role: "second-captain").environment_file
      assert_equal "/lab", config.resolve(project: "lab", role: "worker").path
      assert_raises(Error) { config.resolve(project: "lab", role: "project-overseer") }
    end

    def test_refuses_unknown_project_role_and_missing_runtime
      config = SessionConfiguration.new(loader: -> { document })
      assert_raises(Error) { config.resolve(project: "other", role: "worker") }
      assert_raises(Error) { config.resolve(project: "ace", role: "root") }
      assert_raises(Error) { config.resolve(project: "ace", role: "lab-overseer") }
      config = SessionConfiguration.new(loader: -> { document.merge("session_runtime" => nil) })
      assert_raises(Error) { config.resolve(project: "ace", role: "worker") }
    end
  end
end
