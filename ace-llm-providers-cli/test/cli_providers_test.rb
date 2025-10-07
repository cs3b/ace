# frozen_string_literal: true

require_relative "test_helper"

describe "CLI Providers" do
  describe "ClaudeCodeClient" do
    before do
      @client = Ace::LLM::Providers::CLI::ClaudeCodeClient.new
    end

    it "initializes with default model" do
      assert @client.instance_variable_get(:@model)
    end

    it "can list models" do
      models = @client.list_models
      assert_kind_of Array, models
      assert models.any? { |m| m[:id].include?("opus") }
      assert models.any? { |m| m[:id].include?("sonnet") }
      assert models.any? { |m| m[:id].include?("haiku") }
    end

    it "formats messages correctly" do
      messages = [
        { role: "system", content: "You are helpful" },
        { role: "user", content: "Hello" }
      ]

      formatted = @client.send(:format_messages_as_prompt, messages)
      assert_includes formatted, "System: You are helpful"
      assert_includes formatted, "User: Hello"
    end

    it "handles string prompts" do
      prompt = "Just a string"
      formatted = @client.send(:format_messages_as_prompt, prompt)
      assert_equal "Just a string", formatted
    end
  end

  describe "CodexClient" do
    before do
      @client = Ace::LLM::Providers::CLI::CodexClient.new
    end

    it "initializes with default model" do
      model = @client.instance_variable_get(:@model)
      assert model # Just check it has a model
    end

    it "can list models" do
      models = @client.list_models
      assert_kind_of Array, models
      assert models.any? { |m| m[:id] == "gpt-5" }
      assert models.any? { |m| m[:id] == "gpt-5-mini" }
    end
  end

  describe "OpenCodeClient" do
    before do
      @client = Ace::LLM::Providers::CLI::OpenCodeClient.new
    end

    it "initializes with default model" do
      model = @client.instance_variable_get(:@model)
      assert model # Just check it has a model
    end

    it "provides models" do
      models = @client.list_models
      assert_kind_of Array, models
      assert models.size > 0
      assert models.any? { |m| m[:id].include?("gemini") }
    end
  end

  describe "CodexOSSClient" do
    before do
      @client = Ace::LLM::Providers::CLI::CodexOSSClient.new
    end

    it "initializes with default model" do
      model = @client.instance_variable_get(:@model)
      assert model # Just check it has a model
    end

    it "lists single default model" do
      models = @client.list_models
      assert_kind_of Array, models
      assert_equal 1, models.size
      assert_equal "default", models.first[:id]
    end
  end
end