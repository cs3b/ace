# frozen_string_literal: true

require_relative "test_helper"

describe "Provider Registration" do
  it "loads without errors" do
    assert defined?(Ace::LLM::Providers::CLI), "CLI module should be defined"
    assert defined?(Ace::LLM::Providers::CLI::VERSION), "VERSION should be defined"
  end

  it "defines all provider clients" do
    assert defined?(Ace::LLM::Providers::CLI::ClaudeCodeClient), "ClaudeCodeClient should be defined"
    assert defined?(Ace::LLM::Providers::CLI::CodexClient), "CodexClient should be defined"
    assert defined?(Ace::LLM::Providers::CLI::OpenCodeClient), "OpenCodeClient should be defined"
    assert defined?(Ace::LLM::Providers::CLI::CodexOSSClient), "CodexOSSClient should be defined"
  end

  it "providers have correct provider_name" do
    assert_equal "claude", Ace::LLM::Providers::CLI::ClaudeCodeClient.provider_name
    assert_equal "codex", Ace::LLM::Providers::CLI::CodexClient.provider_name
    assert_equal "opencode", Ace::LLM::Providers::CLI::OpenCodeClient.provider_name
    assert_equal "codexoss", Ace::LLM::Providers::CLI::CodexOSSClient.provider_name
  end

  it "providers don't need credentials" do
    # These CLI providers handle auth through the CLI tool itself
    cc = Ace::LLM::Providers::CLI::ClaudeCodeClient.new
    assert_equal false, cc.needs_credentials?

    codex = Ace::LLM::Providers::CLI::CodexClient.new
    assert_equal false, codex.needs_credentials?

    oc = Ace::LLM::Providers::CLI::OpenCodeClient.new
    assert_equal false, oc.needs_credentials?

    oss = Ace::LLM::Providers::CLI::CodexOSSClient.new
    assert_equal false, oss.needs_credentials?
  end
end