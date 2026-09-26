# frozen_string_literal: true

class MatchMailer < ApplicationMailer
  # Deliberately exposes only the names, the shared topic, and the shared window.
  # The topic option each person picked is insight data and never leaves the admin
  # side of the app.
  def introduction(match)
    @match = match
    @match_cycle = match.match_cycle
    @group = @match_cycle.group
    @member_one = match.member_one
    @member_two = match.member_two
    @topic = match.topic
    @slot_utc = match.email_slot_label_utc
    @local_slots = [ @member_one, @member_two ].map { |member| [ member, match.email_slot_label_for(member) ] }

    mail(
      to: [ @member_one.email, @member_two.email ],
      subject: "WE Match: You're connected for a conversation in #{@group.name}"
    )
  end
end
