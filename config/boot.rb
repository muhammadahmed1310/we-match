# frozen_string_literal: true

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

# Capistrano links shared/.env into the release. Load it before Bundler.require
# so Rails.groups sees RAILS_ENV=production (otherwise CLI defaults to development).
env_path = File.expand_path("../.env", __dir__)
if File.exist?(env_path)
  File.foreach(env_path) do |line|
    line = line.strip
    next if line.empty? || line.start_with?("#")
    next unless line.include?("=")

    key, value = line.split("=", 2)
    next if key.nil? || key.empty?
    next if ENV.key?(key)

    value = value.to_s
    value = value[1..-2] if (value.start_with?('"') && value.end_with?('"')) ||
                            (value.start_with?("'") && value.end_with?("'"))
    ENV[key] = value
  end
end

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.
