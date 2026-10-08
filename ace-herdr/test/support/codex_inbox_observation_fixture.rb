# frozen_string_literal: true

# Inject only native provider replies. Tests retain the actual inbox record,
# per-event locks, context admission, key selection and public socket framing.
module CodexInboxObservationFixture
  THREAD = "0123abcd-0000-4000-8000-000000000001"
  QUEUE = "0123abcd-0000-4000-8000-000000000002"
  TURN = "0123abcd-0000-4000-8000-000000000003"

  class Native
    attr_accessor :on_read, :result, :accepted
    attr_reader :reads, :sends

    def initialize
      @reads, @sends, @accepted = [], [], true
    end

    def prepare_submission(agent:, thread:, event_id:, attempt_id:, claim_generation:, digest:)
      {"schema" => "ace.codex-submission/v1", "provider_version" => "0.159.3", "thread_id" => thread,
        "client_user_message_id" => "ace-" + "a" * 32, "event_id" => event_id, "attempt_id" => attempt_id,
        "claim_generation" => claim_generation, "payload_sha256" => digest,
        "endpoint_reference_sha256" => "b" * 64, "server_process_binding" => {"pid" => 101, "started_at" => "fixture-native"}}
    end

    def submit(**args)
      @sends << args
      return {"accepted" => false, "error" => "controlled lost reply"} unless @accepted
      args.fetch(:submission).slice("provider_version", "thread_id", "client_user_message_id", "payload_sha256",
        "endpoint_reference_sha256", "server_process_binding").merge("accepted" => true, "queued_submission_id" => QUEUE)
    end

    def observe(**args)
      @reads << args
      @on_read&.call
      return @result if @result
      intent = args.fetch(:submission)
      {"outcome" => "consumed", "endpoint_reference_sha256" => intent.fetch("endpoint_reference_sha256"),
        "server_process_binding" => intent.fetch("server_process_binding"), "native_reference" => {
          "provider" => "codex", "version" => intent.fetch("provider_version"), "thread_id" => intent.fetch("thread_id"),
          "client_user_message_id" => intent.fetch("client_user_message_id"), "payload_sha256" => intent.fetch("payload_sha256"),
          "queued_submission_id" => args[:receipt]&.fetch("queued_submission_id"), "turn_id" => TURN, "item_id" => "item-1"}}
    end
  end

  class Pane
    def pane_get_bounded(_id)
      pane = {"pane_id" => "p1", "workspace_id" => "ws1", "terminal_id" => "term1", "agent" => "codex",
        "agent_status" => "busy", "agent_session" => {"agent" => "codex", "kind" => "id", "value" => THREAD}}
      Ace::Herdr::Molecules::ExecutionResult.new(stdout: JSON.generate("result" => {"pane" => pane}),
        stderr: "", success: true, exit_code: 0)
    end
  end
end
