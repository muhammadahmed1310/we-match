# frozen_string_literal: true

require "test_helper"

class MailDeliveryTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    ActionMailer::Base.deliveries.clear
    @original_flag = ENV["EMAIL_DELIVERY_ENABLED"]
    @group = create_group(name: "Delivery Group")
    @member = create_member(name: "Alice", email: "alice@example.com", groups: [ @group ])
    @cycle = create_cycle(group: @group)
    CycleInvitationService.new(@cycle).ensure_all!
    @invitation = @cycle.cycle_invitations.sole
  end

  teardown do
    if @original_flag.nil?
      ENV.delete("EMAIL_DELIVERY_ENABLED")
    else
      ENV["EMAIL_DELIVERY_ENABLED"] = @original_flag
    end
  end

  test "records what was intended and queues the send" do
    delivery = nil

    assert_enqueued_with job: SendTrackedEmailJob do
      delivery = deliver_invitation
    end

    assert_equal "MatchCycleMailer", delivery.mailer
    assert_equal "invitation", delivery.mailer_action
    assert_equal "alice@example.com", delivery.recipients
    assert_match "Share your availability", delivery.subject
    assert delivery.pending?
  end

  test "marks the record delivered once the job runs" do
    delivery = deliver_invitation

    perform_enqueued_jobs

    assert delivery.reload.delivered?
    assert delivery.delivered_at.present?
    assert_equal 1, ActionMailer::Base.deliveries.size
  end

  test "records a failure and keeps the reason" do
    delivery = EmailDelivery.create!(
      mailer: "MatchCycleMailer",
      mailer_action: "does_not_exist",
      recipients: "alice@example.com",
      status: :pending
    )

    assert_raises NoMethodError do
      SendTrackedEmailJob.perform_now(delivery, "MatchCycleMailer", "does_not_exist")
    end

    assert delivery.reload.failed?
    assert delivery.error_message.present?
  end

  test "records but does not send when the flag is off" do
    ENV["EMAIL_DELIVERY_ENABLED"] = "false"
    delivery = nil

    assert_no_enqueued_jobs only: SendTrackedEmailJob do
      delivery = deliver_invitation
    end

    assert delivery.skipped?
    assert_empty ActionMailer::Base.deliveries
  end

  test "the flag turns delivery back on" do
    ENV["EMAIL_DELIVERY_ENABLED"] = "true"

    assert MailDelivery.enabled?
  end

  test "delivery is on by default outside production" do
    ENV.delete("EMAIL_DELIVERY_ENABLED")

    assert MailDelivery.enabled?
  end

  test "invitations are recorded even with the flag off, so links can be handed out" do
    ENV["EMAIL_DELIVERY_ENABLED"] = "false"

    assert_difference -> { EmailDelivery.skipped.count }, 1 do
      CycleInvitationService.new(@cycle).deliver_invitations!
    end

    assert @cycle.cycle_invitations.sole.sent?
  end

  private

  def deliver_invitation
    MailDelivery.deliver(
      mailer: MatchCycleMailer,
      action: :invitation,
      args: [ @invitation ],
      member: @member,
      match_cycle: @cycle
    )
  end
end
