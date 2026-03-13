# frozen_string_literal: true

require "test_helper"

class Ace::Handbook::Molecules::SkillProjectionTest < Minitest::Test
  def test_projected_body_rewrites_codex_runtime_to_ace_llm_command
    frontmatter = {
      "integration" => {
        "providers" => {
          "codex" => {
            "runtime" => {
              "ace-llm" => "codex:spark@yolo",
              "prompt_context" => {
                "intent" => "prepare describe intent of recent changes",
                "changed_files" => "list of files that have been changed in this session"
              }
            }
          }
        }
      }
    }

    body = "read and run `ace-bundle wfi://git/commit`\n"

    rendered = Ace::Handbook::Molecules::SkillProjection.projected_body(
      frontmatter,
      body,
      provider: "codex"
    )

    assert_includes rendered, "Prepare:"
    assert_includes rendered, "- `$INTENT`: prepare describe intent of recent changes"
    assert_includes rendered, "- `$CHANGED_FILES`: list of files that have been changed in this session"
    assert_includes rendered, "ace-llm codex:spark@yolo"
    assert_includes rendered, "$INTENT\n\n$CHANGED_FILES"
    assert_includes rendered, "read and run \\`ace-bundle wfi://git/commit\\`"
  end

  def test_projected_body_leaves_non_codex_body_unchanged
    frontmatter = {
      "integration" => {
        "providers" => {
          "codex" => {
            "runtime" => {
              "ace-llm" => "codex:spark@yolo",
              "prompt_context" => {
                "intent" => "prepare describe intent of recent changes"
              }
            }
          }
        }
      }
    }

    body = "read and run `ace-bundle wfi://git/commit`\n"

    rendered = Ace::Handbook::Molecules::SkillProjection.projected_body(
      frontmatter,
      body,
      provider: "claude"
    )

    assert_equal body, rendered
  end
end
