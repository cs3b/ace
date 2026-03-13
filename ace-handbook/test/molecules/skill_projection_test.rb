# frozen_string_literal: true

require "test_helper"

class Ace::Handbook::Molecules::SkillProjectionTest < Minitest::Test
  def test_projected_body_rewrites_codex_ace_llm_context_using_argument_hint_variables
    frontmatter = {
      "argument-hint" => ["intention"],
      "integration" => {
        "providers" => {
          "codex" => {
            "context" => "ace-llm",
            "ace-llm" => "codex:spark@yolo",
            "prompt_context" => {
              "intention" => "describe intent of recent changes",
              "changed_files" => "list files changed in this session"
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

    assert_includes rendered, "## Variables"
    assert_includes rendered, "- INTENTION"
    assert_includes rendered, "- CHANGED_FILES"
    assert_includes rendered, "## Instructions"
    assert_includes rendered, "If INTENTION was provided explicitly, use it. Otherwise, describe intent of recent changes."
    assert_includes rendered, "If CHANGED_FILES was provided explicitly, use it. Otherwise, list files changed in this session."
    assert_includes rendered, "ace-llm codex:spark@yolo"
    assert_includes rendered, "INTENTION\n\nCHANGED_FILES"
    assert_includes rendered, "read and run \\`ace-bundle wfi://git/commit\\`"
    refute_includes rendered, "$INTENTION"
  end

  def test_projected_body_uses_string_argument_hint_for_release_style_variables
    frontmatter = {
      "argument-hint" => "package-name... bump-level",
      "integration" => {
        "providers" => {
          "codex" => {
            "context" => "ace-llm",
            "ace-llm" => "codex:spark@yolo",
            "prompt_context" => {
              "package_name" => "determine target package names if not explicitly provided",
              "bump_level" => "determine bump level if not explicitly provided"
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

  def test_projected_body_leaves_non_codex_body_unchanged
    frontmatter = {
      "argument-hint" => ["intention"],
      "integration" => {
        "providers" => {
          "codex" => {
            "context" => "ace-llm",
            "ace-llm" => "codex:spark@yolo",
            "prompt_context" => {
              "intention" => "describe intent of recent changes"
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
