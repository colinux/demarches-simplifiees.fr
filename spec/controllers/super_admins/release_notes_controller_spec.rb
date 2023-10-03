require 'rails_helper'

describe SuperAdmins::ReleaseNotesController, type: :controller do
  let(:super_admin) { create(:super_admin) }

  before do
    sign_in super_admin if super_admin.present?
  end

  describe "acl" do
    context 'when user is not signed as super admin' do
      let(:super_admin) { nil }
      let!(:release_note) { create(:release_note, group: "abc123", published: false) }

      it 'is not allowed to post' do
        expect { post :create, params: { release_note: { released_on: Date.current, published: "0" } } }.not_to change(ReleaseNote, :count)
        expect(response.status).to eq(302)
        expect(flash[:alert]).to be_present
      end

      it 'is not allowed to put' do
        expect {
          put :update, params: {
            group: "abc123",
               release_note: {
                 released_on: Date.current,
                 published: "1"
               },
               release_notes_attributes: {
                 "0" => {
                   id: release_note.id,
                   categories: release_note.categories,
                   body: "hacked body"
                 }
               }
          }
        }.not_to change { release_note.reload.body }
        expect(response.status).to eq(302)
        expect(flash[:alert]).to be_present
      end

      it 'is not allowed to index' do
        get :index
        expect(response.status).to eq(302)
        expect(flash[:alert]).to be_present
      end
    end
  end
end
