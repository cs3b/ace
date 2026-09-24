# frozen_string_literal: true

require_relative "../../test_helper"
require "yaml"

class CodexExecPresetTest < AceLlmTestCase
  def test_read_only_preset_uses_supported_codex_exec_flags
    options = preset("ro")
    assert_equal ["--sandbox", "read-only"], options.fetch("cli_args")
  end

  def test_workspace_write_preset_uses_supported_codex_exec_flags
    options = preset("rw")
    assert_equal ["--sandbox", "workspace-write"], options.fetch("cli_args")
  end

  private

  def preset(name)
    YAML.safe_load_file(File.expand_path("../../../.ace-defaults/llm/presets/codex/#{name}.yml", __dir__))
  end
end
