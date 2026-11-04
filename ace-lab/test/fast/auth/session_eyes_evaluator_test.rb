# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/lab/auth/session_eyes_evaluator"

module Ace::Lab::Auth
  class SessionEyesEvaluatorTest < Minitest::Test
    Result = Struct.new(:stdout, :status, :oversized)
    Status = Struct.new(:success?)

    def setup
      @root = Dir.mktmpdir
      @helper = File.join(@root, "gems", "ace-overseer-0.28.2", "libexec", "eyes-ready")
      FileUtils.mkdir_p(File.dirname(@helper))
      File.write(@helper, "installed helper")
      @document = {"gemset" => {"gem_home" => @root}, "session_runtime" => {
        "path" => ["/usr/bin"], "herdr" => {"socket" => "/run/lab/herdr.sock"}}}
      @response = Result.new('{"ready":true}', Status.new(true), false)
      @calls, @verified = [], []
      @evaluator = SessionEyesEvaluator.new(loader: -> { @document },
        verify: ->(path, **options) { @verified << [path, options] },
        runner: ->(argv, **options) { @calls << [argv, options]; @response }, ruby: "/opt/ruby/bin/ruby")
      @file = File.open(@helper, File::RDONLY)
    end

    def teardown
      @file.close
      FileUtils.remove_entry(@root)
    end

    def test_uses_fixed_installed_owner_with_read_only_descriptor_and_clean_environment
      context = {"terminal_id" => "term_1234"}
      assert @evaluator.call(context, file: @file)
      argv, options = @calls.fetch(0)
      assert_equal ["/opt/ruby/bin/ruby", @helper], argv
      assert_equal({3 => @file}, options.fetch(:descriptor_mapping))
      assert_equal context, JSON.parse(options.fetch(:stdin_data))
      assert_equal "installed", options.dig(:environment, "ACE_TOOLCHAIN")
      assert_equal "/", options[:chdir]
      assert_equal 10, options[:timeout_s]
      assert options[:cleanup_group]
      refute options[:environment].key?("RUBYLIB")
      refute options[:environment].key?("BUNDLE_GEMFILE")
    end

    def test_missing_or_ambiguous_owner_never_falls_back_to_checkout
      FileUtils.mkdir_p(File.join(@root, "gems", "ace-overseer-0.28.3"))
      assert_raises(Error) { @evaluator.call({}, file: @file) }
      assert_empty @calls
      FileUtils.remove_entry(File.join(@root, "gems"))
      assert_raises(Error) { @evaluator.call({}, file: @file) }
      assert_empty @calls
    end

    def test_evaluator_failure_and_nonboolean_response_are_not_ready
      [Result.new('{"ready":true}', Status.new(false), false),
        Result.new('{"ready":true}', Status.new(true), true),
        Result.new('{"ready":"true"}', Status.new(true), false),
        Result.new('{"ready":true,"session":"private"}', Status.new(true), false)].each do |response|
        @response = response
        assert_raises(Error) { @evaluator.call({}, file: @file) }
      end
      @response = Result.new('{"ready":false}', Status.new(true), false)
      refute @evaluator.call({}, file: @file)
    end
  end
end
