# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/lab/auth/session_configuration"

module Ace::Lab::Auth
  class SessionConfigurationTest < Minitest::Test
    def setup
      @document = {"projects" => [{"id" => "ace", "path" => "/lab/ace"}],
        "roles" => [{"id" => "worker", "account" => "mo", "instructions" => "wfi://task/work"}],
        "grants" => {"mo" => ["ace"]}, "gemset" => {"gem_home" => "/opt/ace/runtime/gems"}}
      @configuration = SessionConfiguration.new(loader: -> { @document })
    end

    def test_resolves_from_existing_host_manifest
      selected = @configuration.resolve(project: "ace", role: "worker", principal: "mo")
      assert_equal "/lab/ace", selected.path
      assert_equal "wfi://task/work", selected.instructions
      assert_equal "/opt/ace/runtime/gems", selected.gem_home
    end

    def test_refuses_cross_principal_unknown_role_and_unknown_project
      [{principal: "other"}, {role: "integrator"}, {project: "other"}].each do |override|
        arguments = {project: "ace", role: "worker", principal: "mo"}.merge(override)
        assert_raises(Error) { @configuration.resolve(**arguments) }
      end
    end

    def test_missing_runtime_never_falls_back_to_checkout
      @document["gemset"] = nil
      assert_raises(Error) { @configuration.resolve(project: "ace", role: "worker", principal: "mo") }
    end
  end
end
