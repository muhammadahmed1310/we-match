# frozen_string_literal: true

# Install / refresh the programme topics WE landed on.
#
#   bin/rails we_match:install_programme_topics
#
namespace :we_match do
  desc "Replace topics with the current WE Match programme set (view-only in admin)"
  task install_programme_topics: :environment do
    result = ProgrammeTopics.install!
    puts "Programme topics installed."
    puts "  created: #{result.created}"
    puts "  updated: #{result.updated}"
    puts "  removed unused: #{result.deactivated}"
    puts "  deactivated (still referenced): #{result.kept_inactive}"
    Topic.active.ordered.each do |topic|
      bits = if topic.collects_details_on_response?
        "open text on response"
      else
        topic.topic_options.active.ordered.map(&:label).join(", ")
      end
      puts "  - #{topic.name} (#{bits})"
    end
  end
end
