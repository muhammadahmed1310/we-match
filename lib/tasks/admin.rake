# frozen_string_literal: true

namespace :admin do
  desc "Create or update an admin user from ADMIN_EMAIL, ADMIN_PASSWORD, and ADMIN_NAME"
  task create: :environment do
    email = ENV["ADMIN_EMAIL"].to_s.strip
    password = ENV["ADMIN_PASSWORD"].to_s
    name = ENV.fetch("ADMIN_NAME", "WE Admin")

    abort "ADMIN_EMAIL is required." if email.blank?
    abort "ADMIN_PASSWORD is required and must be at least 12 characters." if password.length < 12

    admin = AdminUser.find_or_initialize_by(email: email.downcase)
    admin.name = name
    admin.password = password

    if admin.save
      puts "Admin ready: #{admin.email}"
    else
      abort "Could not save admin: #{admin.errors.full_messages.to_sentence}"
    end
  end

  desc "List admin users"
  task list: :environment do
    if AdminUser.none?
      puts "No admin users yet. Run: bin/rails admin:create"
    else
      AdminUser.order(:email).each do |admin|
        last_seen = admin.last_signed_in_at ? admin.last_signed_in_at.strftime("%b %d, %Y %H:%M UTC") : "never"
        puts "#{admin.email} (#{admin.name}) — last signed in: #{last_seen}"
      end
    end
  end
end
