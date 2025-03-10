# frozen_string_literal: true

module Users
  class StatistiquesController < ApplicationController
    def nav_bar_profile = nav_bar_user_or_guest

    def statistiques
      @procedure = procedure
      return procedure_not_found if @procedure.blank? || @procedure.brouillon?

      @usual_traitement_time = @procedure.stats_usual_traitement_time
      @usual_traitement_time_by_month = @procedure.stats_usual_traitement_time_by_month_in_days
      @dossiers_funnel = @procedure.stats_dossiers_funnel
      @termines_states = @procedure.stats_termines_states
      @termines_by_week = @procedure.stats_termines_by_week

      render :show
    end

    private

    def procedure
      Procedure.publiees_ou_closes.find_with_path(params[:path]).first
    end

    def procedure_not_found
      flash.alert = t('errors.messages.procedure_not_found')
      redirect_to root_path
    end
  end
end
