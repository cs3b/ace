# frozen_string_literal: true
require_relative "../../test_helper"

class BenchmarkInputsTest < DesignTest
  DOMAINS = {
    "app-booking" => %w[capacity location starts_at ends_at equipment],
    "app-inventory" => %w[sku quantity reorder_point location category],
    "app-support" => %w[priority customer assignee waiting_minutes channel summary],
    "site-community" => %w[date time location places_remaining activity experience],
    "site-course" => %w[level sessions price_eur instructor starts_on outcome],
    "site-studio" => %w[project_type location year area_m2 summary]
  }.freeze

  def test_packaged_benchmarks_are_domain_specific_input_pairs
    root = File.join(Ace::Design.gem_root, "handbook/benchmarks")
    assert_equal DOMAINS.keys.sort, Dir.children(root).select { |name| File.directory?(File.join(root, name)) }.sort
    datasets = DOMAINS.map do |name, fields|
      directory = File.join(root, name)
      refute File.exist?(File.join(directory, "session.json")), "#{name} is input, not a generated session"
      brief = File.read(File.join(directory, "brief.md"))
      fixture = JSON.parse(File.read(File.join(directory, "fixtures.json")))
      assert_kind_of Hash, fixture
      assert_includes brief, fixture.fetch("title")
      assert_includes brief, fixture.fetch("primary_action")
      records = fixture.fetch("records")
      assert_operator records.size, :>=, 3
      assert_equal records.size, records.map { |row| row.fetch("id") }.uniq.size
      assert_operator records.map { |row| row.fetch("status") }.uniq.size, :>=, 2
      records.each do |row|
        %w[id title status].each { |key| assert_match(/\S/, row.fetch(key), "#{name}: #{key}") }
        fields.each { |key| assert row.key?(key), "#{name}: missing #{key}" }
        %w[capacity quantity reorder_point waiting_minutes places_remaining sessions price_eur area_m2].each do |key|
          next unless row.key?(key)
          assert_kind_of Numeric, row[key], "#{name}: #{key}"
          assert_operator row[key], :>=, 0
        end
      end
      JSON.generate(records)
    end
    assert_equal datasets.size, datasets.uniq.size, "Domain briefs must not share placeholder records"
  end
end
