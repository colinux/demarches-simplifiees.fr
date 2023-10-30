class CreateReleaseNotes < ActiveRecord::Migration[7.0]
  def change
    create_table :release_notes do |t|
      t.date :released_on
      t.string :group
      t.text :body, default: nil
      t.boolean :published, default: false, null: false
      t.string :categories, array: true, default: []

      t.timestamps
    end

    add_index :release_notes, [:released_on, :group]
    add_index :release_notes, :published
    add_index :release_notes, :categories, using: :gin
  end
end
