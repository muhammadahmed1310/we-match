# frozen_string_literal: true

class MatchCyclesController < ApplicationController
  before_action :set_match_cycle, only: %i[show edit update send_invitations close run_matching invitations]

  def index
    @match_cycles = MatchCycle.includes(:group).recent
  end

  def show
    @match_responses = @match_cycle.match_responses
                                   .includes(:member, :match, :topic, :topic_option, :response_slots)
                                   .order(:created_at)
    @matches = @match_cycle.matches.includes(:member_one, :member_two, :topic)
    @invitations = @match_cycle.cycle_invitations.joins(:member).includes(:member).order("members.name")
  end

  def new
    @match_cycle = MatchCycle.new(
      status: :draft,
      opens_at: Time.current.beginning_of_hour,
      closes_at: 3.days.from_now.beginning_of_hour
    )
    @groups = Group.ordered
  end

  def create
    @match_cycle = MatchCycle.new(match_cycle_params)

    if @match_cycle.save
      CycleInvitationService.new(@match_cycle).ensure_all!
      redirect_to @match_cycle, notice: "Match cycle created. Private links are ready to send."
    else
      @groups = Group.ordered
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @groups = Group.ordered
  end

  def update
    if @match_cycle.update(match_cycle_params)
      redirect_to @match_cycle, notice: "Match cycle updated."
    else
      @groups = Group.ordered
      render :edit, status: :unprocessable_entity
    end
  end

  def send_invitations
    if @match_cycle.matched?
      redirect_to @match_cycle, alert: "Cannot send invitations for a completed cycle."
      return
    end

    result = CycleInvitationService.new(@match_cycle).deliver_invitations!(resend: params[:resend].present?)

    redirect_to @match_cycle, notice: invitation_notice(result)
  end

  def close
    if @match_cycle.matched?
      redirect_to @match_cycle, alert: "This cycle is already complete."
      return
    end

    @match_cycle.update!(status: :closed, closes_at: @match_cycle.closes_at || Time.current)
    redirect_to @match_cycle, notice: "Cycle closed. No further responses will be accepted."
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
      redirect_to @match_cycle, alert: "No responses yet. Explorers and WE Fellows must submit availability and a topic before matching."
      return
    end

    result = MatchingService.new(@match_cycle).call
    redirect_to match_cycle_matches_path(@match_cycle),
                notice: "Created #{result.matches.size} match(es). #{result.unmatched.size} response(s) unmatched."
  rescue MatchingService::AlreadyMatchedError => e
    redirect_to @match_cycle, alert: e.message
  end

  # The manual fallback for the flag-off path: hand these links out yourself.
  def invitations
    CycleInvitationService.new(@match_cycle).ensure_all!
    @invitations = @match_cycle.cycle_invitations.includes(:member).joins(:member).order("members.name")

    respond_to do |format|
      format.html
      format.csv do
        send_data InvitationLinkExport.new(@match_cycle).to_csv,
                  filename: "we-match-links-cycle-#{@match_cycle.id}.csv",
                  type: "text/csv"
      end
    end
  end

  private

  def set_match_cycle
    @match_cycle = MatchCycle.includes(:group).find(params[:id])
  end

  def match_cycle_params
    params.require(:match_cycle).permit(:group_id, :status, :opens_at, :closes_at, :meeting_week_start)
  end

  def invitation_notice(result)
    parts = []
    parts << "Issued #{result.created} new link(s)." if result.created.positive?

    if MailDelivery.enabled?
      parts << "Queued #{result.sent} invitation email(s)."
    else
      parts << "Email delivery is switched off, so #{result.sent} email(s) were recorded but not sent — export the links instead."
    end

    parts.join(" ")
  end
end
