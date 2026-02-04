# frozen_string_literal: true

require "time"

module Ace
  module E2eRunner
    module Organisms
      class TestOrchestrator
        def initialize(config_loader: Molecules::ConfigLoader.new)
          @config_loader = config_loader
        end

        def run(package:, test_id: nil, options: {})
          config = @config_loader.load(options[:config])
          config = @config_loader.merge_with_options(config, options).to_h

          discoverer = Atoms::TestDiscoverer.new
          frontmatter = Atoms::FrontmatterParser.new
          executor = Molecules::TestExecutor.new(config)

          test_paths = discoverer.find_tests(package: package, test_id: test_id)
          return { results: [], report_dir: nil, status: :no_tests } if test_paths.empty?

          scenarios = test_paths.map { |path| build_scenario(path, frontmatter) }

          if options[:dry_run]
            return { results: scenarios, report_dir: nil, status: :dry_run }
          end

          results = scenarios.map { |scenario| executor.execute(scenario) }

          report_dir = write_reports(results, config)
          status = results.all?(&:success?) ? :passed : :failed

          { results: results, report_dir: report_dir, status: status }
        end

        def run_affected(packages:, options: {})
          results = []
          report_dirs = []

          packages.each do |package|
            outcome = run(package: package, options: options)
            results.concat(outcome[:results]) if outcome[:results]
            report_dirs << outcome[:report_dir] if outcome[:report_dir]
          end

          status = results.all?(&:success?) ? :passed : :failed
          { results: results, report_dir: report_dirs.compact.last, status: status }
        end

        private

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
      end
    end
  end
end
