class SuperAdmins::ReleaseNotesController < ApplicationController
  before_action :authenticate_super_admin!
  before_action :set_notes, only: [:edit, :update]

  def index
    @release_notes_groups = ReleaseNote
      .group(:id, :group)
      .order(released_on: :desc, id: :asc)
      .with_rich_text_body.group_by(&:group)
  end

  def show
    # allows refreshing a submitted page in error
    redirect_to edit_super_admins_release_note_path(params[:group])
  end

  def create
    release_note = ReleaseNote.new(group: SecureRandom.uuid, published: false, released_on: Date.current)
    release_note.save(validate: false)

    redirect_to edit_super_admins_release_note_path(release_note.group)
  end

  def edit
    released_on = @notes.first.released_on || Date.current
    published = @notes.first.published || false
    @release_note_form = ReleaseNoteForm.new(released_on:, published:, group: params[:group])
    @release_note_form.assign_notes_and_attributes(@notes, {})
  end

  def update
    @release_note_form = ReleaseNoteForm.new(group: params[:group])
    @release_note_form.assign_notes_and_attributes(@notes, release_note_form_params)
    if @release_note_form.save
      redirect_to edit_super_admins_release_note_path(@release_note_form.group), notice: t('.success')
    else
      flash.now[:alert] = [t('.error'), @release_note_form.errors.full_messages].flatten
      render :edit
    end
  end

  def add_note
    @release_note_form = ReleaseNoteForm.new(group: params[:group])
    @release_note = ReleaseNote.new(group: params[:group], published: false)
    @release_note.save(validate: false)

    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def release_note_form_params
    release_note_params = params.require(:release_note).permit(:released_on, :published, :group)
    release_notes_attributes_params = params.permit(release_notes_attributes: [:id, :body, categories: []])

    release_note_params.merge(release_notes_attributes_params)
  end

  def set_notes
    @notes = ReleaseNote.where(group: params[:group]).order(:id)

    fail ActiveRecord::RecordNotFound.new("Could not find release notes with group `#{params[:group]}`") if @notes.empty?
  end

  def transform_notes_attributes(notes)
    notes.each_with_index.to_h { |note, index| [index, note.slice(:id, :body, :categories)] }
  end
end
