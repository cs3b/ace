# frozen_string_literal: true
require_relative "../test_helper"
require_relative "../support/codex_runtime_installation_fixture"

class CodexRuntimeInstallationTest < AceRuntimeTestCase
  include CodexRuntimeInstallationFixture


  def test_same_installation_owner_verifies_dedicated_profile_and_refuses_changes
    installation = selected_installation
    assert_equal @manifest, installation.verify!(manager: @manager)
    @profiles.fetch("codex.service")["ExecStartEx"].first[1] << "--arbitrary"
    assert_raises(Unavailable) { installation.verify!(manager: @manager) }
  end

  def test_selection_refuses_invalid_original_bindings_and_bounds
    [->(intent) { intent["native_mapping_id"] = "foreign" },
     ->(intent) { intent["credentials"]["uid"] = 13002 },
     ->(intent) { intent["socket_path"] = "/" + "s" * 107 },
     ->(intent) { intent["inbox_context_id"] = "c" * 129 },
     ->(intent) { intent["dependencies"] = [intent.fetch("codex").dup] }].each do |change|
      setup
      assert_raises(Unavailable) { selected_installation(change) }
    end
  end
  def test_effective_profile_and_selected_bytes_never_weaken_original_containment
    [->(profile) { profile["User"] = "13002" },
     ->(profile) { profile["ProtectControlGroups"] = false },
     ->(profile) { profile["RootDirectory"] = "/foreign" },
     ->(profile) { profile["NetworkNamespacePath"] = "/run/netns/foreign" },
     ->(profile) { profile["BindPaths"] = [] },
     ->(profile) { profile["SupplementaryGroups"] = ["13002"] }].each do |change|
      setup
      installation = selected_installation
      change.call(@profiles.fetch("codex.service"))
      assert_raises(Unavailable) { installation.verify!(manager: @manager) }
    end
    setup
    installation = selected_installation
    @files.bytes[@intent_ref.fetch("path")] = "x" * @intent_ref.fetch("bytes")
    assert_raises(Unavailable) { installation.verify!(manager: @manager) }
    setup
    selected_installation
    changed = Marshal.load(Marshal.dump(@selection))
    changed.fetch("execution_scope")["root_directory"] = "/foreign"
    assert_raises(Unavailable) do
      Installation.for_codex_runtime(service: changed, intent_reference: @intent_ref, original_mapping: @original,
        mapping_id: "map", authority: {"socket_path" => "/run/authority/socket", "uid" => 13000}, files: @files)
    end
  end

  def test_typed_dedicated_selection_refuses_foreign_factory_unit_and_manager
    installation = selected_installation
    assert installation.verify_codex_runtime_selection!(service: @selection, intent_reference: @intent_ref, manager: @manager)
    wrong = Marshal.load(Marshal.dump(@selection))
    wrong.fetch("unit_manifest")["sha256"] = "f" * 64
    assert_raises(Unavailable) { installation.verify_codex_runtime_selection!(service: wrong, intent_reference: @intent_ref, manager: @manager) }
    assert_raises(Unavailable) { @installation.verify_codex_runtime_selection!(service: @selection, intent_reference: @intent_ref, manager: @manager) }
    wrong_manager = Manager.new(slice_unit: @scope.fetch("slice_unit"), service_unit: "foreign.service", command: @command)
    assert_raises(Unavailable) { installation.verify_codex_runtime_selection!(service: @selection, intent_reference: @intent_ref, manager: wrong_manager) }
  end

end
