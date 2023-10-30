# frozen_string_literal: true

class InstructeurExpertMainNavigationComponent < ApplicationComponent
  def instructeur?
    helpers.instructeur_signed_in?
  end

  def expert?
    helpers.expert_signed_in?
  end
end
