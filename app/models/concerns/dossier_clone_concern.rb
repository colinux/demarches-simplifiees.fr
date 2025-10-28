# frozen_string_literal: true

module DossierCloneConcern
  extend ActiveSupport::Concern

  included do
    belongs_to :parent_dossier, class_name: 'Dossier', optional: true
    has_many :cloned_dossiers, class_name: 'Dossier', foreign_key: :parent_dossier_id, dependent: :nullify, inverse_of: :parent_dossier
  end

  def clone(user: nil)
    dossier_attributes = [:autorisation_donnees, :revision_id]
    relationships = [:individual, :etablissement]

    discarded_row_ids = champs_on_main_stream
      .filter { _1.row? && _1.discarded? }
      .to_set(&:row_id)
    cloned_champs = champs_on_main_stream
      .reject { discarded_row_ids.member?(_1.row_id) }
      .map(&:clone)

    cloned_dossier = deep_clone(only: dossier_attributes, include: relationships) do |original, kopy|
      ClonePiecesJustificativesService.clone_attachments(original, kopy)

      if original.is_a?(Dossier)
        kopy.parent_dossier = original
        kopy.user = user || original.user
        kopy.state = Dossier.states.fetch(:brouillon)
        kopy.champs = cloned_champs.map do |champ|
          champ.dossier = kopy
          champ
        end
      end
    end

    transaction do
      cloned_dossier.validate(:champs_public_value)
      cloned_dossier.save!
      cloned_dossier.rebase!
    end

    cloned_dossier.index_search_terms_later
    cloned_dossier.reload
  end
end
