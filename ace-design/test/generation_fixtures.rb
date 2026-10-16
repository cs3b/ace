# frozen_string_literal: true
require_relative "test_helper"
require "timeout"
module GenerationFixtures
  class CodingAgent
    attr_reader :calls, :peak
    attr_accessor :failure, :change_shared, :gate
    def initialize
      @calls, @mutex, @active, @peak = [], Mutex.new, 0, 0
    end
    def validate_model(*)
    end
    def call(model:, prompt:, workspace:, **)
      id = File.basename(File.dirname(workspace))
      @mutex.synchronize do
        @calls << {id: id, model: model, prompt: prompt, workspace: workspace}
        @active += 1
        @peak = [@peak, @active].max
      end
      if id == "preparation"
        fixture = File.join(workspace, "fixtures.json")
        File.write(fixture, '{"title":"Shared title","rows":[1,2,3]}') unless File.exist?(fixture)
        specs = JSON.parse(prompt.split("Variant instructions:\n", 2).last.split("\nOutput only", 2).first)
        File.write(File.join(workspace, "directions.json"), JSON.generate(specs.to_h { |s| [s.fetch("id"), "Direction #{s['id']}"] }))
      else
        @gate&.call(id)
        raise "Worker #{id} failed" if failure == id
        File.write(File.join(workspace, "fixtures.json"), '{}') if change_shared == id
        dir = File.join(workspace, "variants", id)
        FileUtils.mkdir_p(dir)
        File.write(File.join(dir, "index.html"), "<h1>#{id}: #{calls.count { |c| c[:id] == id }}</h1><script>fetch('../../fixtures.json')</script>")
        File.write(File.join(dir, "direction.md"), "Working mockup #{id}")
      end
      {"execution" => {"status" => "succeeded", "provider" => "fixture-cli", "model" => model}, "usage" => {"output_tokens" => 20}}
    ensure
      @mutex.synchronize { @active -= 1 }
    end
  end
  def with_runner
    Dir.mktmpdir("design-runner") do |base|
      config = Ace::Design.config.merge("run_root" => File.join(base, "runs"))
      agent = CodingAgent.new
      runner = Ace::Design::Organisms::Generator.new(config: config, executor: agent)
      def runner.prepare(**options)
        controller = Ace::Design::Organisms::DesignRun.method(:new)
        paused = lambda do |*args, **kwargs|
          run = controller.call(*args, **kwargs)
          def run.resume; status; end
          run
        end
        Ace::Design::Organisms::DesignRun.stub(:new, paused) { generate(**options) }
      end
      yield runner, agent, base
    end
  end
  def controller(root, agent)
    Ace::Design::Organisms::DesignRun.new(root, executor: agent)
  end
  def hashes(root)
    %w[a b c].to_h { |id| [id, Ace::Design::Molecules::Artifacts.digest(File.join(root, "variants", id))] }
  end
end
