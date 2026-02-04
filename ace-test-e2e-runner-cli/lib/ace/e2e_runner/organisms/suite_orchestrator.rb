# frozen_string_literal: true

require "thread"
require "time"

module Ace
  module E2eRunner
    module Organisms
      class SuiteOrchestrator
        def initialize(config_loader: Molecules::ConfigLoader.new)
          @config_loader = config_loader
        end

        def run(options: {})
          config = @config_loader.load(options[:config])
          config = @config_loader.merge_with_options(config, options).to_h

          discoverer = Atoms::TestDiscoverer.new
          frontmatter = Atoms::FrontmatterParser.new
          executor = Molecules::TestExecutor.new(config)
          formatter = build_formatter(config, options)

          test_paths = discoverer.find_all_tests
          return { results: [], report_dir: nil, status: :no_tests } if test_paths.empty?

          scenarios = test_paths.map { |path| build_scenario(path, frontmatter) }

          if options[:dry_run]
            return { results: scenarios, report_dir: nil, status: :dry_run }
          end

          formatter.on_start(scenarios.length) if formatter

          max_parallel = config[:execution][:max_parallel].to_i
          max_parallel = 1 if max_parallel <= 0
          max_parallel = options[:parallel].to_i if options[:parallel]

          results = if max_parallel > 1
                      run_parallel(scenarios, executor, max_parallel, formatter)
                    else
                      scenarios.map do |scenario|
                        formatter.on_test_start(scenario.id, scenario.package) if formatter
                        executor.execute(scenario)
                      end
                    end

          report_dir = write_reports(results, config)
          results.each do |result|
            formatter.on_test_complete(
              result.test_id,
              result.status,
              result.duration,
              report_dir ? File.join(report_dir, result.test_id.to_s, "summary.r.md") : nil
            ) if formatter
          end
          status = results.all?(&:success?) ? :passed : :failed
          summary = build_summary(results)
          formatter.on_finish(summary) if formatter

          { results: results, report_dir: report_dir, status: status }
        end

        private

        def run_parallel(scenarios, executor, max_parallel, formatter)
          queue = Queue.new
          scenarios.each { |scenario| queue << scenario }

          results = []
          results_mutex = Mutex.new

          workers = Array.new(max_parallel) do
            Thread.new do
              until queue.empty?
                scenario = queue.pop(true) rescue nil
                next unless scenario

                formatter.on_test_start(scenario.id, scenario.package) if formatter
                result = executor.execute(scenario)
                results_mutex.synchronize { results << result }
              end
            end
          end

          workers.each(&:join)
          results
        end

        def build_scenario(path, frontmatter_parser)
          content = File.read(path)
          frontmatter = frontmatter_parser.parse(content)
          body = frontmatter_parser.strip(content)

          id = frontmatter["test-id"] || frontmatter[:test_id] || extract_test_id(path)
          title = frontmatter["title"] || frontmatter[:title]
          area = frontmatter["area"] || frontmatter[:area]
          package = frontmatter["package"] || frontmatter[:package] || extract_package(path)

          Models::TestScenario.new(
            id: id,
            title: title,
            area: area,
            package: package,
            path: path,
            content: body,
            frontmatter: frontmatter
          )
        end

        def extract_test_id(path)
          File.basename(path).split("-").first(3).join("-")
        end

        def extract_package(path)
          path.split(File::SEPARATOR).first
        end

        def write_reports(results, config)
          timestamp = Time.now.utc.strftime("%Y%m%d-%H%M%S")
          report_dir = config[:defaults][:report_dir] || ".cache/ace-test-e2e"
          writer = Molecules::ReportWriter.new(report_dir: report_dir, timestamp: timestamp)
          writer.write_all(results)
        end

        def build_formatter(config, options)
          format = config[:defaults][:format] || "progress"
          formatter_class = Atoms::LazyLoader.load_formatter(format)
          formatter_class.new(options)
        rescue StandardError
          nil
        end

        def build_summary(results)
          {
            total: results.length,
            passed: results.count(&:success?),
            failed: results.count(&:failure?)
          }
        end
      end
    end
  end
end
