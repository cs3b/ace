# frozen_string_literal: true

require "test_helper"
require_relative "../../support/inbox_context_service_runtime_fixture"

class InboxContextLifetimeTest < Minitest::Test
  include InboxContextServiceRuntimeFixture
  ERROR = Ace::Herdr::ValidationError

  def test_full_verified_installation_and_exact_observed_owner_create_one_immutable_epoch
    epoch = @lifetime.capture_epoch!
    assert_equal "ace.herdr.inbox-owner-epoch/v1", epoch.fetch("schema")
    assert_equal "01010101010101010101010101010101", epoch.fetch("service_invocation_id")
    assert_equal Process.pid, epoch.dig("process_identity", "pid")
    assert_equal @scope.fetch("unit_manifest_sha256"), epoch.fetch("installation_sha256")
    assert @cgroups.handle.closed?
    assert_raises(FrozenError) { epoch.fetch("process_identity")["groups"] << 7 }
    assert_raises(ERROR) { @lifetime.capture_epoch! }
  end

  def test_foreign_dead_empty_replaced_and_effectively_weakened_service_refuse
    failures = [-> { @kernel.foreign = true }, -> { @kernel.dead = true }, -> { @cgroups.populated = 0 },
      -> { @cgroups.replaced = true }, -> { @cgroups.foreign = true },
      -> { @profiles.fetch("ace-slot.service")["ProtectControlGroups"] = false }]
    failures.each do |change|
      change.call
      assert_raises(ERROR) { @lifetime.capture_epoch! }
      assert_nil @lifetime.epoch
      assert @cgroups.handle.nil? || @cgroups.handle.closed?
      teardown
      setup
    end
  end
end
