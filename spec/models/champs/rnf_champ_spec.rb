# frozen_string_literal: true

describe Champs::RNFChamp, type: :model do
  let(:champ) { described_class.new(external_id:) }
  let(:external_id) { '075-FDD-00003-01' }
  let(:body) { Rails.root.join('spec', 'fixtures', 'files', 'api_rnf', "#{response_type}.json").read }
  let(:response_type) { 'valid' }

  describe 'fetch_external_data' do
    let(:url) { RNFService.new.send(:url) }
    let(:status) { 200 }
    before { stub_request(:get, "#{url}/075-FDD-00003-01").to_return(body:, status:) }

    subject { champ.fetch_external_data }

    context 'success' do
      it do
        expect(subject.value!).to eq({
          id: 3,
          rnfId: '075-FDD-00003-01',
          type: 'FDD',
          department: '75',
          title: 'Fondation SFR',
          dissolvedAt: nil,
          phone: '+33185060000',
          email: 'fondation@sfr.fr',
          addressId: 3,
          createdAt: "2023-09-07T13:26:10.358Z",
          updatedAt: "2023-09-07T13:26:10.358Z",
          address: {
            id: 3,
            createdAt: "2023-09-07T13:26:10.358Z",
            updatedAt: "2023-09-07T13:26:10.358Z",
            label: "16 Rue du Général de Boissieu 75015 Paris",
            type: "housenumber",
            streetAddress: "16 Rue du Général de Boissieu",
            streetNumber: "16",
            streetName: "Rue du Général de Boissieu",
            postalCode: "75015",
            cityName: "Paris",
            cityCode: "75115",
            departmentName: "Paris",
            departmentCode: "75",
            regionName: "Île-de-France",
            regionCode: "11"
          },
          status: nil,
          persons: []
        })
      end
    end

    context 'success (with space)' do
      let(:external_id) { '075-FDD- 00003-01 ' }
      it {
        expect(subject).to be_success
      }
    end

    context 'success (with tab)' do
      let(:external_id) { '075-FDD-0	0003-01	' }
      it {
        expect(subject).to be_success
      }
    end

    context 'failure (schema)' do
      let(:response_type) { 'invalid' }
      it {
        expect(subject.failure.retryable).to be_falsey
        expect(subject.failure.reason).to be_a(API::Client::SchemaError)
      }
    end

    context 'failure (http 500)' do
      let(:status) { 500 }
      let(:response_type) { 'invalid' }
      it {
        expect(subject.failure.retryable).to be_truthy
        expect(subject.failure.reason).to be_a(API::Client::HTTPError)
      }
    end

    context 'failure (http 401)' do
      let(:status) { 401 }
      let(:response_type) { 'invalid' }
      it {
        expect(subject.failure.retryable).to be_falsey
        expect(subject.failure.reason).to be_a(API::Client::HTTPError)
      }
    end

    context 'failure (http 400)' do
      let(:status) { 400 }
      let(:response_type) { 'invalid' }
      it {
        expect(subject.failure.retryable).to be_falsey
        expect(subject.failure.reason).to be_a(API::Client::HTTPError)
      }
    end

    context 'failure (http 404)' do
      let(:status) { 404 }
      let(:response_type) { 'invalid' }
      it {
        expect(subject.failure.retryable).to be_falsey
        expect(subject.failure.reason).to be_a(API::Client::HTTPError)
      }
    end

    describe 'update_external_data!' do
      it 'works' do
        value_json = {
          street_number: "16",
          street_name: "Rue du Général de Boissieu",
          street_address: "16 Rue du Général de Boissieu",
          postal_code: "75015",
          city_name: "Paris 15e Arrondissement",
          city_code: "75115",
          departement_code: "75",
          department_code: "75",
          departement_name: "Paris",
          department_name: "Paris",
          region_code: "11",
          region_name: "Île-de-France",
          title: "Fondation SFR",
          country_code: "FR",
          country_name: "France"
        }
        expect(champ).to receive(:update!).with(data: anything, value_json:, fetch_external_data_exceptions: [])
        champ.update_external_data!(data: subject.value!)
      end
    end
  end

  describe 'for_export' do
    let(:champ) { described_class.new(external_id:, data: JSON.parse(body)) }
    before { allow(champ).to receive(:type_de_champ).and_return(build(:type_de_champ_rnf)) }
    it do
      expect(champ.type_de_champ.champ_value_for_export(champ, :value)).to eq '075-FDD-00003-01'
      expect(champ.type_de_champ.champ_value_for_export(champ, :nom)).to eq 'Fondation SFR'
      expect(champ.type_de_champ.champ_value_for_export(champ, :address)).to eq '16 Rue du Général de Boissieu 75015 Paris'
      expect(champ.type_de_champ.champ_value_for_export(champ, :code_insee)).to eq '75115'
      expect(champ.type_de_champ.champ_value_for_export(champ, :departement)).to eq '75 – Paris'
    end
  end
end
