# frozen_string_literal: true

require_relative "../test_helper"

module Organisms
  class TopologyServiceTest < Minitest::Test
    def config_for_local_identity(projects: %w[atlas borealis])
      config = topology_config
      config["authorization"]["principals"] = {
        Ace::Lab::Molecules::CallerAuthorizer.local_identity.first => {"projects" => projects}
      }
      config
    end

    def test_from_config_authorizes_the_verified_local_identity
      result = Ace::Lab::Organisms::TopologyService.from_config(config_for_local_identity).projects

      assert_predicate result, :ok?
      assert_equal %w[atlas borealis], result.data["projects"].map { |p| p["id"] }
    end

    def test_resolve_routes_through_authorized_exact_resolution
      result = Ace::Lab::Organisms::TopologyService.from_config(
        config_for_local_identity(projects: ["atlas"])
      ).resolve(id: "atlas-planner")

      assert_predicate result, :ok?
      assert_equal "atlas-planner", result.data["entry"]["id"]
    end

    def test_local_identity_outside_principals_is_unauthorized
      result = Ace::Lab::Organisms::TopologyService.from_config(topology_config).projects

      refute_predicate result, :ok?
      assert_equal "unauthorized", result.error_code
    end

    def test_routes_capability_through_authorized_default
      service = Ace::Lab::Organisms::TopologyService.from_config(
        config_for_local_identity(projects: ["atlas"])
      )

      result = service.route(project: "atlas", capability: "search")

      assert_predicate result, :ok?
      assert_equal "atlas-search", result.data["entry"]["id"]
    end

    def test_invalid_configuration_is_a_classified_result
      broken = topology_config
      broken["topology"]["agents"].first["project"] = "ghost"

      result = Ace::Lab::Organisms::TopologyService.from_config(broken).projects

      refute_predicate result, :ok?
      assert_equal "invalid_configuration", result.error_code
      assert_match(/unknown project/, result.message)
    end

    def test_invalid_configuration_classifies_every_command
      broken = topology_config
      broken["topology"]["services"].first["capabilities"] = []

      service = Ace::Lab::Organisms::TopologyService.from_config(broken)
      refute_predicate service.resolve(id: "atlas-planner"), :ok?
      refute_predicate service.agents(project: "atlas"), :ok?
    end

    def test_principal_with_empty_policy_denies_without_crashing
      config = topology_config
      config["authorization"]["principals"] = {
        Ace::Lab::Molecules::CallerAuthorizer.local_identity.first => {}
      }

      result = Ace::Lab::Organisms::TopologyService.from_config(config).projects

      refute_predicate result, :ok?
      assert_equal "unauthorized", result.error_code
    end

    def test_padded_principal_names_normalize_before_authorization
      config = topology_config
      identity = Ace::Lab::Molecules::CallerAuthorizer.local_identity.first
      config["authorization"]["principals"] = {
        " #{identity} " => {"projects" => ["atlas"]}
      }

      result = Ace::Lab::Organisms::TopologyService.from_config(config).projects

      assert_predicate result, :ok?
      assert_equal %w[atlas], result.data["projects"].map { |p| p["id"] }
    end

    def test_malformed_deployed_yaml_classifies_not_falls_back
      Dir.mktmpdir do |dir|
        config_dir = File.join(dir, ".ace", "lab")
        FileUtils.mkdir_p(config_dir)
        File.write(File.join(config_dir, "config.yml"), "schema_version: [")

        Ace::Lab.reset_config!
        begin
          Dir.chdir(dir) do
            result = Ace::Lab::Organisms::TopologyService.from_config.projects

            # Broken deployed config must report invalid_configuration, never
            # degrade to an empty-topology authorization denial (review R4)
            refute_predicate result, :ok?
            assert_equal "invalid_configuration", result.error_code
          end
        ensure
          Ace::Lab.reset_config!
        end
      end
    end

    def test_non_mapping_project_document_is_rejected_not_ignored
      Dir.mktmpdir do |dir|
        config_dir = File.join(dir, ".ace", "lab")
        FileUtils.mkdir_p(config_dir)
        File.write(File.join(config_dir, "config.yml"), "- broken")

        Ace::Lab.reset_config!
        begin
          Dir.chdir(dir) do
            result = Ace::Lab::Organisms::TopologyService.from_config.projects

            # A non-mapping document must fail configuration loading, never
            # merge as a silent empty overlay (review round 3, F1)
            refute_predicate result, :ok?
            assert_equal "invalid_configuration", result.error_code
            assert_match(/must contain a YAML mapping/, result.message)
          end
        ensure
          Ace::Lab.reset_config!
        end
      end
    end

    def test_load_error_messages_never_expose_configuration_content
      Dir.mktmpdir do |dir|
        config_dir = File.join(dir, ".ace", "lab")
        FileUtils.mkdir_p(config_dir)
        File.write(File.join(config_dir, "config.yml"), "secret: *private_token_canary")

        Ace::Lab.reset_config!
        begin
          Dir.chdir(dir) do
            result = Ace::Lab::Organisms::TopologyService.from_config.projects

            refute_predicate result, :ok?
            assert_equal "invalid_configuration", result.error_code
            # Parser text may quote anchors/values; the public message must not
            refute_includes result.message, "private_token_canary"
          end
        ensure
          Ace::Lab.reset_config!
        end
      end
    end

    def with_authorization_file(path)
      previous = ENV[Ace::Lab::AUTHORIZATION_ENV]
      ENV[Ace::Lab::AUTHORIZATION_ENV] = path
      yield
    ensure
      ENV[Ace::Lab::AUTHORIZATION_ENV] = previous
    end

    def write_lab_config(root, content)
      config_dir = File.join(root, ".ace", "lab")
      FileUtils.mkdir_p(config_dir)
      File.write(File.join(config_dir, "config.yml"), YAML.dump(content))
    end

    def deployment_config(with_authorization: true)
      config = topology_config
      config.delete("authorization") unless with_authorization
      config
    end

    def test_cascade_authorization_sections_are_rejected
      Dir.mktmpdir do |project|
        write_lab_config(project, deployment_config) # includes authorization

        Ace::Lab.reset_config!
        begin
          Dir.chdir(project) do
            result = Ace::Lab::Organisms::TopologyService.from_config.projects

            # A caller-writable cascade tier must never define grants; the
            # error points operators at the trusted channel (review F3)
            refute_predicate result, :ok?
            assert_equal "invalid_configuration", result.error_code
            assert_match(/grants come from the trusted file/, result.message)
            assert_match(/remove the authorization section/, result.message)
          end
        ensure
          Ace::Lab.reset_config!
        end
      end
    end

    def test_grants_come_from_the_trusted_authorization_file
      Dir.mktmpdir do |project|
        Dir.mktmpdir do |trusted_dir|
          write_lab_config(project, deployment_config(with_authorization: false))
          trusted_path = File.join(trusted_dir, "authorization.yml")
          File.write(trusted_path, YAML.dump({
            "principals" => {
              Ace::Lab::Molecules::CallerAuthorizer.local_identity.first => {"projects" => %w[atlas borealis]}
            }
          }))

          Ace::Lab.reset_config!
          begin
            with_authorization_file(trusted_path) do
              Dir.chdir(project) do
                result = Ace::Lab::Organisms::TopologyService.from_config.projects

                assert_predicate result, :ok?
                assert_equal %w[atlas borealis], result.data["projects"].map { |p| p["id"] }
              end
            end
          ensure
            Ace::Lab.reset_config!
          end
        end
      end
    end

    def test_without_a_trusted_file_nobody_is_authorized
      Dir.mktmpdir do |project|
        write_lab_config(project, deployment_config(with_authorization: false))

        Ace::Lab.reset_config!
        begin
          with_authorization_file("/nonexistent/lab/authorization.yml") do
            Dir.chdir(project) do
              result = Ace::Lab::Organisms::TopologyService.from_config.projects

              refute_predicate result, :ok?
              assert_equal "unauthorized", result.error_code
            end
          end
        ensure
          Ace::Lab.reset_config!
        end
      end
    end
  end
end
