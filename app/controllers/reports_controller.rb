# frozen_string_literal: true

class ReportsController < ApplicationController
  def index
    @group = Group.find_by(id: params[:group_id])
    @groups = Group.ordered
    @report = ProgrammeReport.new(group: @group)

    respond_to do |format|
      format.html
      format.csv do
        send_data @report.to_csv,
                  filename: "we-match-cycles-#{Date.current.strftime('%Y-%m-%d')}.csv",
                  type: "text/csv"
      end
    end
  end

  def cycle
    @match_cycle = MatchCycle.includes(:group).find(params[:id])
    @report = CycleReport.new(@match_cycle)

    respond_to do |format|
      format.html
      format.csv do
        send_data @report.to_csv,
                  filename: "we-match-cycle-#{@match_cycle.id}-results.csv",
                  type: "text/csv"
      end
    end
  end
end
