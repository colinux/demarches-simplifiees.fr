# frozen_string_literal: true

FactoryBot.define do
  factory :procedure_presentation do
    transient do
      procedure { create(:procedure, :with_instructeur, :with_type_de_champ) }
    end

    assign_to { association :assign_to, procedure: procedure, instructeur: procedure.instructeurs.first }
  end
end
