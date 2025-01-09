# frozen_string_literal: true

class Types::DossierLabelType < Types::LabelType
  field :date_modification, GraphQL::Types::ISO8601DateTime,
    "Date de dernière modification de ce label sur le dossier", null: false, method: :updated_at

  def id
    object.label.to_typed_id
  end

  def name
    object.label.name
  end

  def color
    object.label.color
  end

  def self.authorized?(object, context)
    context.authorized_demarche?(object.label.procedure)
  end
end
