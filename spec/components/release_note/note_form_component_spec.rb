require "rails_helper"

RSpec.describe ReleaseNote::NoteFormComponent, type: :component do
  let(:note) { create(:release_note) }
  let(:index) { 1 }
  let(:component) { described_class.new(note: note, index: index) }

  describe "rendering" do
    it "renders the note fields" do
      render_inline(component)

      # Check for presence of specific elements or content.
      expect(page).to have_css(".fr-fieldset")
      expect(page).to have_field("release_notes_attributes[1][id]", type: 'hidden', with: note.id)

      # Check for categories
      ReleaseNote::CATEGORIES.each do |category|
        expect(page).to have_css("input[type='checkbox'][id='#{component.send(:dom_id, note, "1_category_#{category}")}']")
        expect(page).to have_text(category.humanize)
      end

      expect(page).not_to have_css(".fr-messages-group")

      # Check for body field
      expect(page).to have_field("release_notes_attributes[1][body]", type: 'hidden', visible: false)
    end
  end
end
