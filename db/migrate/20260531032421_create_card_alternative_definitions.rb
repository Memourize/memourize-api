class CreateCardAlternativeDefinitions < ActiveRecord::Migration[8.0]
  def change
    create_table :card_alternative_definitions do |t|
      t.references :card, null: false, foreign_key: true
      t.text :content, null: false
      t.integer :position, null: false

      t.timestamps
    end
  end
end
