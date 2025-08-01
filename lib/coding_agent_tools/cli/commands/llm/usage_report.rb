# frozen_string_literal: true

require 'dry/cli'
require 'json'
require 'csv'
require 'date'

module CodingAgentTools
  module Cli
    module Commands
      module LLM
        # UsageReport command for analyzing LLM cost and usage data
        class UsageReport < Dry::CLI::Command
          desc 'Generate usage and cost reports from LLM query logs'

          option :format, type: :string, default: 'table',
                          values: %w[table json csv],
                          desc: 'Output format (table, json, csv)'

          option :date_range, type: :string,
                              desc: 'Date range filter (today, week, month, or YYYY-MM-DD:YYYY-MM-DD)'

          option :provider, type: :string,
                            desc: 'Filter by provider (google, anthropic, openai, etc.)'

          option :model, type: :string,
                         desc: 'Filter by specific model'

          option :output, type: :string, aliases: ['o'],
                          desc: 'Output file path (format inferred from extension)'

          option :debug, type: :boolean, default: false, aliases: ['d'],
                         desc: 'Enable debug output for verbose error information'

          example [
            '',
            '--format json',
            '--date-range today',
            '--date-range week',
            '--provider google',
            '--model claude-3-5-sonnet',
            '--output usage-report.csv'
          ]

          def call(**options)
            # For now, create a placeholder implementation
            # In a real implementation, this would read from cache/logs
            generate_sample_report(options)
            0
          rescue StandardError => e
            handle_error(e, options[:debug])
            1
          end

          private

          def generate_sample_report(options)
            sample_data = create_sample_usage_data

            # Apply filters
            filtered_data = apply_filters(sample_data, options)

            # Format and output
            case options[:format]
            when 'json'
              output_json(filtered_data, options)
            when 'csv'
              output_csv(filtered_data, options)
            else
              output_table(filtered_data, options)
            end
          end

          def create_sample_usage_data
            [
              {
                timestamp: '2024-01-01T10:00:00Z',
                provider: 'google',
                model: 'gemini-2.0-flash',
                input_tokens: 1234,
                output_tokens: 567,
                cached_tokens: 0,
                total_cost: 0.001891,
                input_cost: 0.001543,
                output_cost: 0.000348,
                cache_cost: 0.0,
                execution_time: 2.5
              },
              {
                timestamp: '2024-01-01T11:00:00Z',
                provider: 'anthropic',
                model: 'claude-3-5-sonnet',
                input_tokens: 2000,
                output_tokens: 800,
                cached_tokens: 100,
                total_cost: 0.006125,
                input_cost: 0.006000,
                output_cost: 0.004000,
                cache_cost: 0.000125,
                execution_time: 3.2
              },
              {
                timestamp: '2024-01-01T12:00:00Z',
                provider: 'openai',
                model: 'gpt-4o-mini',
                input_tokens: 1500,
                output_tokens: 600,
                cached_tokens: 0,
                total_cost: 0.000585,
                input_cost: 0.000225,
                output_cost: 0.000360,
                cache_cost: 0.0,
                execution_time: 1.8
              }
            ]
          end

          def apply_filters(data, options)
            filtered = data

            filtered = filtered.select { |item| item[:provider] == options[:provider] } if options[:provider]

            filtered = filtered.select { |item| item[:model] == options[:model] } if options[:model]

            filtered = apply_date_filter(filtered, options[:date_range]) if options[:date_range]

            filtered
          end

          def apply_date_filter(data, date_range)
            case date_range
            when 'today'
              today = Date.today.strftime('%Y-%m-%d')
              data.select { |item| item[:timestamp].start_with?(today) }
            when 'week'
              week_ago = (Date.today - 7).strftime('%Y-%m-%d')
              data.select { |item| item[:timestamp] >= week_ago }
            when 'month'
              month_ago = (Date.today - 30).strftime('%Y-%m-%d')
              data.select { |item| item[:timestamp] >= month_ago }
            else
              # Handle custom date range YYYY-MM-DD:YYYY-MM-DD
              if date_range.include?(':')
                start_date, end_date = date_range.split(':')
                data.select do |item|
                  item_date = item[:timestamp][0..9] # Extract YYYY-MM-DD
                  item_date.between?(start_date, end_date)
                end
              else
                data
              end
            end
          end

          def output_table(data, _options)
            if data.empty?
              puts 'No usage data found matching the specified criteria.'
              return
            end

            puts 'LLM Usage Report'
            puts '=' * 80
            puts

            # Summary stats
            total_queries = data.length
            total_cost = data.sum { |item| item[:total_cost] }
            total_tokens = data.sum { |item| item[:input_tokens] + item[:output_tokens] }
            avg_cost_per_query = total_cost / total_queries

            puts 'Summary:'
            puts "  Total Queries: #{total_queries}"
            puts "  Total Cost: $#{'%.6f' % total_cost}"
            puts "  Total Tokens: #{total_tokens}"
            puts "  Average Cost per Query: $#{'%.6f' % avg_cost_per_query}"
            puts

            # Provider breakdown
            provider_stats = data.group_by { |item| item[:provider] }
            puts 'By Provider:'
            provider_stats.each do |provider, items|
              provider_cost = items.sum { |item| item[:total_cost] }
              provider_queries = items.length
              puts "  #{provider.capitalize}: #{provider_queries} queries, $#{'%.6f' % provider_cost}"
            end
            puts

            # Detailed table
            puts 'Detailed Usage:'
            puts 'Timestamp           Provider     Model                   Input   Output   Cached       Cost     Time'
            puts '-' * 80

            data.each do |item|
              puts format('%-19s %-12s %-20s %8d %8d %8d $%8.6f %6.1fs',
                          item[:timestamp][0..18],
                          item[:provider],
                          item[:model][0..19],
                          item[:input_tokens],
                          item[:output_tokens],
                          item[:cached_tokens],
                          item[:total_cost],
                          item[:execution_time])
            end
          end

          def output_json(data, options)
            summary = generate_summary_stats(data)

            output = {
              summary: summary,
              usage_data: data
            }

            json_output = JSON.pretty_generate(output)

            if options[:output]
              File.write(options[:output], json_output)
              puts "JSON report saved to: #{options[:output]}"
            else
              puts json_output
            end
          end

          def output_csv(data, options)
            csv_string = CSV.generate do |csv|
              # Header
              csv << %w[timestamp provider model input_tokens output_tokens
                        cached_tokens total_cost input_cost output_cost cache_cost
                        execution_time]

              # Data rows
              data.each do |item|
                csv << [
                  item[:timestamp],
                  item[:provider],
                  item[:model],
                  item[:input_tokens],
                  item[:output_tokens],
                  item[:cached_tokens],
                  item[:total_cost],
                  item[:input_cost],
                  item[:output_cost],
                  item[:cache_cost],
                  item[:execution_time]
                ]
              end
            end

            if options[:output]
              File.write(options[:output], csv_string)
              puts "CSV report saved to: #{options[:output]}"
            else
              puts csv_string
            end
          end

          def generate_summary_stats(data)
            return {} if data.empty?

            {
              total_queries: data.length,
              total_cost: data.sum { |item| item[:total_cost] }.round(6),
              total_tokens: data.sum { |item| item[:input_tokens] + item[:output_tokens] },
              average_cost_per_query: (data.sum { |item| item[:total_cost] } / data.length).round(6),
              providers: data.group_by { |item| item[:provider] }.transform_values do |items|
                {
                  queries: items.length,
                  cost: items.sum { |item| item[:total_cost] }.round(6)
                }
              end,
              models: data.group_by { |item| item[:model] }.transform_values do |items|
                {
                  queries: items.length,
                  cost: items.sum { |item| item[:total_cost] }.round(6)
                }
              end
            }
          end

          def handle_error(error, debug_enabled)
            if debug_enabled
              warn "Error: #{error.class.name}: #{error.message}"
              warn "\nBacktrace:"
              error.backtrace.each { |line| warn "  #{line}" }
            else
              warn "Error: #{error.message}"
              warn 'Use --debug flag for more information'
            end
          end
        end
      end
    end
  end
end
