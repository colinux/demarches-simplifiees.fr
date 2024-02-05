class Champs::RNAChamp < Champ
  include RNAChampAssociationFetchableConcern

  validates :value, allow_blank: true, format: {
    with: /\AW[0-9]{9}\z/, message: I18n.t(:not_a_rna, scope: 'activerecord.errors.messages')
  }, if: :validate_champ_value?

  delegate :id, to: :procedure, prefix: true

  def title
    data&.dig("association_titre")
  end

  def identifier
    title.present? ? "#{value} (#{title})" : value
  end

  def for_export
    identifier
  end

  def search_terms
    etablissement.present? ? etablissement.search_terms : [value]
  end

  def rna_address
    # TODO: enregistrer l'adresse depuis l'API en base
    # puis adapter la sortie ici.
    # Actuellement aucune info sur l'adresse n'est enregistrée.
    {
      label: data["address_label"],
      street_address: nil,
      street_number: nil,
      street_name: nil,
      postal_code: data["code_postal"],
      city_name: data["localite"],
      city_code: data["cose_insee_localite"],
      departement_name: departement_name,
      departement_code: code_departement
    }
  end

  # Reprise du code adapté depuis RNFChamp, probablement à mettre dans un concern
  def departement?
    code_departement.present?
  end

  def code_departement
    return if data["code_insee_localite"].blank?

    data["code_insee_localite"][..1] # extraction depuis le code INSEE
  end

  def departement
    if departement?
      { code: code_departement, name: departement_name }
    end
  end

  def departement_name
    APIGeoService.departement_name(code_departement)
  end

  def departement_code_and_name
    if departement?
      "#{code_departement} – #{departement_name}"
    end
  end

  def commune_name
    if departement?
      "#{APIGeoService.commune_name(department_code, etablissement.code_insee_localite)} (#{etablissement.code_postal})"
    end
  end

  def commune
    if departement?
      city_code = etablissement.code_insee_localite
      city_name = etablissement.localite
      postal_code = etablissement.code_postal

      commune_name = APIGeoService.commune_name(department_code, city_code)
      commune_code = APIGeoService.commune_code(department_code, city_name)

      if commune_name.present?
        {
          code: city_code,
          name: commune_name
        }
      elsif commune_code.present?
        {
          code: commune_code,
          name: city_name
        }
      else
        {
          code: city_code,
          name: city_name
        }
      end.merge(postal_code:)
    end
  end
end
