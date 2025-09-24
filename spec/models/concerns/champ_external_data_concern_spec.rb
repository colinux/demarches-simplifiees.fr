# frozen_string_literal: true

RSpec.describe ChampExternalDataConcern do
  include Dry::Monads[:result]

  context "external_data" do
    let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :rnf }]) }
    let(:dossier) { create(:dossier, procedure:) }
    let(:champ) { dossier.champs.first }

    describe "waiting_for_external_data?" do
      context "pending" do
        before { champ.update(external_id: 'external_id') }
        it { expect(champ.waiting_for_external_data?).to be_truthy }
      end

      context "done" do
        before { champ.update_columns(external_id: 'external_id', data: 'some data') }
        it { expect(champ.waiting_for_external_data?).to be_falsey }
      end
    end

    describe "external_data_fetched?" do
      context "pending" do
        it { expect(champ.external_data_fetched?).to be_falsey }
      end

      context "done" do
        before { champ.update_columns(external_id: 'external_id', data: 'some data') }
        it { expect(champ.external_data_fetched?).to be_truthy }
      end
    end

    describe "fetch_external_data" do
      context "cleanup_if_empty" do
        before { champ.update_columns(data: 'some data') }

        it "remove data if external_id changes" do
          expect(champ.data).to_not be_nil
          champ.update(external_id: 'external_id')
          expect(champ.data).to be_nil
        end
      end
    end
  end

  describe '#save_external_exception' do
    let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :rnf }]) }
    let(:dossier) { create(:dossier, procedure:) }
    let(:champ) { dossier.champs.first }
    context "add execption to the log" do
      it do
        champ.send(:save_external_exception, double(inspect: 'PAN'), 404)
        expect { champ.reload }.not_to raise_error
      end
    end
  end

  describe 'the state machine' do
    let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :rnf }]) }
    let(:dossier) { create(:dossier, procedure:) }
    let(:champ) { dossier.champs.first }

    describe 'initial state' do
      it { expect(champ).to be_idle }
    end

    describe 'fetch_later' do
      let(:ready_for_external_call?) { true }

      subject { champ.fetch_later!; champ }

      before do
        allow(champ).to receive(:ready_for_external_call?).and_return(ready_for_external_call?)
        allow(champ).to receive(:fetch_external_data_later)
      end

      it do
        is_expected.to be_waiting_for_job
        expect(champ).to have_received(:fetch_external_data_later)
      end

      context 'when not ready for external call' do
        let(:ready_for_external_call?) { false }

        it 'does not change the state' do
          expect(champ.may_fetch_later?).to be_falsey
          expect { subject }.to raise_error(AASM::InvalidTransition)
        end
      end
    end

    describe 'fetch' do
      before do
        allow(champ).to receive(:ready_for_external_call?).and_return(true)
        champ.fetch_later!
        allow(champ).to receive(:fetch_and_handle_result)
      end

      subject { champ.fetch!; champ }

      it do
        is_expected.to be_fetching
        expect(champ).to have_received(:fetch_and_handle_result)
      end
    end

    describe 'fetch a success, now is fetched state' do
      before do
        allow(champ).to receive(:ready_for_external_call?).and_return(true)
        champ.fetch_later!

        allow(champ).to receive(:fetch_external_data).and_return(Success('some data'))
        allow(champ).to receive(:update_external_data!)
        champ.fetch!
      end

      it { expect(champ).to be_fetched }
    end

    describe 'fetch a non retryable failure, now is external_error state' do
      before do
        allow(champ).to receive(:ready_for_external_call?).and_return(true)
        champ.fetch_later!

        failure = Failure(retryable: false, reason: Exception.new('nop'), code: 404)
        allow(champ).to receive(:fetch_external_data).and_return(failure)
        champ.fetch!
      end

      it { expect(champ).to be_external_error }
    end

    describe 'fetch a retryable failure, now is back in waiting_for_job state' do
      before do
        allow(champ).to receive(:ready_for_external_call?).and_return(true)
        champ.fetch_later!

        failure = Failure(retryable: true, reason: Exception.new('nop'), code: 404)
        allow(champ).to receive(:fetch_external_data).and_return(failure)
      end

      subject { champ.fetch!; champ }

      it do
        expect { subject }.to raise_error(Exception, 'nop')
        expect(champ.reload).to be_waiting_for_job
      end
    end

    describe 'reset_external_data' do
      before do
        allow(champ).to receive(:ready_for_external_call?).and_return(true)
        champ.fetch_later!

        allow(champ).to receive(:after_reset_external_data)
        champ.reset_external_data!
      end

      it do
        expect(champ).to be_idle
        expect(champ).to have_received(:after_reset_external_data)
      end
    end
  end
end
