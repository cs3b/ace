# frozen_string_literal: true

require_relative "../../test_helper"

class AsciinemaCommandBuilderTest < AceDemoTestCase
  def test_builds_default_command_array
    cmd = Ace::Demo::Atoms::AsciinemaCommandBuilder.build(
      output_path: "/tmp/demo.cast",
      script_path: "/tmp/demo.compiled.sh"
    )

    assert_equal [
      "asciinema",
      "rec",
      "--overwrite",
      "--command",
      "bash /tmp/demo.compiled.sh",
      "--cols",
      "80",
      "--rows",
      "24",
      "/tmp/demo.cast"
    ], cmd
  end

  def test_builds_command_without_tty_size
    cmd = Ace::Demo::Atoms::AsciinemaCommandBuilder.build(
      output_path: "/tmp/demo.cast",
      shell_command: "bash --noprofile --norc -i",
      tty_size: nil,
      asciinema_bin: "asciinema-custom"
    )

    assert_equal [
      "asciinema-custom",
      "rec",
      "--overwrite",
      "--command",
      "bash --noprofile --norc -i",
      "/tmp/demo.cast"
    ], cmd
  end

  def test_raises_on_invalid_tty_size
    error = assert_raises(ArgumentError) do
      Ace::Demo::Atoms::AsciinemaCommandBuilder.build(
        output_path: "/tmp/demo.cast",
        script_path: "/tmp/demo.compiled.sh",
        tty_size: "80"
      )
    end

    assert_includes error.message, "tty_size"
  end

  def test_raises_on_invalid_cast_compatibility
    error = assert_raises(ArgumentError) do
      Ace::Demo::Atoms::AsciinemaCommandBuilder.build(
        output_path: "/tmp/demo.cast",
        script_path: "/tmp/demo.compiled.sh",
        cast_compatibility: :v4
      )
    end

    assert_includes error.message, "cast_compatibility"
  end

  def test_escapes_script_path_for_shell_command
    cmd = Ace::Demo::Atoms::AsciinemaCommandBuilder.build(
      output_path: "/tmp/demo.cast",
      script_path: "/tmp/demo script '$HOME'.sh"
    )

    assert_equal "bash /tmp/demo\\ script\\ \\'\\$HOME\\'.sh", cmd[4]
  end

  def test_prefers_explicit_shell_command_when_provided
    cmd = Ace::Demo::Atoms::AsciinemaCommandBuilder.build(
      output_path: "/tmp/demo.cast",
      script_path: "/tmp/demo.compiled.sh",
      shell_command: "bash --noprofile --norc -i"
    )

    assert_equal "bash --noprofile --norc -i", cmd[4]
  end
end
