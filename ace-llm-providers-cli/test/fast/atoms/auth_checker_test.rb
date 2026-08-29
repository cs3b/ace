# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../../lib/ace/llm/providers/cli/atoms/auth_checker"

describe Ace::Llm::Providers::Cli::Atoms::AuthChecker do
  describe ".check_agy" do
    it "reports an installed agy binary as ready but not headlessly verified" do
      Open3.stub(:capture3, ["", "", Struct.new(:success?).new(true)]) do
        result = Ace::Llm::Providers::Cli::Atoms::AuthChecker.check_agy

        assert_equal false, result[:authenticated]
        assert_equal true, result[:ready]
        assert_includes result[:message], "Installed"
      end
    end

    it "returns setup guidance when agy is unavailable" do
      Open3.stub(:capture3, ["", "", Struct.new(:success?).new(false)]) do
        result = Ace::Llm::Providers::Cli::Atoms::AuthChecker.check_agy

        assert_equal false, result[:authenticated]
        assert_equal false, result[:ready]
        assert_equal "Run: agy", result[:message]
      end
    end
  end
end
