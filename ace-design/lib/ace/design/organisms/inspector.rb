# frozen_string_literal: true
require "fileutils"
require "securerandom"
module Ace
  module Design
    module Organisms
      class Inspector
        def initialize(config: Design.config, runtime: nil)
          @config = config
          @runtime = runtime || Molecules::Runtime.new(config)
        end
        def run(url:, surface:, out: nil)
          Atoms::Contracts.url(url)
          Atoms::Contracts.surface(surface)
          seconds = Integer(@config.fetch("timeout"))
          raise Error, "timeout must be between 1 and 300 seconds" unless (1..300).cover?(seconds)
          output = File.expand_path(out || File.join(@config.fetch("run_root"), "#{Ace::B36ts.now}-#{SecureRandom.hex(4)}", "inspection"))
          if File.symlink?(output) || (File.exist?(output) && (!File.directory?(output) || !Dir.empty?(output)))
            raise Error, "Inspection output must be new or empty: #{output}"
          end
          FileUtils.mkdir_p(output)
          owned_output = true
          result = @runtime.capture(@runtime.node, @runtime.script("inspect.mjs"), url, surface, output,
            @runtime.directory, seconds.to_s, timeout: seconds * 3 + 30)
          report_path = File.join(output, "report.json")
          raise Error, "Runner produced no report: #{result['stderr']}" unless File.file?(report_path)
          report = JSON.parse(File.read(report_path))
          unless report.is_a?(Hash) && %w[pass findings incomplete].include?(report["status"]) && report["viewports"].is_a?(Array)
            raise Error, "Runner produced an invalid inspection report"
          end
          if report["status"] == "pass" && (report["viewports"].map { |v| v["width"] }.sort != [390, 768, 1440] ||
              !report.fetch("errors", ["missing errors"]).empty? || !report.fetch("findings", ["missing findings"]).empty?)
            raise Error, "Runner pass report lacks complete clean evidence"
          end
          if result["exit_code"] != 0 && report["status"] == "pass"
            raise Error, "Runner failed despite a pass report: #{result['stderr']}"
          end
          report.merge("report_path" => report_path)
        rescue JSON::ParserError => e
          raise Error, "Invalid inspection JSON: #{e.message}"
        rescue Error => e
          if defined?(owned_output) && owned_output && File.directory?(output) && !File.exist?(File.join(output, "report.json"))
            File.write(File.join(output, "error.json"), JSON.pretty_generate({"status" => "incomplete", "error" => e.message}))
          end
          raise
        end
      end
    end
  end
end
