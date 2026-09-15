# frozen_string_literal: true

namespace :db do
  desc "Delete all app data but keep admin sign-in accounts"
  task wipe: :environment do
    if Rails.env.production? && ENV["ALLOW_DESTRUCTIVE_WIPE"] != "true"
      abort "Refusing to wipe production. Set ALLOW_DESTRUCTIVE_WIPE=true if that is really what you want."
    end

    admin_count = AdminUser.count

    ActiveRecord::Base.transaction do
      ResponseSlot.destroy_all
      MatchFeedback.destroy_all
      MatchResponse.destroy_all
      Match.destroy_all
      CycleInvitation.destroy_all
      EmailDelivery.destroy_all
      MatchCycle.destroy_all
      GroupMembership.destroy_all
      TopicOption.destroy_all
      Topic.destroy_all
      Member.destroy_all
      Group.destroy_all
    end

    puts "Wiped all groups, people, topics, cycles, and responses."
    puts "Kept #{admin_count} admin account(s)."
    AdminUser.order(:email).pluck(:email).each { |email| puts "  - #{email}" }
  end
end
