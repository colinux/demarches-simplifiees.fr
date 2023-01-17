RSpec.describe Cron::BackfillSiretDegradedModeJob, type: :job do
  describe '.perform' do
    context "adresse nil" do
      let(:etablissement) { create(:etablissement, adresse: nil, siret: '01234567891011') }
      let(:new_adresse) { '7 rue du puits, coye la foret' }

      context 'fix etablissement with dossier with adresse nil' do
        let!(:dossier) { create(:dossier, :en_construction, etablissement: etablissement) }

        it 'works' do
          allow_any_instance_of(APIEntreprise::EtablissementAdapter).to receive(:to_params).and_return({ adresse: new_adresse })
          expect { Cron::BackfillSiretDegradedModeJob.perform_now }.to change { etablissement.reload.adresse }.from(nil).to(new_adresse)
        end
      end

      context 'fix etablisEtablissementAdapter.newsement with champs with adresse nil' do
        let!(:champ_siret) { create(:champ_siret, etablissement: etablissement) }

        it 'works' do
          allow_any_instance_of(APIEntreprise::EtablissementAdapter).to receive(:to_params).and_return({ adresse: new_adresse })
          expect { Cron::BackfillSiretDegradedModeJob.perform_now }.to change { etablissement.reload.adresse }.from(nil).to(new_adresse)
        end
      end
    end

    context 'fix etablissement with dossier with naf nil' do
      let(:etablissement) { create(:etablissement, naf: nil, siret: '01234567891011') }
      let(:new_naf) { '01K23' }
      let!(:dossier) { create(:dossier, :en_construction, etablissement: etablissement) }

      it 'works' do
        allow_any_instance_of(APIEntreprise::EtablissementAdapter).to receive(:to_params).and_return({ naf: new_naf })
        expect { Cron::BackfillSiretDegradedModeJob.perform_now }.to change { etablissement.reload.naf }.from(nil).to(new_naf)
      end
    end

    context 'fix etablissement with dossier with siege_social nil' do
      let(:etablissement) { create(:etablissement, siege_social: nil, siret: '01234567891011') }
      let!(:dossier) { create(:dossier, :en_construction, etablissement: etablissement) }

      it 'works' do
        allow_any_instance_of(APIEntreprise::EtablissementAdapter).to receive(:to_params).and_return({ siege_social: true })
        expect { Cron::BackfillSiretDegradedModeJob.perform_now }.to change { etablissement.reload.siege_social }.from(nil).to(true)
      end
    end
  end
end
