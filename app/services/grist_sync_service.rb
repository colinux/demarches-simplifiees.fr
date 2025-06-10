# frozen_string_literal: true

require 'csv'
require 'grist/client' # Assurez-vous que le client Grist est chargé

class GristSyncService
  # CONFIGURATION
  # =================================================================
  # Ces valeurs doivent être configurées pour votre installation spécifique.
  # L'utilisation de variables d'environnement est recommandée en production.
  #
  # L'ID de votre document Grist.
  GRIST_DOC_ID = ENV.fetch('GRIST_DOC_ID', '8WQJkhi9Crx3DRW89iNkWh')
  # L'ID de la table dans votre document Grist.
  GRIST_TABLE_ID = ENV.fetch('GRIST_TABLE_ID', 'Import_ds2')
  # L'ID de la procédure Démarches Simplifiées à partir de laquelle exporter.
  PROCEDURE_ID = 1 # À remplacer par l'ID réel de la procédure
  # L'ID du profil instructeur à utiliser pour l'export.
  # Cela détermine quels dossiers sont visibles.
  INSTRUCTEUR_ID = 1 # À remplacer par l'ID réel de l'instructeur
  # (Optionnel) L'ID d'un modèle d'export à utiliser.
  EXPORT_TEMPLATE_ID = nil
  # Le nom de la colonne dans votre table Grist qui stocke l'ID du dossier.
  # Elle est utilisée pour faire correspondre les enregistrements.
  GRIST_DOSSIER_ID_COLUMN = 'dossier_id'
  # L'en-tête EXACT de la colonne de l'ID du dossier dans le CSV généré.
  # ex: 'Numéro du dossier', 'ID Dossier', etc.
  # Cette valeur est sensible à la casse.
  DOSSIER_ID_CSV_HEADER = 'dossier_id'
  # =================================================================

  def initialize
    @grist_client = Grist::Client.new
  end

  def import
    Rails.logger.info('Début de la synchronisation Grist.')

    # setup_export_context
    # csv_data = generate_csv_data
    csv_data = File.read('tmp/dossiers-journee-marseille.csv')

    records = build_grist_records(csv_data)
    Rails.logger.info("Trouvé #{records.count} dossiers à synchroniser.")

    upload_records_to_grist(records)

    Rails.logger.info('Synchronisation Grist terminée.')
  rescue ActiveRecord::RecordNotFound => e
    puts e
    Rails.logger.error("Erreur de configuration pour la synchronisation Grist: #{e.message}")
  rescue StandardError => e
    puts e
    Rails.logger.error("Une erreur est survenue lors de la synchronisation Grist: #{e.message}\\n#{e.backtrace.join("\n")}")
  end

  def create_columns
    lines = File.read('tmp/dossiers-journee-marseille.csv')

    csv_data = CSV.parse(lines, headers: true, col_sep: ';')

    columns = csv_data.headers.each_with_object([]) do |col_name, array|
      array << { id: column_id(col_name), fields: { label: col_name } }
    end

    Grist::Client.new.create_columns(GRIST_DOC_ID, GRIST_TABLE_ID, columns)
  end

  private

  # def setup_export_context
  #   @procedure = Procedure.find(PROCEDURE_ID)
  #   @instructeur = Instructeur.find(INSTRUCTEUR_ID)
  #   @export_template = EXPORT_TEMPLATE_ID ? ExportTemplate.find(EXPORT_TEMPLATE_ID) : nil
  # end

  # def generate_csv_data
  #   # Nous réutilisons la logique d'export pour obtenir le bon jeu de dossiers
  #   export = Export.new(
  #     procedure_presentation: @procedure.presentation,
  #     groupe_instructeurs: @instructeur.groupe_instructeurs,
  #     user_profile: @instructeur,
  #     export_template: @export_template,
  #     format: :csv
  #   )

  #   dossiers = export.send(:dossiers_for_export)

  #   # Utilisation de ProcedureExportService pour générer les données CSV en mémoire
  #   service = ProcedureExportService.new(@procedure, dossiers, @instructeur, @export_template)
  #   service.to_csv.download
  # end

  def build_grist_records(csv_data)
    records = []
    # Les en-têtes CSV peuvent contenir des caractères spéciaux ou des espaces.
    # Grist requiert des identifiants de colonnes simples (sans caractères non-ASCII, etc.).
    # Nous allons les "nettoyer" pour les rendre compatibles.
    CSV.parse(csv_data, headers: true, col_sep: ';').each do |row|
      row_hash = row.to_h

      # L'en-tête de la colonne de l'ID du dossier dans le CSV.
      # ex: 'Numéro du dossier'
      dossier_id = row_hash.fetch(DOSSIER_ID_CSV_HEADER, nil)
      next if dossier_id.blank?

      # Nettoyage des clés (en-têtes) pour la compatibilité avec Grist.
      # "Date de dépôt" -> "date_de_depot"
      # "Établissement" -> "etablissement"
      sanitized_fields = row_hash.transform_keys do |key|
        column_id(key)
      end

      # Exclure l'ID de dossier des champs à envoyer, car il sert de clé de rapprochement.
      # La clé a aussi été nettoyée, nous utilisons donc sa version "parameterized".
      dossier_id_header_sanitized = DOSSIER_ID_CSV_HEADER.parameterize.underscore
      fields_to_update = sanitized_fields.except(dossier_id_header_sanitized)

      records << {
        require: { GRIST_DOSSIER_ID_COLUMN.to_sym => dossier_id.to_i },
        fields: fields_to_update
      }
    end
    records
  end

  def column_id(key)
    key.parameterize.underscore
  end

  def upload_records_to_grist(records)
    return if records.empty?

    # Envoyer les données à Grist par lots pour éviter les requêtes trop volumineuses
    records.in_groups_of(100, false).each do |batch|
      Rails.logger.info("Envoi de #{batch.size} enregistrements à Grist...")
      @grist_client.put_records(GRIST_DOC_ID, GRIST_TABLE_ID, batch)
    end
  end
end
