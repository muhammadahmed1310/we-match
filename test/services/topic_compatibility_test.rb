# frozen_string_literal: true

require "test_helper"

class TopicCompatibilityTest < ActiveSupport::TestCase
  test "exact match topics are compatible" do
    assert TopicCompatibility.compatible?("Career Transitions", "career transitions")
  end

  test "alias topics are compatible" do
    assert TopicCompatibility.compatible?("Leadership", "Leading Teams")
  end

  test "different topics are not compatible" do
    assert_not TopicCompatibility.compatible?("Leadership", "Mentorship")
  end
end
