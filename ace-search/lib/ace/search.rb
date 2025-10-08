# frozen_string_literal: true

require_relative "search/version"
require "ace/core"

module Ace
  module Search
    class Error < StandardError; end

    # Configuration
    def self.config
      @config ||= begin
        base_config = Ace::Core.config
        base_config.dig("ace", "search") || default_config
      end
    end

    def self.default_config
      {
        "case_insensitive" => false,
        "max_results" => nil,
        "exclude" => [
          ".ace-taskflow/done/**/*",
          "dev-taskflow/done/**/*",
          "dev-taskflow/current/*/tasks/x/*"
        ],
        "context" => 0,
        "hidden" => false,
        "whole_word" => false,
        "files_with_matches" => false,
        "type" => "auto"
      }
    end
  end
end
