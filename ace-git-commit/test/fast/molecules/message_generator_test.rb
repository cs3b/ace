# frozen_string_literal: true

require_relative "../../test_helper"

class MessageGeneratorTest < TestCase
  def setup
    @generator = Ace::GitCommit::Molecules::MessageGenerator.new("model" => "glite")
  end

  def test_parse_batch_response_with_strict_json
    groups = [
      {scope_name: "ace-assign"},
      {scope_name: "ace-docs"}
    ]
    response = <<~JSON
      {
        "order": ["ace-docs", "ace-assign"],
        "messages": [
          {"scope":"ace-docs","message":"docs(ace-docs): update usage guidance"},
          {"scope":"ace-assign","message":"feat(ace-assign): add rolling scheduler"}
        ]
      }
    JSON

    parsed = @generator.send(:parse_batch_response, response, groups)
    assert_equal ["ace-docs", "ace-assign"], parsed[:order]
    assert_equal "docs(ace-docs): update usage guidance", parsed[:messages][0]
    assert_equal "feat(ace-assign): add rolling scheduler", parsed[:messages][1]
  end

  def test_parse_batch_response_with_fenced_json
    groups = [{scope_name: "ace-review"}, {scope_name: "ace-docs"}]
    response = <<~TXT
      ```json
      {"order":["ace-review","ace-docs"],"messages":[{"scope":"ace-review","message":"fix(ace-review): harden preset lookup"},{"scope":"ace-docs","message":"docs(ace-docs): align examples"}]}
      ```
    TXT

    parsed = @generator.send(:parse_batch_response, response, groups)
    assert_equal ["ace-review", "ace-docs"], parsed[:order]
    assert_equal "fix(ace-review): harden preset lookup", parsed[:messages][0]
    assert_equal "docs(ace-docs): align examples", parsed[:messages][1]
  end

  def test_parse_batch_response_rejects_missing_scopes
    groups = [
      {scope_name: "ace-assign"},
      {scope_name: "ace-docs"}
    ]
    bad = '{"order":["ace-assign"],"messages":[{"scope":"ace-assign","message":"feat(ace-assign): add x"}]}'

    error = assert_raises(Ace::GitCommit::Molecules::MessageGenerator::BatchParseError) do
      @generator.send(:parse_batch_response, bad, groups)
    end
    assert_includes error.message, "scope validation failed"
  end

  def test_generate_batch_retries_once_on_invalid_json
    groups = [
      {
        scope_name: "ace-assign",
        diff: "diff --git a/x b/x",
        files: ["ace-assign/lib/x.rb"],
        type_hint: nil,
        description: nil
      },
      {
        scope_name: "ace-docs",
        diff: "diff --git a/y b/y",
        files: ["ace-docs/docs/usage.md"],
        type_hint: nil,
        description: nil
      }
    ]

    call_count = 0
    Ace::LLM::QueryInterface.stub(:query, proc { |_model, _prompt, **_opts|
      call_count += 1
      if call_count == 1
        {text: "not-json"}
      else
        {text: '{"order":["ace-assign","ace-docs"],"messages":[{"scope":"ace-assign","message":"feat(ace-assign): add retry-safe parsing"},{"scope":"ace-docs","message":"docs(ace-docs): clarify split behavior"}]}'}
      end
    }) do
      result = @generator.generate_batch(groups, intention: "improve parser")
      assert_equal ["ace-assign", "ace-docs"], result[:order]
      assert_equal "feat(ace-assign): add retry-safe parsing", result[:messages][0]
      assert_equal "docs(ace-docs): clarify split behavior", result[:messages][1]
    end
    assert_equal 2, call_count
  end

  def test_generate_includes_setup_guidance_for_role_based_missing_credentials
    error = assert_raises(Ace::GitCommit::Error) do
      Ace::LLM::QueryInterface.stub(:query, proc { |_model, _prompt, **_opts|
        raise Ace::LLM::Error, "Missing API key for provider"
      }) do
        @generator.generate("diff --git a/a.rb b/a.rb", intention: "setup", files: ["a.rb"], config: {"model" => "role:commit"})
      end
    end

    assert_includes error.message, "Failed to generate commit message with ACE role 'role:commit': Missing API key for provider"
    assert_includes error.message, "ace-llm --list-providers"
    assert_includes error.message, "ace-config doctor"
    assert_includes error.message, 'ace-git-commit --only-staged --no-split -m "chore: set up ace tooling"'
  end

  def test_generate_includes_setup_guidance_for_unsupported_model
    error = assert_raises(Ace::GitCommit::Error) do
      Ace::LLM::QueryInterface.stub(:query, proc { |_model, _prompt, **_opts|
        raise Ace::LLM::Error, "Model codex:mini is not available"
      }) do
        @generator.generate("diff --git a/a.rb b/a.rb", intention: "setup", files: ["a.rb"], config: {"model" => "codex:mini"})
      end
    end

    assert_includes error.message, "Failed to generate commit message with LLM model 'codex:mini': Model codex:mini is not available"
    assert_includes error.message, "ace-llm --list-providers"
    assert_includes error.message, "ace-config doctor"
    assert_includes error.message, 'ace-git-commit --only-staged --no-split -m "chore: set up ace tooling"'
  end

  def test_generate_batch_includes_setup_guidance_when_repair_query_fails
    groups = [
      {
        scope_name: "ace-assign",
        diff: "diff --git a/x b/x",
        files: ["ace-assign/lib/x.rb"],
        type_hint: nil,
        description: nil
      },
      {
        scope_name: "ace-docs",
        diff: "diff --git a/y b/y",
        files: ["ace-docs/docs/usage.md"],
        type_hint: nil,
        description: nil
      }
    ]

    call_count = 0
    error = assert_raises(Ace::GitCommit::Error) do
      Ace::LLM::QueryInterface.stub(:query, proc { |_model, _prompt, **_opts|
        call_count += 1
        if call_count == 1
          {text: "not-json"}
        else
          raise Ace::LLM::Error, "Provider unavailable"
        end
      }) do
        @generator.generate_batch(groups, intention: "improve parser")
      end
    end

    assert_equal 2, call_count
    assert_includes error.message, "Failed to generate batch commit messages"
    assert_includes error.message, "Provider unavailable"
    assert_includes error.message, "ace-llm --list-providers"
    assert_includes error.message, "ace-config doctor"
    assert_includes error.message, 'ace-git-commit --only-staged --no-split -m "chore: set up ace tooling"'
  end
end
