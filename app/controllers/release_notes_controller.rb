class ReleaseNotesController < ApplicationController
  before_action :ensure_access_allowed!
  after_action :touch_default_categories_seen_at

  def nav_bar_profile
    # detect context from referer
    params = Rails.application.routes.recognize_path(request.referer)

    controller_class = "#{params[:controller].camelize}Controller".safe_constantize
    return if controller_class.nil?

    controller_instance = controller_class.new
    controller_instance.try(:nav_bar_profile)
  end

  def index
    @categories = params[:categories].presence || helpers.infer_default_announce_categories

    # Paginate per groups (per date), then show all announces for theses groups
    @paginated_groups = ReleaseNote.published
      .for_categories(@categories)
      .select(:group)
      .group(:group)
      .order('MAX(released_on) DESC')
      .page(params[:page]).per(5)

    @announces = ReleaseNote.where(group: @paginated_groups.map(&:group))
      .with_rich_text_body
      .for_categories(@categories)
      .order(released_on: :desc, id: :asc)

    render "scrollable_list" if params[:page].present?
  end

  private

  def touch_default_categories_seen_at
    return if params[:categories].present? || params[:page].present?
    return if current_user.blank?

    return if current_user.announces_seen_at&.after?(@announces.max_by(&:released_on).released_on)

    current_user.touch(:announces_seen_at)
  end

  def ensure_access_allowed!
    return if administrateur_signed_in?
    return if instructeur_signed_in?
    return if expert_signed_in?

    flash[:alert] = t('release_notes.index.forbidden')
    redirect_to root_path
  end
end
