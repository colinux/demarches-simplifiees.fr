# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

# Simple Grist API Client
module Grist
  class Client
    API_BASE_URL = 'https://grist.numerique.gouv.fr'

    attr_reader :api_key

    def initialize(api_key = ENV.fetch('GRIST_API_KEY'))
      @api_key = api_key
    end

    def list_columns(doc_id, table_id)
      uri = URI("#{API_BASE_URL}/api/docs/#{doc_id}/tables/#{table_id}/columns")
      http, request = configure_http(uri, :get)

      response = http.request(request)
      handle_response(response)
    end

    def create_columns(doc_id, table_id, columns)
      uri = URI("#{API_BASE_URL}/api/docs/#{doc_id}/tables/#{table_id}/columns")

      http, request = configure_http(uri, :post)
      request.body = { columns: }.to_json

      response = http.request(request)
      handle_response(response)
    end

    # @param doc_id [String] The document ID
    # @param table_id [String] The table ID
    # @param records [Array<Hash>] An array of records to add or update.
    #   Each hash should have a :require and :fields key.
    #   e.g. { require: { 'dossier_id': 123 }, fields: { 'column_a': 'value' } }
    # @return [Hash] The parsed JSON response from the Grist API
    def put_records(doc_id, table_id, records)
      uri = URI("#{API_BASE_URL}/api/docs/#{doc_id}/tables/#{table_id}/records")

      http, request = configure_http(uri, :put)
      request.body = { records: }.to_json

      response = http.request(request)
      handle_response(response)
    end

    private

    def configure_http(uri, method)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')

      request = case method
      when :get
        Net::HTTP::Get.new(uri.path)
      when :post
        Net::HTTP::Post.new(uri.path)
      when :put
        Net::HTTP::Put.new(uri.path)
      end

      request['Authorization'] = "Bearer #{api_key}"
      request['Content-Type'] = 'application/json'

      [http, request]
    end

    def handle_response(response)
      if response.is_a?(Net::HTTPSuccess)
        JSON.parse(response.body) if response.body.present?
      else
        raise "Erreur de l'API Grist : #{response.code} #{response.message} - #{response.body}"
      end
    end
  end
end
