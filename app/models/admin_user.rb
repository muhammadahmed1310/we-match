# frozen_string_literal: true

class AdminUser < ApplicationRecord
  has_secure_password

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 12 }, allow_nil: true

  normalizes :email, with: ->(email) { email.to_s.strip.downcase }

  def self.authenticate(email:, password:)
    find_by(email: email.to_s.strip.downcase)&.authenticate(password) || nil
  end
end
