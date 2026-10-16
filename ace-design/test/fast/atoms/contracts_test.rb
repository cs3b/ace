# frozen_string_literal: true
require_relative "../../test_helper"
class ContractsTest < DesignTest
  def test_surface_is_explicit
    assert_equal "app", Ace::Design::Atoms::Contracts.surface("app")
    assert_raises(Ace::Design::Error) { Ace::Design::Atoms::Contracts.surface("native") }
  end
  def test_urls_allow_local_http_but_reject_credentials_and_other_schemes
    assert_equal "http://127.0.0.1:3000", Ace::Design::Atoms::Contracts.url("http://127.0.0.1:3000")
    %w[file:///tmp/page javascript:alert(1) https://user:pass@example.com http://].each do |url|
      assert_raises(Ace::Design::Error) { Ace::Design::Atoms::Contracts.url(url) }
    end
  end
end
