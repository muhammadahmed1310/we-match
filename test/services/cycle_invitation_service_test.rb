# frozen_string_literal: true

require "test_helper"

class CycleInvitationServiceTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    @group = create_group(name: "Opt-out Group")
    @active = create_member(name: "Alice", email: "alice@example.com", groups: [ @group ])
    @opted_out = create_member(name: "Bob", email: "bob@example.com", groups: [ @group ])
    @opted_out.opt_out_of_cycle_emails!
    @cycle = create_cycle(group: @group)
  end

  test "deliver_invitations skips opted-out members" do
    ActionMailer::Base.deliveries.clear

    result = nil
    assert_emails 1 do
      result = CycleInvitationService.new(@cycle).deliver_invitations!
    end

    assert_equal 2, result.created
    assert_equal 1, result.sent
    assert_equal 1, result.skipped
    assert_equal [ "alice@example.com" ], ActionMailer::Base.deliveries.last.to
  end

  test "deliver_reminders skips opted-out members" do
    CycleInvitationService.new(@cycle).ensure_all!
    ActionMailer::Base.deliveries.clear

    result = nil
    assert_emails 1 do
      result = CycleInvitationService.new(@cycle).deliver_reminders!
    end

    assert_equal 1, result.sent
    assert_equal 1, result.skipped
  end
end
