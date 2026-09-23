# frozen_string_literal: true

require "test_helper"
require "ace/hitl/providers/providers"

class ProvidersRegistryTest < AceHitlTestCase
  def test_lab_is_the_registered_provider
    assert_equal ["lab"], Ace::Hitl::Providers.available
  end

  def test_resolve_returns_lab_adapter_instance
    adapter = Ace::Hitl::Providers.resolve("lab")

    assert_instance_of Ace::Hitl::Providers::Lab, adapter
  end

  def test_resolve_accepts_symbols
    adapter = Ace::Hitl::Providers.resolve(:lab)

    assert_instance_of Ace::Hitl::Providers::Lab, adapter
  end

  def test_unknown_provider_raises_with_available_list
    error = assert_raises(Ace::Hitl::Providers::UnknownProviderError) do
      Ace::Hitl::Providers.resolve("nope")
    end

    assert_match(/unknown HITL provider 'nope'/, error.message)
    assert_match(/available: lab/, error.message)
  end
end
