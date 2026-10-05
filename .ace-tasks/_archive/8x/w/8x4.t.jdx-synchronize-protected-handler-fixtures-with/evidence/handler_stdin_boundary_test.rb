require_relative '../../ace-lab/test/molecules/protected_service_handler_test'
class HandlerStdinBoundaryTest < Ace::Lab::ProtectedServiceHandlerTest
  def test_unconsumed_envelope_refuses_but_consumed_envelope_succeeds
    with_handler do |handler, root, envelope|
      envelope.fetch('input')['controlled_padding'] = 'x' * (256 * 1024)
      reply = JSON.generate(envelope.fetch('request').merge('outcome' => 'succeeded', 'evidence' => []))
      script = "printf '%s' '#{reply}'"
      assert_nil handler.execute(operation: operation(script), envelope: envelope, candidate_root: root)
      result = handler.execute(operation: operation("cat >/dev/null; " + script), envelope: envelope, candidate_root: root)
      assert_equal 'succeeded', result.fetch('outcome')
    end
  end
end
