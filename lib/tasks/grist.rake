namespace :grist do
  desc 'Import Grist data'
  GRIST_DOC_ID = ENV.fetch('GRIST_DOC_ID', '8WQJkhi9Crx3DRW89iNkWh')
  GRIST_TABLE_ID = ENV.fetch('GRIST_TABLE_ID', 'Import_ds2')

  task import: :environment do
    GristSyncService.new.import
  end

  task create_columns: :environment do
    hash = GristSyncService.new.create_columns

    puts hash.to_json
  end

  task list_columns: :environment do
    hash = Grist::Client.new.list_columns(GRIST_DOC_ID, GRIST_TABLE_ID)

    puts hash.to_json
  end
end
