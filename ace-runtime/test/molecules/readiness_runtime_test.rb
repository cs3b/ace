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

  def test_undeclared_home_gem_or_relative_load_never_authorizes_code
    runtime = owner
    ["/home/worker/.gem/json.rb", "./json.rb", "../../writable/json", "unlisted"].each do |feature|
      assert_raises(Ace::Runtime::RuntimeUnavailableError) { runtime.resolve!(feature) }
    end
    assert_raises(Ace::Runtime::RuntimeUnavailableError) { runtime.verify_loaded!(["/home/worker/.gem/json.rb"]) }
    assert_empty @reader.seen
  end
end
