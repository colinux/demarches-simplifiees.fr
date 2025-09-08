# frozen_string_literal: true

class TypesDeChamp::DropDownListTypeDeChamp < TypesDeChamp::TypeDeChampBase
  def champ_value(champ)
    if drop_down_advanced? && champ.respond_to?(:referentiel) && champ.referentiel.present?
      path = champ.referentiel_headers&.first&.second
      champ.referentiel_item_value(path)
    else
      super
    end
  end

  def champ_value_for_export(champ, path = :value)
    if drop_down_advanced? && path != :value
      champ.referentiel_item_value(path)
    else
      super
    end
  end

  def champ_value_for_tag(champ, path = :value)
    if drop_down_advanced? && path != :value
      champ.referentiel_item_value(path)
    else
      super
    end
  end

  def columns(procedure:, displayable: true, prefix: nil)
    if drop_down_advanced?
      referentiel.present? ? referentiel.headers_with_path.map do |(header, path)|
        Columns::JSONPathColumn.new(
          procedure_id: procedure.id,
          stable_id:,
          tdc_type: type_champ,
          label: "#{libelle_with_prefix(prefix)} – Référentiel #{header}",
          type: :enum,
          jsonpath: "$.referentiel.data.row.#{path}",
          displayable:,
          options_for_select: referentiel.options_for_path(path),
          mandatory: mandatory?
        )
      end : []
    else
      super
    end
  end

  def paths
    if drop_down_advanced? && referentiel.present?
      referentiel.headers_with_path.map do |(header, path)|
        {
          libelle: "#{libelle} (#{header})",
          description: "#{description} (#{header})",
          path:,
          maybe_null: public? && !mandatory?
        }
      end
    else
      super
    end
  end
end
