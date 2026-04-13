# frozen_string_literal: true

require_relative "../../test_helper"

class AsciinemaAggPipelineTest < AceDemoTestCase
  def test_compiler_and_builders_chain_for_cast_to_gif_flow
    spec = {
      "settings" => {"env" => {"PROJECT_ROOT_PATH" => "/tmp/sandbox"}},
      "scenes" => [{"name" => "Main", "commands" => [{"type" => "echo hi", "sleep" => "1s"}]}]
    }

    script = Ace::Demo::Atoms::AsciinemaTapeCompiler.compile(spec: spec)
    record_cmd = Ace::Demo::Atoms::AsciinemaCommandBuilder.build(
      output_path: "/tmp/demo.cast",
      script_path: "/tmp/demo.compiled.sh",
      cast_compatibility: :v3
    )
    convert_cmd = Ace::Demo::Atoms::AggCommandBuilder.build(
      input_path: "/tmp/demo.cast",
      output_path: "/tmp/demo.gif"
    )

    assert_includes script, "echo hi"
    assert_equal "/tmp/demo.cast", record_cmd.last
    assert_equal "/tmp/demo.cast", convert_cmd[-2]
    assert_equal "/tmp/demo.gif", convert_cmd.last
  end

  def test_compatibility_guard_raises_actionable_error_for_unsupported_mode
    error = assert_raises(ArgumentError) do
      Ace::Demo::Atoms::AsciinemaCommandBuilder.build(
        output_path: "/tmp/demo.cast",
        script_path: "/tmp/demo.compiled.sh",
        cast_compatibility: :v4
      )
    end

    assert_includes error.message, "cast_compatibility"
  end
end
