# frozen_string_literal: true

class WarnUnverifiedEmailComponent < ApplicationComponent
  attr_reader :user

  def initialize(user:)
    @user = user
  end

  def render? = user.unverified_email? || true
end
