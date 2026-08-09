# frozen_string_literal: true

require "csv"

# CSV of per-person invitation links, so a Community Manager can send them by hand
# while in-app delivery is switched off.
class InvitationLinkExport
  HEADERS = [ "Name", "Email", "Time zone", "Private link", "Invitation sent at (UTC)", "Responded at (UTC)" ].freeze

  def initialize(match_cycle)
    @match_cycle = match_cycle
  end

  def to_csv
    CSV.generate do |csv|
      csv << HEADERS

      invitations.each do |invitation|
        member = invitation.member

        csv << [
          member.name,
          member.email,
          member.time_zone,
          invitation.response_url,
          invitation.sent_at&.utc&.strftime("%Y-%m-%d %H:%M"),
          invitation.responded_at&.utc&.strftime("%Y-%m-%d %H:%M")
        ]
      end
    end
  end

  private

  def invitations
    @match_cycle.cycle_invitations.joins(:member).includes(:member).order("members.name")
  end
end
