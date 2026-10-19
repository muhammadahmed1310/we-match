# frozen_string_literal: true

require "test_helper"

class ProgrammeTopicsTest < ActiveSupport::TestCase
  test "installs the three programme topics and removes unused ones" do
    stale = create_topic(name: "Leadership", options: [ "Difficult conversations" ])

    result = ProgrammeTopics.install!

    assert_equal 3, Topic.active.count
    refute Topic.active.exists?(id: stale.id)
    assert_includes Topic.active.ordered.map(&:name), "How do I jettison some elements of my leading?"

    jettison = Topic.active.find_by!(name: "How do I jettison some elements of my leading?")
    assert_equal [ "Good girl", "Imposter syndrome", "Saying yes to everything", "Other" ],
                 jettison.topic_options.active.ordered.map(&:label)

    dilemma = Topic.active.find_by!(name: "Can we brainstorm solutions to a leadership dilemma I’m facing now?")
    assert dilemma.collects_details_on_response?
    assert_equal 0, dilemma.topic_options.active.count

    assert result.created.positive? || result.updated.positive?
  end

  test "keeps referenced old topics inactive instead of destroying them" do
    group = create_group(name: "Fellows")
    member = create_member(name: "Alice", email: "alice@example.com", groups: [ group ])
    cycle = create_cycle(group: group)
    old_topic = create_topic(name: "Leadership", options: [ "Difficult conversations" ])
    create_response(cycle: cycle, member: member, topic: old_topic, windows: [ window_at(cycle) ])

    ProgrammeTopics.install!

    assert Topic.exists?(old_topic.id)
    refute old_topic.reload.active?
    assert_equal 3, Topic.active.count
  end
end
