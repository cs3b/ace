# frozen_string_literal: true
require_relative "../test_helper"
require "ace/runtime/molecules/readiness_runtime"

class ReadinessRuntimeTest < AceRuntimeTestCase
  Runtime = Ace::Runtime::Molecules::ReadinessRuntime
  Reader = Struct.new(:seen) do
    def with
      yield self
    end
    def read!(ref)
      seen << ref.fetch("path")
      "verified bytes"
    end
    def verify_unchanged! = true
  end

  def owner
    @reader = Reader.new([])
    config = {"runtime" => {"load_paths" => ["/fixed/lib"], "interpreter_path" => "/fixed/ruby",
      "dependencies" => [{"path" => "/fixed/lib/json.rb", "sha256" => "a" * 64, "bytes" => 1}]}}
    Runtime.new(configuration: config, artifacts: @reader)
  end

  def test_requires_exact_declared_file_and_authenticates_initial_features
    runtime = owner
    assert_equal "/fixed/lib/json.rb", runtime.resolve!("json")
    assert runtime.verify_loaded!(["enumerator.so", "/fixed/lib/json.rb"])
    assert_equal ["/fixed/lib/json.rb"], @reader.seen
  end

  def test_platform_extension_alias_selects_only_declared_interpreter_extension
    %w[bundle so].each do |extension|
      selected = "/fixed/lib/pathname.#{extension}"
      reader = Reader.new([])
      runtime = Runtime.new(configuration: {"runtime" => {"load_paths" => ["/fixed/lib"],
        "dependencies" => [{"path" => selected, "sha256" => "b" * 64, "bytes" => 1}]}}, artifacts: reader)
      RbConfig::CONFIG.stub(:fetch, extension) do
        %w[pathname pathname.so pathname.o].each { |feature| assert_equal selected, runtime.resolve!(feature) }
        assert_equal selected, runtime.resolve!(selected)
        assert runtime.verify_file!(runtime.resolve!("pathname.so"))
      end
      assert_equal [selected], reader.seen
    end
  end

  def test_platform_extension_never_uses_undeclared_or_other_suffix
    runtime = Runtime.new(configuration: {"runtime" => {"load_paths" => ["/fixed/lib"],
      "dependencies" => [{"path" => "/fixed/lib/pathname.so", "sha256" => "b" * 64, "bytes" => 1}]}}, artifacts: Reader.new([]))
    RbConfig::CONFIG.stub(:fetch, "bundle") do
      %w[pathname pathname.so pathname.o /home/worker/pathname.so].each do |feature|
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { runtime.resolve!(feature) }
      end
    end
  end

  def activate_without_kernel_patch(runtime, features)
    guard = nil
    Ace::Runtime::Molecules::ProtectedSocket.stub(:root_path!, nil) do
      Kernel.stub(:prepend, ->(selected) { guard = selected }) { runtime.activate!(features: features, load_paths: []) }
    end
    guard
  end

  def test_only_initially_verified_builtin_spelling_or_bare_alias_is_a_noop
    runtime = owner
    refute runtime.builtin_loaded?("thread")
    activate_without_kernel_patch(runtime, ["thread.rb"])
    assert runtime.builtin_loaded?("thread")
    assert runtime.builtin_loaded?("thread.rb")
    ["thread.so", "./thread", "../thread", "/fixed/lib/thread.rb", "fiber", nil].each do |feature|
      refute runtime.builtin_loaded?(feature)
    end
    # Re-activation verifies later files but cannot grow initialized authority.
    activate_without_kernel_patch(runtime, ["thread.rb", "fiber.so"])
    refute runtime.builtin_loaded?("fiber")
    assert_empty @reader.seen
  end

  def test_actual_guard_returns_false_without_delegation_for_initialized_builtin
    runtime = owner
    guard = activate_without_kernel_patch(runtime, ["thread.rb"])
    calls = []
    controlled = Class.new do
      define_method(:require) { |feature| calls << feature; true }
    end
    controlled.prepend(guard)
    receiver = controlled.new
    assert_equal false, receiver.send(:require, "thread")
    assert_equal false, receiver.send(:require, "thread.rb")
    assert_empty calls
    assert_raises(Ace::Runtime::RuntimeUnavailableError) { receiver.send(:require, "fiber") }
    assert_empty calls
    assert receiver.send(:require, "json")
    assert_equal ["/fixed/lib/json.rb"], calls
    assert_equal ["/fixed/lib/json.rb"], @reader.seen
  end

  def test_bare_builtin_collision_does_not_exempt_an_absolute_declared_file
    runtime = Runtime.new(configuration: {"runtime" => {"load_paths" => ["/fixed/lib"],
      "dependencies" => [{"path" => "/fixed/lib/thread.rb", "sha256" => "b" * 64, "bytes" => 1}]}}, artifacts: Reader.new([]))
    activate_without_kernel_patch(runtime, ["thread.rb"])
    assert runtime.builtin_loaded?("thread")
    refute runtime.builtin_loaded?("/fixed/lib/thread.rb")
    assert_equal "/fixed/lib/thread.rb", runtime.resolve!("/fixed/lib/thread.rb")
  end

  def test_undeclared_home_gem_or_relative_load_never_authorizes_code
    runtime = owner
    ["/home/worker/.gem/json.rb", "./json.rb", "../../writable/json", "unlisted"].each do |feature|
      assert_raises(Ace::Runtime::RuntimeUnavailableError) { runtime.resolve!(feature) }
    end
    assert_raises(Ace::Runtime::RuntimeUnavailableError) { runtime.verify_loaded!(["/home/worker/.gem/json.rb"]) }
    assert_empty @reader.seen
  end
end
