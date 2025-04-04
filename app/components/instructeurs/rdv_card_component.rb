# frozen_string_literal: true

class Instructeurs::RdvCardComponent < ApplicationComponent
  attr_reader :rdv, :with_dossier_infos

  def initialize(rdv:, with_dossier_infos: false)
    @rdv = rdv
    @with_dossier_infos = with_dossier_infos
  end

  def dossier
    @rdv.dossier
  end

  def owner
    if @rdv.instructeur == current_instructeur
      t('.you')
    else
      @rdv.instructeur.email
    end
  end

  def icon_class
    case rdv.location_type
    when "phone"
      "fr-icon-phone-fill"
    when "visio"
      "fr-icon-vidicon-fill"
    when "home"
      "fr-icon-home-4-fill"
    end
  end
end
