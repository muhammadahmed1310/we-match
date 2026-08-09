# frozen_string_literal: true

# Issues and sends the private participant links for a cycle.
class CycleInvitationService
  Result = Struct.new(:created, :sent, :skipped, keyword_init: true)

  def initialize(match_cycle)
    @match_cycle = match_cycle
  end

  # Idempotent: every current group member ends up with exactly one invitation.
  def ensure_all!
    existing_member_ids = @match_cycle.cycle_invitations.pluck(:member_id).to_set
    created = 0

    @match_cycle.group.members.order(:name).each do |member|
      next if existing_member_ids.include?(member.id)

      @match_cycle.cycle_invitations.create!(member: member)
      created += 1
    end

    created
  end

  def deliver_invitations!(resend: false)
    created = ensure_all!
    scope = @match_cycle.cycle_invitations.includes(:member)
    scope = scope.unsent unless resend

    sent = 0
    scope.find_each do |invitation|
      MailDelivery.deliver(
        mailer: MatchCycleMailer,
        action: :invitation,
        args: [ invitation ],
        member: invitation.member,
        match_cycle: @match_cycle
      )
      invitation.mark_sent!
      sent += 1
    end

    @match_cycle.update!(status: :open, invitations_sent_at: Time.current) unless @match_cycle.open?
    @match_cycle.update!(invitations_sent_at: Time.current) if @match_cycle.open?

    Result.new(created: created, sent: sent, skipped: @match_cycle.cycle_invitations.count - sent)
  end

  def deliver_reminders!
    sent = 0

    @match_cycle.cycle_invitations.pending.includes(:member).find_each do |invitation|
      MailDelivery.deliver(
        mailer: MatchCycleMailer,
        action: :reminder,
        args: [ invitation ],
        member: invitation.member,
        match_cycle: @match_cycle
      )
      invitation.mark_sent!
      sent += 1
    end

    Result.new(created: 0, sent: sent, skipped: 0)
  end
end
