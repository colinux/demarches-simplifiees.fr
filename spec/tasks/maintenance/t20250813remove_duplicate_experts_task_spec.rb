# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250813removeDuplicateExpertsTask do
    let!(:initial_expert) { create(:expert, created_at: 3.days.ago) }
    let!(:duplicate_expert) { create(:expert, created_at: 1.day.ago) }

    # Since PR#12027, we have an uniq index on user_id
    before do
      ActiveRecord::Base.connection.execute("DROP INDEX IF EXISTS index_experts_on_user_id")
      duplicate_expert.update_column(:user_id, initial_expert.user_id)
    end

    after do
      duplicate_expert.destroy!
      ActiveRecord::Base.connection.execute("CREATE UNIQUE INDEX index_experts_on_user_id ON experts(user_id)")
    end

    describe "#collection" do
      subject(:collection) { described_class.collection }

      let(:user_without_duplicates) { create(:user) }
      let!(:single_expert) { create(:expert, user: user_without_duplicates) }

      it 'returns only the experts that are duplicates' do
        expect(collection).to include([duplicate_expert, initial_expert])
        expect(collection.map(&:first)).not_to include(initial_expert, single_expert)
      end
    end

    describe "#process" do
      subject(:process) { described_class.process([duplicate_expert, initial_expert]) }

      let!(:commentaire) { create(:commentaire, expert: duplicate_expert) }
      let(:procedure_1) { create(:procedure) }
      let(:procedure_2) { create(:procedure) }
      let!(:initial_expert_procedure_1) { create(:experts_procedure, expert: initial_expert, procedure: procedure_1) }
      let!(:duplicate_expert_procedure_1) { create(:experts_procedure, expert: duplicate_expert, procedure: procedure_1) }
      let!(:duplicate_expert_procedure_2) { create(:experts_procedure, expert: duplicate_expert, procedure: procedure_2) }

      it "reassigns experts_procedures and commentaires, and destroy duplicates experts" do
        subject
        expect(commentaire.reload.expert_id).to eq(initial_expert.id)
        expect(ExpertsProcedure.exists?(expert: duplicate_expert, procedure: procedure_1)).to be false
        expect(ExpertsProcedure.exists?(expert: initial_expert, procedure: procedure_1)).to be true
        expect(duplicate_expert_procedure_2.reload.expert_id).to eq(initial_expert.id)
        expect(Expert.exists?(id: duplicate_expert.id)).to be false
      end
    end
  end
end
