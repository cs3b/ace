# frozen_string_literal: true

require_relative "../test_helper"

module Atoms
  class PublicProjectionTest < Minitest::Test
    def index
      @index ||= Ace::Lab::Molecules::TopologyLoader.new(topology_config).load
    end

    def test_project_projection_exposes_only_id_and_label
      projected = Ace::Lab::Atoms::PublicProjection.project(index.lookup("atlas"))

      assert_equal({"id" => "atlas", "label" => "Atlas platform"}, projected)
    end

    def test_project_without_label_omits_the_key
      projected = Ace::Lab::Atoms::PublicProjection.project(index.lookup("borealis"))

      assert_equal({"id" => "borealis"}, projected)
    end

    def test_agent_projection_exposes_stable_identity_and_availability
      projected = Ace::Lab::Atoms::PublicProjection.agent(index.lookup("atlas-planner"))

      assert_equal(
        {
          "id" => "atlas-planner", "project" => "atlas", "role" => "planner",
          "capabilities" => ["planning"],
          "binding" => {"kind" => "runtime", "state" => "available"}
        },
        projected
      )
    end

    def test_agent_with_unattested_identity_projects_stale
      projected = Ace::Lab::Atoms::PublicProjection.agent(index.lookup("atlas-coder"))

      assert_equal "stale", projected["binding"]["state"]
    end

    def test_service_projection_sanitizes_endpoint_to_safe_identity
      projected = Ace::Lab::Atoms::PublicProjection.service(index.lookup("atlas-search"))
      binding = projected["binding"]

      assert_equal "available", binding["state"]
      assert_equal "http", binding["endpoint"]["kind"]
      assert_equal "https://search.example.internal:8443", binding["endpoint"]["url"]
    end

    def test_public_output_never_contains_secrets_or_transient_identifiers
      config = topology_config
      config["topology"]["agents"].first["binding"]["instance_id"] = "pane-42-session-9"
      index = Ace::Lab::Molecules::TopologyLoader.new(config).load

      public_json = JSON.generate([
        Ace::Lab::Atoms::PublicProjection.entry(index.lookup("atlas-planner")),
        Ace::Lab::Atoms::PublicProjection.service(index.lookup("atlas-search"))
      ])

      %w[token secret auth_file fragment inst-search inst-planner pane session
        q? /lab /etc].each do |forbidden|
        refute_includes public_json, forbidden, "public output leaked #{forbidden.inspect}"
      end
    end

    def test_endpoint_with_default_port_omits_the_port
      projected = Ace::Lab::Atoms::PublicProjection.service(index.lookup("atlas-index"))

      assert_equal "https://index.example.internal", projected["binding"]["endpoint"]["url"]
    end

    def test_unparseable_endpoint_projects_no_url
      config = topology_config
      config["topology"]["services"].first["endpoint"]["url"] = "::not a url::"
      index = Ace::Lab::Molecules::TopologyLoader.new(config).load

      projected = Ace::Lab::Atoms::PublicProjection.service(index.lookup("atlas-search"))

      assert_nil projected["binding"]["endpoint"]["url"]
    end

    def test_entry_dispatches_by_kind
      assert_equal "atlas", Ace::Lab::Atoms::PublicProjection.entry(index.lookup("atlas"))["id"]
      assert_equal "atlas-planner", Ace::Lab::Atoms::PublicProjection.entry(index.lookup("atlas-planner"))["id"]
      assert_equal "atlas-search", Ace::Lab::Atoms::PublicProjection.entry(index.lookup("atlas-search"))["id"]
    end
  end
end
