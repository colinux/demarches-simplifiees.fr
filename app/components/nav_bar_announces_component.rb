# frozen_string_literal: true

class NavBarAnnouncesComponent < ApplicationComponent
  def render?
    @most_recent_released_on = load_most_recent_released_on
    return false if @most_recent_released_on.nil?

    # also see app/controllers/release_notes_controller.rb#ensure_access_allowed!
    return true if helpers.instructeur_signed_in?
    return true if helpers.administrateur_signed_in?
    return true if helpers.expert_signed_in?

    false
  end

  def something_new?
    return true if current_user.announces_seen_at.nil?

    @most_recent_released_on.after? current_user.announces_seen_at
  end

  def load_most_recent_released_on
    categories = helpers.infer_default_announce_categories

    ReleaseNote.most_recent_announce_date_for_categories(categories)
  end
end
