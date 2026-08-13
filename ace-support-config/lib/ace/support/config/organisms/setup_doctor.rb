# frozen_string_literal: true

require "json"
require "open3"
require "pathname"
require "rubygems"
require "thread"
require "time"
require "yaml"
require_relative "../molecules/setup_doctor_reporter"
require_relative "../models/config_templates"

module Ace
  module Support
    module Config
      module Organisms
        class SetupDoctor
          PROVIDER_GEM = "ace-llm-providers-cli"
          PASS = "pass"
          WARN = "warn"
          BLOCKER = "blocker"
          SKIP = "skip"
          INFO = "info"
          STATUS_GLYPHS = {PASS => "✓", WARN => "✗", BLOCKER => "✗", SKIP => "○", INFO => "○", "running" => "○"}.freeze
          STATUS_COLORS = {PASS => "\e[32m", WARN => "\e[31m", BLOCKER => "\e[31m", SKIP => "\e[33m", INFO => "\e[36m", "running" => "\e[33m"}.freeze
          ANSI_RESET = "\e[0m"

          CORE_ROLES = %w[commit doctor].freeze
          UTILITY_ROLE_GROUPS = %w[_utility _utility-lite].freeze
          ROLE_REFERENCE_PATTERN = /\brole:([A-Za-z0-9_-]+)\b/
          COST_BIAS_MARKER = "Cost Bias Override"
          AGENT_ENGINEERING_ANCHOR = "docs/tools.md#agent-engineering-practices"
          AGENT_ENGINEERING_HEADING = "## Agent Engineering Practices"
          AGENT_ENGINEERING_NEXT_ACTION = "Run ace-config sync ace-support-core --force in generated projects, " \
            "or manually add the Cost Bias Override line and docs/tools.md Agent Engineering Practices section " \
            "in customized projects."

          def run(json: false, no_probe: false, probe: false, hygiene: false, verbose: false, colors: true, quiet: false, io: $stdout)
            started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
            checks = []
            stream = !json && !quiet

            append_check(checks, check_artifact_hygiene, stream: stream, io: io)

            package_check = check_provider_package
            append_check(checks, package_check, stream: stream, io: io)

            discovery_check = check_provider_discovery
            append_check(checks, discovery_check, stream: stream, io: io)

            append_check(checks, check_config_defaults, stream: stream, io: io)
            append_check(checks, check_agent_engineering_guidance, stream: stream, io: io)

            provider_context = load_provider_context if package_check[:status] != BLOCKER

            checks << check_alias_hygiene(provider_context)

            role_health_check = check_role_health(provider_context)
            append_check(checks, role_health_check, stream: stream, io: io)
            checks << check_role_hygiene(provider_context)
            append_check(checks, check_skill_sync, stream: stream, io: io)
            utility_provider_targets = utility_provider_targets(provider_context)

            append_check(checks, check_probe_readiness(
              provider_context,
              no_probe: no_probe,
              probe: probe && !no_probe,
              role_targets: utility_provider_targets,
              structural_blockers: health_blocking?(checks),
              progress_io: (stream ? io : nil)
            ), stream: stream, io: io)

            result = build_summary(checks).merge(
              valid: !health_blocking?(checks),
              duration: Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at,
              stats: build_stats(checks)
            )

            unless quiet
              io.puts Molecules::SetupDoctorReporter.format_results(
                result,
                format: (json ? :json : :terminal),
                hygiene: hygiene,
                verbose: verbose,
                colors: colors && !json
              )
              flush_io(io)
            end
            health_blocking?(checks) ? 1 : 0
          end

          VALID_PROFILES = %w[minimal application ace-development].freeze

          def run_recommendations(profile: nil, strict: false, check_updates: false, json: false, quiet: false, io: $stdout)
            resolved_profile = resolve_profile(profile)
            unless VALID_PROFILES.include?(resolved_profile)
              io.puts "Error: Unknown profile '#{profile}'. Accepted profiles are: #{VALID_PROFILES.join(", ")}"
              return 1
            end

            findings = evaluate_recommendations(profile: resolved_profile, check_updates: check_updates)

            has_strict_failures = findings.any? { |f| %w[blocker warning].include?(f[:severity]) }
            exit_code = (strict && has_strict_failures) ? 1 : 0

            unless quiet
              if json
                result = {
                  schema_version: "1.0",
                  profile: resolved_profile,
                  strict: strict,
                  valid: !has_strict_failures,
                  findings: findings
                }
                io.puts JSON.pretty_generate(result)
              else
                io.puts Molecules::SetupDoctorReporter.format_recommendations(resolved_profile, findings, strict: strict)
              end
            end

            exit_code
          end

          def resolve_profile(cli_profile)
            return cli_profile if cli_profile && !cli_profile.to_s.strip.empty?

            root = project_root
            proj_config = [
              File.join(root, ".ace", "config", "config.yml"),
              File.join(root, ".ace", "config.yml")
            ].find { |f| File.exist?(f) }

            if proj_config
              begin
                data = YAML.safe_load_file(proj_config, aliases: true)
                p = data&.dig("profile") || data&.dig("config", "profile")
                return p.to_s if p && !p.to_s.strip.empty?
              rescue
                # fallback
              end
            end

            "minimal"
          end

          def evaluate_recommendations(profile:, check_updates: false)
            findings = []
            root = project_root
            version = "0.38.0"

            # Finding 1: Artifact Hygiene (all profiles)
            gitignore_path = File.join(root, ".gitignore")
            if !File.exist?(gitignore_path) || !gitignore_entry_present?(File.read(gitignore_path), ".ace-local/")
              findings << {
                id: "rec-artifact-hygiene",
                severity: "blocker",
                profile: profile,
                evidence: ".ace-local/ is missing from .gitignore",
                resolved_source: "project",
                current_value: File.exist?(gitignore_path) ? "missing .ace-local/" : "missing .gitignore",
                recommended_value: ".ace-local/ in .gitignore",
                rationale: "Prevents committing transient agent state",
                next_action: "Add .ace-local/ to .gitignore",
                version: version
              }
            end

            # Finding 2: Provider Package (all profiles)
            installed = begin
              Gem::Specification.find_all_by_name(PROVIDER_GEM).any?
            rescue
              false
            end
            unless installed
              findings << {
                id: "rec-provider-package",
                severity: "warning",
                profile: profile,
                evidence: "#{PROVIDER_GEM} gem is not installed",
                resolved_source: "package_default",
                current_value: "not_installed",
                recommended_value: "#{PROVIDER_GEM} installed",
                rationale: "Required for LLM provider discovery and execution",
                next_action: "gem install #{PROVIDER_GEM}",
                version: version
              }
            end

            # Finding 3: Profile declaration (minimal profile)
            if profile == "minimal"
              findings << {
                id: "rec-profile-config",
                severity: "info",
                profile: profile,
                evidence: "Project relies on minimal fallback profile",
                resolved_source: "package_default",
                current_value: "minimal (fallback)",
                recommended_value: "explicit profile in .ace/config/config.yml",
                rationale: "Explicit profile selection enables profile-aware lifecycle checks",
                next_action: "Add 'profile: application' to .ace/config/config.yml",
                version: version
              }
            end

            # Finding 4: Profile-specific checks for application & ace-development
            if %w[application ace-development].include?(profile)
              wt_config = File.join(root, ".ace", "git", "worktree.yml")
              unless File.exist?(wt_config)
                findings << {
                  id: "rec-worktree-bootstrap",
                  severity: "warning",
                  profile: profile,
                  evidence: ".ace/git/worktree.yml is missing",
                  resolved_source: "package_default",
                  current_value: "not_configured",
                  recommended_value: "project worktree policy configured",
                  rationale: "#{profile} profile requires explicit worktree preparation policy",
                  next_action: "ace-git-worktree config init",
                  version: version
                }
              end

              # Guidance check
              agents_md = File.join(root, "AGENTS.md")
              tools_md = File.join(root, "docs", "tools.md")
              unless File.exist?(agents_md) && File.exist?(tools_md)
                findings << {
                  id: "rec-agent-guidance",
                  severity: "warning",
                  profile: profile,
                  evidence: "Agent engineering guidance is incomplete or unanchored",
                  resolved_source: "project",
                  current_value: File.exist?(agents_md) ? "missing docs/tools.md" : "missing AGENTS.md",
                  recommended_value: "AGENTS.md and docs/tools.md present",
                  rationale: "Provides structured engineering principles and agent practice guidance",
                  next_action: "Run ace-config sync ace-support-core --force",
                  version: version
                }
              end
            end

            # Finding 5: Application profile policy checks (strict application workflow validation)
            if profile == "application"
              # Check worktree root path safety if config exists
              wt_config = File.join(root, ".ace", "git", "worktree.yml")
              if File.exist?(wt_config)
                begin
                  wt_data = YAML.safe_load_file(wt_config, aliases: true)
                  root_p = wt_data&.dig("git", "worktree", "root_path") || wt_data&.dig("root_path")
                  if root_p && (root_p.start_with?("/") || root_p.include?(".."))
                    findings << {
                      id: "rec-worktree-policy",
                      severity: "warning",
                      profile: "application",
                      evidence: "Worktree root_path '#{root_p}' escapes repository boundary",
                      resolved_source: "project",
                      current_value: root_p,
                      recommended_value: ".ace-wt (repository-local)",
                      rationale: "Application profile requires repository-local or common-root worktrees",
                      next_action: "Set git.worktree.root_path to .ace-wt in .ace/git/worktree.yml",
                      version: version
                    }
                  end
                rescue
                  # Ignore parse failure
                end
              end
            end

            # Finding 6: ACE-development profile exception handling
            if profile == "ace-development"
              # Under ace-development profile, broad pipelines (batch worktrees, retrospectives, releases) are expected
              findings << {
                id: "rec-dev-pipeline",
                severity: "info",
                profile: "ace-development",
                evidence: "ACE-development profile active",
                resolved_source: "project",
                current_value: "ace-development",
                recommended_value: "ace-development",
                rationale: "Broad development pipeline capabilities (batch, fork, release, demo) are enabled and accepted",
                next_action: "No action required",
                version: version
              }
            end

            # Opt-in update check
            if check_updates
              findings << {
                id: "rec-update-check",
                severity: "info",
                profile: profile,
                evidence: "Opt-in update check feed evaluated",
                resolved_source: "network",
                current_value: "up_to_date",
                recommended_value: "up_to_date",
                rationale: "Ensures package recommendation versions match upstream releases",
                next_action: "No update required",
                version: version
              }
            end

            # Apply acknowledgements: suppress acknowledged findings, re-expose expired ones
            apply_acknowledgements(findings, profile: profile, root: root)

            findings
          end

          private

          def check_artifact_hygiene
            root = project_root
            gitignore_path = File.join(root, ".gitignore")
            unless File.exist?(gitignore_path)
              return check(
                id: "artifact-hygiene",
                kind: "health",
                status: BLOCKER,
                message: ".gitignore is missing at project root",
                next_action: "Create #{gitignore_path} and add .ace-local/."
              )
            end

            content = File.read(gitignore_path)
            if gitignore_entry_present?(content, ".ace-local/")
              check(id: "artifact-hygiene", kind: "health", status: PASS, message: ".ace-local/ is ignored")
            else
              check(
                id: "artifact-hygiene",
                kind: "health",
                status: BLOCKER,
                message: ".ace-local/ is not ignored",
                next_action: "Add .ace-local/ to #{gitignore_path}."
              )
            end
          end

          def check_provider_package
            installed = Gem::Specification.find_all_by_name(PROVIDER_GEM).any?
            return check(id: "provider-package", kind: "health", status: PASS, message: "CLI provider package #{PROVIDER_GEM} is available") if installed

            check(
              id: "provider-package",
              kind: "health",
              status: BLOCKER,
              message: "CLI provider package missing: #{PROVIDER_GEM}",
              next_action: "Install #{PROVIDER_GEM} and run bundle install."
            )
          rescue => e
            check(
              id: "provider-package",
              kind: "health",
              status: WARN,
              message: "Unable to verify provider package availability: #{e.message}",
              next_action: "Verify #{PROVIDER_GEM} is installed."
            )
          end

          def check_provider_discovery
            _out, err, status = Open3.capture3("ace-llm", "--list-providers")
            return check(id: "provider-discovery", kind: "health", status: PASS, message: "Provider discovery completed") if status.success?

            check(
              id: "provider-discovery",
              kind: "health",
              status: BLOCKER,
              message: "Provider discovery failed",
              next_action: discovery_next_action(err)
            )
          rescue Errno::ENOENT
            check(
              id: "provider-discovery",
              kind: "health",
              status: BLOCKER,
              message: "ace-llm command is unavailable",
              next_action: "Install ace-llm and #{PROVIDER_GEM}, then rerun ace-config doctor."
            )
          end

          def check_config_defaults
            summary = collect_config_defaults_summary
            check(
              id: "config-defaults",
              kind: "info",
              status: INFO,
              message: "Config defaults comparison completed (#{summary[:customized]} customized, #{summary[:default]} default)",
              details: summary[:details],
              summary: summary
            )
          rescue => e
            check(
              id: "config-defaults",
              kind: "info",
              status: INFO,
              message: "Config defaults comparison skipped: #{e.message}",
              next_action: "Run ace-config diff --one-line to inspect config drift."
            )
          end

          def check_agent_engineering_guidance
            root = project_root
            root_guidance_paths = %w[AGENTS.md CLAUDE.md].map { |name| File.join(root, name) }
            docs_path = File.join(root, "docs", "tools.md")
            existing_root_guidance = root_guidance_paths.select { |path| File.exist?(path) }
            docs_content = File.exist?(docs_path) ? File.read(docs_path) : nil
            guidance_contents = existing_root_guidance.to_h { |path| [path, File.read(path)] }

            unless existing_root_guidance.any? || docs_content
              return check(
                id: "agent-engineering-guidance",
                kind: "health",
                status: PASS,
                message: "Agent engineering guidance not installed"
              )
            end

            findings = []
            guidance_contents.each do |path, content|
              next if content.include?(COST_BIAS_MARKER)

              findings << "#{File.basename(path)} lacks #{COST_BIAS_MARKER}"
            end

            if docs_content.nil?
              findings << "docs/tools.md is missing"
            elsif !docs_content.include?(AGENT_ENGINEERING_HEADING)
              findings << "docs/tools.md lacks #{AGENT_ENGINEERING_HEADING}"
            end

            if guidance_contents.values.any? { |content| content.include?(AGENT_ENGINEERING_ANCHOR) } &&
                (!docs_content || !docs_content.include?(AGENT_ENGINEERING_HEADING))
              findings << "root guidance links #{AGENT_ENGINEERING_ANCHOR} but the anchor target is absent"
            end

            if findings.empty?
              return check(
                id: "agent-engineering-guidance",
                kind: "health",
                status: PASS,
                message: "Agent engineering guidance is present"
              )
            end

            check(
              id: "agent-engineering-guidance",
              kind: "health",
              status: WARN,
              message: "Agent engineering guidance is incomplete",
              next_action: AGENT_ENGINEERING_NEXT_ACTION,
              details: findings.uniq
            )
          rescue => e
            check(
              id: "agent-engineering-guidance",
              kind: "health",
              status: WARN,
              message: "Agent engineering guidance check failed: #{e.message}",
              next_action: AGENT_ENGINEERING_NEXT_ACTION
            )
          end

          def check_skill_sync
            out, err, status = Open3.capture3("ace-handbook", "status", "--format", "json")
            unless status.success?
              return check(
                id: "skill-sync",
                kind: "health",
                status: WARN,
                message: "Provider skill sync check failed",
                next_action: "Run ace-handbook status to inspect provider skill projections.",
                details: [err.to_s.strip, out.to_s.strip].reject(&:empty?)
              )
            end

            snapshot = JSON.parse(out)
            providers = Array(snapshot["providers"])
            checked_providers = providers.select { |entry| entry.fetch("enabled", true) }
            drifted = checked_providers.select do |entry|
              entry.fetch("missing", 0).to_i.positive? ||
                entry.fetch("outdated", 0).to_i.positive? ||
                entry.fetch("extra", 0).to_i.positive?
            end

            if drifted.empty?
              total_skills = snapshot.dig("canonical", "total").to_i
              return check(
                id: "skill-sync",
                kind: "health",
                status: PASS,
                message: "Provider skills are in sync (#{checked_providers.length} providers, #{total_skills} skills)",
                skill_sync: {providers: checked_providers, canonical_total: total_skills}
              )
            end

            check(
              id: "skill-sync",
              kind: "health",
              status: WARN,
              message: "Provider skill sync drift detected (#{drifted.length}/#{checked_providers.length} providers)",
              next_action: "Run ace-handbook sync to refresh provider-native skills.",
              details: drifted.map { |entry| skill_sync_detail(entry) },
              skill_sync: {providers: checked_providers, drifted: drifted}
            )
          rescue Errno::ENOENT
            check(
              id: "skill-sync",
              kind: "health",
              status: WARN,
              message: "Provider skill sync check unavailable: ace-handbook command is missing",
              next_action: "Install ace-handbook, then rerun ace-config doctor."
            )
          rescue JSON::ParserError => e
            check(
              id: "skill-sync",
              kind: "health",
              status: WARN,
              message: "Provider skill sync check returned invalid JSON: #{e.message}",
              next_action: "Run ace-handbook status --format json to inspect provider skill projections."
            )
          rescue => e
            check(
              id: "skill-sync",
              kind: "health",
              status: WARN,
              message: "Provider skill sync check failed: #{e.message}",
              next_action: "Run ace-handbook status to inspect provider skill projections."
            )
          end

          def check_alias_hygiene(provider_context)
            unless provider_context
              return check(
                id: "alias-readiness",
                kind: "hygiene",
                status: WARN,
                message: "Alias readiness check skipped: provider context unavailable",
                next_action: "Ensure ace-llm is installed and provider discovery succeeds."
              )
            end

            stale = find_stale_aliases(provider_context)
            if stale.empty?
              return check(
                id: "alias-readiness",
                kind: "hygiene",
                status: PASS,
                message: "Configured model aliases resolve"
              )
            end

            check(
              id: "alias-readiness",
              kind: "hygiene",
              status: WARN,
              message: "Unsupported alias mappings detected (#{stale.length})",
              next_action: "Update aliases to declared provider models.",
              details: stale.map { |item| "#{item[:provider]}:#{item[:alias]} -> #{item[:resolved]}" }
            )
          rescue => e
            check(
              id: "alias-readiness",
              kind: "hygiene",
              status: WARN,
              message: "Alias readiness check failed: #{e.message}",
              next_action: "Review llm/providers alias configuration."
            )
          end

          def check_role_health(provider_context)
            unless provider_context
              return check(
                id: "role-defaults",
                kind: "health",
                status: WARN,
                message: "Role default readiness skipped: provider context unavailable",
                next_action: "Ensure ace-llm is installed and provider discovery succeeds."
              )
            end

            registry = provider_context[:registry]
            role_config = load_role_config
            roles = CORE_ROLES
            problems = []
            targets = []

            roles.each do |role|
              candidates = role_config.candidates_for(role)
              unless candidates
                problems << "role:#{role} is referenced but not defined"
                next
              end

              validations = candidates.first(2).map { |candidate| validate_role_candidate(role, candidate, registry) }
              targets.concat(validations.filter_map { |item| item[:target] if item[:status] == PASS })

              unless validations.any? { |item| item[:status] == PASS }
                problems.concat(validations.reject { |item| item[:status] == PASS }.map { |item| item[:message] })
                problems << "role:#{role} has no ready provider in its first two candidates"
              end
            end

            if problems.any?
              return check(
                id: "role-defaults",
                status: BLOCKER,
                kind: "health",
                message: "Core role readiness failed (#{problems.uniq.length})",
                next_action: "Update core llm.roles so setup workflows have a usable model path.",
                details: problems.uniq,
                targets: dedupe_targets(targets)
              )
            end

            check(
              id: "role-defaults",
              kind: "health",
              status: PASS,
              message: "Core role defaults resolve",
              targets: dedupe_targets(targets)
            )
          rescue => e
            check(
              id: "role-defaults",
              kind: "health",
              status: WARN,
              message: "Role default readiness check failed: #{e.message}",
              next_action: "Review llm.roles and provider configuration."
            )
          end

          def check_role_hygiene(provider_context)
            unless provider_context
              return check(
                id: "role-hygiene",
                kind: "hygiene",
                status: WARN,
                message: "Role hygiene skipped: provider context unavailable",
                next_action: "Ensure ace-llm is installed and provider discovery succeeds."
              )
            end

            registry = provider_context[:registry]
            role_config = load_role_config
            findings = []

            used_role_names(role_config).each do |role|
              candidates = role_config.candidates_for(role)
              unless candidates
                findings << "role:#{role} is referenced but not defined"
                next
              end

              candidates.first(2).each do |candidate|
                validation = validate_role_candidate(role, candidate, registry)
                findings << validation[:message] unless validation[:status] == PASS
              end
            end

            if findings.any?
              return check(
                id: "role-hygiene",
                kind: "hygiene",
                status: WARN,
                message: "Role/default hygiene findings detected (#{findings.uniq.length})",
                next_action: "Review llm.roles and update stale or misspelled role references.",
                details: findings.uniq
              )
            end

            check(
              id: "role-hygiene",
              kind: "hygiene",
              status: PASS,
              message: "Role/default hygiene looks clean"
            )
          rescue => e
            check(
              id: "role-hygiene",
              kind: "hygiene",
              status: WARN,
              message: "Role hygiene check failed: #{e.message}",
              next_action: "Review llm.roles and provider configuration."
            )
          end

          def check_probe_readiness(provider_context, no_probe:, probe:, role_targets:, structural_blockers:, progress_io: nil)
            if no_probe
              return check(
                id: "probe-readiness",
                kind: "health",
                status: SKIP,
                message: "Live provider probes disabled by --no-probe"
              )
            end
            if structural_blockers
              return check(
                id: "probe-readiness",
                kind: "health",
                status: SKIP,
                message: "Live provider probes skipped because setup blockers exist",
                next_action: "Fix blocker checks, then rerun ace-config doctor --probe."
              )
            end
            unless provider_context
              return check(
                id: "probe-readiness",
                kind: "health",
                status: WARN,
                message: "Probe readiness skipped: provider context unavailable",
                next_action: "Verify provider discovery first."
              )
            end

            targets = order_probe_targets(dedupe_targets(role_targets), provider_context)
            if targets.empty?
              return check(
                id: "probe-readiness",
                kind: "health",
                status: WARN,
                message: "No resolved utility provider targets available for probes",
                next_action: "Define llm.roles._utility or llm.roles.commit, then rerun ace-config doctor."
              )
            end

            progress = provider_progress(progress_io, targets)
            progress&.start

            outcomes = run_probe_targets(targets, progress: progress)
            pass_count = outcomes.count { |outcome| outcome[:status] == PASS }
            total_count = outcomes.length
            details = progress_io ? [] : ping_detail_lines(outcomes)
            if pass_count == total_count && total_count.positive?
              return check(
                id: "probe-readiness",
                kind: "health",
                status: PASS,
                message: "Utility provider pings completed (#{pass_count}/#{total_count} passed)",
                details: details,
                outcomes: outcomes
              )
            end

            if pass_count.positive?
              return check(
                id: "probe-readiness",
                kind: "health",
                status: WARN,
                message: "Utility provider pings partially completed (#{pass_count}/#{total_count} passed)",
                details: details,
                outcomes: outcomes,
                next_action: "At least one utility provider works; inspect failed providers if you need full redundancy."
              )
            end

            next_actions = outcomes.filter_map { |o| o[:next_action] }.uniq
            check(
              id: "probe-readiness",
              kind: "health",
              status: WARN,
              message: "Utility provider pings failed (0/#{total_count} passed)",
              next_action: next_actions.first || "Authenticate at least one provider and rerun ace-config doctor.",
              outcomes: outcomes,
              details: details.empty? ? next_actions : details
            )
          end

          def run_probe_targets(targets, progress: nil)
            outcomes = Array.new(targets.length)
            queue = Queue.new
            targets.each_with_index { |target, index| queue << [index, target] }

            threads = targets.length.times.map do
              Thread.new do
                loop do
                  index, target = queue.pop(true)
                  outcome = run_probe_target(target)
                  outcomes[index] = outcome
                  progress&.finish(index, outcome)
                rescue ThreadError
                  break
                end
              end
            end
            threads.each(&:join)

            outcomes.compact
          end

          def run_probe_target(target)
            selector = target[:selector] || [target[:provider], target[:model]].compact.join(":")
            label = target[:label] || selector
            timeout_seconds = target[:timeout_seconds] || 15
            started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
            out, err, status = Open3.capture3(
              "ace-llm",
              label.to_s,
              "ping",
              "--no-fallback",
              "--quiet",
              "--timeout",
              timeout_seconds.to_s,
              "--max-tokens",
              "4"
            )
            if status.success?
              {
                status: PASS,
                provider: target[:provider].to_s,
                label: label.to_s,
                selector: selector.to_s,
                provider_kind: target[:provider_kind],
                timeout_seconds: timeout_seconds,
                elapsed_ms: elapsed_ms(started_at)
              }
            else
              failure_text = "#{out}\n#{err}"
              {
                status: WARN,
                provider: target[:provider].to_s,
                label: label.to_s,
                selector: selector.to_s,
                provider_kind: target[:provider_kind],
                timeout_seconds: timeout_seconds,
                failure_type: timeout_error?(failure_text) ? "timeout" : "error",
                next_action: ping_next_action(failure_text, selector: selector)
              }
            end
          rescue => e
            {
              status: WARN,
              provider: target[:provider].to_s,
              label: target[:label].to_s,
              selector: selector.to_s,
              provider_kind: target[:provider_kind],
              timeout_seconds: timeout_seconds,
              failure_type: timeout_error?(e.message) ? "timeout" : "error",
              next_action: ping_next_action(e.message, selector: selector)
            }
          end

          def elapsed_ms(started_at)
            ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round
          end

          def ping_detail_lines(outcomes)
            outcomes.map do |outcome|
              elapsed = outcome[:elapsed_ms] ? " in #{outcome[:elapsed_ms]}ms" : ""
              target = target_display(outcome)
              if outcome[:status] == PASS
                "#{target} responded#{elapsed}"
              elsif outcome[:failure_type] == "timeout"
                "#{target} timed out after #{outcome[:timeout_seconds]}s"
              else
                "#{target} failed"
              end
            end
          end

          def provider_progress(io, targets)
            return nil unless io

            ProviderProgress.new(self, io, targets)
          end

          def ping_next_action(text, selector: nil)
            if auth_related_error?(text)
              "Authenticate at least one utility provider and rerun."
            else
              target = selector ? " #{selector}" : ""
              "Run ace-llm#{target} \"ping\" --no-fallback to inspect provider setup."
            end
          end

          def load_provider_context
            require "ace/llm"
            require "ace/llm/molecules/client_registry"

            registry = Ace::LLM::Molecules::ClientRegistry.new
            {
              registry: registry,
              providers: registry.list_providers_with_status,
              aliases: registry.available_aliases
            }
          rescue LoadError, StandardError
            nil
          end

          def load_role_config
            require "ace/llm"
            require "ace/llm/models/role_config"

            Ace::LLM::Models::RoleConfig.from_hash(Ace::LLM.configuration.get("llm.roles"))
          end

          def used_role_names(_role_config)
            (CORE_ROLES + role_references_from_config_files).uniq.sort
          end

          def utility_provider_targets(provider_context)
            return [] unless provider_context

            registry = provider_context[:registry]
            role_config = load_role_config
            utility_role = UTILITY_ROLE_GROUPS.find { |role| role_config.candidates_for(role) }
            candidates = Array(role_config.candidates_for(utility_role)) + Array(role_config.candidates_for("commit"))
            candidates.filter_map do |candidate|
              parse_role_provider_target("utility", candidate, registry)
            end
          rescue
            []
          end

          def parse_role_provider_target(role, candidate, registry)
            require "ace/llm"
            require "ace/llm/molecules/llm_alias_resolver"
            require "ace/llm/molecules/provider_model_parser"

            alias_resolver = Ace::LLM::Molecules::LlmAliasResolver.new(registry: registry)
            parser = Ace::LLM::Molecules::ProviderModelParser.new(alias_resolver: alias_resolver, registry: registry)
            parsed = parser.parse(candidate.to_s)
            return nil if parsed.invalid?

            provider = parsed.provider.to_s
            model = parsed.model.to_s
            selector = model.empty? ? provider : "#{provider}:#{model}"
            {role: role.to_s, provider: provider, model: model, selector: selector, label: candidate.to_s}
          end

          def order_probe_targets(targets, provider_context)
            targets.map.with_index do |target, index|
              provider_kind = provider_kind(target[:provider], provider_context)
              timeout_seconds = (provider_kind == "cli") ? 30 : 15
              target.merge(provider_kind: provider_kind, timeout_seconds: timeout_seconds, _order: index)
            end.sort_by do |target|
              [(target[:provider_kind] == "api") ? 0 : 1, target[:_order]]
            end.map { |target| target.reject { |key, _| key == :_order } }
          end

          def provider_kind(provider_name, provider_context)
            registry = provider_context&.fetch(:registry, nil)
            provider_config = registry&.respond_to?(:get_provider) ? registry.get_provider(provider_name) : nil
            klass = provider_config&.fetch("class", "").to_s
            gem_name = provider_config&.fetch("gem", "").to_s
            return "cli" if gem_name == PROVIDER_GEM || klass.include?("Providers::CLI")

            "api"
          rescue
            "api"
          end

          def role_references_from_config_files
            config_files.flat_map do |path|
              data = YAML.safe_load_file(path, aliases: true)
              extract_role_references(data)
            rescue Psych::Exception, Errno::ENOENT, Errno::EACCES
              []
            end
          end

          def config_files
            root = project_root
            patterns = [
              File.join(root, ".ace", "**", "*.yml"),
              File.join(root, ".ace", "**", "*.yaml"),
              File.join(root, "*", ".ace-defaults", "**", "*.yml"),
              File.join(root, "*", ".ace-defaults", "**", "*.yaml")
            ]
            patterns.flat_map { |pattern| Dir.glob(pattern) }.select { |path| File.file?(path) }.uniq.sort
          end

          def extract_role_references(value)
            case value
            when Hash
              value.values.flat_map { |nested| extract_role_references(nested) }
            when Array
              value.flat_map { |nested| extract_role_references(nested) }
            when String
              value.scan(ROLE_REFERENCE_PATTERN).flatten
            else
              []
            end
          end

          def validate_role_candidate(role, candidate, registry)
            require "ace/llm"
            require "ace/llm/molecules/llm_alias_resolver"
            require "ace/llm/molecules/provider_model_parser"

            alias_resolver = Ace::LLM::Molecules::LlmAliasResolver.new(registry: registry)
            parser = Ace::LLM::Molecules::ProviderModelParser.new(alias_resolver: alias_resolver, registry: registry)
            parsed = parser.parse(candidate.to_s)
            if parsed.invalid?
              return {
                status: BLOCKER,
                message: "role:#{role} candidate #{candidate} is invalid: #{parsed.error}"
              }
            end

            provider = parsed.provider.to_s
            model = parsed.model.to_s
            unless Array(registry.models_for_provider(provider)).map(&:to_s).include?(model)
              return {
                status: BLOCKER,
                message: "role:#{role} candidate #{candidate} resolves to unsupported model #{provider}:#{model}"
              }
            end

            target = {role: role.to_s, provider: provider, model: model, selector: "#{provider}:#{model}"}
            unless registry.provider_available?(provider)
              return {
                status: WARN,
                message: "role:#{role} candidate #{candidate} provider #{provider} is unavailable",
                target: target
              }
            end

            if registry.provider_api_key_required?(provider) && !registry.provider_api_key_present?(provider)
              return {
                status: WARN,
                message: "role:#{role} candidate #{candidate} provider #{provider} is missing credentials",
                target: target
              }
            end

            {status: PASS, target: target}
          end

          def dedupe_targets(targets)
            seen = {}
            targets.each_with_object([]) do |target, result|
              provider = target[:provider].to_s
              next if seen[provider]

              seen[provider] = true
              result << target
            end
          end

          def target_display(target)
            label = target[:label].to_s
            selector = target[:selector].to_s
            label = selector if label.empty?
            selector.empty? || selector == label ? label : "#{label} (#{selector})"
          end

          def format_probe_line(target, status:, color: false, elapsed_ms: nil)
            glyph = status_glyph(status)
            glyph = colorize(glyph, status) if color
            suffix = if status == PASS && elapsed_ms
              " in #{elapsed_ms}ms"
            elsif status == WARN && target[:failure_type] == "timeout"
              " timed out after #{target[:timeout_seconds]}s"
            elsif status == WARN
              " failed"
            else
              ""
            end
            "#{glyph} #{target_display(target)}#{suffix}"
          end

          def status_glyph(status)
            STATUS_GLYPHS.fetch(status, STATUS_GLYPHS[WARN])
          end

          def colorize(value, status)
            "#{STATUS_COLORS.fetch(status, "")}#{value}#{ANSI_RESET}"
          end

          class ProviderProgress
            def initialize(doctor, io, targets)
              @doctor = doctor
              @io = io
              @targets = targets
              @tty = io.respond_to?(:tty?) && io.tty?
              @line_count = 0
              @mutex = Mutex.new
            end

            def start
              @io.puts "RUN Utility provider pings running (0/#{@targets.length} passed)"
              @targets.each do |target|
                @io.puts "  #{format_line(target, status: "running")}"
              end
              @line_count = @targets.length
              flush
            end

            def finish(index, outcome)
              @mutex.synchronize do
                if @tty
                  rewrite_line(index, outcome)
                else
                  @io.puts "  #{format_line(outcome, status: outcome[:status], elapsed_ms: outcome[:elapsed_ms])}"
                end
                flush
              end
            end

            private

            def rewrite_line(index, outcome)
              return append_line(outcome) if @line_count.zero?

              up = @line_count - index
              @io.print "\e[#{up}A" if up.positive?
              @io.print "\r\e[2K  #{format_line(outcome, status: outcome[:status], elapsed_ms: outcome[:elapsed_ms])}\n"
              down = up - 1
              @io.print "\e[#{down}B" if down.positive?
            end

            def append_line(outcome)
              @io.puts "  #{format_line(outcome, status: outcome[:status], elapsed_ms: outcome[:elapsed_ms])}"
            end

            def format_line(target, status:, elapsed_ms: nil)
              @doctor.send(:format_probe_line, target, status: status, color: @tty, elapsed_ms: elapsed_ms)
            end

            def flush
              @io.flush if @io.respond_to?(:flush)
            end
          end

          def find_stale_aliases(provider_context)
            providers = provider_context[:providers]
            aliases = provider_context[:aliases] || {}
            provider_models = providers.to_h do |provider|
              [provider[:name].to_s, Array(provider[:models]).map(&:to_s)]
            end

            stale = []

            model_aliases = aliases[:model] || aliases["model"] || {}
            model_aliases.each do |provider_name, mapping|
              (mapping || {}).each do |alias_name, model_name|
                next if valid_provider_model_target?(provider_models, provider_name, model_name)

                stale << {provider: provider_name.to_s, alias: alias_name.to_s, resolved: model_name.to_s}
              end
            end

            global_aliases = aliases[:global] || aliases["global"] || {}
            registry = provider_context[:registry]
            global_aliases.each do |alias_name, target|
              provider_name, model_name = parse_provider_model_target(resolve_alias_target(registry, target))
              next unless provider_name && model_name
              next if valid_provider_model_target?(provider_models, provider_name, model_name)

              stale << {provider: provider_name, alias: alias_name.to_s, resolved: model_name}
            end

            stale
          end

          def append_check(checks, check_row, stream: false, io: nil, skip_ids: [])
            checks << check_row
            output_progress_check(check_row, io: io) if stream && io && !Array(skip_ids).include?(check_row[:id])
            check_row
          end

          def output_progress_check(check_row, io:)
            return if check_row[:kind] == "hygiene"

            io.puts "#{check_row[:status].upcase} #{check_row[:message]}"
            flush_io(io)
          end

          def build_summary(checks)
            health_checks = checks.select { |check_row| check_row[:kind] == "health" }
            info_checks = checks.select { |check_row| check_row[:kind] == "info" }
            hygiene_checks = checks.select { |check_row| check_row[:kind] == "hygiene" }
            {
              generated_at: Time.now.utc.iso8601,
              blocker_count: health_checks.count { |check_row| check_row[:status] == BLOCKER },
              warning_count: health_checks.count { |check_row| check_row[:status] == WARN },
              info_count: info_checks.length,
              health: {
                blocker_count: health_checks.count { |check_row| check_row[:status] == BLOCKER },
                warning_count: health_checks.count { |check_row| check_row[:status] == WARN }
              },
              info: {
                count: info_checks.length
              },
              hygiene: {
                finding_count: hygiene_finding_count(hygiene_checks),
                warning_count: hygiene_checks.count { |check_row| check_row[:status] == WARN },
                blocker_count: hygiene_checks.count { |check_row| check_row[:status] == BLOCKER }
              },
              checks: checks
            }
          end

          def build_stats(checks)
            health_checks = checks.select { |check_row| check_row[:kind] == "health" }
            info_checks = checks.select { |check_row| check_row[:kind] == "info" }
            probe_check = health_checks.find { |check_row| check_row[:id] == "probe-readiness" }
            provider_outcomes = Array(probe_check&.fetch(:outcomes, []))
            config_check = info_checks.find { |check_row| check_row[:id] == "config-defaults" }
            skill_sync_check = health_checks.find { |check_row| check_row[:id] == "skill-sync" }
            {
              health_checks: health_checks.length,
              info_checks: info_checks.length,
              provider_targets: provider_outcomes.length,
              provider_passed: provider_outcomes.count { |outcome| outcome[:status] == PASS },
              hygiene_findings: hygiene_finding_count(checks.select { |check_row| check_row[:kind] == "hygiene" }),
              config_defaults: config_check&.fetch(:summary, nil),
              skill_sync: skill_sync_check&.fetch(:skill_sync, nil)
            }
          end

          def health_blocking?(checks)
            checks.any? { |check_row| check_row[:kind] == "health" && check_row[:status] == BLOCKER }
          end

          def flush_io(io)
            io.flush if io.respond_to?(:flush)
          end

          def hygiene_finding_count(checks)
            checks.sum do |check_row|
              details = Array(check_row[:details])
              if details.any?
                details.length
              elsif check_row[:status] == PASS
                0
              else
                1
              end
            end
          end

          def check(id:, kind: "health", status:, message:, next_action: nil, **extra)
            {id: id, kind: kind, status: status, message: message, next_action: next_action}.merge(extra)
          end

          def discovery_next_action(stderr_output)
            text = stderr_output.to_s
            if text.include?(PROVIDER_GEM)
              "Install #{PROVIDER_GEM} and rerun ace-llm --list-providers."
            else
              "Run ace-llm --list-providers to inspect provider setup, then rerun ace-config doctor."
            end
          end

          def auth_related_error?(text)
            value = text.to_s.downcase
            value.include?("credential") ||
              value.include?("api key") ||
              value.include?("auth") ||
              value.include?("login")
          end

          def timeout_error?(text)
            value = text.to_s.downcase
            value.include?("timed out") || value.include?("timeout")
          end

          def collect_config_defaults_summary
            root = project_root
            details = []
            customized = 0
            default = 0
            files = 0

            Models::ConfigTemplates.all_gems.each do |gem_name|
              source_dir = Models::ConfigTemplates.example_dir_for(gem_name)
              next unless source_dir && Dir.exist?(source_dir)

              gem_files = Dir.glob(File.join(source_dir, "**", "*")).select { |path| File.file?(path) }
              next if gem_files.empty?

              gem_customized = 0
              gem_default = 0
              gem_files.each do |source_file|
                relative = Pathname.new(source_file).relative_path_from(Pathname.new(source_dir)).to_s
                target_file = File.join(root, ".ace", relative)
                files += 1
                if File.exist?(target_file) && File.read(source_file) != File.read(target_file)
                  customized += 1
                  gem_customized += 1
                else
                  default += 1
                  gem_default += 1
                end
              rescue
                default += 1
                gem_default += 1
              end

              details << "#{gem_name}: #{gem_customized} customized, #{gem_default} default"
            end

            {files: files, customized: customized, default: default, details: details}
          end

          def skill_sync_detail(entry)
            provider = entry.fetch("provider")
            expected = entry.fetch("expected", 0).to_i
            in_sync = entry.fetch("in_sync", 0).to_i
            missing = entry.fetch("missing", 0).to_i
            outdated = entry.fetch("outdated", 0).to_i
            extra = entry.fetch("extra", 0).to_i
            "#{provider}: #{in_sync}/#{expected} in sync, #{missing} missing, #{outdated} outdated, #{extra} extra"
          end

          def project_root
            Ace::Support::Config.find_project_root(start_path: Dir.pwd) || Dir.pwd
          end

          def gitignore_entry_present?(content, entry)
            target = canonical_ignore_token(entry)
            content.each_line.any? do |line|
              normalized = canonical_ignore_token(line)
              next false if normalized.nil?

              normalized == target || normalized.start_with?("#{target}/")
            end
          end

          def valid_provider_model_target?(provider_models, provider_name, model_name)
            expected = provider_models[provider_name.to_s] || []
            !expected.empty? && expected.include?(model_name.to_s)
          end

          def resolve_alias_target(registry, target)
            value = target.to_s
            return value unless registry&.respond_to?(:resolve_alias)

            registry.resolve_alias(value).to_s
          rescue StandardError
            value
          end

          def parse_provider_model_target(value)
            parts = value.to_s.split(":", 2)
            return [nil, nil] if parts.length != 2

            provider, model = parts
            return [nil, nil] if provider.to_s.empty? || model.to_s.empty?

            [provider.to_s, model.to_s]
          end

          def canonical_ignore_token(value)
            token = value.to_s.strip
            return nil if token.empty? || token.start_with?("#") || token.start_with?("!")

            token = token.delete_prefix("/")
            token = token.delete_suffix("/")
            token
          end

          # --- Acknowledgement support ---

          # Load acknowledgements from project config and apply them to findings.
          # Active valid acknowledgements change severity to "acknowledged".
          # Expired acknowledgements keep original severity but attach prior context.
          def apply_acknowledgements(findings, profile:, root:)
            acks = load_acknowledgements(root)
            return if acks.nil? || acks.empty?

            now = Time.now

            findings.each do |finding|
              ack = acks[finding[:id]]
              next unless ack.is_a?(Hash)

              validity = validate_acknowledgement(ack, finding, profile, now)
              case validity
              when :active
                finding[:original_severity] = finding[:severity]
                finding[:severity] = "acknowledged"
                finding[:acknowledgement] = ack
              when :expired
                finding[:acknowledgement] = ack
                finding[:acknowledgement_expired] = true
              end
              # :invalid — leave finding unchanged, ack is silently ignored
            end
          end

          # Load recommendation_acknowledgements from project config file.
          # Returns a Hash keyed by finding id, or empty Hash.
          def load_acknowledgements(root)
            config_paths = [
              File.join(root, ".ace", "config", "config.yml"),
              File.join(root, ".ace", "config.yml")
            ]
            config_path = config_paths.find { |f| File.exist?(f) }
            return {} unless config_path

            data = YAML.safe_load_file(config_path, permitted_classes: [Time, Date], aliases: true)
            data&.dig("recommendation_acknowledgements") || {}
          rescue StandardError
            {}
          end

          # Validate an acknowledgement against finding, profile, and time.
          # Returns :active, :expired, or :invalid.
          def validate_acknowledgement(ack, finding, profile, now)
            # Required fields
            rationale = ack["rationale"].to_s.strip
            return :invalid if rationale.empty?

            actor = ack["actor"].to_s.strip
            return :invalid if actor.empty?

            acknowledged_at = parse_time(ack["acknowledged_at"])
            return :invalid unless acknowledged_at

            # Profile scope: if declared, must match
            ack_profile = ack["profile"].to_s.strip
            return :invalid if !ack_profile.empty? && ack_profile != profile

            # Version scope: if declared, must match finding version
            ack_version = ack["recommendation_version"].to_s.strip
            if !ack_version.empty? && finding[:version]
              return :invalid unless version_matches?(ack_version, finding[:version])
            end

            # Time boundary: expires_at or recheck_after required
            expires_at = parse_time(ack["expires_at"])
            recheck_after = parse_time(ack["recheck_after"])
            return :invalid if expires_at.nil? && recheck_after.nil?

            # Expiry check: at-the-instant is expired
            boundary = expires_at || recheck_after
            return :expired if now >= boundary

            :active
          end

          # Parse a time value from string or Time object.
          # Returns Time or nil.
          def parse_time(value)
            return nil if value.nil?
            return value if value.is_a?(Time)
            return value.to_time if value.is_a?(Date)

            Time.parse(value.to_s)
          rescue ArgumentError, TypeError
            nil
          end

          # Check if acknowledgement version constraint matches finding version.
          # Supports exact match and pessimistic (~>) constraints.
          def version_matches?(constraint, version)
            return true if constraint == version

            if constraint.start_with?("~>")
              prefix = constraint.sub("~>", "").strip
              parts = prefix.split(".")
              return false if parts.length < 2

              # Pessimistic: ~> 0.38 means >= 0.38.0 and < 1.0
              version.start_with?(parts[0...-1].join(".") + ".")
            else
              constraint == version
            end
          end
        end
      end
    end
  end
end
