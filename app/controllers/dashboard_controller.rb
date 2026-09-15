# frozen_string_literal: true

class DashboardController < ApplicationController
  def show
    @groups_count = Group.count
    @members_count = Member.count
    @open_cycles_count = MatchCycle.where(status: :open).count
    @topics_count = Topic.active.count
    @recent_matches = Match.includes(:match_cycle, :member_one, :member_two).order(created_at: :desc).limit(5)
    @open_cycles = MatchCycle.open.includes(:group).recent.limit(5)
    @recent_deliveries = EmailDelivery.recent.limit(5)
    @email_delivery_enabled = MailDelivery.delivers_to_inbox?
    @setup_warnings = setup_warnings
  end

  private

  # The handful of things that quietly stop a round from working.
  def setup_warnings
    warnings = []
    warnings << "No topics are active yet, so nobody can submit a response." if Topic.active.none?
    warnings << "No groups exist yet." if Group.none?
    warnings << "No users yet." if Member.none?

    if Rails.env.production? && !MailDelivery.enabled?
      warnings << "Email delivery is switched off. Invitations are recorded but not sent — export the links from each cycle."
    end

    warnings
  end
end
