# frozen_string_literal: true
require "test_helper"
require "rbconfig"

class HerdrPrimitiveLoadingTest < Minitest::Test
  def test_primitives_load_errors_without_the_broad_configuration_entrypoint
    %w[ace/assign/organisms/attempt_coordinator ace/herdr/errors ace/herdr/organisms/inbox ace/herdr/molecules/herdr_executor ace/herdr/molecules/native_queue_executor].each do |entry|
      code = <<~RUBY
        require #{entry.inspect}
        abort "missing hierarchy" unless Ace::Herdr::ValidationError < Ace::Herdr::Error && Ace::Herdr::ExecutorError < Ace::Herdr::Error
        abort "broad entry loaded" if $LOADED_FEATURES.any? { |path| path.end_with?("/ace/herdr.rb") }
        abort "configuration loaded" if Ace::Herdr.respond_to?(:config)
        error = Ace::Herdr::TabMaterializationError.new(tab_id: "tab", message: "failed")
        abort "error behavior changed" unless error.tab_id == "tab" && error.message == "failed"
        STDOUT.write("loaded")
      RUBY
      result = Ace::Herdr::Molecules::BoundedProcess.call(
        [RbConfig.ruby, "--disable=gems,rubyopt", "-I", $LOAD_PATH.join(File::PATH_SEPARATOR), "-e", code], timeout_s: 5)
      assert result.status.success?, "#{entry}: #{result.stderr}"
      assert_equal "loaded", result.stdout
      assert_empty result.stderr
    end
  end
end
