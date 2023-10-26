# frozen_string_literal: true

class ReleaseNote::NoteFormComponent < ApplicationComponent
  attr_reader :note
  attr_reader :index

  def initialize(note:, index: generate_incremental_index)
    @note = note
    @index = index
  end

  private

  def categories_fieldset_class
    class_names(
      "fr-fieldset--error": categories_error?
    )
  end

  def categories_error?
    note.errors.key?(:categories)
  end

  def categories_errors_describedby_id
    return nil if !categories_error?

    dom_id(note, "#{index}_categories_errors")
  end

  def categories_full_messages_errors
    note.errors.full_messages_for(:categories)
  end

  def generate_incremental_index
    Time.current.to_f.to_i
  end

  def fieldset_element_id
    dom_id(note, :fieldset_element)
  end

  def delete_button
    link_to t('.delete'), super_admins_release_note_path(group: note.group, id: note.id),
      class: "fr-btn fr-btn--secondary fr-btn--sm fr-btn--icon-left fr-icon-delete-line",
      data: { turbo: true, turbo_method: :delete, turbo_confirm: "Supprimer cette note ?" }
  end
end
