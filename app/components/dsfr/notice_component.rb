# frozen_string_literal: true

# see: https://www.systeme-de-design.gouv.fr/elements-d-interface/composants/bandeau-d-information-importante/
class Dsfr::NoticeComponent < ApplicationComponent
  renders_one :title
  renders_one :description

  attr_reader :state
  attr_reader :data_attributes

  def initialize(state: :info, closable: false, data_attributes: {})
    @state = state
    @closable = closable
    @data_attributes = data_attributes
  end

  def closable?
    !!@closable
  end

  def notice_class_names
    class_names(
      "fr-notice--info" => state == :info,
      "fr-notice--warning" => state == :warning
    )
  end

  def notice_data_attributes
    { "data-dsfr-header-target": "notice" }.merge(data_attributes)
  end
end
