# frozen_string_literal: true

require_relative "../test_helper"

module Atoms
  class InstallSchemaTest < Minitest::Test
    def normalize(document, platform: "linux")
      Ace::Lab::Atoms::InstallSchema.normalize(document, platform: platform)
    end

    def manifest(overrides = {})
      {
        "schema_version" => 1,
        "machine" => "lab01",
        "accounts" => [{"username" => "ace-worker", "role" => "worker"}],
        "directories" => [{"path" => "/home/ace-worker/labs", "owner" => "ace-worker", "mode" => "0750"}],
        "keys" => [{"account" => "ace-worker"}],
        "roles" => [{"id" => "worker", "account" => "ace-worker", "instructions" => "wfi://assign/work"}]
      }.merge(overrides)
    end

    def test_full_manifest_normalizes_with_defaults
      result = normalize(manifest)

      assert_equal 1, result["schema_version"]
      assert_equal "lab01", result["machine"]
      account = result["accounts"].first
      assert_equal "ace-worker", account["username"]
      assert_equal "worker", account["role"]
      assert_equal false, account["create"]
      assert_equal "/home/ace-worker", account["home"]
      directory = result["directories"].first
      assert_equal "0750", directory["mode"]
      key = result["keys"].first
      assert_equal "ed25519", key["type"]
      assert_equal "/home/ace-worker/.ssh/id_ed25519", key["path"]
      assert_equal "wfi://assign/work", result["roles"].first["instructions"]
    end

    def test_darwin_platform_defaults_home_under_users
      result = normalize(manifest, platform: "darwin")

      assert_equal "/Users/ace-worker", result["accounts"].first["home"]
      assert_equal "/Users/ace-worker/.ssh/id_ed25519", result["keys"].first["path"]
    end

    def test_optional_sections_default_to_empty_lists
      result = normalize({"schema_version" => 1, "machine" => "lab01"})

      assert_empty result["accounts"]
      assert_empty result["directories"]
      assert_empty result["keys"]
      assert_empty result["roles"]
    end

    def test_non_mapping_document_is_rejected
      error = assert_raises(Ace::Lab::InvalidConfigurationError) do
        normalize("- one")
      end

      assert_match(/manifest must be a mapping/, error.message)
    end

    def test_wrong_schema_version_is_rejected
      error = assert_raises(Ace::Lab::InvalidConfigurationError) do
        normalize(manifest("schema_version" => 2))
      end

      assert_match(/schema_version must be 1/, error.message)
    end

    def test_blank_or_whitespace_machine_is_rejected
      ["", "  ", "lab 01"].each do |machine|
        error = assert_raises(Ace::Lab::InvalidConfigurationError) do
          normalize(manifest("machine" => machine))
        end

        assert_match(/machine must be a non-empty string without whitespace/, error.message)
      end
    end

    def test_duplicate_username_is_rejected
      document = manifest("accounts" => [
        {"username" => "ace-worker", "role" => "worker"},
        {"username" => "ace-worker", "role" => "reviewer"}
      ])

      error = assert_raises(Ace::Lab::InvalidConfigurationError) { normalize(document) }

      assert_match(/accounts entry username is declared more than once/, error.message)
    end

    def test_unknown_top_level_key_is_rejected
      document = manifest("acounts" => [])

      error = assert_raises(Ace::Lab::InvalidConfigurationError) { normalize(document) }

      assert_match(/unknown top-level key 'acounts'/, error.message)
    end

    def test_unknown_entry_key_is_rejected
      document = manifest("accounts" => [
        {"username" => "ace-worker", "role" => "worker", "creat" => true}
      ])

      error = assert_raises(Ace::Lab::InvalidConfigurationError) { normalize(document) }

      assert_match(/accounts entry #0 has unknown key 'creat'/, error.message)
    end

    def test_invalid_username_format_is_rejected
      ["1worker", "-worker", "Ace-Worker", "w" * 40].each do |username|
        error = assert_raises(Ace::Lab::InvalidConfigurationError) do
          normalize(manifest("accounts" => [{"username" => username, "role" => "worker"}]))
        end

        assert_match(/accounts entry username format is invalid/, error.message)
      end
    end

    def test_missing_required_fields_are_rejected_per_section
      [["accounts", {"role" => "worker"}, "username is required"],
       ["accounts", {"username" => "ace-worker"}, "role is required"],
       ["directories", {"owner" => "ace-worker"}, "path is required"],
       ["keys", {"type" => "ed25519"}, "account is required"],
       ["roles", {"account" => "ace-worker"}, "id is required"]].each do |section_name, entry, reason|
        error = assert_raises(Ace::Lab::InvalidConfigurationError) do
          normalize(manifest(section_name => [entry]))
        end

        assert_match(/#{section_name} entry #{reason}/, error.message)
      end
    end

    def test_non_mapping_entry_is_rejected
      error = assert_raises(Ace::Lab::InvalidConfigurationError) do
        normalize(manifest("accounts" => ["ace-worker"]))
      end

      assert_match(/accounts entry #0 must be a mapping/, error.message)
    end

    def test_non_list_section_is_rejected
      error = assert_raises(Ace::Lab::InvalidConfigurationError) do
        normalize(manifest("roles" => {"id" => "worker"}))
      end

      assert_match(/roles must be a list/, error.message)
    end

    def test_unknown_account_reference_is_rejected
      [["directories", {"path" => "/srv", "owner" => "ghost"}],
       ["keys", {"account" => "ghost"}],
       ["roles", {"id" => "worker", "account" => "ghost", "instructions" => "wfi://x"}]].each do |section_name, entry|
        error = assert_raises(Ace::Lab::InvalidConfigurationError) do
          normalize(manifest(section_name => [entry]))
        end

        assert_match(/#{section_name} entry .* must reference a declared account/, error.message)
      end
    end

    def test_non_octal_mode_is_rejected
      ["0999", "8", "75", "abc", 0o750].each do |mode|
        error = assert_raises(Ace::Lab::InvalidConfigurationError) do
          normalize(manifest("directories" => [{"path" => "/srv", "mode" => mode}]))
        end

        assert_match(/directories entry mode must be an octal string/, error.message)
      end
    end

    def test_relative_paths_are_rejected
      [["directories", {"path" => "relative/labs"}],
       ["accounts", {"username" => "ace-worker", "role" => "worker", "home" => "home/ace-worker"}],
       ["keys", {"account" => "ace-worker", "path" => "relative/.ssh/id_ed25519"}]].each do |section_name, entry|
        error = assert_raises(Ace::Lab::InvalidConfigurationError) do
          normalize(manifest(section_name => [entry]))
        end

        assert_match(/#{section_name} entry .* must be an absolute path/, error.message)
      end
    end

    def test_duplicate_key_path_is_rejected
      document = manifest(
        "accounts" => [{"username" => "ace-a", "role" => "a"}, {"username" => "ace-b", "role" => "b"}],
        "directories" => [],
        "keys" => [
          {"account" => "ace-a", "path" => "/shared/.ssh/id_ed25519"},
          {"account" => "ace-b", "path" => "/shared/.ssh/id_ed25519"}
        ]
      )

      error = assert_raises(Ace::Lab::InvalidConfigurationError) { normalize(document) }

      assert_match(/keys entry path is declared more than once/, error.message)
    end

    def test_defaulted_key_path_colliding_with_declared_path_is_rejected
      document = manifest(
        "accounts" => [{"username" => "ace-a", "role" => "a"}, {"username" => "ace-b", "role" => "b"}],
        "directories" => [],
        "keys" => [
          {"account" => "ace-a"},
          {"account" => "ace-b", "path" => "/home/ace-a/.ssh/id_ed25519"}
        ]
      )

      error = assert_raises(Ace::Lab::InvalidConfigurationError) { normalize(document) }

      assert_match(/keys entry path is declared more than once/, error.message)
    end

    def test_duplicate_role_id_is_rejected
      document = manifest(
        "accounts" => [{"username" => "ace-a", "role" => "a"}, {"username" => "ace-b", "role" => "b"}],
        "directories" => [],
        "keys" => [],
        "roles" => [
          {"id" => "worker", "account" => "ace-a", "instructions" => "wfi://a"},
          {"id" => "worker", "account" => "ace-b", "instructions" => "wfi://b"}
        ]
      )

      error = assert_raises(Ace::Lab::InvalidConfigurationError) { normalize(document) }

      assert_match(/roles entry id is declared more than once/, error.message)
    end

    def test_invalid_role_id_is_rejected
      ["1worker", "Worker", "w" * 40].each do |id|
        error = assert_raises(Ace::Lab::InvalidConfigurationError) do
          normalize(manifest("roles" => [{"id" => id, "account" => "ace-worker", "instructions" => "wfi://x"}]))
        end

        assert_match(/roles entry id format is invalid/, error.message)
      end
    end

    def test_invalid_instructions_are_rejected
      ["relative/path", "http://example.com", "wfi:/missing-slash"].each do |instructions|
        error = assert_raises(Ace::Lab::InvalidConfigurationError) do
          normalize(manifest("roles" => [{"id" => "worker", "account" => "ace-worker", "instructions" => instructions}]))
        end

        assert_match(/roles entry instructions must use a wfi:\/\/, prompt:\/\/ or tmpl:\/\/ prefix/, error.message)
      end
    end

    def test_supported_instruction_protocols_and_absolute_paths_are_accepted
      %w[wfi://assign/work prompt://plan tmpl://base].each do |instructions|
        result = normalize(manifest("roles" => [
          {"id" => "worker", "account" => "ace-worker", "instructions" => instructions}
        ]))

        assert_equal instructions, result["roles"].first["instructions"]
      end

      result = normalize(manifest("roles" => [
        {"id" => "worker", "account" => "ace-worker", "instructions" => "/etc/lab/roles/worker.md"}
      ]))

      assert_equal "/etc/lab/roles/worker.md", result["roles"].first["instructions"]
    end

    def test_unsupported_key_type_is_rejected
      error = assert_raises(Ace::Lab::InvalidConfigurationError) do
        normalize(manifest("keys" => [{"account" => "ace-worker", "type" => "rsa"}]))
      end

      assert_match(/keys entry type must be one of: ed25519/, error.message)
    end

    def test_non_boolean_create_is_rejected
      error = assert_raises(Ace::Lab::InvalidConfigurationError) do
        normalize(manifest("accounts" => [{"username" => "ace-worker", "role" => "worker", "create" => "yes"}]))
      end

      assert_match(/accounts entry create must be a boolean/, error.message)
    end

    def test_mode_normalizes_to_four_digits
      result = normalize(manifest("directories" => [{"path" => "/srv", "mode" => "750"}]))

      assert_equal "0750", result["directories"].first["mode"]
    end

    def test_projects_section_normalizes
      result = normalize(manifest("projects" => [
        {"id" => "atlas", "path" => "/Users/ace/lab/atlas",
         "remote" => "git@forge:atlas/atlas.git", "label" => "Atlas platform"},
        {"id" => "borealis", "path" => "/Users/ace/lab/borealis"}
      ]))

      atlas = result["projects"].first
      assert_equal "atlas", atlas["id"]
      assert_equal "/Users/ace/lab/atlas", atlas["path"]
      assert_equal "git@forge:atlas/atlas.git", atlas["remote"]
      assert_equal "Atlas platform", atlas["label"]
      borealis = result["projects"][1]
      assert_nil borealis["remote"]
      assert_nil borealis["label"]
    end

    def test_projects_and_grants_default_to_empty
      result = normalize(manifest)

      assert_empty result["projects"]
      assert_empty result["grants"]
    end

    def test_project_entry_validation
      [
        [{"id" => "Atlas", "path" => "/lab/atlas"}, /projects entry id format is invalid/],
        [{"id" => "atlas", "path" => "relative"}, /projects entry path must be an absolute path/],
        [{"id" => "atlas", "path" => "/lab/atlas", "remote" => ""}, /remote must be a non-empty string/],
        [{"id" => "atlas", "path" => "/lab/atlas", "label" => "  "}, /label must be a non-empty string/],
        [{"path" => "/lab/atlas"}, /projects entry id is required/],
        [{"id" => "atlas"}, /projects entry path is required/],
        [{"id" => "atlas", "path" => "/lab/atlas", "extra" => 1}, /projects entry #\d+ has unknown key/]
      ].each do |entry, pattern|
        error = assert_raises(Ace::Lab::InvalidConfigurationError) do
          normalize(manifest("projects" => [entry]))
        end

        assert_match(pattern, error.message)
      end
    end

    def test_duplicate_project_ids_and_paths_are_rejected
      error = assert_raises(Ace::Lab::InvalidConfigurationError) do
        normalize(manifest("projects" => [
          {"id" => "atlas", "path" => "/lab/atlas"},
          {"id" => "atlas", "path" => "/lab/other"}
        ]))
      end
      assert_match(/projects entry id is declared more than once/, error.message)

      error = assert_raises(Ace::Lab::InvalidConfigurationError) do
        normalize(manifest("projects" => [
          {"id" => "atlas", "path" => "/lab/atlas"},
          {"id" => "other", "path" => "/lab/atlas"}
        ]))
      end
      assert_match(/projects entry path is declared more than once/, error.message)
    end

    def test_grants_normalize_and_validate_references
      result = normalize(manifest(
        "projects" => [{"id" => "atlas", "path" => "/lab/atlas"}],
        "grants" => {"ace-overseer" => ["atlas"], " operator " => ["atlas"]}
      ))

      assert_equal({"ace-overseer" => %w[atlas], "operator" => %w[atlas]}, result["grants"])

      error = assert_raises(Ace::Lab::InvalidConfigurationError) do
        normalize(manifest("grants" => {"ace-overseer" => ["atlas"]}))
      end
      assert_match(/reference project 'atlas' which the manifest does not declare/, error.message)
    end

    def test_grants_shape_validation
      [
        [{"ace-overseer" => "atlas"}, /must be a non-empty list of project ids/],
        [{"ace-overseer" => []}, /must be a non-empty list of project ids/],
        [{"ace-overseer" => ["atlas", "atlas"]},
         /list a project more than once/],
        [{"" => ["atlas"]}, /principal name must be a non-empty string/],
        [["atlas"], /grants must be a mapping of principal to project ids/],
        # duplicates after strip are rejected like duplicate project ids
        [{"ace-overseer" => ["atlas"], " ace-overseer " => ["atlas"]},
         /grants principal name is declared more than once/]
      ].each do |grants, pattern|
        error = assert_raises(Ace::Lab::InvalidConfigurationError) do
          normalize(manifest(
            "projects" => [{"id" => "atlas", "path" => "/lab/atlas"}],
            "grants" => grants
          ))
        end

        assert_match(pattern, error.message)
      end
    end

    # --- adapters and tools (task 8xg.t.sbz.7.2/.7.4, LAB-3) ----------

    def test_adapters_normalize_with_defaults
      result = normalize(manifest("adapters" => [
        {"id" => "hermes", "kind" => "communication", "command" => "ace-hitl-hermes"},
        {"id" => "console", "kind" => "hitl", "config" => {"prompt" => "tty"}}
      ]))

      hermes = result["adapters"].first
      assert_equal "hermes", hermes["id"]
      assert_equal "communication", hermes["kind"]
      assert_equal "ace-hitl-hermes", hermes["command"]
      assert_empty hermes["config"]
      console = result["adapters"][1]
      assert_nil console["command"]
      assert_equal({"prompt" => "tty"}, console["config"])
    end

    def test_adapter_validation
      [
        [{"id" => "Hermes", "kind" => "communication"}, /adapters entry id format is invalid/],
        [{"kind" => "communication"}, /adapters entry id is required/],
        [{"id" => "hermes"}, /adapters entry kind is required/],
        [{"id" => "hermes", "kind" => "transport"}, /adapters entry kind must be one of:/],
        [{"id" => "hermes", "kind" => "hitl", "config" => "tty"}, /config must be a mapping when present/],
        [{"id" => "hermes", "kind" => "hitl", "command" => "  "}, /command must be a non-empty string/],
        [{"id" => "hermes", "kind" => "hitl", "extra" => 1}, /adapters entry #\d+ has unknown key/],
        [[{"id" => "a", "kind" => "hitl"}, {"id" => "a", "kind" => "communication"}],
         /adapters entry id is declared more than once/]
      ].each do |entries, pattern|
        entries = [entries] if entries.is_a?(Hash)
        error = assert_raises(Ace::Lab::InvalidConfigurationError) do
          normalize(manifest("adapters" => entries))
        end

        assert_match(pattern, error.message)
      end
    end

    def test_adapters_and_tools_default_to_empty
      result = normalize(manifest)

      assert_empty result["adapters"]
      assert_empty result["tools"]
    end

    def test_tools_normalize_and_validate
      result = normalize(manifest("tools" => %w[git ssh-keygen ace-nav]))

      assert_equal %w[git ssh-keygen ace-nav], result["tools"]

      [["git", 1], [" ", "git"]].each do |raw|
        error = assert_raises(Ace::Lab::InvalidConfigurationError) do
          normalize(manifest("tools" => raw.is_a?(Array) ? raw : [raw]))
        end

        assert_match(/tools must be a list of non-empty strings/, error.message)
      end

      error = assert_raises(Ace::Lab::InvalidConfigurationError) do
        normalize(manifest("tools" => %w[git git]))
      end
      assert_match(/tools list a tool more than once/, error.message)

      error = assert_raises(Ace::Lab::InvalidConfigurationError) do
        normalize(manifest("tools" => "git"))
      end
      assert_match(/tools must be a list of non-empty strings/, error.message)
    end

    # --- gemset: target runtime + required gem set (gad.2) --------------

    def test_gemset_normalizes_with_defaults
      result = normalize(manifest("gemset" => {
        "gem_home" => " /opt/lab/gems ",
        "gems" => [{"name" => " ace-lab ", "version" => " 0.13.0 "}]
      }))

      assert_equal "/opt/lab/gems", result["gemset"]["gem_home"]
      assert_equal [{"name" => "ace-lab", "version" => "0.13.0"}], result["gemset"]["gems"]
    end

    def test_absent_gemset_defaults_to_no_runtime_and_no_gems
      result = normalize(manifest)

      assert_equal({"gem_home" => nil, "gems" => []}, result["gemset"])
    end

    def test_gemset_section_validation
      [
        ["accounts", /gemset must be a mapping/],
        [{"gems" => []}, /gemset gem_home is required and must be an absolute path/],
        [{"gem_home" => "opt/lab/gems"}, /gemset gem_home is required and must be an absolute path/],
        [{"gem_home" => "/opt/g", "gems" => "ace-lab"}, /gemset gems must be a list/],
        [{"gem_home" => "/opt/g", "gems" => ["ace-lab"]}, /gemset gems entry #0 must be a mapping/],
        [{"gem_home" => "/opt/g", "gems" => [{"version" => "0.13.0"}]},
         /gemset gems entry name is required and must be a gem name/],
        [{"gem_home" => "/opt/g", "gems" => [{"name" => "ACE::Lab", "version" => "0.13.0"}]},
         /gemset gems entry name is required and must be a gem name/],
        [{"gem_home" => "/opt/g", "gems" => [{"name" => "ace-lab"}]},
         /gemset gems entry version is required and must be an exact version/],
        [{"gem_home" => "/opt/g", "gems" => [{"name" => "ace-lab", "version" => "  "}]},
         /gemset gems entry version is required and must be an exact version/],
        [{"gem_home" => "/opt/g", "gems" => [{"name" => "ace-lab", "version" => "~> 0.13"}]},
         /gemset gems entry version must be an exact gem version/],
        [{"gem_home" => "/opt/g", "gems" => [{"name" => "ace-lab", "version" => "latest"}]},
         /gemset gems entry version must be an exact gem version/],
        [{"gem_home" => "/opt/g", "gems" => [{"name" => "ace-lab", "version" => "0.13.0", "extra" => 1}]},
         /gemset gems entry #0 has unknown key 'extra'/],
        [{"gem_home" => "/opt/g", "platform" => "linux"}, /gemset has unknown key 'platform'/]
      ].each do |gemset, pattern|
        gemset = [gemset] if gemset.is_a?(String)
        error = assert_raises(Ace::Lab::InvalidConfigurationError) do
          normalize(manifest("gemset" => gemset))
        end

        assert_match(pattern, error.message)
      end
    end

    def test_gemset_rejects_duplicate_gem_names
      error = assert_raises(Ace::Lab::InvalidConfigurationError) do
        normalize(manifest("gemset" => {
          "gem_home" => "/opt/lab/gems",
          "gems" => [
            {"name" => "ace-lab", "version" => "0.13.0"},
            {"name" => "ace-lab", "version" => "0.14.0"}
          ]
        }))
      end

      assert_match(/gemset gems entry name is declared more than once/, error.message)
    end

    def test_gemset_accepts_exact_pre_release_versions
      result = normalize(manifest("gemset" => {
        "gem_home" => "/opt/lab/gems",
        "gems" => [{"name" => "ace-lab", "version" => "1.0.0.pre.1"}]
      }))

      assert_equal "1.0.0.pre.1", result["gemset"]["gems"].first["version"]
    end
  end
end
