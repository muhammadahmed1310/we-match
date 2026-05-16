# frozen_string_literal: true

namespace :match do
  desc "Send biweekly invitation emails for a match cycle (match:send_invitations[cycle_id])"
  task :send_invitations, [ :cycle_id ] => :environment do |_task, args|
    cycle = MatchCycle.find(args[:cycle_id])
    count = 0

    cycle.group.members.find_each do |member|
      MatchCycleMailer.invitation(member, cycle).deliver_now
      count += 1
    end

    cycle.update!(status: :open) unless cycle.open? || cycle.matched?

    puts "Sent #{count} invitation emails for cycle ##{cycle.id} (#{cycle.group.name})."
  end
end
