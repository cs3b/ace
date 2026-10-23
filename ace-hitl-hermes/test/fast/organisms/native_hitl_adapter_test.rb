# frozen_string_literal: true

require "test_helper"
require "open3"
require "rbconfig"
require "ace/hitl/hermes/organisms/native_sync"
require "ace/hitl/adapters/hermes_native"

class NativeHitlAdapterTest < AceHermesTestCase
  H = Ace::Hitl
  N = H::Hermes::Molecules::NativeFolder

  def setup
    super
    @tmp = Dir.mktmpdir("native-adapter")
    # Real fixture layout from docs/native-folder.md: one project event root
    # and one native transport folder, both private and user-owned.
    @root = File.join(@tmp, "overseer-lab92", ".ace-local", "hitl")
    FileUtils.mkdir_p(@root)
    File.chmod(0o700, @root)
    @folder = File.join(@tmp, "hitl-address", "ace")
    FileUtils.mkdir_p(@folder, mode: 0o700)
    @route = {"route" => "captain", "adapter" => "hermes_native",
      "recipients" => ["captain"], "machine" => "lab", "channel" => "ace",
      "project" => "ace", "folder" => @folder, "event_roots" => [@root]}
    @config = {"hitl" => {"machine" => "lab", "root_dir" => @root,
      "recipients" => {"captain" => {"machine" => "lab", "panel" => "ace"}},
      "adapters" => {"routes" => [@route]}}}
  end

  def teardown
    FileUtils.remove_entry(@tmp)
    super
  end

  def owner(config = @config)
    H::Organisms::HitlManager.new(root_dir: @root, config: config)
  end

  def send_event(ref, config: @config, force: false)
    H::Organisms::HitlSender.new(config: config).send(ref, force: force).results.first
  end

  def question(to: "captain")
    owner.create("Choose next task", to: to, kind: "approval", questions: ["Continue?"],
      time: Time.utc(2026, 10, 23, 12, 0, 0))
  end

  def report(to: "captain")
    owner.create("Work done", to: to, type: "report", result: "success", body: ["done"],
      time: Time.utc(2026, 10, 23, 12, 1, 0))
  end

  def confirm_gateway_delivery
    folder = N.new(@route)
    folder.keys("request").each do |key|
      folder.write_once("delivery", key, {"schema" => N::SCHEMA, "kind" => "delivery",
        "key" => key, "state" => "delivered", "message_ids" => ["10"]})
    end
  end

  # Regression (ii): a question event flows through hermes_native exactly like
  # a report for a matching panel recipient — same route outcome, published
  # frame per event, gateway confirmation turns both into delivered.
  def test_question_event_sends_through_native_exactly_like_a_report
    question_event = question
    report_event = report

    question_result = send_event(question_event.id)
    report_result = send_event(report_event.id)

    assert_equal :unavailable, question_result.status
    assert_equal report_result.status, question_result.status
    assert_includes question_result.detail, "queued"
    assert_includes report_result.detail, "queued"

    frames = N.new(@route).keys("request")
      .map { |key| N.new(@route).read("request", key) }
    assert_equal %w[question report], frames.map { |frame| frame["event_type"] }.sort
    by_case = frames.to_h { |frame| [frame["origin"]["case_id"], frame] }
    assert_equal({"machine" => "lab", "panel" => "ace"}, by_case.fetch(question_event.id)["recipient"])
    assert_equal by_case.fetch(question_event.id)["recipient"], by_case.fetch(report_event.id)["recipient"]
    # Questions carry the reply address binding the answer to the exact case.
    assert_equal({"machine" => "lab", "folder" => @root, "id" => question_event.id},
      by_case.fetch(question_event.id)["reply_to"])
    refute by_case.fetch(report_event.id)["reply_to"]

    confirm_gateway_delivery
    question_redelivered = send_event(question_event.id, force: true)
    report_redelivered = send_event(report_event.id, force: true)
    assert_equal :delivered, question_redelivered.status
    assert_equal :delivered, report_redelivered.status
    assert_includes question_redelivered.detail, "delivered"
  end

  # Regression (iii): a genuine recipient mismatch must still refuse closed —
  # with the CORRECT error class, not a NameError.
  def test_genuine_recipient_mismatch_refuses_closed_with_contract_error
    # The route's recipients resolve to captain's address, but the route is
    # configured for a different channel: selection matches, delivery refuses.
    misrouted = @route.merge("channel" => "review")
    config = @config.merge("hitl" => @config["hitl"].merge("adapters" => {"routes" => [misrouted]}))
    event = question

    result = send_event(event.id, config: config)

    assert_equal :failed, result.status
    assert_includes result.detail, "native Hermes recipient differs from the configured channel"
    refute_includes result.detail, "NameError"
    assert_empty Dir.children(@folder), "nothing may be published for a refused recipient"
  end

  # Legacy recipient-less events keep the fail-closed refusal on the native
  # transport: an event without a declared destination is never published.
  def test_legacy_recipient_less_question_refuses_closed
    event = owner.create("Legacy pending question", kind: "decision", questions: ["Proceed?"],
      time: Time.utc(2026, 10, 23, 12, 2, 0))
    assert_nil event.recipient

    result = send_event(event.id)

    assert_equal :failed, result.status
    assert_includes result.detail, "native Hermes recipient differs from the configured channel"
    refute_includes result.detail, "NameError"
    assert_empty Dir.children(@folder)
  end

  # The 2026-10-23 host hit: the route's channel folder exists but is not
  # private. The contract failure must surface as Hermes ContractError with
  # its real message — never as NameError masking it.
  def test_non_private_route_folder_reports_contract_error_not_nameerror
    operator_folder = File.join(@tmp, "hitl-address", "operator")
    FileUtils.mkdir_p(operator_folder, mode: 0o755)
    operator_route = @route.merge("route" => "operator", "channel" => "operator",
      "recipients" => ["operator"], "folder" => operator_folder)
    config = @config.merge("hitl" => @config["hitl"].merge(
      "recipients" => @config["hitl"]["recipients"].merge("operator" => {"machine" => "lab", "panel" => "operator"}),
      "adapters" => {"routes" => [@route, operator_route]}))
    operator_owner = owner(@config.merge("hitl" => @config["hitl"].merge(
      "recipients" => @config["hitl"]["recipients"].merge("operator" => {"machine" => "lab", "panel" => "operator"}))))
    event = operator_owner.create("Work done", to: "operator", type: "report", result: "success",
      body: ["done"], time: Time.utc(2026, 10, 23, 12, 1, 0))

    result = send_event(event.id, config: config)

    assert_equal :failed, result.status
    assert_includes result.detail, "Ace::Hitl::Hermes::ContractError"
    assert_includes result.detail, "native Hermes folder must be real, private, and owned by the non-root user"
    refute_includes result.detail, "NameError"
  end

  # Route validation itself raises the Hermes contract error class.
  def test_invalid_native_route_raises_hermes_contract_error
    error = assert_raises(H::Hermes::ContractError) do
      N.new(@route.merge("channel" => "BAD TOKEN!"))
    end
    assert_includes error.message, "native Hermes route requires project, channel and machine tokens"
  end

  # Regression (i): in the live loading order — ace-hitl alone, the adapter
  # entrypoint loaded lazily by the registry — a native contract failure
  # raises Ace::Hitl::Hermes::ContractError. Before the require-chain fix the
  # raised class was NameError, masking the real failure.
  def test_live_entrypoint_loading_raises_hermes_contract_error_not_nameerror
    bad_folder = File.join(@tmp, "hitl-address", "operator")
    FileUtils.mkdir_p(bad_folder, mode: 0o755)
    script = File.join(@tmp, "live_loading_check.rb")
    File.write(script, <<~RUBY)
      require "ace/hitl"
      # The live CLI condition: the Hermes namespace (and its errors) must NOT
      # be preloaded when the registry lazily loads the adapter entrypoint.
      abort "precondition broken: errors already loaded" if defined?(Ace::Hitl::Hermes::ContractError)

      route = JSON.parse(ENV.fetch("NATIVE_ROUTE"))
      event = Ace::Hitl::Models::HitlEvent.new(id: "8xhk91", type: "question", metadata: {})

      # Adapter-level contract failure (recipient differs): the adapter's own
      # rescue must catch the Hermes contract error and report it.
      adapter = Ace::Hitl::Adapters.resolve(:hermes_native, route: route)
      result = adapter.deliver(event: event, text: "t",
        recipient: {"machine" => "lab", "panel" => "elsewhere"}, reply_to: nil)
      puts "RESULT \#{result.status} \#{result.detail}"

      # Construction-level contract failure (folder not private): the raised
      # class must be Ace::Hitl::Hermes::ContractError.
      begin
        Ace::Hitl::Adapters.resolve(:hermes_native, route: route.merge("folder" => ENV.fetch("NATIVE_BAD_FOLDER")))
        puts "NO-RAISE"
      rescue => e
        puts "RAISED \#{e.class}"
      end
    RUBY
    libs = %w[ace-hitl ace-hitl-hermes ace-hitl-contract ace-support-core ace-support-items ace-support-fs ace-support-config]
      .map { |package| File.expand_path("../../../..", __dir__) + "/#{package}/lib" }
      .select { |path| Dir.exist?(path) }
      .flat_map { |path| ["-I", path] }
    out, err, status = Open3.capture3(
      {"NATIVE_ROUTE" => JSON.generate(@route), "NATIVE_BAD_FOLDER" => bad_folder,
       "BUNDLE_GEMFILE" => nil, "RUBYOPT" => nil, "RUBYLIB" => nil},
      RbConfig.ruby, *libs, script)
    assert status.success?, "child failed:\n#{out}#{err}"
    assert_includes out, "RESULT failed native Hermes recipient differs from the configured channel"
    assert_includes out, "RAISED Ace::Hitl::Hermes::ContractError"
    refute_includes out, "NameError"
    refute_includes out, "NO-RAISE"
  end
end
