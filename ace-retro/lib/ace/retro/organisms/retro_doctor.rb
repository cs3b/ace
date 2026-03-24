# frozen_string_literal: true

require_relative "../molecules/retro_scanner"
require_relative "../molecules/retro_loader"
require_relative "../molecules/retro_frontmatter_validator"
require_relative "../molecules/retro_structure_validator"
require_relative "../atoms/retro_validation_rules"

module Ace
  module Retro
    module Organisms
      # Orchestrates comprehensive health checks for the retros system.
      # Runs structure validation, frontmatter validation, and scope/status
      # consistency checks across all retros in a root directory.
      class RetroDoctor
        attr_reader :root_path, :options

        # @param root_path [String] Path to retros root directory
        # @param options [Hash] Diagnosis options (:check, :verbose, etc.)
        def initialize(root_path, options = {})
          @root_path = root_path
          @options = options
          @issues = []
          @stats = {
            retros_scanned: 0,
            folders_checked: 0,
            errors: 0,
            warnings: 0,
            info: 0
          }
        end

        # Run comprehensive health check
        # @return [Hash] Diagnosis results
        def run_diagnosis
          unless @root_path && Dir.exist?(@root_path)
            return {
              valid: false,
              health_score: 0,
              issues: [{type: :error, message: "Retros root directory not found: #{@root_path}"}],
              stats: @stats,
              duration: 0,
              root_path: @root_path
            }
          end

          @start_time = Time.now

          if options[:check]
            run_specific_check(options[:check])
          else
            run_full_check
          end

          health_score = calculate_health_score

          {
            valid: @stats[:errors] == 0,
            health_score: health_score,
            issues: @issues,
            stats: @stats,
            duration: Time.now - @start_time,
            root_path: @root_path
          }
        end

        # Check if an issue can be auto-fixed
        # @param issue [Hash] Issue to check
        # @return [Boolean]
        def auto_fixable?(issue)
          return false unless issue[:type] == :error || issue[:type] == :warning

          Molecules::RetroDoctorFixer::FIXABLE_PATTERNS.any? { |pattern| issue[:message].match?(pattern) }
        end

        private

        def run_full_check
          run_structure_check
          run_frontmatter_check
          run_scope_check
        end

        def run_specific_check(check_type)
          case check_type.to_s
          when "structure"
            run_structure_check
          when "frontmatter"
            run_frontmatter_check
          when "scope"
            run_scope_check
          else
            add_issue(:error, "Unknown check type: #{check_type}")
          end
        end

        def run_structure_check
          validator = Molecules::RetroStructureValidator.new(@root_path)
          issues = validator.validate

          issues.each do |issue|
            add_issue(issue[:type], issue[:message], issue[:location])
          end

          @stats[:folders_checked] = count_retro_folders
        end

        def run_frontmatter_check
          scanner = Molecules::RetroScanner.new(@root_path)
          return unless scanner.root_exists?

          scan_results = scanner.scan
          @stats[:retros_scanned] = scan_results.size

          scan_results.each do |scan_result|
            spec_file = scan_result.file_path
            next unless spec_file && File.exist?(spec_file)

            issues = Molecules::RetroFrontmatterValidator.validate(
              spec_file,
              special_folder: scan_result.special_folder
            )

            # Filter out scope issues (handled separately in run_scope_check)
            issues.reject! { |i| scope_issue?(i[:message]) }

            issues.each do |issue|
              add_issue(issue[:type], issue[:message], issue[:location])
            end
          end
        end

        def run_scope_check
          scanner = Molecules::RetroScanner.new(@root_path)
          return unless scanner.root_exists?

          scan_results = scanner.scan

          scan_results.each do |scan_result|
            spec_file = scan_result.file_path
            next unless spec_file && File.exist?(spec_file)

            content = File.read(spec_file)
            frontmatter, _body = Ace::Support::Items::Atoms::FrontmatterParser.parse(content)
            next unless frontmatter.is_a?(Hash)

            status = frontmatter["status"]
            special_folder = scan_result.special_folder

            scope_issues = Atoms::RetroValidationRules.scope_consistent?(status, special_folder)
            scope_issues.each do |issue|
              add_issue(issue[:type], issue[:message], spec_file)
            end
          end
        end

        def scope_issue?(message)
          message.include?("not in _archive") ||
            message.include?("in _archive/ but status")
        end

        def count_retro_folders
          return 0 unless Dir.exist?(@root_path)

          count = 0
          Dir.glob(File.join(@root_path, "*")).each do |path|
            next unless File.directory?(path)

            count += if File.basename(path).start_with?("_")
              Dir.glob(File.join(path, "*")).count { |p| File.directory?(p) }
            else
              1
            end
          end
          count
        end

        def add_issue(type, message, location = nil)
          issue = {type: type, message: message}
          issue[:location] = location if location
          @issues << issue

          case type
          when :error then @stats[:errors] += 1
          when :warning then @stats[:warnings] += 1
          when :info then @stats[:info] += 1
          end
        end

        def calculate_health_score
          score = 100
          score -= @stats[:errors] * 10
          score -= @stats[:warnings] * 2
          [[score, 0].max, 100].min
        end
      end
    end
  end
end
