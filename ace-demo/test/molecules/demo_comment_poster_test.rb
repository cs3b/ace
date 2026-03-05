# frozen_string_literal: true

require_relative "../test_helper"

class DemoCommentPosterTest < AceDemoTestCase
  class FakeStatus
    def initialize(success, code)
      @success = success
      @code = code
    end

    def success?
      @success
    end

    def exitstatus
      @code
    end
  end

  def test_post_success
    Open3.stub(:capture3, proc { |_cmd, *_args|
      ["", "", FakeStatus.new(true, 0)]
    }) do
      poster = Ace::Demo::Molecules::DemoCommentPoster.new
      result = poster.post(pr: 123, comment_body: "body")

      assert_equal true, result[:posted]
      assert_equal false, result[:dry_run]
    end
  end

  def test_post_dry_run
    poster = Ace::Demo::Molecules::DemoCommentPoster.new
    result = poster.post(pr: 123, comment_body: "body", dry_run: true)

    assert_equal true, result[:dry_run]
  end

  def test_post_raises_pr_not_found
    Open3.stub(:capture3, proc { |_cmd, *_args|
      ["", "could not resolve to a pull request", FakeStatus.new(false, 1)]
    }) do
      poster = Ace::Demo::Molecules::DemoCommentPoster.new
      assert_raises(Ace::Demo::PrNotFoundError) { poster.post(pr: 999, comment_body: "body") }
    end
  end

  def test_post_does_not_misclassify_generic_not_found_errors
    Open3.stub(:capture3, proc { |_cmd, *_args|
      ["", "artifact not found while posting pull request comment", FakeStatus.new(false, 1)]
    }) do
      poster = Ace::Demo::Molecules::DemoCommentPoster.new
      assert_raises(Ace::Demo::GhCommentError) { poster.post(pr: 999, comment_body: "body") }
    end
  end
end
