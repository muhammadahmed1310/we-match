# frozen_string_literal: true

class MatchCyclesController < ApplicationController
  before_action :set_match_cycle, only: %i[show send_invitations run_matching]

  def index
    @match_cycles = MatchCycle.includes(:group).recent
  end

  def show
    @match_responses = @match_cycle.match_responses.includes(:member, :match).order(:created_at)
    @matches = @match_cycle.matches.includes(:member_one, :member_two)
  end

  def new
    @match_cycle = MatchCycle.new(status: :draft)
    @groups = Group.order(:name)
  end

  def create
    @match_cycle = MatchCycle.new(match_cycle_params)

    if @match_cycle.save
      redirect_to @match_cycle, notice: "Match cycle created."
    else
      @groups = Group.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def send_invitations
    if @match_cycle.matched?
      redirect_to @match_cycle, alert: "Cannot send invitations for a completed cycle."
      return
    end

    count = 0
    @match_cycle.group.members.find_each do |member|
      MatchCycleMailer.invitation(member, @match_cycle).deliver_now
      count += 1
    end

    @match_cycle.update!(status: :open) unless @match_cycle.open?

    redirect_to @match_cycle, notice: "Sent #{count} invitation emails (logged in development)."
  end

  def run_matching
    if @match_cycle.matched?
      redirect_to @match_cycle, alert: "Matching has already been run for this cycle."
      return
    end

    unless @match_cycle.ready_for_matching?
      redirect_to @match_cycle, alert: "Cycle must be open or closed before matching."
      return
    end

    if @match_cycle.match_responses.none?
      redirect_to @match_cycle, alert: "No responses yet. Members must submit availability and topic before matching."
      return
    end

    result = MatchingService.new(@match_cycle).call
    redirect_to match_cycle_matches_path(@match_cycle),
                notice: "Created #{result.matches.size} match(es). #{result.unmatched.size} response(s) unmatched."
  rescue MatchingService::AlreadyMatchedError => e
    redirect_to @match_cycle, alert: e.message
  end

  private

  def set_match_cycle
    @match_cycle = MatchCycle.includes(:group).find(params[:id])
  end

  def match_cycle_params
    params.require(:match_cycle).permit(:group_id, :status, :opens_at, :closes_at)
  end
end
