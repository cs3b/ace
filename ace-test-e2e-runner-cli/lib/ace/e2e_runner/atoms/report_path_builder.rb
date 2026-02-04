# frozen_string_literal: true

module Ace
  module E2eRunner
    module Atoms
      class ReportPathBuilder
        def initialize(base_dir: ".cache/ace-test-e2e")
          @base_dir = base_dir
        end

        def build(test_id:, package:, run_id:)
          short_pkg = package ? package.sub(/^ace-/, "") : "project"
          short_id = short_test_id(test_id)
          base_name = [run_id, short_pkg, short_id].compact.join("-")

          test_dir = File.join(@base_dir, base_name)
          report_dir = "#{test_dir}-reports"

          {
            run_id: run_id,
            short_pkg: short_pkg,
            short_id: short_id,
            base_name: base_name,
            test_dir: test_dir,
            report_dir: report_dir,
            summary_path: File.join(report_dir, "summary.r.md"),
            experience_path: File.join(report_dir, "experience.r.md"),
            metadata_path: File.join(report_dir, "metadata.yml")
          }
        end

        private

        def short_test_id(test_id)
          return "mt000" unless test_id

          normalized = test_id.downcase
          digits = normalized.scan(/\d+/).join
          digits = digits.rjust(3, "0") if digits.length < 3
          "mt#{digits}"
        end
      end
    end
  end
end
