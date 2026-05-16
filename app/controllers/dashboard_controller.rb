# frozen_string_literal: true

class DashboardController < ApplicationController
  def show
    @groups_count = Group.count
    @members_count = Member.count
    @open_cycles_count = MatchCycle.where(status: :open).count
    @recent_matches = Match.includes(:match_cycle, :member_one, :member_two).order(created_at: :desc).limit(5)
    @open_cycles = MatchCycle.open.recent.limit(5)
  end
end
