# frozen_string_literal: true

# Public static pages (no admin session).
class PagesController < ApplicationController
  allow_participant_access

  layout "minimal"

  def privacy
  end
end
