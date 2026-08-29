# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../../lib/ace/llm/providers/cli/molecules/health_checker"

describe Ace::Llm::Providers::Cli::Molecules::HealthChecker do
  it "treats agy as ready when the binary is callable but auth is not headlessly verifiable" do
    checker = Ace::Llm::Providers::Cli::Molecules::HealthChecker.new

    Ace::Llm::Providers::Cli::Atoms::ProviderDetector.stub(:available?, true) do
      Ace::Llm::Providers::Cli::Atoms::ProviderDetector.stub(:version, "agy 1.2.3") do
        Ace::Llm::Providers::Cli::Atoms::AuthChecker.stub(
          :check,
          {authenticated: false, ready: true, message: "Installed, but headless authentication is not verified"}
        ) do
          agy_result = checker.check_all.find { |result| result[:provider] == "agy" }

          assert_equal true, agy_result[:available]
          assert_equal false, agy_result[:authenticated]
          assert_equal true, agy_result[:ready]
          assert_equal "Installed, but headless authentication is not verified", agy_result[:auth_status]
        end
      end
    end
  end
end
