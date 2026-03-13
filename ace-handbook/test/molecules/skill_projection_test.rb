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
    frontmatter["skill"] = {"execution" => {"workflow" => "wfi://git/commit"}}

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
    assert_includes rendered, "You are working in the current project."
    assert_includes rendered, "Run `mise exec -- ace-bundle wfi://git/commit` in the current project to load the workflow instructions."
    assert_includes rendered, "Read the loaded workflow and execute it end-to-end in this project."
    assert_includes rendered, "Do the work described by the workflow instead of only summarizing it."
    assert_includes rendered, "ace-llm codex:spark@yolo"
    assert_includes rendered, "INTENTION\n\nCHANGED_FILES\n\nYou are working in the current project."
    assert_includes rendered, "mise exec -- ace-bundle wfi://git/commit"
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
    frontmatter["skill"] = {"execution" => {"workflow" => "wfi://release/publish"}}

    rendered = Ace::Handbook::Molecules::SkillProjection.projected_body(
      frontmatter,
      body,
      provider: "codex"
    )

    assert_includes rendered, "## Variables"
    assert_includes rendered, "- PACKAGE_NAME"
    assert_includes rendered, "- BUMP_LEVEL"
    assert_includes rendered, "If PACKAGE_NAME was provided explicitly, use it. Otherwise, determine target package names if not explicitly provided."
    assert_includes rendered, "If BUMP_LEVEL was provided explicitly, use it. Otherwise, determine bump level if not explicitly provided."
    assert_includes rendered, "Run `mise exec -- ace-bundle wfi://release/publish` in the current project to load the workflow instructions."
  end

  def test_projected_body_renders_simple_codex_run_when_no_variables_are_configured
    frontmatter = {
      "argument-hint" => "package-name... bump-level",
      "integration" => {
        "providers" => {
          "codex" => {
            "context" => "ace-llm",
            "ace-llm" => "codex:spark@yolo"
          }
        }
      }
    }

    body = "read and run `ace-bundle wfi://release/publish`\n"
    frontmatter["skill"] = {"execution" => {"workflow" => "wfi://release/publish"}}

    rendered = Ace::Handbook::Molecules::SkillProjection.projected_body(
      frontmatter,
      body,
      provider: "codex"
    )

    assert_includes rendered, "Run:"
    assert_includes rendered, "## Instructions"
    assert_includes rendered, "ace-llm codex:spark@yolo"
    assert_includes rendered, "You are working in the current project."
    assert_includes rendered, "Run `mise exec -- ace-bundle wfi://release/publish` in the current project to load the workflow instructions."
    assert_includes rendered, "Do the work described by the workflow instead of only summarizing it."
    refute_includes rendered, "## Variables"
  end

  def test_projected_body_renders_fork_workflow_instructions_for_non_codex_provider
    frontmatter = {
      "integration" => {
        "providers" => {
          "claude" => {
            "frontmatter" => {
              "context" => "fork",
              "model" => "haiku"
            }
          }
        }
      },
      "skill" => {"execution" => {"workflow" => "wfi://github/pr/create"}}
    }

    body = "read and run `ace-bundle wfi://github/pr/create`\n"

    rendered = Ace::Handbook::Molecules::SkillProjection.projected_body(
      frontmatter,
      body,
      provider: "claude"
    )

    assert_includes rendered, "## Instructions"
    assert_includes rendered, "You are working in a forked execution context for the current project."
    assert_includes rendered, "Run `mise exec -- ace-bundle wfi://github/pr/create` in the current project to load the workflow instructions."
    assert_includes rendered, "Read the loaded workflow and execute it end-to-end in this forked context."
    assert_includes rendered, "Do the work described by the workflow instead of only summarizing it."
    refute_includes rendered, "ace-llm"
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
