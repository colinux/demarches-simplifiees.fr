describe 'SuperAdmins::ReleaseNotes' do
  let(:super_admin) { create(:super_admin) }

  before do
    sign_in super_admin
  end

  scenario 'Adding a note', js: true, retry: 3 do
    visit super_admins_release_notes_path
    click_on "Créer une annonce"

    fill_in 'Date de publication', with: Date.current

    check 'Administrateur', allow_label_click: true
    check 'API', allow_label_click: true
    fill_in_trix_editor 'Annonce', with: 'Some text for the note'

    click_link 'Ajouter une autre note'

    # Second note
    within(all('.fr-background-alt--grey', count: 2)[1]) do
      fill_in_trix_editor 'Annonce', with: 'Additional text for the new note'
      check 'Instructeur', allow_label_click: true
    end

    click_button 'Valider'

    expect(page).to have_content("Les annonces ont été sauvegardées.")

    notes = ReleaseNote.all.order(:id)
    expect(notes.count).to eq(2)
    expect(notes[0].body.to_plain_text).to eq('Some text for the note')
    expect(notes[0].categories).to eq(['administrateur', 'api'])
    expect(notes[1].body.to_plain_text).to eq('Additional text for the new note')
    expect(notes[1].categories).to eq(['instructeur'])

    expect(notes).to all(have_attributes(released_on: Date.current))
    expect(notes).to all(have_attributes(published: false))

    check 'Publier toutes les annonces', allow_label_click: true
    within(all('.fr-background-alt--grey')[0]) do
      fill_in_trix_editor 'Annonce', with: 'Some updated text for the note'
    end
    click_button 'Valider'

    notes = notes.reload
    expect(notes).to all(have_attributes(published: true))
    expect(notes[0].body.to_plain_text).to eq('Some updated text for the note')
    expect(notes[0].categories).to eq(['administrateur', 'api'])
  end

  scenario 'Editing a note prefill', js: true, retry: 3 do
    note1 = create(:release_note, released_on: Date.current, published: false, body: "Initial text", categories: ['administrateur'])
    note2 = note1.dup.update!(body: "Second text", categories: ['usager'])

    visit edit_super_admins_release_note_path(note1.group)

    within(all('.fr-background-alt--grey')[0]) do
      expect(page).to have_content('Initial text')
      expect(find_field('Administrateur')).to be_checked
    end

    within(all('.fr-background-alt--grey')[1]) do
      expect(page).to have_content('Second text')
      expect(find_field('Usager')).to be_checked
    end

    click_link 'Ajouter une autre note'

    within(all('.fr-background-alt--grey', count: 3)[2]) do
      fill_in_trix_editor 'Annonce', with: 'Third text note'
      check 'Expert', allow_label_click: true
    end

    click_button 'Valider'

    note = ReleaseNote.last
    expect(note).not_to be_published
    expect(note.body.to_plain_text).to eq('Third text note')
    expect(note.categories).to eq(['expert'])
  end

  scenario 'Delete a note', js: true, retry: 3 do
    note1 = create(:release_note, body: "first note", group: "abc123")
    note2 = create(:release_note, body: "second note", group: "abc123")

    visit edit_super_admins_release_note_path("abc123")

    expect(page).to have_content("first note")

    within(all('.fr-background-alt--grey')[0]) do
      accept_confirm { click_link 'Supprimer cette note' }
    end

    expect(page).not_to have_content("first note")
    wait_until {
      expect(ReleaseNote.exists?(note1.id)).to be_falsy
    }

    within(all('.fr-background-alt--grey')[0]) do
      accept_confirm { click_link 'Supprimer cette note' }
    end

    expect(ReleaseNote.exists?(note2.id)).to be_truthy
    expect(page).to have_content("Vous ne pouvez pas")
    expect(page).to have_content("second note")
  end

  def fill_in_trix_editor(label, with:)
    within(".fr-input-group", text: label) do
      find('trix-editor').click.set(with)
    end
  end
end
