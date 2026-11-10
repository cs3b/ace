# frozen_string_literal: true

require_relative "../test_helper"
require "open3"
require "rbconfig"

class ProtectedDependencyLoadingTest < AceRuntimeTestCase
  CASES = {
    "protected_socket" => 'Ace::Runtime::Molecules::ProtectedSocket.root_path!("relative")',
    "protected_linux" => 'identity = Object.new; def identity.capture(*) = nil; Ace::Runtime::Molecules::ProtectedLinux.new(identity: identity).capture(1)',
    "systemd_scope_manager" => 'manager = Ace::Runtime::Molecules::SystemdScopeManager.new(slice_unit: "ace.slice", service_unit: "ace.service", command: ->(*) { "" }); manager.inspect_units'
  }.freeze

  CASES.each do |leaf, operation|
    define_method("test_#{leaf}_loads_its_typed_failure_dependency") do
      script = <<~RUBY
        require "ace/runtime/molecules/#{leaf}"
        begin
          #{operation}
        rescue StandardError => error
          abort "unexpected error: \#{error.class}: \#{error.message}" unless
            error.class.name == "Ace::Runtime::RuntimeUnavailableError"
          exit 0
        end
        abort "unsafe operation did not fail"
      RUBY
      out, err, status = Open3.capture3({"RUBYOPT" => nil}, RbConfig.ruby,
        "-I", File.expand_path("../../lib", __dir__), "-e", script)
      assert status.success?, "#{leaf}: #{out}#{err}"
    end
  end
end
