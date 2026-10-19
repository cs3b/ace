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
  end
end
