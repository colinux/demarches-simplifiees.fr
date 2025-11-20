# frozen_string_literal: true

class AttestationPdfGenerationJob < ApplicationJob
  queue_as :default

  def perform(dossier)
    # Idempotence: si attestation existe déjà, on s'arrête
    return if dossier.attestation.present?

    template = template_for(dossier)
    return unless template

    # Générer le PDF (peut échouer - exception levée AVANT création attestation)
    pdf_data = template.build_pdf(dossier)

    # Créer l'attestation + attacher PDF (atomique)
    attestation = Attestation.new
    attestation.title = template.send(:replace_tags, template.title, dossier, escape: false) if template.version == 1
    attestation.dossier = dossier
    attestation.pdf.attach(
      io: StringIO.new(pdf_data),
      filename: "attestation-#{dossier.id}.pdf",
      content_type: 'application/pdf',
      metadata: { virus_scan_result: ActiveStorage::VirusScanner::SAFE }
    )
    attestation.save!
  end

  private

  def template_for(dossier)
    kind = if accepte?
      :acceptation
    elsif refuse?
      :refus
    end

    dossier.attestation_template_for(AttestationTemplate.kinds.fetch(kind))
  end
end
