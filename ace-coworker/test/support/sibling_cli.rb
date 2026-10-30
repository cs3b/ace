# frozen_string_literal: true

require "stringio"
require "ace/assign"

# Performance helper (test/optimize): runs sibling-package CLIs in
# this process through the exact CLI.start entry the binstub uses,
# minus the per-invocation Ruby/bundler boot (~0.7s each). Reserved
# for choreography (fixture state the test drives but does not
# assert on): the package under test always runs as a real
# subprocess through its binstub.
module SiblingCli
  module_function

  # Open3::Status-compatible result for assertions.
  Status = Struct.new(:exitstatus) do
    def success?
      exitstatus.zero?
    end
  end

  # call(cli, "start", ..., chdir: dir) -> [stdout, stderr, status]
  # cli is a callable taking an argv array, e.g.
  # ->(argv) { Ace::Assign::CLI.start(argv) }
  def call(cli, argv, chdir: Dir.pwd)
    out = StringIO.new
    err = StringIO.new
    previous_out, previous_err = $stdout, $stderr
    exit_code = 0
    begin
      Dir.chdir(chdir) do
        $stdout = out
        $stderr = err
        # A subprocess would start with empty config state; replicate
        # that: clear the cached project root and drop the thread-local
        # config test mode/mock (set by AceTestCase) so the sibling CLI
        # resolves real fixture configuration like the binstub would.
        Ace::Support::Config.reset! if defined?(Ace::Support::Config) && Ace::Support::Config.respond_to?(:reset!)
        test_mode_key = :ace_config_test_mode
        mock_key = :ace_config_default_mock
        saved_mode = Thread.current[test_mode_key]
        saved_mock = Thread.current[mock_key]
        Thread.current[test_mode_key] = nil
        Thread.current[mock_key] = nil
        begin
          code = cli.call(argv)
          exit_code = code.nil? ? 0 : code
        rescue Ace::Support::Cli::Error => e
          err.puts e.message
          exit_code = e.exit_code
        ensure
          Thread.current[test_mode_key] = saved_mode
          Thread.current[mock_key] = saved_mock
        end
      end
    ensure
      $stdout = previous_out
      $stderr = previous_err
    end
    [out.string, err.string, Status.new(exit_code)]
  end

  def run_assign(*argv, chdir: Dir.pwd)
    call(->(args) { Ace::Assign::CLI.start(args) }, argv, chdir: chdir)
  end
end
