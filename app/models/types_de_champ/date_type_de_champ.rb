# frozen_string_literal: true

class TypesDeChamp::DateTypeDeChamp < TypesDeChamp::TypeDeChampBase
  def champ_value(champ)
    I18n.l(Time.zone.parse(champ.value), format: '%d %B %Y')
  rescue ArgumentError
    champ.value.presence || "" # old dossiers can have not parseable dates
  end
end
