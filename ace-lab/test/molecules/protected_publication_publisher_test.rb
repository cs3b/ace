# frozen_string_literal: true
require_relative "../test_helper"
require "ace/lab/molecules/protected_publication_publisher"

class ProtectedPublicationPublisherTest < Minitest::Test
  Publisher = Ace::Lab::Molecules::ProtectedPublicationPublisher

  def publication
    {"gem_name" => "ace-hitl", "version" => "1.2.3", "registry" => "https://rubygems.org"}
  end

  def registry(status, body)
    response = Net::HTTPResponse::CODE_TO_OBJ.fetch(status).new("1.1", status, "fixture")
    response.instance_variable_set(:@read, true)
    response.body = body
    response.define_singleton_method(:read_body) { |&block| block.call(body) }
    connection = Object.new
    %i[use_ssl= open_timeout= read_timeout= write_timeout= max_retries=].each { |method| connection.define_singleton_method(method) { |_| } }
    connection.define_singleton_method(:start) { |&block| block.call(connection) }
    connection.define_singleton_method(:request) do |request, &block|
      raise "unexpected registry path" unless request.path == "/api/v2/rubygems/ace-hitl/versions/1.2.3.json?platform=ruby"
      block.call(response)
    end
    factory = Object.new
    factory.define_singleton_method(:new) do |host, port, proxy|
      raise "untrusted endpoint" unless [host, port, proxy] == ["rubygems.org", 443, nil]
      connection
    end
    Publisher.new(http: factory)
  end

  def verify(owner)
    owner.verify!(publication: publication, artifact_digest: "b" * 64, platform: "ruby",
      deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5)
  end

  def test_exact_artifact_not_merely_existing_version
    value = {"name" => "ace-hitl", "version" => "1.2.3", "platform" => "ruby", "sha" => "b" * 64, "yanked" => false}
    assert_equal "succeeded", verify(registry("200", JSON.generate(value))).fetch("classification")
    assert_equal "failed", verify(registry("200", JSON.generate(value.merge("sha" => "c" * 64)))).fetch("classification")
    assert_equal "uncertain", verify(registry("200", JSON.generate(value.except("sha")))).fetch("classification")
    assert_equal "uncertain", verify(registry("200", JSON.generate(value.merge("platform" => "java")))).fetch("classification")
    assert_equal "uncertain", verify(registry("200", JSON.generate(value.merge("yanked" => true)))).fetch("classification")
  end

  def test_absence_and_untrusted_responses_never_approve_or_push
    assert_equal "absent", verify(registry("404", "missing")).fetch("classification")
    assert_equal "uncertain", verify(registry("302", "redirect")).fetch("classification")
    assert_equal "uncertain", verify(registry("200", "x" * 65_537)).fetch("classification")
    assert_equal "uncertain", verify(registry("200", '{"name":"a","name":"b"}')).fetch("classification")
  end

  def test_otp_only_enters_immediate_environment_not_argv_or_stdin
    calls = []
    process = Object.new
    process.define_singleton_method(:call) do |argv, **options|
      calls << [argv, options.dup]
      Struct.new(:status, :stdout, :oversized).new(Struct.new(:success?).new(true),
        JSON.generate("classification" => "otp-rejected", "code" => "provider_rejected_before_acceptance"), false)
    end
    secret = (1..6).to_a.join
    operation = {"executor_uid" => Process.uid, "argv" => ["selected-publisher", "--scoped-publication"]}
    owner = Publisher.new(process: process)
    result = owner.push!(operation: operation, publication: publication, artifact: "/owned/exact.gem",
      artifact_digest: "b" * 64, otp: secret, deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5)
    assert_equal "otp-rejected", result.fetch("classification")
    refute_includes calls.first.first.join, secret
    refute_includes calls.first.last.fetch(:stdin_data), secret
    refute_includes JSON.generate(result), secret
    # The caller's environment map is emptied after child return.
    refute calls.first.last.fetch(:environment).key?("GEM_HOST_OTP_CODE")
    assert_equal 1, calls.size
  end
end
